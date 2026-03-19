-- Client hooks for Funding module
local MODULE = MODULE

if (CLIENT) then
    -- Add an Economy tab to the Parallax TAB menu
    hook.Add("PopulateTabButtons", "bmrp_funding_tab_economy", function(buttons)
        if ( !istable(buttons) ) then return end

        buttons["economy"] = {
            Populate = function(this, panel)
                local pnl = panel:Add("bmrp.economy")
                if (IsValid(pnl)) then
                    MODULE._economyPanel = pnl
                    -- Ensure we fetch fresh data whenever panel is (re)built
                    if (MODULE and isfunction(MODULE.RequestFunding)) then
                        MODULE:RequestFunding()
                    end
                end
            end,
            OnOpen = function(this, panel)
                -- When opening the tab, optionally request fresh funding data
                if (MODULE and isfunction(MODULE.RequestFunding)) then
                    MODULE:RequestFunding()
                end
                -- Only prefill UI after we've received at least one real snapshot
                if (MODULE and MODULE._fundingInited and IsValid(MODULE._economyPanel) and MODULE.funding and MODULE.funding.BuildSnapshot) then
                    MODULE._economyPanel:SetData(MODULE.funding:BuildSnapshot())
                end
            end
        }
    end)
end
