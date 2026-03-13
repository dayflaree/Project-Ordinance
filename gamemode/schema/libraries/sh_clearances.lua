ax.clearance = ax.clearance or {}

local clearance = ax.clearance

clearance.MIN_LEVEL = 1
clearance.MAX_LEVEL = 5

clearance.MODE_KEYCARD = "keycard"
clearance.MODE_RETINAL = "retinal"
clearance.MODE_EITHER = "either"

clearance.DATA_KEY_INITIALIZED = "clearance.keycard.initialized"
clearance.DATA_KEY_LEVEL = "clearance.keycard.level"
clearance.DATA_KEY_OVERRIDE = "clearance.level"

clearance.LEVELS = clearance.LEVELS or {
    [1] = {
        id = 1,
        key = "level_1",
        name = "Level 1",
        shortName = "L1",
        description = "Visitor access for above-ground public areas only.",
        itemClass = "keycard_level_1",
        retinalRequired = false
    },
    [2] = {
        id = 2,
        key = "level_2",
        name = "Level 2",
        shortName = "L2",
        description = "Service access for non-sensitive work and limited subterranean routes.",
        itemClass = "keycard_level_2",
        retinalRequired = false
    },
    [3] = {
        id = 3,
        key = "level_3",
        name = "Level 3",
        shortName = "L3",
        description = "Operational access for security and research personnel.",
        itemClass = "keycard_level_3",
        retinalRequired = true
    },
    [4] = {
        id = 4,
        key = "level_4",
        name = "Level 4",
        shortName = "L4",
        description = "High-security access for senior facility personnel.",
        itemClass = "keycard_level_4",
        retinalRequired = true
    },
    [5] = {
        id = 5,
        key = "level_5",
        name = "Level 5",
        shortName = "L5",
        description = "Executive access with unrestricted facility authority.",
        itemClass = "keycard_level_5",
        retinalRequired = true
    }
}

clearance.ALIASES = clearance.ALIASES or {
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["l1"] = 1,
    ["l2"] = 2,
    ["l3"] = 3,
    ["l4"] = 4,
    ["l5"] = 5,
    ["level1"] = 1,
    ["level2"] = 2,
    ["level3"] = 3,
    ["level4"] = 4,
    ["level5"] = 5,
    ["level_1"] = 1,
    ["level_2"] = 2,
    ["level_3"] = 3,
    ["level_4"] = 4,
    ["level_5"] = 5,
    ["one"] = 1,
    ["two"] = 2,
    ["three"] = 3,
    ["four"] = 4,
    ["five"] = 5,
    ["low"] = 2,
    ["medium"] = 3,
    ["high"] = 4
}

-- Public constants for schema content.
CLEARANCE_LEVEL_1 = 1
CLEARANCE_LEVEL_2 = 2
CLEARANCE_LEVEL_3 = 3
CLEARANCE_LEVEL_4 = 4
CLEARANCE_LEVEL_5 = 5

-- Compatibility aliases for old 3-tier content.
CLEARANCE_LOW = CLEARANCE_LEVEL_2
CLEARANCE_MEDIUM = CLEARANCE_LEVEL_3
CLEARANCE_HIGH = CLEARANCE_LEVEL_4

local function normalizeNumber(value)
    if ( !isnumber(value) ) then return nil end

    local level = math.floor(value)
    if ( level < clearance.MIN_LEVEL or level > clearance.MAX_LEVEL ) then
        return nil
    end

    return level
end

function clearance:Normalize(value, fallback)
    if ( istable(value) ) then
        value = value.clearanceLevel or value.level or value.clearance or value.requiredClearance
    end

    if ( isnumber(value) ) then
        local level = normalizeNumber(value)
        if ( level != nil ) then
            return level
        end
    elseif ( isstring(value) ) then
        local cleaned = string.lower(string.Trim(value))

        local aliased = self.ALIASES[cleaned]
        if ( aliased != nil ) then
            return aliased
        end

        local extracted = tonumber(string.match(cleaned, "(%d+)"))
        local fromNumber = normalizeNumber(extracted)
        if ( fromNumber != nil ) then
            return fromNumber
        end
    end

    if ( fallback == nil ) then
        return nil
    end

    if ( fallback == value ) then
        return 0
    end

    return self:Normalize(fallback, nil) or 0
