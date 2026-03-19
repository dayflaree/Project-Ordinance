-- Client hooks for Funding module
local MODULE = MODULE

if (CLIENT) then
    -- Add an Economy tab to the Parallax TAB menu
    hook.Add("PopulateTabButtons", "bmrp_funding_tab_economy", function(buttons)
        if ( !istable(buttons) ) then return end

        buttons["economy"] = {
            Populate = function(this, panel)
                panel:Add("bmrp.economy")
            end,
            OnOpen = function(this, panel)
                -- When opening the tab, optionally request fresh funding data
                if (MODULE and isfunction(MODULE.RequestFunding)) then
                    MODULE:RequestFunding()
                end
            end
        }
    end)
end
