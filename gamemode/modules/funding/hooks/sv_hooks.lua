-- Server hooks for Funding module
local MODULE = MODULE

if (SERVER) then
    -- Seed starting global budget on server init if not already set/persisted.
    hook.Add("Initialize", "bmrp_funding_seed_global", function()
        if (not MODULE or not MODULE.funding) then return end
        MODULE.funding:EnsureStructureWithDefaults()
        local current = tonumber(MODULE.funding:GetGlobal() or 0) or 0
        -- Only override the placeholder/default small value; respect saved states.
        if (current <= 100) then
            MODULE.funding:SetGlobal(MODULE.startGlobal or 275000000)
            MODULE.funding:PushHistoryPoint(MODULE.funding:GetGlobal())
            MODULE.funding:PushAllocationHistoryPoints()
        end
    end)

    -- Send a snapshot to players when they first join so UI has data immediately.
    hook.Add("PlayerInitialSpawn", "bmrp_funding_autosnap", function(ply)
        if (not IsValid(ply)) then return end
        if (MODULE and isfunction(MODULE.SendSnapshot)) then
            timer.Simple(2, function()
                if (IsValid(ply)) then MODULE:SendSnapshot(ply) end
            end)
        end
    end)
end