end

function clearance:NormalizeMode(mode)
    if ( !isstring(mode) ) then
        return self.MODE_EITHER
    end

    local cleaned = string.lower(string.Trim(mode))
    if ( cleaned == "keycard" or cleaned == "keycards" or cleaned == "card" or cleaned == "cards" or cleaned == "id" ) then
        return self.MODE_KEYCARD
    end

    if ( cleaned == "retinal" or cleaned == "retina" or cleaned == "biometric" or cleaned == "identity" ) then
        return self.MODE_RETINAL
    end

    return self.MODE_EITHER
end

function clearance:GetDefinition(level)
    level = self:Normalize(level, nil)
    if ( level == nil ) then return nil end

    return self.LEVELS[level]
end

function clearance:GetName(level)
    local data = self:GetDefinition(level)
    return data and data.name or "No Clearance"
end

function clearance:GetKeycardClass(level)
    local data = self:GetDefinition(level)
    return data and data.itemClass or nil
end

function clearance:IsRetinalRequired(level)
    local data = self:GetDefinition(level)
    return data and data.retinalRequired == true or false
end

function clearance:IsManagedKeycard(item)
    if ( !istable(item) ) then return false end

    if ( isfunction(item.GetData) ) then
        return item:GetData("schemaIssued", false) == true
    end

    if ( istable(item.data) ) then
        return item.data.schemaIssued == true
    end

    return false
end

function clearance:IsKeycardBroken(item)
    if ( !istable(item) ) then return false end

    if ( isfunction(item.GetData) ) then
        return item:GetData("broken", item:GetData("isBroken", false)) == true
    end

    if ( istable(item.data) ) then
        return item.data.broken == true or item.data.isBroken == true
    end

    return false
end

function clearance:GetLevelFromKeycard(itemOrClass)
    if ( itemOrClass == nil ) then return 0 end

    local itemClass = nil
    if ( istable(itemOrClass) ) then
        local directLevel = self:Normalize(itemOrClass.clearanceLevel or itemOrClass.clearance, nil)
        if ( directLevel != nil ) then
            return directLevel
        end

        if ( isfunction(itemOrClass.GetData) ) then
            directLevel = self:Normalize(itemOrClass:GetData("clearanceLevel", nil), nil)
            if ( directLevel != nil ) then
                return directLevel
            end
        end

        itemClass = itemOrClass.class
    elseif ( isstring(itemOrClass) ) then
        itemClass = itemOrClass
    end

    if ( !isstring(itemClass) or itemClass == "" ) then
        return 0
    end

    local stored = ax.item and ax.item.stored and ax.item.stored[itemClass]
    if ( istable(stored) ) then
        local fromStored = self:Normalize(stored.clearanceLevel or stored.clearance, nil)
        if ( fromStored != nil and stored.isKeycard == true ) then
            return fromStored
        end

        if ( fromStored != nil and string.find(itemClass, "keycard", 1, true) ) then
            return fromStored
        end
    end

    local matchedLevel = string.match(itemClass, "keycard_level_(%d+)")
    if ( matchedLevel ) then
        return self:Normalize(tonumber(matchedLevel), 0)
    end

    return 0
end

function clearance:IsKeycard(itemOrClass)
    return self:GetLevelFromKeycard(itemOrClass) > 0
end

function clearance:ResolveCharacter(holder)
    if ( holder == nil ) then return nil end

    if ( ax.util:IsValidPlayer(holder) and isfunction(holder.GetCharacter) ) then
        return holder:GetCharacter()
    end

    if ( istable(holder) and isfunction(holder.GetInventory) and isfunction(holder.GetID) ) then
        return holder
    end

    if ( istable(holder) and isfunction(holder.GetOwner) and isfunction(holder.GetItems) ) then
        local owner = holder:GetOwner()
        if ( istable(owner) and isfunction(owner.GetInventory) and isfunction(owner.GetID) ) then
            return owner
        end
    end

    return nil
end

function clearance:ResolveInventory(holder)
    if ( holder == nil ) then return nil end

    if ( istable(holder) and isfunction(holder.GetItems) and isfunction(holder.GetID) ) then
        return holder
    end

    local character = self:ResolveCharacter(holder)
    if ( istable(character) and isfunction(character.GetInventory) ) then
        return character:GetInventory()
    end

    return nil
