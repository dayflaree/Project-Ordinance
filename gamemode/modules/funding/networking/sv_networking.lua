local MODULE = MODULE

-- Send full snapshot to a single player
function MODULE:SendSnapshot(ply)
    if (SERVER and IsValid(ply)) then
        local snap = self.funding:BuildSnapshot()
        -- Parallax ax.net: send message with payload to a specific player
        ax.net.Start("funding.init", ply, snap)
    end
end

-- Client requests current funding snapshot when opening the panel
ax.net.Hook("funding.request", function(ply)
    if (not IsValid(ply)) then return end
    MODULE:SendSnapshot(ply)
end)

-- Helper to broadcast updates when values change in future edits
function MODULE:BroadcastUpdate()
    local snap = self.funding:BuildSnapshot()
    ax.net.Start("funding.update", nil, snap) -- broadcast
end

-- Example: server may periodically push history points and rebroadcast.
-- Keep lightweight; actual timers should live elsewhere if expanded.
if (SERVER) then
    timer.Create("bmrp_funding_history_tick", 5, 0, function()
        if (not MODULE or not MODULE.funding or not MODULE.funding.data) then return end
        MODULE.funding:PushHistoryPoint(MODULE.funding:GetGlobal())
        -- Optionally broadcast less frequently in production.
        -- MODULE:BroadcastUpdate()
    end)
end
