ITEM.name = "Trash Bag"
ITEM.description = "A heavy-duty bag used to collect trash."
ITEM.model = Model("models/riggs9162/bmrp/items/trash_bag.mdl")
ITEM.category = "Maintenance"
ITEM.weight = 0.3
ITEM.price = 0
ITEM.shouldStack = false

local DEFAULT_MAX_BAG_WEIGHT = 10

local function GetBagMaxWeight()
    if ( istable(TRASH) and isfunction(TRASH.GetBagMaxStoredWeight) ) then
        return TRASH:GetBagMaxStoredWeight()
    end

    return DEFAULT_MAX_BAG_WEIGHT
end

local function FindLookedAtBin(client)
    if ( istable(TRASH) and isfunction(TRASH.GetLookedAtBin) ) then
        return TRASH:GetLookedAtBin(client)
    end

    return nil
end

local function GetLookDistance()
    if ( istable(TRASH) and isfunction(TRASH.GetBinLookDistance) ) then
        return TRASH:GetBinLookDistance()
    end

    return 196
end

local function IsTrashPieceClass(className)
    if ( !isstring(className) or className == "" ) then
        return false
    end

    if ( string.StartWith(className, "trash_piece_") ) then
        return true
    end

    local stored = ax.item and ax.item.stored and ax.item.stored[className]
    return istable(stored) and stored.base == "trash_piece"
end

local function FindLookedAtDroppedTrash(client)
    if ( !ax.util:IsValidPlayer(client) ) then
        return nil, nil
    end

    local trace = client:GetEyeTrace()
    if ( !istable(trace) ) then
        return nil, nil
    end

    local entity = trace.Entity
    if ( !IsValid(entity) or entity:GetClass() != "ax_item" ) then
        return nil, nil
    end

    local maxDistance = GetLookDistance()
    if ( client:GetPos():DistToSqr(entity:GetPos()) > maxDistance ^ 2 ) then
        return nil, nil
    end

    local droppedItem = entity:GetItemTable()
    if ( !istable(droppedItem) ) then
        return nil, nil
    end

    local invID = tonumber(droppedItem.invID)
    if ( invID and invID != 0 ) then
        return nil, nil
    end

    if ( !IsTrashPieceClass(droppedItem.class) ) then
        return nil, nil
    end

    return entity, droppedItem
end

local function GetStoredClasses(item)
    local stored = item:GetData("storedClasses", {})
    if ( !istable(stored) ) then
        stored = {}
    end

    return stored
end

local function GetClassWeight(className)
    local stored = ax.item and ax.item.stored and ax.item.stored[className]
    local weight = istable(stored) and tonumber(stored.weight) or nil
    if ( !isnumber(weight) or weight <= 0 ) then
        return 0.2
    end

    return math.Round(weight, 2)
end

local function GetStoredWeight(item)
    local total = 0
    local classes = GetStoredClasses(item)
    for i = 1, #classes do
        total = total + GetClassWeight(classes[i])
    end

    return math.Round(total, 2)
end

local function GetFreeBagWeight(item)
    return math.max(GetBagMaxWeight() - GetStoredWeight(item), 0)
end