end

function clearance:GetFactionDefaultLevel(factionOrCharacter)
    local factionData = factionOrCharacter

    if ( istable(factionOrCharacter) and isfunction(factionOrCharacter.GetFactionData) ) then
        factionData = factionOrCharacter:GetFactionData()
    elseif ( isnumber(factionOrCharacter) and ax.faction and isfunction(ax.faction.Get) ) then
        factionData = ax.faction:Get(factionOrCharacter)
    end

    if ( !istable(factionData) ) then
        return 0
    end

    local id = string.lower(tostring(factionData.id or ""))
    local name = string.lower(tostring(factionData.name or ""))
    local source = id .. " " .. name

    if ( string.find(source, "service", 1, true) ) then
        return CLEARANCE_LEVEL_2
    end

    if ( string.find(source, "security", 1, true) ) then
        return CLEARANCE_LEVEL_3
    end

    if ( string.find(source, "research", 1, true) or string.find(source, "science", 1, true) ) then
        return CLEARANCE_LEVEL_3
    end

    if ( string.find(source, "admin", 1, true) ) then
        return CLEARANCE_LEVEL_4
    end

    if ( string.find(source, "black", 1, true) or string.find(source, "hecu", 1, true) ) then
        return CLEARANCE_LEVEL_4
    end

    return 0
end

function clearance:GetAssignedLevel(holder)
    local character = self:ResolveCharacter(holder)
    if ( !istable(character) ) then return 0 end

    local overrideLevel = nil
    if ( isfunction(character.GetData) ) then
        overrideLevel = self:Normalize(character:GetData(self.DATA_KEY_OVERRIDE, nil), nil)
        if ( overrideLevel == nil ) then
            overrideLevel = self:Normalize(character:GetData("clearanceLevel", nil), nil)
        end
    end

    if ( overrideLevel != nil ) then
        return overrideLevel
    end

    local rankData = character.GetRankData and character:GetRankData() or nil
    local classData = character.GetClassData and character:GetClassData() or nil

    local rankLevel = self:Normalize(rankData and rankData.clearance or nil, nil)
    if ( rankLevel != nil ) then
        return rankLevel
    end

    local classLevel = self:Normalize(classData and classData.clearance or nil, nil)
    if ( classLevel != nil ) then
        return classLevel
    end

    return self:GetFactionDefaultLevel(character)
end

function clearance:GetAssignedMaximumLevel(holder)
    local character = self:ResolveCharacter(holder)
    if ( !istable(character) ) then return 0 end

    local assigned = self:GetAssignedLevel(character)
    local rankData = character.GetRankData and character:GetRankData() or nil
    local classData = character.GetClassData and character:GetClassData() or nil

    local maxLevel = self:Normalize(classData and classData.maxClearance or nil, nil)
    if ( maxLevel == nil ) then
        maxLevel = self:Normalize(rankData and rankData.maxClearance or nil, nil)
    end

    if ( maxLevel == nil or maxLevel < assigned ) then
        maxLevel = assigned
    end

    return maxLevel or 0
end

