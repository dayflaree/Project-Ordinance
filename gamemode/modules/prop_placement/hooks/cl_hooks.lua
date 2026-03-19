local MODULE = MODULE

local function openCatalog()
    if (IsValid(MODULE._propCatalog)) then
        MODULE._propCatalog:ClosePanel()
    end

    local pnl = vgui.Create("bmrp.prop_catalog")
    MODULE._propCatalog = pnl
    local payload = MODULE:RequestCatalog() or { categories = {} }
    pnl:SetCatalogData(payload.categories or {})
end

hook.Add("PlayerBindPress", "bmrp.prop_placement.open", function(ply, bind, pressed)
    if (not pressed or ply ~= LocalPlayer()) then return end
    if (bind == "impulse 101") then return end
    if (string.find(bind, "+menu_context") or string.find(bind, "+gm_spare2")) then
        openCatalog()
        return true
    end
end)

hook.Add("ShowSpare2", "bmrp.prop_placement.spare2", function(ply)
    if (ply ~= LocalPlayer()) then return end
    openCatalog()
    return true
end)