ITEM.name = "Night Vision Goggles"
ITEM.description = "A pair of night vision goggles that enhance vision in low-light conditions."
ITEM.category = "Equipment"
ITEM.model = Model("models/ventrische/w_quadnods.mdl")

ITEM.weight = 0.7

local function equipNVGs(item, client)
    local gun = client:GetActiveWeapon()
    if ( IsValid(gun) and !client.vrnvgbroken and !client.vrnvgflipped ) then
        client:SetSuppressPickupNotices(true)

        local vrnvgs = client:Give("vrnvgs")
        if ( !IsValid(vrnvgs) ) then
            vrnvgs = client:GetWeapon("vrnvgs")
        end

        if ( IsValid(vrnvgs) ) then
            vrnvgs.slamholdtype = true
            client:SelectWeapon("vrnvgs")
        else
            print("NVGs: potentially broken by another mod, look for a weapon pickup related addon in your addons and disable it.")
        end

        client:SetSuppressPickupNotices(false)
    end
end

ITEM:AddAction("equip", {
    name = "Equip",
    description = "Equip this outfit.",
    icon = "parallax/icons/check-circle.png",
    OnRun = function(action, client, item)
        equipNVGs(item, client)

        return false -- Returning false prevents the item from being removed after use
    end,
    CanUse = function(action, client, item)
        return client:GetNW2Bool("vrnvgequipped", false) == false -- Can only equip if the player doesn't already have the NVGs equipped
    end
})

ITEM:AddAction("unequip", {
    name = "Unequip",
    description = "Unequip this outfit.",
    icon = "parallax/icons/minus-circle.png",
    OnRun = function(action, client, item)
        equipNVGs(item, client)

        return false -- Returning false prevents the item from being removed after use
    end,
    CanUse = function(action, client, item)
        return client:GetNW2Bool("vrnvgequipped", false) == true and client:GetNW2Bool("vrnvgflipped", false) == false -- Can only unequip if the NVGs are currently equipped and not flipped up
    end
})

ITEM:AddAction("flip", {
    name = "Flip",
    description = "Flip the NVGs up or down.",
    icon = "parallax/icons/flip-circle.png",
    OnRun = function(action, client, item)
        client:ConCommand("vrnvgflip")

        return false -- Returning false prevents the item from being removed after use
    end,
    CanUse = function(action, client, item)
        return client:GetNW2Bool("vrnvgequipped", false) == true -- Can only flip if the NVGs are equipped
    end
})
