ITEM.name = "Trash Piece"
ITEM.description = "Loose facility waste that should be disposed of in a nearby trash bin."
ITEM.model = Model("models/props_junk/garbage_bag001a.mdl")
ITEM.category = "Maintenance"
ITEM.weight = 0.2
ITEM.price = 0
ITEM.shouldStack = true
ITEM.maxStack = 12

local function FindNearbyTrashBin(client)
    if ( istable(TRASH) and isfunction(TRASH.FindNearbyBin) ) then
        return TRASH:FindNearbyBin(client)
    end

    return nil
end

ITEM:AddAction("dispose", {
    name = "Dispose",
    description = "Dispose of this trash in a nearby trash bin.",
    order = 5,
    icon = "parallax/icons/trash-2.png",
    CanUse = function(action, client, item)
        local trashBin = FindNearbyTrashBin(client)
        if ( !IsValid(trashBin) ) then
            return false, "You need to be near a trash bin."
        end

        if ( !isfunction(trashBin.CanStoreClass) ) then
            return false, "This trash bin cannot store trash right now."
        end

        local canStore, reason = trashBin:CanStoreClass(item.class)
        if ( !canStore ) then
            return false, reason or "This trash bin is full."
        end

        return true
    end,
    OnRun = function(action, client, item)
        local inventory = ax.inventory.instances[item:GetInventoryID()]
        local trashBin = FindNearbyTrashBin(client)
        trashBin:StoreClass(item.class)
        inventory:RemoveItem(item.id)
        trashBin:EmitSound("physics/metal/metal_canister_impact_hard2.wav", 65, 100)
        client:Notify("You disposed of the trash.", "success")

        return false
    end
})
