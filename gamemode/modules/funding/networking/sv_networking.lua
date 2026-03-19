local MODULE = MODULE

-- Send full snapshot to a single player
function MODULE:SendSnapshot(ply)
    if (SERVER and IsValid(ply)) then
        local snap = self.funding:BuildSnapshot()
        -- Parallax ax.net: send message with payload to a specific player
        ax.net:Start(ply, "funding.init", snap)
    end
end

-- Client requests current funding snapshot when opening the panel
ax.net:Hook("funding.request", function(ply)
    if (not IsValid(ply)) then return end
    MODULE:SendSnapshot(ply)
end)

-- Helper to broadcast updates when values change in future edits
function MODULE:BroadcastUpdate()
    local snap = self.funding:BuildSnapshot()
    ax.net:Start(nil, "funding.update", snap) -- broadcast
end

-- Example: server may periodically push history points and rebroadcast.
-- Keep lightweight; actual timers should live elsewhere if expanded.
if (SERVER) then
    timer.Create("bmrp_funding_history_tick", 5, 0, function()
        if (not MODULE or not MODULE.funding or not MODULE.funding.data) then return end

        -- Deterministic operating cost: subtract evenly amortized monthly ops
        local g = tonumber(MODULE.funding:GetGlobal() or 0) or 0
        local cost = MODULE.funding:ComputeOpsTickCost()
        local newG = math.max(0, g - cost)
        MODULE.funding:SetGlobal(newG)

        -- Accumulate for periodic audit + notifications (summarize every ~60s)
        MODULE.funding.ops = MODULE.funding.ops or {}
        local tickSec = (MODULE.funding.ops.tickSeconds or 5)
        MODULE.funding.ops._accumulatedCost = (MODULE.funding.ops._accumulatedCost or 0) + (tonumber(cost) or 0)
        MODULE.funding.ops._accumulatedSeconds = (MODULE.funding.ops._accumulatedSeconds or 0) + tickSec

        if (MODULE.funding.ops._accumulatedSeconds >= 60) then
            local delta = MODULE.funding.ops._accumulatedCost or 0
            -- Build a compact breakdown using category proportions
            local monthly = MODULE.funding:GetMonthlyOpsTotal()
            local categories = MODULE.funding.ops.monthlyUSDByCategory or {}
            local monthSec = (MODULE.funding.ops.monthSeconds or 432000)
            local spanSec = MODULE.funding.ops._accumulatedSeconds

            -- Compute per-category spend over the accumulated seconds
            local parts = {}
            if (monthly > 0 and spanSec > 0) then
                for k, v in pairs(categories) do
                    local share = (tonumber(v) or 0) / monthly
                    local catSpend = share * (monthly / monthSec) * spanSec
                    table.insert(parts, { id = k, amount = catSpend })
                end
            end

            -- Generate a simple one-line summary
            local function money(n)
                n = tonumber(n) or 0
                return string.format("$%s", tostring(math.floor(n + 0.5)))
            end

            local summary = "Operations cost: -" .. money(delta)
            -- Keep the breakdown short (first 3 categories) to avoid spam
            table.sort(parts, function(a, b) return (a.amount or 0) > (b.amount or 0) end)
            local labels = {
                utilities = "Utilities",
                infrastructure = "Infrastructure",
                medical_ops = "Medical",
                supplies_logistics = "Logistics",
                security_ops = "Security",
                rnd_ops = "R&D",
                compliance_safety = "Compliance"
            }
            local segs = {}
            for i = 1, math.min(3, #parts) do
                local p = parts[i]
                table.insert(segs, string.format("%s %s", labels[p.id] or p.id, money(p.amount)))
            end
            if (#segs > 0) then
                summary = summary .. " (" .. table.concat(segs, ", ") .. ")"
            end

            -- Add to audit feed
            MODULE.funding:AddEvent("info", "Monthly Operations", summary, { seconds = spanSec, amount = delta })

            -- Notify all connected players
            for _, ply in ipairs(player.GetAll()) do
                if (IsValid(ply)) then ply:Notify(summary) end
            end

            -- reset accumulators
            MODULE.funding.ops._accumulatedCost = 0
            MODULE.funding.ops._accumulatedSeconds = 0
        end

        -- 2) Rebalance allocations proportionally to maintain shares
        local list = MODULE.funding.data.allocations or {}
        local sum = 0
        for _, r in ipairs(list) do sum = sum + (tonumber(r.amount) or 0) end
        if (sum <= 0) then
            -- If unseeded, use EnsureStructureWithDefaults to seed from global
            MODULE.funding:EnsureStructureWithDefaults()
        else
            for _, r in ipairs(list) do
                local share = (tonumber(r.amount) or 0) / math.max(1, sum)
                r.amount = math.floor(newG * share)
            end
        end

        -- 3) Record history points and broadcast to clients for live updates
        MODULE.funding:PushHistoryPoint(newG)
        MODULE.funding:PushAllocationHistoryPoints()
        MODULE:BroadcastUpdate()
    end)
end
