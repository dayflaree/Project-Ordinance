--[[
    Emote Definitions
]]

MODULE.Emotes = MODULE.Emotes or {}
MODULE.EmoteGroups = MODULE.EmoteGroups or {}

local VALID_EMOTE_TYPES = {
    gesture = true,
    static = true,
    loop = true
}

local function NormalizeID(id)
    if ( !isstring(id) or id == "" ) then return nil end

    return string.lower(id)
end

local function PrettyName(id)
    id = tostring(id or "")

    return string.upper(string.Left(id, 1)) .. string.sub(id, 2)
end

local function SortEmoteEntries(a, b)
    local orderA = a.data.sort or 100
    local orderB = b.data.sort or 100

    if ( orderA != orderB ) then
        return orderA < orderB
    end

    local nameA = tostring(a.data.name or a.id)
    local nameB = tostring(b.data.name or b.id)

    if ( nameA != nameB ) then
        return nameA < nameB
    end

    return a.id < b.id
end

MODULE.SectionDefinitions = MODULE.SectionDefinitions or {
    gestures = {
        name = "Gestures",
        description = "Quick upper-body signals for moment-to-moment roleplay.",
        color = Color(103, 181, 255, 180),
        order = 1
    },
    taunts = {
        name = "Taunts",
        description = "Bigger reactions and expressive full-body performances.",
        color = Color(255, 171, 79, 180),
        order = 2
    },
    poses = {
        name = "Poses",
        description = "Longer looping stances for scenes, surrender, or idling.",
        color = Color(135, 221, 166, 180),
        order = 3
    },
    misc = {
        name = "Misc",
        description = "Additional emotes that do not fit a primary section.",
        color = Color(192, 162, 255, 180),
        order = 99
    }
}

local function InferCategory(data)
    if ( isstring(data.category) and data.category != "" ) then
        return string.lower(data.category)
    end

    if ( isstring(data.group) and data.group != "" ) then
        local group = MODULE.EmoteGroups[data.group]

        if ( istable(group) and isstring(group.category) and group.category != "" ) then
            return string.lower(group.category)
        end
    end

    local sequence = string.lower(data.sequence or "")

    if ( string.StartWith(sequence, "gesture_") or data.type == "gesture" ) then
        return "gestures"
    end

    if ( string.StartWith(sequence, "taunt_") ) then
        return "taunts"
    end

    if ( data.type == "static" or data.type == "loop" ) then
        return "poses"
    end

    return "misc"
end

function MODULE:RegisterEmoteGroup(id, data)
    id = NormalizeID(id)

    if ( !id or !istable(data) ) then return end

    data.id = id
    data.name = data.name or PrettyName(id)
    data.description = data.description or "Grouped emotes with a similar roleplay use case."
    data.category = string.lower(data.category or "misc")
    data.sort = data.sort or 100

    self.EmoteGroups[id] = data
end

function MODULE:RegisterEmote(id, data)
    id = NormalizeID(id)

    if ( !id or !istable(data) ) then return end

    data.id = id
    data.name = data.name or PrettyName(id)
    data.type = VALID_EMOTE_TYPES[data.type] and data.type or "static"
    data.group = NormalizeID(data.group)
    data.idleSequence = isstring(data.idleSequence) and data.idleSequence or nil
    data.category = InferCategory(data)
    data.description = data.description or "A custom emote."
    data.sort = data.sort or 100

    self.Emotes[id] = data
end

function MODULE:GetEmoteGroupMeta(groupId, fallbackData)
    groupId = NormalizeID(groupId)

    if ( !groupId ) then return nil end

    local data = self.EmoteGroups[groupId] or {}
    local category = data.category

    if ( !isstring(category) or category == "" ) then
        category = InferCategory(fallbackData or data)
    end

    return {
        id = groupId,
        name = data.name or PrettyName(groupId),
        description = data.description or "Grouped emotes with a similar roleplay use case.",
        category = string.lower(category or "misc"),
        sort = data.sort or 100
    }
end

function MODULE:GetEmoteGroupMembers(groupId)
    groupId = NormalizeID(groupId)

    if ( !groupId ) then
        return {}
    end

    local members = {}

    for id, data in pairs(self.Emotes or {}) do
        if ( data.group == groupId ) then
            members[#members + 1] = {
                id = id,
                data = data
            }
        end
    end

    table.sort(members, SortEmoteEntries)

    return members
end

function MODULE:ResolveEmote(emoteId)
    if ( !isstring(emoteId) or emoteId == "" ) then
        return nil, nil
    end

    local normalized = NormalizeID(emoteId)
    local emote = self.Emotes[normalized]

    if ( emote ) then
        return normalized, emote
    end

    local lowered = string.lower(emoteId)

    for id, data in pairs(self.Emotes or {}) do
        if ( string.lower(data.name or "") == lowered ) then
            return id, data
        end
    end

    return nil, nil
end

-- Default Emotes
-- Type can be "gesture" (upper body), "static" (timed forced sequence), or "loop" (forced until cancelled)
-- Gestures can optionally define "idleSequence" to pick a specific idle base in the wheel preview
-- "sequence" must match the animation sequence name in the model

MODULE:RegisterEmoteGroup("wounded", {
    name = "Wounded",
    description = "Injured loops and pain-focused idle poses for medical or combat scenes.",
    category = "poses",
    sort = 40
})

MODULE:RegisterEmoteGroup("standing_idles", {
    name = "Standing Idles",
    description = "Relaxed standing poses for conversations, waiting, or background roleplay.",
    category = "poses",
    sort = 70
})

