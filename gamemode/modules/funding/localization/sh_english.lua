-- Localization for Funding module
if (ax and ax.localization and isfunction(ax.localization.Register)) then
    ax.localization:Register("en", {
        ["tab.economy"] = "Economy",
    })
end
