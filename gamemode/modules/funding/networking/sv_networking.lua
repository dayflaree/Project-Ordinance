local MODULE = MODULE

local function GetFundingModule()
    local mod = MODULE
    if (not mod or not mod.funding) then
        mod = ax.module and ax.module:Get("funding") or mod
    end
    if (mod and mod.funding) then return mod end
end

-- Send full snapshot to a single player
function MODULE:SendSnapshot(ply)
    local mod = GetFundingModule()
    if (SERVER and IsValid(ply) and mod and mod.funding and mod.funding.BuildSnapshot) then
        if (mod.funding.EnsureStructureWithDefaults) then
            mod.funding:EnsureStructureWithDefaults()
        end
        local snap = mod.funding:BuildSnapshot()
        -- Parallax ax.net: send message with payload to a specific player
        ax.net:Start(ply, "funding.init", snap)
    end
end

-- Client requests current funding snapshot when opening the panel
ax.net:Hook("funding.request", function(ply)
    if (not IsValid(ply)) then return end
    if (MODULE and MODULE.SendSnapshot) then
        MODULE:SendSnapshot(ply)
    end
end)

-- Helper to broadcast updates when values change in future edits
function MODULE:BroadcastUpdate()
    local mod = GetFundingModule()
    if (not mod or not mod.funding or not mod.funding.BuildSnapshot) then return end
    if (mod.funding.EnsureStructureWithDefaults) then
        mod.funding:EnsureStructureWithDefaults()
    end
    local snap = mod.funding:BuildSnapshot()
    ax.net:Start(nil, "funding.update", snap) -- broadcast
end

-- Example: server may periodically push history points and rebroadcast.
-- Keep lightweight; actual timers should live elsewhere if expanded.
if (SERVER) then
    local function applyMonthlyOpsCharge(spanSeconds)
        local mod = GetFundingModule()
        if (not mod or not mod.funding) then return end
        local monthly = mod.funding:GetMonthlyOpsTotal()
        local g = tonumber(mod.funding:GetGlobal() or 0) or 0
        local newG = math.max(0, g - monthly)
        mod.funding:SetGlobal(newG)

        -- Build breakdown summary for notifications
        local categories = mod.funding.ops.monthlyUSDByCategory or {}
        local parts = {}
        local labels = {
            utilities = "Utilities",
            infrastructure = "Infrastructure",
            medical_ops = "Medical",
            supplies_logistics = "Logistics",
            security_ops = "Security",
            rnd_ops = "R&D",
            compliance_safety = "Compliance"
        }
        for k, v in pairs(categories) do
            table.insert(parts, { id = k, amount = tonumber(v) or 0 })
        end
        table.sort(parts, function(a, b) return (a.amount or 0) > (b.amount or 0) end)

        local function money(n)
            n = tonumber(n) or 0
            return string.format("$%s", tostring(math.floor(n + 0.5)))
        end

        local summary = "Operations cost: -" .. money(monthly)
        local segs = {}
        for i = 1, math.min(3, #parts) do
            local p = parts[i]
            table.insert(segs, string.format("%s %s", labels[p.id] or p.id, money(p.amount)))
        end
        if (#segs > 0) then
            summary = summary .. " (" .. table.concat(segs, ", ") .. ")"
        end

        if (mod.funding.AddEvent) then
            mod.funding:AddEvent("info", "Monthly Operations", summary, { seconds = spanSeconds, amount = monthly })
        end
        for _, ply in ipairs(player.GetAll()) do
            if (IsValid(ply)) then ply:Notify(summary) end
        end
    end

    timer.Create("bmrp_funding_history_tick", 5, 0, function()
        local mod = GetFundingModule()
        if (not mod or not mod.funding or not mod.funding.data) then return end

        mod.funding.ops = mod.funding.ops or {}
        local tickSec = (mod.funding.ops.tickSeconds or 5)
        mod.funding.ops._accumulatedSeconds = (mod.funding.ops._accumulatedSeconds or 0) + tickSec

        local monthSec = (mod.funding.ops.monthSeconds or 432000)
        if (mod.funding.ops._accumulatedSeconds >= monthSec) then
            applyMonthlyOpsCharge(mod.funding.ops._accumulatedSeconds)
            mod.funding.ops._accumulatedSeconds = mod.funding.ops._accumulatedSeconds - monthSec
        end

        -- 2) Rebalance allocations proportionally to maintain shares
        local list = mod.funding.data.allocations or {}
        local sum = 0
        for _, r in ipairs(list) do sum = sum + (tonumber(r.amount) or 0) end
        if (sum <= 0) then
            -- If unseeded, use EnsureStructureWithDefaults to seed from global
            mod.funding:EnsureStructureWithDefaults()
        else
            for _, r in ipairs(list) do
                local share = (tonumber(r.amount) or 0) / math.max(1, sum)
                local g = tonumber(mod.funding:GetGlobal() or 0) or 0
                r.amount = math.floor(g * share)
            end
        end

        -- 3) Record history points and broadcast to clients for live updates
        mod.funding:PushHistoryPoint(mod.funding:GetGlobal())
        mod.funding:PushAllocationHistoryPoints()
        if (mod.BroadcastUpdate) then
            mod:BroadcastUpdate()
        end
    end)
end