MODULE:RegisterEmote("agree", {
    name = "Agree",
    sequence = "gesture_agree",
    type = "gesture",
    category = "gestures",
    description = "A short, affirmative nod to signal agreement.",
    sort = 10
})

MODULE:RegisterEmote("disagree", {
    name = "Disagree",
    sequence = "gesture_disagree",
    type = "gesture",
    category = "gestures",
    description = "A clear refusal or dismissive rejection.",
    sort = 20
})

MODULE:RegisterEmote("wave", {
    name = "Wave",
    sequence = "gesture_wave",
    type = "gesture",
    category = "gestures",
    description = "A casual greeting or farewell across the room.",
    sort = 30
})

MODULE:RegisterEmote("salute", {
    name = "Salute",
    sequence = "gesture_salute",
    type = "gesture",
    category = "gestures",
    description = "A formal salute for authority, respect, or reporting in.",
    sort = 40
})

MODULE:RegisterEmote("bow", {
    name = "Bow",
    sequence = "gesture_bow",
    type = "gesture",
    category = "gestures",
    description = "A restrained bow suited to ceremony or gratitude.",
    sort = 50
})

MODULE:RegisterEmote("beckon", {
    name = "Beckon",
    sequence = "gesture_becon",
    type = "gesture",
    category = "gestures",
    description = "Signal someone over without breaking the conversation.",
    sort = 60
})

MODULE:RegisterEmote("cheer", {
    name = "Cheer",
    sequence = "taunt_cheer_base",
    type = "static",
    category = "taunts",
    description = "Celebrate loudly and draw attention to the moment.",
    sort = 10
})

MODULE:RegisterEmote("laugh", {
    name = "Laugh",
    sequence = "taunt_laugh_base",
    type = "static",
    category = "taunts",
    description = "Break into a broad laugh for reactions or mockery.",
    sort = 20
})

MODULE:RegisterEmote("dance", {
    name = "Dance",
    sequence = "taunt_dance_base",
    type = "static",
    category = "taunts",
    description = "A full-body dance loop for celebrations or distractions.",
    sort = 30
})

MODULE:RegisterEmote("zombie", {
    name = "Zombie",
    sequence = "taunt_zombie",
    type = "gesture",
    category = "taunts",
    description = "A shambling bit for jokes, scares, or theatrics.",
    sort = 40
})

MODULE:RegisterEmote("robot", {
    name = "Robot",
    sequence = "taunt_robot_base",
    type = "static",
    category = "taunts",
    description = "A stiff, mechanical routine with exaggerated timing.",
    sort = 50
})

MODULE:RegisterEmote("sit", {
    name = "Sit",
    sequence = "sit_zen",
    type = "loop",
    category = "poses",
    description = "Settle into a grounded seated loop for slower scenes.",
    sort = 10
})

MODULE:RegisterEmote("surrender", {
    name = "Surrender",
    sequence = "arrestidle",
    type = "loop",
    category = "poses",
    description = "Lay on the floor with hands behind your head, legs crossed in the air.",
    sort = 20
})

MODULE:RegisterEmote("wounded_1", {
    name = "Wounded 1",
    sequence = "d1_town05_winston_down",
    type = "loop",
    category = "poses",
    group = "wounded",
    description = "A painful stagger for a wounded character or intense roleplay.",
    sort = 40
})

MODULE:RegisterEmote("wounded_2", {
    name = "Wounded 2",
    sequence = "d1_town05_wounded_idle_1",
    type = "loop",
    category = "poses",
    group = "wounded",
    description = "A painful stagger for a wounded character or intense roleplay.",
    sort = 50
})

MODULE:RegisterEmote("wounded_3", {
    name = "Wounded 3",
    sequence = "d1_town05_wounded_idle_2",
    type = "loop",
    category = "poses",
    group = "wounded",
    description = "A painful stagger for a wounded character or intense roleplay.",
    sort = 60
})

MODULE:RegisterEmote("kneel", {
    name = "Kneel",
    sequence = "d1_town05_daniels_kneel_idle",
    type = "loop",
    category = "poses",
    description = "A painful stagger for a wounded character or intense roleplay.",
    sort = 30
})

MODULE:RegisterEmote("stand_idle_1", {
    name = "Stand Idle 1",
    sequence = "d1_t02_playground_cit1_arms_crossed",
    type = "loop",
    category = "poses",
    group = "standing_idles",
    description = "A casual standing idle pose with arms crossed.",
    sort = 70
})

MODULE:RegisterEmote("stand_idle_2", {
    name = "Stand Idle 2",
    sequence = "d1_t02_playground_cit2_pockets",
    type = "loop",
    category = "poses",
    group = "standing_idles",
    description = "A casual standing idle pose with arms in pockets.",
    sort = 80
})

MODULE:RegisterEmote("stand_idle_3", {
    name = "Stand Idle 3",
    sequence = "d1_t01_breakroom_watchbreen",
    type = "loop",
    category = "poses",
    group = "standing_idles",
    description = "A casual standing idle pose with arms crossed.",
    sort = 90
})

MODULE:RegisterEmote("stand_idle_4", {
    name = "Stand Idle 4",
    sequence = "lineidle04",
    type = "loop",
    category = "poses",
    group = "standing_idles",
    description = "A casual standing idle pose with arms in pockets.",
    sort = 100
})

MODULE:RegisterEmote("stand_idle_5", {
    name = "Stand Idle 5",
    sequence = "lineidle02",
    type = "loop",
    category = "poses",
    group = "standing_idles",
    description = "A casual standing idle pose with arms crossed.",
    sort = 110
})