local function GetInventoryTrashToBag(item, inventory)
    if ( !istable(inventory) ) then
        return {}, 0
    end

    local freeWeight = GetFreeBagWeight(item)
    if ( freeWeight <= 0 ) then
        return {}, 0
    end

    local candidates = inventory:GetItemsByBase("trash_piece", false)
    if ( !istable(candidates) or candidates[1] == nil ) then
        return {}, 0
    end

    table.sort(candidates, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)

    local baggedItems = {}
    local totalWeight = 0

    for i = 1, #candidates do
        local candidate = candidates[i]
        if ( !istable(candidate) or candidate.id == item.id ) then
            continue
        end

        local classWeight = GetClassWeight(candidate.class)
        if ( classWeight > 0 and totalWeight + classWeight <= freeWeight ) then
            baggedItems[#baggedItems + 1] = candidate
            totalWeight = totalWeight + classWeight
        end
    end

    return baggedItems, math.Round(totalWeight, 2)
end

local function GetTransferableBinWeight(item, trashBin)
    if ( !IsValid(trashBin) ) then
        return 0
    end

    local freeWeight = math.max(GetBagMaxWeight() - GetStoredWeight(item), 0)
    if ( freeWeight <= 0 ) then
        return 0
    end

    local binWeight = isfunction(trashBin.GetStoredWeight) and (tonumber(trashBin:GetStoredWeight()) or 0) or 0
    if ( binWeight <= 0 ) then
        return 0
    end

    local maxTransferWeight = math.min(freeWeight, binWeight)
    if ( !isfunction(trashBin.GetStoredTrashClasses) or !isfunction(trashBin.GetClassWeight) ) then
        return math.Round(maxTransferWeight, 2)
    end

    local classes = trashBin:GetStoredTrashClasses()
    if ( !istable(classes) ) then
        return 0
    end

    local transferableWeight = 0
    for i = 1, #classes do
        local classWeight = tonumber(trashBin:GetClassWeight(classes[i])) or 0
        if ( classWeight > 0 and transferableWeight + classWeight <= maxTransferWeight ) then
            transferableWeight = transferableWeight + classWeight
        end
    end

    return math.Round(transferableWeight, 2)
end

local function GetBinCollectDuration(client, transferWeight)
    local canManage = hook.Run("PlayerCanManageTrash", client) == true
    local minSeconds = canManage and 1 or 5
    local maxSeconds = canManage and 10 or 30

    return math.Remap(transferWeight, 0, GetBagMaxWeight(), minSeconds, maxSeconds)
end

function ITEM:GetWeight()
    return (self.weight or 0.3) + GetStoredWeight(self)
end

function ITEM:GetDescription()
    local count = #GetStoredClasses(self)
    local weight = GetStoredWeight(self)
    local maxWeight = GetBagMaxWeight()
    return "A heavy-duty bag used to collect trash. (" .. count .. " items, " .. weight .. "/" .. maxWeight .. " kg)"
end

ITEM:AddAction("collect_from_bin", {
    name = "Collect Trash",
    description = "Collect trash from a looked-at bin or dropped trash item.",
    order = 2,
    icon = "parallax/icons/trash-2.png",
    CanUse = function(action, client, item)
        local freeWeight = math.max(GetBagMaxWeight() - GetStoredWeight(item), 0)
        if ( freeWeight <= 0 ) then
            return false, "This trash bag is full."
        end

        local trashBin = FindLookedAtBin(client)
        if ( IsValid(trashBin) ) then
            local transferWeight = GetTransferableBinWeight(item, trashBin)
            if ( transferWeight <= 0 ) then
                if ( isfunction(trashBin.GetStoredWeight) and trashBin:GetStoredWeight() > 0 ) then
                    return false, "No trash in that bin fits this bag's remaining capacity."
                end

                return false, "That trash bin is empty."
            end

            return true
        end

        local droppedEntity, droppedItem = FindLookedAtDroppedTrash(client)
        if ( !IsValid(droppedEntity) or !istable(droppedItem) ) then
            return false, "Look at a nearby trash bin or dropped trash item."
        end

        if ( droppedEntity:GetTable().axPickupInProgress ) then
            return false, "That item is already being collected."
        end

        local classWeight = GetClassWeight(droppedItem.class)
        if ( classWeight > freeWeight ) then
            return false, "This trash bag does not have enough space for that item."
        end

        return true
    end,
    OnRun = function(action, client, item)
        if ( CLIENT ) then return false end

        local trashBin = FindLookedAtBin(client)
        if ( IsValid(trashBin) ) then
            local plannedWeight = GetTransferableBinWeight(item, trashBin)
            if ( plannedWeight <= 0 ) then
                return false
            end

            trashBin:SetRelay("trash.collector", client)
            client:PerformEntityAction(trashBin, "Bagging Bin Trash", GetBinCollectDuration(client, plannedWeight), function()
                local storedClasses = GetStoredClasses(item)
                local freeWeight = math.max(GetBagMaxWeight() - GetStoredWeight(item), 0)
                local extractedClasses, extractedWeight = trashBin:ExtractClassesByWeight(math.min(plannedWeight, freeWeight))

                for i = 1, #extractedClasses do
                    storedClasses[#storedClasses + 1] = extractedClasses[i]
                end

                item:SetData("storedClasses", storedClasses)
                trashBin:SetRelay("trash.collector", nil)
                trashBin:EmitSound("physics/cardboard/cardboard_box_break3.wav", 65, 100)
                client:Notify("Collected " .. #extractedClasses .. " item(s) (" .. extractedWeight .. " kg) from the bin.")
            end, function()
                if ( IsValid(trashBin) ) then
                    trashBin:SetRelay("trash.collector", nil)
                end
            end)

            return false
        end

        local droppedEntity, droppedItem = FindLookedAtDroppedTrash(client)
        if ( !IsValid(droppedEntity) or !istable(droppedItem) ) then
            return false
        end

        local droppedTable = droppedEntity:GetTable()
        if ( droppedTable.axPickupInProgress ) then
            return false
        end

        droppedTable.axPickupInProgress = true
        droppedEntity:SetRelay("trash.collector", client)
        client:PerformEntityAction(droppedEntity, "Collecting Dropped Trash", hook.Run("PlayerCanManageTrash", client) and 2 or 4, function()
            local liveItem = IsValid(droppedEntity) and droppedEntity:GetItemTable() or droppedItem
            if ( !istable(liveItem) or !IsTrashPieceClass(liveItem.class) ) then
                if ( IsValid(droppedEntity) ) then
                    droppedEntity:SetRelay("trash.collector", nil)
                    droppedEntity:GetTable().axPickupInProgress = nil
                end

                return
            end

            local freeWeight = math.max(GetBagMaxWeight() - GetStoredWeight(item), 0)
            local classWeight = GetClassWeight(liveItem.class)
            if ( classWeight > freeWeight ) then
                if ( IsValid(droppedEntity) ) then
                    droppedEntity:SetRelay("trash.collector", nil)
                    droppedEntity:GetTable().axPickupInProgress = nil
                end

                client:Notify("This trash bag does not have enough space for that item.", "error")
                return
            end

            local character = client:GetCharacter()
            local inventory = istable(character) and character:GetInventory() or nil
            if ( !istable(inventory) ) then
                if ( IsValid(droppedEntity) ) then
                    droppedEntity:SetRelay("trash.collector", nil)
                    droppedEntity:GetTable().axPickupInProgress = nil
                end

                return
            end

            local transferOk, transferReason = ax.item:Transfer(liveItem, 0, inventory, function(didTransfer)
                if ( !didTransfer ) then
                    if ( IsValid(droppedEntity) ) then
                        droppedEntity:SetRelay("trash.collector", nil)
                        droppedEntity:GetTable().axPickupInProgress = nil
                    end

                    client:Notify("You cannot collect that item right now.", "error")
                    return
                end

                local storedClasses = GetStoredClasses(item)
                storedClasses[#storedClasses + 1] = liveItem.class
                item:SetData("storedClasses", storedClasses)
                inventory:RemoveItem(liveItem.id)

                if ( IsValid(droppedEntity) ) then
                    droppedEntity:GetTable().axBeingPickedUp = true
                    droppedEntity:SetRelay("trash.collector", nil)
                    droppedEntity:GetTable().axPickupInProgress = nil
                    droppedEntity:EmitSound("physics/plastic/plastic_barrel_break1.wav", 65, 100)
                    SafeRemoveEntity(droppedEntity)
                end

                client:Notify("Collected dropped trash into the bag.")
            end)

            if ( transferOk == false ) then
                if ( IsValid(droppedEntity) ) then
                    droppedEntity:SetRelay("trash.collector", nil)
                    droppedEntity:GetTable().axPickupInProgress = nil
                end

                client:Notify(transferReason or "You cannot collect that item right now.", "error")
            end
        end, function()
            if ( IsValid(droppedEntity) ) then
                droppedEntity:SetRelay("trash.collector", nil)
                droppedEntity:GetTable().axPickupInProgress = nil
            end
        end)

        return false
    end
})

ITEM:AddAction("bag_inventory_trash", {
    name = "Bag Inventory Trash",
    description = "Bag loose trash items from your inventory.",
    order = 3,
    icon = "parallax/icons/trash-2.png",
    CanUse = function(action, client, item)
        local inventory = ax.inventory.instances[item:GetInventoryID()]
        if ( !istable(inventory) ) then
            return false, "This trash bag must be in your inventory."
        end

        local _, totalWeight = GetInventoryTrashToBag(item, inventory)
        if ( totalWeight <= 0 ) then
            if ( inventory:GetItemsByBase("trash_piece", false)[1] != nil ) then
                return false, "No trash in your inventory fits this bag's remaining capacity."
            end

            return false, "You do not have any loose trash to bag."
        end

        return true
    end,
    OnRun = function(action, client, item)
        if ( CLIENT ) then return false end

        local inventory = ax.inventory.instances[item:GetInventoryID()]
        if ( !istable(inventory) ) then
            return false
        end

        local _, plannedWeight = GetInventoryTrashToBag(item, inventory)
        if ( plannedWeight <= 0 ) then
            return false
        end

        client:PerformAction("Bagging Inventory Trash", GetBinCollectDuration(client, plannedWeight), function()
            local baggedItems, totalWeight = GetInventoryTrashToBag(item, inventory)
            if ( totalWeight <= 0 ) then
                client:Notify("There is no inventory trash left to bag.", "error")
                return
            end

            local storedClasses = GetStoredClasses(item)
            for i = 1, #baggedItems do
                storedClasses[#storedClasses + 1] = baggedItems[i].class
            end

            item:SetData("storedClasses", storedClasses)

            for i = 1, #baggedItems do
                inventory:RemoveItem(baggedItems[i].id)
            end

            client:Notify("Bagged " .. #baggedItems .. " trash item(s) (" .. totalWeight .. " kg) from your inventory.")
        end)

        return false
    end
})