function clearance:GetKeycards(holder, includeBroken)
    local inventory = self:ResolveInventory(holder)
    if ( !istable(inventory) or !isfunction(inventory.GetItems) ) then
        return {}
    end

    local items = {}
    for _, item in pairs(inventory:GetItems() or {}) do
        if ( !self:IsKeycard(item) ) then
            continue
        end

        if ( includeBroken != true and self:IsKeycardBroken(item) ) then
            continue
        end

        items[#items + 1] = item
    end

    table.sort(items, function(a, b)
        local aLevel = clearance:GetLevelFromKeycard(a)
        local bLevel = clearance:GetLevelFromKeycard(b)

        if ( aLevel == bLevel ) then
            return (a.id or 0) < (b.id or 0)
        end

        return aLevel > bLevel
    end)

    return items
end

function clearance:GetHighestKeycardLevel(holder, includeBroken)
    local highest = 0

    local cards = self:GetKeycards(holder, includeBroken)
    for i = 1, #cards do
        local level = self:GetLevelFromKeycard(cards[i])
        if ( level > highest ) then
            highest = level
        end
    end

    return highest
end

function clearance:GetHighestLevel(holder, options)
    local opts = istable(options) and options or {}
    local mode = self:NormalizeMode(opts.mode or self.MODE_KEYCARD)
    local includeAssigned = opts.includeAssigned != false
    local includeBroken = opts.includeBrokenKeycards == true or opts.includeBrokenCards == true or opts.includeBroken == true

    local keycardLevel = self:GetHighestKeycardLevel(holder, includeBroken)
    local retinalLevel = includeAssigned and self:GetAssignedLevel(holder) or 0

    local selected = 0
    local source = nil

    if ( mode == self.MODE_KEYCARD ) then
        selected = keycardLevel
        source = keycardLevel > 0 and self.MODE_KEYCARD or nil
    elseif ( mode == self.MODE_RETINAL ) then
        selected = retinalLevel
        source = retinalLevel > 0 and self.MODE_RETINAL or nil
    else
        if ( retinalLevel > keycardLevel ) then
            selected = retinalLevel
            source = self.MODE_RETINAL
        else
            selected = keycardLevel
            source = keycardLevel > 0 and self.MODE_KEYCARD or nil
        end
    end

    return selected, source, {
        keycard = keycardLevel,
        retinal = retinalLevel,
        mode = mode
    }
end

function clearance:HasClearance(holder, requirement, options)
    local opts = istable(options) and options or {}
    if ( opts.mode == nil ) then
        opts.mode = self.MODE_KEYCARD
    end

    local requiredLevel = self:Normalize(requirement, 0)

    if ( requiredLevel <= 0 ) then
        return true, nil, {
            required = 0,
            provided = 0,
            source = nil,
            keycard = 0,
            retinal = 0,
            mode = self:NormalizeMode(opts.mode)
        }
    end

    if ( opts.scannerBroken == true or opts.broken == true ) then
        return false, "scanner_broken", {
            required = requiredLevel,
            provided = 0,
            source = nil,
            keycard = 0,
            retinal = 0,
            mode = self:NormalizeMode(opts.mode)
        }
    end

    local provided, source, detail = self:GetHighestLevel(holder, opts)
    if ( provided >= requiredLevel ) then
        return true, nil, {
            required = requiredLevel,
            provided = provided,
            source = source,
            keycard = detail.keycard,
            retinal = detail.retinal,
            mode = detail.mode
        }
    end

    return false, "insufficient_clearance", {
        required = requiredLevel,
        provided = provided,
        source = source,
        keycard = detail.keycard,
        retinal = detail.retinal,
        mode = detail.mode
    }
end

function clearance:CanUseScanner(holder, scannerData, options)
    local scanner = istable(scannerData) and scannerData or {}
    local opts = table.Copy(istable(options) and options or {})

    opts.mode = opts.mode or scanner.mode or scanner.scannerMode or scanner.scannerType
    if ( opts.scannerBroken == nil ) then
        opts.scannerBroken = scanner.broken == true or scanner.isBroken == true
    end

    local requiredLevel = scanner.requiredClearance or scanner.clearanceLevel or scanner.clearance or scanner.level
    return self:HasClearance(holder, requiredLevel, opts)
end

if ( SERVER ) then
    function clearance:IssueKeycard(holder, level, data)
        local inventory = self:ResolveInventory(holder)
        if ( !istable(inventory) or !isfunction(inventory.AddItem) ) then
            return false, "missing_inventory"
        end

        local normalizedLevel = self:Normalize(level, nil)
        if ( normalizedLevel == nil ) then
            return false, "invalid_level"
        end

        local itemClass = self:GetKeycardClass(normalizedLevel)
        if ( !isstring(itemClass) or itemClass == "" ) then
            return false, "missing_item_class"
        end

        if ( !istable(ax.item:Get(itemClass)) ) then
            return false, "item_not_registered"
        end

        local payload = table.Copy(istable(data) and data or {})
        payload.clearanceLevel = normalizedLevel

        inventory:AddItem(itemClass, payload)
        return true, nil, itemClass
    end

    function clearance:RevokeKeycards(holder, options)
        local inventory = self:ResolveInventory(holder)
        if ( !istable(inventory) or !isfunction(inventory.GetItems) or !isfunction(inventory.RemoveItem) ) then
            return 0
        end

        local opts = istable(options) and options or {}
        local minLevel = self:Normalize(opts.minLevel, nil)
        local maxLevel = self:Normalize(opts.maxLevel, nil)
        local onlyManaged = opts.onlyManaged == true

        local toRemove = {}
        for _, item in pairs(inventory:GetItems() or {}) do
            local itemLevel = self:GetLevelFromKeycard(item)
            if ( itemLevel <= 0 ) then
                continue
            end

            if ( onlyManaged and !self:IsManagedKeycard(item) ) then
                continue
            end

            if ( minLevel != nil and itemLevel < minLevel ) then
                continue
            end

            if ( maxLevel != nil and itemLevel > maxLevel ) then
                continue
            end

            toRemove[#toRemove + 1] = item.id
        end

        for i = 1, #toRemove do
            inventory:RemoveItem(toRemove[i])
        end

        return #toRemove
    end

    function clearance:SyncCharacterKeycard(holder, forceUpdate)
        local character = self:ResolveCharacter(holder)
        if ( !istable(character) or !isfunction(character.GetData) or !isfunction(character.SetData) ) then
            return false, "invalid_character"
        end

        local inventory = character:GetInventory()
        if ( !istable(inventory) or !isfunction(inventory.GetItems) or !isfunction(inventory.RemoveItem) ) then
            return false, "missing_inventory"
        end

        local initialized = character:GetData(self.DATA_KEY_INITIALIZED, false)
        if ( initialized and forceUpdate != true ) then
            return false, "already_initialized"
        end

        local targetLevel = self:GetAssignedLevel(character)
        local targetClass = self:GetKeycardClass(targetLevel)

        local managedCards = {}
        for _, card in ipairs(self:GetKeycards(character, true)) do
            if ( self:IsManagedKeycard(card) ) then
                managedCards[#managedCards + 1] = card
            end
        end

        local hasTargetCard = false
        local targetCardID = nil
        for i = 1, #managedCards do
            local card = managedCards[i]

            if ( targetClass and card.class == targetClass and !hasTargetCard ) then
                hasTargetCard = true
                targetCardID = card.id
            else
                inventory:RemoveItem(card.id)
            end
        end

        if ( targetClass and !hasTargetCard ) then
            self:IssueKeycard(character, targetLevel, {
                schemaIssued = true,
                issuedCharacterID = character:GetID(),
                issuedAt = os.time()
            })
        elseif ( !targetClass and targetCardID != nil ) then
            inventory:RemoveItem(targetCardID)
        end

        if ( character:GetData(self.DATA_KEY_INITIALIZED, false) != true ) then
            character:SetData(self.DATA_KEY_INITIALIZED, true)
        end

        if ( character:GetData(self.DATA_KEY_LEVEL, 0) != targetLevel ) then
            character:SetData(self.DATA_KEY_LEVEL, targetLevel)
        end

        return true, nil, targetLevel
    end

    clearance._syncQueue = clearance._syncQueue or {}

    function clearance:QueueSync(holder, forceUpdate)
        local character = self:ResolveCharacter(holder)
        if ( !istable(character) ) then return end

        local characterID = character:GetID()
        if ( !isnumber(characterID) or characterID <= 0 ) then return end

        local queued = self._syncQueue[characterID]
        if ( !istable(queued) ) then
            queued = {
                character = character,
                force = forceUpdate == true
            }
            self._syncQueue[characterID] = queued
        else
            queued.character = character
            queued.force = queued.force or forceUpdate == true
        end

        timer.Create("ax.clearance.sync." .. tostring(characterID), 0, 1, function()
            local pending = clearance._syncQueue[characterID]
            clearance._syncQueue[characterID] = nil

            if ( !istable(pending) ) then return end
            clearance:SyncCharacterKeycard(pending.character, pending.force)
        end)
    end
end

local inventoryMeta = ax.inventory.meta
if ( istable(inventoryMeta) ) then
    function inventoryMeta:GetFacilityClearanceKeycards(includeBroken)
        return clearance:GetKeycards(self, includeBroken)
    end

    function inventoryMeta:GetFacilityHighestClearanceLevel(options)
        local level = clearance:GetHighestLevel(self, options)
        return level
    end

    if ( !isfunction(inventoryMeta.GetClearanceKeycards) ) then
        inventoryMeta.GetClearanceKeycards = inventoryMeta.GetFacilityClearanceKeycards
    end

    if ( !isfunction(inventoryMeta.GetHighestClearanceLevel) ) then
        inventoryMeta.GetHighestClearanceLevel = inventoryMeta.GetFacilityHighestClearanceLevel
    end
end

local characterMeta = ax.character.meta
if ( istable(characterMeta) ) then
    function characterMeta:GetFacilityAssignedClearanceLevel()
        return clearance:GetAssignedLevel(self)
    end

    function characterMeta:GetFacilityMaximumAssignedClearanceLevel()
        return clearance:GetAssignedMaximumLevel(self)
    end

    function characterMeta:GetFacilityClearanceKeycards(includeBroken)
        return clearance:GetKeycards(self, includeBroken)
    end

    function characterMeta:GetFacilityHighestClearanceLevel(options)
        local level = clearance:GetHighestLevel(self, options)
        return level
    end

    function characterMeta:HasFacilityClearance(requirement, options)
        return clearance:HasClearance(self, requirement, options)
    end

    if ( !isfunction(characterMeta.GetAssignedClearanceLevel) ) then
        characterMeta.GetAssignedClearanceLevel = characterMeta.GetFacilityAssignedClearanceLevel
    end

    if ( !isfunction(characterMeta.GetMaximumAssignedClearanceLevel) ) then
        characterMeta.GetMaximumAssignedClearanceLevel = characterMeta.GetFacilityMaximumAssignedClearanceLevel
    end

    if ( !isfunction(characterMeta.GetClearanceKeycards) ) then
        characterMeta.GetClearanceKeycards = characterMeta.GetFacilityClearanceKeycards
    end

    if ( !isfunction(characterMeta.GetHighestClearanceLevel) ) then
        characterMeta.GetHighestClearanceLevel = characterMeta.GetFacilityHighestClearanceLevel
    end

    if ( !isfunction(characterMeta.HasClearance) ) then
        characterMeta.HasClearance = characterMeta.HasFacilityClearance
    end
end

local playerMeta = ax.player.meta
if ( istable(playerMeta) ) then
    function playerMeta:GetFacilityAssignedClearanceLevel()
        return clearance:GetAssignedLevel(self)
    end

    function playerMeta:GetFacilityMaximumAssignedClearanceLevel()
        return clearance:GetAssignedMaximumLevel(self)
    end

    function playerMeta:GetFacilityClearanceKeycards(includeBroken)
        return clearance:GetKeycards(self, includeBroken)
    end

    function playerMeta:GetFacilityHighestClearanceLevel(options)
        local level = clearance:GetHighestLevel(self, options)
        return level
    end

    function playerMeta:HasFacilityClearance(requirement, options)
        return clearance:HasClearance(self, requirement, options)
    end

    if ( !isfunction(playerMeta.GetAssignedClearanceLevel) ) then
        playerMeta.GetAssignedClearanceLevel = playerMeta.GetFacilityAssignedClearanceLevel
    end

    if ( !isfunction(playerMeta.GetMaximumAssignedClearanceLevel) ) then
        playerMeta.GetMaximumAssignedClearanceLevel = playerMeta.GetFacilityMaximumAssignedClearanceLevel
    end

    if ( !isfunction(playerMeta.GetClearanceKeycards) ) then
        playerMeta.GetClearanceKeycards = playerMeta.GetFacilityClearanceKeycards
    end

    if ( !isfunction(playerMeta.GetHighestClearanceLevel) ) then
        playerMeta.GetHighestClearanceLevel = playerMeta.GetFacilityHighestClearanceLevel
    end

    if ( !isfunction(playerMeta.HasClearance) ) then
        playerMeta.HasClearance = playerMeta.HasFacilityClearance
    end
end

if ( SERVER ) then
    hook.Add("PostPlayerLoadout", "ax.clearance.PostPlayerLoadout", function(client)
        if ( !ax.util:IsValidPlayer(client) ) then return end
        clearance:QueueSync(client, false)
    end)

    hook.Add("OnCharacterClassChanged", "ax.clearance.OnCharacterClassChanged", function(character)
        clearance:QueueSync(character, true)
    end)

    hook.Add("OnCharacterRankChanged", "ax.clearance.OnCharacterRankChanged", function(character)
        clearance:QueueSync(character, true)
    end)
end
