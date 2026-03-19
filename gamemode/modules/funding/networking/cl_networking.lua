local MODULE = MODULE

-- Receive initial snapshot
ax.net:Hook("funding.init", function(data)
    MODULE.funding:ApplySnapshot(data)
    MODULE._fundingInited = true

    -- Update UI panel if open (prefer the instance we created during Populate)
    if (IsValid(MODULE._economyPanel)) then
        MODULE._economyPanel:SetData(MODULE.funding:BuildSnapshot())
    elseif (IsValid(ax.gui) and IsValid(ax.gui.main) and IsValid(ax.gui.main.economy)) then
        ax.gui.main.economy:SetData(MODULE.funding:BuildSnapshot())
    end
end, true)

-- Receive incremental updates
ax.net:Hook("funding.update", function(data)
    MODULE.funding:ApplySnapshot(data)
    MODULE._fundingInited = true
    if (IsValid(MODULE._economyPanel)) then
        MODULE._economyPanel:SetData(MODULE.funding:BuildSnapshot())
    elseif (IsValid(ax.gui) and IsValid(ax.gui.main) and IsValid(ax.gui.main.economy)) then
        ax.gui.main.economy:SetData(MODULE.funding:BuildSnapshot())
    end
end, true)

-- Convenience to request snapshot
function MODULE:RequestFunding()
    ax.net:Start("funding.request")
end
