--[[
    Emote Wheel UI (Client-side)
]]

local MODULE = MODULE
local PANEL = {}

local SEGMENT_STEPS = 64
local ITEM_GAP = 1
local SECTION_GAP = 8
local ENTRY_KIND_EMOTE = "emote"
local ENTRY_KIND_GROUP = "group"
local ENTRY_KIND_QUICK_PLAY = "quick_play"
local PREVIEW_IDLE_SEQUENCES = {
    "idle_all_01",
    "idle_all_02"
}

local function GetAnimationFraction(speed)
    local animationsEnabled = true

    if ( ax.option ) then
        animationsEnabled = ax.option:Get("performance.animations", ax.option:Get("performanceAnimations", true))
    end

    if ( !animationsEnabled ) then
        return 1
    end

    return math.min(1, FrameTime() * speed)
end

local function EaseNumber(current, target, speed, easing)
    local fraction = GetAnimationFraction(speed)

    if ( fraction >= 1 ) then
        return target
    end

    if ( ax.ease and ax.ease.Lerp ) then
        return ax.ease:Lerp(easing or "OutQuad", fraction, current, target)
    end

    return Lerp(fraction, current, target)
end

local function AlphaColor(color, alpha)
    if ( !color ) then
        return Color(255, 255, 255, alpha or 255)
    end

    return Color(color.r, color.g, color.b, alpha or color.a or 255)
end

local function BlendColors(from, to, fraction)
    fraction = math.Clamp(fraction or 0, 0, 1)
    from = from or color_white
    to = to or color_white

    return Color(
        Lerp(fraction, from.r, to.r),
        Lerp(fraction, from.g, to.g),
        Lerp(fraction, from.b, to.b),
        Lerp(fraction, from.a or 255, to.a or 255)
    )
end

local function GetTextWidth(font, text)
    surface.SetFont(font)

    local width = surface.GetTextSize(tostring(text or ""))

    return width
end

local function GetTextHeight(font, sample)
    surface.SetFont(font)

    local _, height = surface.GetTextSize(sample or "Hg")

    return height
end

local function FitTextToWidth(font, text, maxWidth)
    text = tostring(text or "")
    maxWidth = math.max(1, maxWidth or 1)

    surface.SetFont(font)

    local textWidth = surface.GetTextSize(text)

    if ( textWidth <= maxWidth ) then
        return text
    end

    local ellipsis = "..."
    local ellipsisWidth = surface.GetTextSize(ellipsis)

    if ( ellipsisWidth >= maxWidth ) then
        return ellipsis
    end

    for length = #text, 1, -1 do
        local candidate = string.sub(text, 1, length) .. ellipsis
        local candidateWidth = surface.GetTextSize(candidate)

        if ( candidateWidth <= maxWidth ) then
            return candidate
        end
    end

    return ellipsis
end

local function LimitWrappedLines(lines, maxLines)
    if ( !istable(lines) or #lines == 0 ) then
        return { "" }
    end

    maxLines = math.max(1, maxLines or #lines)

    if ( #lines <= maxLines ) then
        return lines
    end

    local limited = {}

    for i = 1, maxLines do
        limited[i] = lines[i]
    end

    limited[maxLines] = tostring(limited[maxLines] or "") .. "..."

    return limited
end

local function NormalizeAngle(angle)
    angle = angle % 360

    if ( angle < 0 ) then
        angle = angle + 360
    end

    return angle
end

local function AngleWithin(angle, startAngle, endAngle)
    angle = NormalizeAngle(angle)
    startAngle = NormalizeAngle(startAngle)
    endAngle = NormalizeAngle(endAngle)

    if ( startAngle <= endAngle ) then
        return angle >= startAngle and angle <= endAngle
    end

    return angle >= startAngle or angle <= endAngle
end

local function PolarToScreen(centerX, centerY, radius, angle)
    local radians = math.rad(angle - 90)

    return centerX + math.cos(radians) * radius, centerY + math.sin(radians) * radius
end

local function DrawRingSegment(centerX, centerY, innerRadius, outerRadius, startAngle, endAngle, color)
    if ( !color or color.a <= 0 or endAngle <= startAngle ) then return end

    local steps = math.max(6, math.ceil((endAngle - startAngle) / SEGMENT_STEPS))

    draw.NoTexture()
    surface.SetDrawColor(color)

    for i = 0, steps - 1 do
        local fractionA = i / steps
        local fractionB = (i + 1) / steps
        local angleA = Lerp(fractionA, startAngle, endAngle)
        local angleB = Lerp(fractionB, startAngle, endAngle)
        local outerAX, outerAY = PolarToScreen(centerX, centerY, outerRadius, angleA)
        local outerBX, outerBY = PolarToScreen(centerX, centerY, outerRadius, angleB)
        local innerAX, innerAY = PolarToScreen(centerX, centerY, innerRadius, angleA)
        local innerBX, innerBY = PolarToScreen(centerX, centerY, innerRadius, angleB)

        surface.DrawPoly({
            { x = outerAX, y = outerAY },
            { x = outerBX, y = outerBY },
            { x = innerBX, y = innerBY }
        })

        surface.DrawPoly({
            { x = outerAX, y = outerAY },
            { x = innerBX, y = innerBY },
            { x = innerAX, y = innerAY }
        })
    end
end

local function DrawDivider(centerX, centerY, innerRadius, outerRadius, angle, color)
    if ( !color or color.a <= 0 ) then return end

    local startX, startY = PolarToScreen(centerX, centerY, innerRadius, angle)
    local endX, endY = PolarToScreen(centerX, centerY, outerRadius, angle)

    surface.SetDrawColor(color)
    surface.DrawLine(startX, startY, endX, endY)
end

local function ResolveSectionId(data)
    if ( isstring(data.category) and data.category != "" ) then
        return string.lower(data.category)
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

local function GetSectionMeta(sectionId)
    local definitions = MODULE.SectionDefinitions or {}
    local section = definitions[sectionId] or definitions.misc or {}

    return {
        id = sectionId,
        name = section.name or string.upper(string.Left(sectionId, 1)) .. string.sub(sectionId, 2),
        description = section.description or "Additional emotes.",
        color = section.color or Color(125, 165, 225, 180),
        order = section.order or 99
    }
end

local function SortEntries(a, b)
    local orderA = a.sort or (a.data and a.data.sort) or 100
    local orderB = b.sort or (b.data and b.data.sort) or 100

    if ( orderA != orderB ) then
        return orderA < orderB
    end

    local nameA = tostring((a.data and a.data.name) or a.name or a.id)
    local nameB = tostring((b.data and b.data.name) or b.name or b.id)

    if ( nameA != nameB ) then
        return nameA < nameB
    end

    return a.id < b.id
end

local function CreateSectionBucket(sectionMap, sections, sectionId)
    local section = sectionMap[sectionId]

    if ( section ) then
        return section
    end

    local meta = GetSectionMeta(sectionId)

    section = {
        id = sectionId,
        name = meta.name,
        description = meta.description,
        color = meta.color,
        order = meta.order,
        emoteCount = 0,
        items = {}
    }

    sectionMap[sectionId] = section
    sections[#sections + 1] = section

    return section
end

local function GetValidatedFavoriteMember(favoriteMap, groupId, members)
    if ( !istable(favoriteMap) or !isstring(groupId) ) then
        return nil, nil
    end

    local favoriteId = favoriteMap[groupId]

    if ( !isstring(favoriteId) or favoriteId == "" ) then
        return nil, nil
    end

    for _, member in ipairs(members) do
        if ( member.emoteId == favoriteId ) then
            return favoriteId, member
        end
    end

    return nil, nil
end

local function BuildEmoteEntry(id, data, groupId, groupMeta)
    return {
        id = "emote:" .. id,
        emoteId = id,
        kind = ENTRY_KIND_EMOTE,
        groupId = groupId,
        group = groupMeta,
        sort = data.sort or 100,
        data = data,
        favorite = false
    }
end

local function BuildGroupEntry(groupMeta, members, favoriteMember)
    local previewEntry = favoriteMember or members[1]

    return {
        id = "group:" .. groupMeta.id,
        kind = ENTRY_KIND_GROUP,
        groupId = groupMeta.id,
        group = groupMeta,
        members = members,
        previewEntry = previewEntry,
        favoriteEmoteId = favoriteMember and favoriteMember.emoteId or nil,
        sort = groupMeta.sort or 100,
        data = {
            id = groupMeta.id,
            name = groupMeta.name,
            description = groupMeta.description,
            type = ENTRY_KIND_GROUP,
            category = groupMeta.category,
            sequence = previewEntry and previewEntry.data.sequence or nil,
            sort = groupMeta.sort or 100
        }
    }
end

local function BuildQuickPlayEntry(groupMeta, members, favoriteMember)
    local previewEntry = favoriteMember or members[1]
    local favoriteName = favoriteMember and (favoriteMember.data.name or favoriteMember.emoteId) or nil

    return {
        id = "quick:" .. groupMeta.id,
        kind = ENTRY_KIND_QUICK_PLAY,
        groupId = groupMeta.id,
        group = groupMeta,
        members = members,
        previewEntry = previewEntry,
        favoriteEmoteId = favoriteMember and favoriteMember.emoteId or nil,
        sort = -1000,
        data = {
            id = "quick_" .. groupMeta.id,
            name = "Quick Play",
            description = favoriteName and ("Play your favorite from this group: " .. favoriteName .. ".") or "Play a random emote from this group.",
            type = ENTRY_KIND_QUICK_PLAY,
            category = groupMeta.category,
            sequence = previewEntry and previewEntry.data.sequence or nil,
            sort = -1000
        }
    }
end

local function FinalizeWheelData(sections, context)
    table.sort(sections, function(a, b)
        if ( a.order != b.order ) then
            return a.order < b.order
        end

        return a.name < b.name
    end)

    local totalItems = 0

    for _, section in ipairs(sections) do
        table.sort(section.items, SortEntries)
        totalItems = totalItems + #section.items
    end

    if ( totalItems == 0 ) then
        return {
            sections = {},
            items = {},
            count = 0,
            mode = context and context.mode or "root",
            group = context and context.group or nil,
            groupId = context and context.groupId or nil,
            defaultItemId = context and context.defaultItemId or nil
        }
    end

    local totalGap = (#sections * SECTION_GAP) + (totalItems * ITEM_GAP)
    local segmentAngle = math.max(12, (360 - totalGap) / totalItems)
    local cursor = 0
    local flatItems = {}

    for _, section in ipairs(sections) do
        cursor = cursor + SECTION_GAP * 0.5
        section.startAngle = cursor

        for _, item in ipairs(section.items) do
            item.section = section
            item.startAngle = cursor
            item.endAngle = cursor + segmentAngle + ITEM_GAP
            item.drawStartAngle = item.startAngle + ITEM_GAP * 0.5
            item.drawEndAngle = item.endAngle - ITEM_GAP * 0.5
            item.midAngle = (item.drawStartAngle + item.drawEndAngle) * 0.5

            flatItems[#flatItems + 1] = item

            cursor = item.endAngle
        end

        section.endAngle = cursor
        section.midAngle = (section.startAngle + section.endAngle) * 0.5
        cursor = cursor + SECTION_GAP * 0.5
    end

    return {
        sections = sections,
        items = flatItems,
        count = totalItems,
        mode = context and context.mode or "root",
        group = context and context.group or nil,
        groupId = context and context.groupId or nil,
        defaultItemId = context and context.defaultItemId or nil
    }
end

local function BuildRootWheelData(favoriteMap)
    local sectionMap = {}
    local sections = {}
    local groupedEntries = {}

    for id, data in pairs(MODULE.Emotes or {}) do
        if ( isstring(data.group) and data.group != "" ) then
            local groupMeta = MODULE:GetEmoteGroupMeta(data.group, data)
            local groupBundle = groupedEntries[data.group]

            if ( !groupBundle ) then
                groupBundle = {
                    group = groupMeta,
                    members = {}
                }

                groupedEntries[data.group] = groupBundle
            end

            groupBundle.members[#groupBundle.members + 1] = BuildEmoteEntry(id, data, data.group, groupMeta)
        else
            local sectionId = ResolveSectionId(data)
            local section = CreateSectionBucket(sectionMap, sections, sectionId)

            section.items[#section.items + 1] = BuildEmoteEntry(id, data)
            section.emoteCount = section.emoteCount + 1
        end
    end

    for groupId, groupBundle in pairs(groupedEntries) do
        table.sort(groupBundle.members, SortEntries)

        if ( #groupBundle.members > 0 ) then
            local groupMeta = groupBundle.group or MODULE:GetEmoteGroupMeta(groupId, groupBundle.members[1].data)
            local sectionId = ResolveSectionId({
                category = groupMeta.category
            })
            local section = CreateSectionBucket(sectionMap, sections, sectionId)
            local _, favoriteMember = GetValidatedFavoriteMember(favoriteMap, groupId, groupBundle.members)

            section.items[#section.items + 1] = BuildGroupEntry(groupMeta, groupBundle.members, favoriteMember)
            section.emoteCount = section.emoteCount + #groupBundle.members
        end
    end

    return FinalizeWheelData(sections, {
        mode = "root"
    })
end

local function BuildGroupWheelData(groupId, favoriteMap)
    local groupMeta = MODULE:GetEmoteGroupMeta(groupId)
    local rawMembers = MODULE:GetEmoteGroupMembers(groupId)
    local sectionMap = {}
    local sections = {}
    local members = {}

    for _, member in ipairs(rawMembers) do
        members[#members + 1] = BuildEmoteEntry(member.id, member.data, groupId, groupMeta)
    end

    if ( #members == 0 ) then
        return FinalizeWheelData({}, {
            mode = "group",
            groupId = groupId,
            group = groupMeta
        })
    end

    table.sort(members, SortEntries)

    local _, favoriteMember = GetValidatedFavoriteMember(favoriteMap, groupId, members)

    for _, member in ipairs(members) do
        member.favorite = favoriteMember and member.emoteId == favoriteMember.emoteId or false
    end

    local sectionId = ResolveSectionId({
        category = groupMeta.category
    })
    local section = CreateSectionBucket(sectionMap, sections, sectionId)

    section.description = groupMeta.description or section.description
    section.emoteCount = #members
    section.items[#section.items + 1] = BuildQuickPlayEntry(groupMeta, members, favoriteMember)

    for _, member in ipairs(members) do
        section.items[#section.items + 1] = member
    end

    return FinalizeWheelData(sections, {
        mode = "group",
        groupId = groupId,
        group = groupMeta,
        defaultItemId = favoriteMember and favoriteMember.id or ("quick:" .. groupId)
    })
end

local function BuildWheelData(groupId, favoriteMap)
    if ( isstring(groupId) and groupId != "" ) then
        return BuildGroupWheelData(groupId, favoriteMap or {})
    end

    return BuildRootWheelData(favoriteMap or {})
end

local function ResolvePreviewSequenceID(entity, sequenceName)
    if ( !IsValid(entity) ) then
        return nil
    end

    if ( !isstring(sequenceName) or sequenceName == "" ) then
        return nil
    end

    local sequence = entity:LookupSequence(sequenceName)

    if ( sequence and sequence != -1 ) then
        return sequence
    end

    return nil
end

local function ResolvePreviewIdleSequence(entity, preferredSequence)
    if ( isstring(preferredSequence) and preferredSequence != "" ) then
        local preferredID = ResolvePreviewSequenceID(entity, preferredSequence)

        if ( preferredID ) then
            return preferredID
        end
    end

    for _, sequenceName in ipairs(PREVIEW_IDLE_SEQUENCES) do
        local sequence = ResolvePreviewSequenceID(entity, sequenceName)

        if ( sequence ) then
            return sequence
        end
    end

    return nil
end

local function ResolvePreviewSequence(entity, item)
    if ( !IsValid(entity) ) then
        return nil
    end

    if ( item and item.data ) then
        if ( item.data.type == "gesture" ) then
            local idleSequence = ResolvePreviewIdleSequence(entity, item.data.idleSequence)
            local gestureSequence = ResolvePreviewSequenceID(entity, item.data.sequence)

            -- ClientsideModel previews do not reliably render layered player gestures,
            -- so use the gesture sequence directly and fall back to idle if it is missing.
            if ( gestureSequence and !entity:IsPlayer() ) then
                return {
                    baseSequence = gestureSequence
                }
            end

            if ( idleSequence ) then
                return {
                    baseSequence = idleSequence,
                    gestureSequence = gestureSequence
                }
            end

            if ( gestureSequence ) then
                return {
                    baseSequence = gestureSequence
                }
            end

            return nil
        end

        local sequence = ResolvePreviewSequenceID(entity, item.data.sequence)

        if ( sequence ) then
            return {
                baseSequence = sequence
            }
        end
    end

    local idleSequence = ResolvePreviewIdleSequence(entity)

    if ( idleSequence ) then
        return {
            baseSequence = idleSequence
        }
    end

    return nil
end

local function GetPreviewStateKey(previewState)
    if ( !istable(previewState) ) then
        return nil
    end

    return tostring(previewState.baseSequence or -1) .. ":" .. tostring(previewState.gestureSequence or -1)
end

local function RestartPreviewGesture(entity, gestureSequenceID)
    if ( !IsValid(entity) or !isnumber(gestureSequenceID) or gestureSequenceID == -1 ) then
        if ( IsValid(entity) and entity.AnimResetGestureSlot ) then
            entity:AnimResetGestureSlot(GESTURE_SLOT_VCD)
        end

        return nil
    end

    if ( entity.AnimResetGestureSlot ) then
        entity:AnimResetGestureSlot(GESTURE_SLOT_VCD)
    end

    if ( !entity.AddVCDSequenceToGestureSlot ) then
        return nil
    end

    entity:AddVCDSequenceToGestureSlot(GESTURE_SLOT_VCD, gestureSequenceID, 0, true)

    if ( entity.AnimSetGestureWeight ) then
        entity:AnimSetGestureWeight(GESTURE_SLOT_VCD, 1)
    end

    local duration = entity:SequenceDuration(gestureSequenceID)

    if ( isnumber(duration) and duration > 0 ) then
        return duration
    end

    return nil
end

local function ApplyPreviewSequence(entity, previewState)
    if ( !IsValid(entity) or !istable(previewState) ) then return nil end

    local sequenceID = previewState.baseSequence

    if ( !isnumber(sequenceID) or sequenceID == -1 ) then
        return RestartPreviewGesture(entity, previewState.gestureSequence)
    end

    entity:ResetSequence(sequenceID)
    entity:SetCycle(0)
    entity:SetPlaybackRate(1)

    if ( entity.ResetSequenceInfo ) then
        entity:ResetSequenceInfo()
    end

    entity:InvalidateBoneCache()
    entity:FrameAdvance(0)
    entity:SetupBones()

    return RestartPreviewGesture(entity, previewState.gestureSequence)
end

local function ApplyPlayerAppearance(entity, client)
    if ( !IsValid(entity) or !IsValid(client) ) then return end

    entity:SetModel(client:GetModel())
    entity:SetSkin(client:GetSkin() or 0)
    entity:SetMaterial(client:GetMaterial() or "")
    entity:SetColor(client:GetColor())
    entity.GetPlayerColor = function()
        return client.GetPlayerColor and client:GetPlayerColor() or Vector(1, 1, 1)
    end

    for _, bodygroup in ipairs(client:GetBodyGroups() or {}) do
        if ( isnumber(bodygroup.id) and bodygroup.id >= 0 ) then
            entity:SetBodygroup(bodygroup.id, client:GetBodygroup(bodygroup.id))
        end
    end
end

function PANEL:GetFavoriteMap()
    local favorites = LocalPlayer():GetData("emoteFavorites", {})

    if ( !istable(favorites) ) then
        return {}
    end

    return table.Copy(favorites)
end

function PANEL:FindWheelItem(itemId)
    if ( !isstring(itemId) or !istable(self.wheelData) or !istable(self.wheelData.items) ) then
        return nil
    end

    for _, item in ipairs(self.wheelData.items) do
        if ( item.id == itemId ) then
            return item
        end
    end

    return nil
end

function PANEL:GetPreviewEntry(item)
    if ( !item ) then return nil end

    if ( item.kind == ENTRY_KIND_EMOTE ) then
        return item
    end

    return item.previewEntry or (item.members and item.members[1]) or nil
end

function PANEL:EmitUISound(soundName)
    if ( !isstring(soundName) or soundName == "" ) then return end
    if ( !ax.client or !ax.client.EmitSound ) then return end

    ax.client:EmitSound(soundName)
end

function PANEL:SetWheelData(groupId, preferredItemId)
    self.currentGroupId = isstring(groupId) and groupId != "" and groupId or nil
    self.wheelData = BuildWheelData(self.currentGroupId, self.favoriteMap or {})
    self.hoveredItem = nil
    self.itemAnimations = {}
    self.sectionAnimations = {}
    self.suppressNextHoverSound = true

    local previewItem = preferredItemId and self:FindWheelItem(preferredItemId) or nil

    if ( !previewItem and self.wheelData.defaultItemId ) then
        previewItem = self:FindWheelItem(self.wheelData.defaultItemId)
    end

    self.previewItem = previewItem or self.wheelData.items[1]
    self.hoveredSection = self.previewItem and self.previewItem.section or self.wheelData.sections[1]
end

function PANEL:IsReleaseCommitBlocked(item)
    return self.releaseCommitBlocked and item and item.id == self.releaseCommitBlockItemId
end

function PANEL:SetFavorite(groupId, emoteId, preferredItemId)
    if ( !isstring(groupId) or groupId == "" ) then return end

    local favorites = table.Copy(self.favoriteMap or {})

    if ( isstring(emoteId) and emoteId != "" ) then
        favorites[groupId] = emoteId
    else
        favorites[groupId] = nil
    end

    self:EmitUISound("ax.gui.button.toggle")

    self.favoriteMap = favorites
    ax.net:Start("emote.favorite", groupId, emoteId or "")
    self:SetWheelData(self.currentGroupId, preferredItemId)

    self.releaseCommitBlocked = true
    self.releaseCommitBlockItemId = preferredItemId
end

function PANEL:GetWheelTitle()
    if ( self.wheelData and self.wheelData.mode == "group" and self.wheelData.group ) then
        return self.wheelData.group.name or "Emote Group"
    end

    return "Emote Wheel"
end

function PANEL:GetWheelSubtitle()
    local item = self.hoveredItem or self.previewItem

    if ( item ) then
        if ( item.kind == ENTRY_KIND_GROUP ) then
            return item.favoriteEmoteId and "Release to play your favorite | left click to open group | right click to clear favorite"
                or "Release to quick play this group | left click to open group"
        elseif ( item.kind == ENTRY_KIND_QUICK_PLAY ) then
            if ( self:IsReleaseCommitBlocked(item) ) then
                return item.favoriteEmoteId and "Favorite updated | move off this entry or left click to play"
                    or "Favorite cleared | move off this entry or left click to play"
            end

            return item.favoriteEmoteId and "Release to play your favorite | right click to clear favorite"
                or "Release to play a random emote"
        elseif ( self.currentGroupId and item.kind == ENTRY_KIND_EMOTE ) then
            if ( self:IsReleaseCommitBlocked(item) ) then
                return item.favorite and "Favorite updated | move off this emote or left click to play"
                    or "Favorite cleared | move off this emote or left click to play"
            end

            return item.favorite and "Release to play | right click to remove favorite" or "Release to play | right click to favorite"
        elseif ( item.kind == ENTRY_KIND_EMOTE ) then
            return "Release to play"
        end
    end

    return self.currentGroupId and "Move into the ring to preview or favorite within this group" or "Move into the ring to preview"
end

function PANEL:CommitItem(item, isExplicit)
    if ( !item ) then
        return false
    end

    if ( !isExplicit and self:IsReleaseCommitBlocked(item) ) then
        return false
    end

    if ( item.kind == ENTRY_KIND_GROUP and isExplicit ) then
        return false
    end

    self:EmitUISound("ax.gui.button.click")
    self.dismissed = true

    if ( item.kind == ENTRY_KIND_GROUP or item.kind == ENTRY_KIND_QUICK_PLAY ) then
        ax.net:Start("emote.group", item.groupId)
    else
        ax.net:Start("emote", item.emoteId)
    end

    self:Remove()

    return true
end

function PANEL:ToggleFavorite(item)
    if ( !item or item.kind != ENTRY_KIND_EMOTE or !isstring(item.groupId) or item.groupId == "" ) then return end

    local currentFavorite = (self.favoriteMap or {})[item.groupId]
    local nextFavorite = currentFavorite == item.emoteId and nil or item.emoteId

    self:SetFavorite(item.groupId, nextFavorite, item.id)
end

function PANEL:ClearFavorite(groupId, preferredItemId)
    if ( !isstring(groupId) or groupId == "" ) then return end

    self:SetFavorite(groupId, nil, preferredItemId or ("quick:" .. groupId))
end

function PANEL:BackOut()
    if ( !self.currentGroupId ) then
        return false
    end

    local groupId = self.currentGroupId
    self:EmitUISound("ax.gui.menu.return")
    self:SetWheelData(nil, "group:" .. groupId)

    return true
end

function PANEL:Init()
    if ( IsValid(ax.gui.emoteWheel) and ax.gui.emoteWheel != self ) then
        ax.gui.emoteWheel:Remove()
    end

    self.favoriteMap = self:GetFavoriteMap()
    self.currentGroupId = nil
    self.wheelData = {
        sections = {},
        items = {},
        count = 0
    }
    self.itemAnimations = {}
    self.sectionAnimations = {}
    self.openFraction = 0
    self.previewFraction = 0
    self.previewDistance = 1.2
    self.previewFocus = 0.56
    self.previewFOV = 25
    self.previewYaw = 45
    self.lastPreviewState = nil
    self.lastPreviewStateKey = nil
    self.nextPreviewGestureRestart = nil

    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetAlpha(255)
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)
    self:MakePopup()

    self.previewItem = nil
    self.hoveredItem = nil
    self.hoveredSection = nil

    self.previewModel = ClientsideModel(LocalPlayer():GetModel(), RENDERGROUP_OPAQUE)

    if ( IsValid(self.previewModel) ) then
        self.previewModel:SetNoDraw(true)
        self.previewModel:SetIK(false)
        ApplyPlayerAppearance(self.previewModel, LocalPlayer())
    end

    self:SetWheelData(nil)
    self:EmitUISound("ax.gui.menu.switch")

    ax.gui.emoteWheel = self
    gui.EnableScreenClicker(true)
end

function PANEL:OnRemove()
    gui.EnableScreenClicker(false)

    if ( IsValid(self.previewModel) ) then
        self.previewModel:Remove()
        self.previewModel = nil
    end

    if ( ax.gui.emoteWheel == self ) then
        ax.gui.emoteWheel = nil
    end
end

function PANEL:GetLayoutMetrics(width, height)
    width = width or self:GetWide()
    height = height or self:GetTall()

    local base = math.min(width, height)
    local reveal = 0.92 + self.openFraction * 0.08
    local ringOuter = math.Clamp(base * 0.31, 220, 360) * reveal
    local ringInner = math.Clamp(base * 0.18, 118, 190) * reveal
    local previewSize = math.Clamp(base * 0.28, 186, 300)
    local panelWidth = math.Clamp(base * 0.28, 236, 332)
    local panelHeight = math.Clamp(base * 0.31, 220, 340)
    local gap = math.max(24, base * 0.03)
    local centerX = width * 0.5
    local centerY = height * 0.5 - panelHeight * 0.03
    local slide = (1 - self.openFraction) * math.max(16, base * 0.03)
    local hintWidth = math.max(panelWidth * 1.45, 420)

    return {
        centerX = centerX,
        centerY = centerY,
        ringOuter = ringOuter,
        ringInner = ringInner,
        previewSize = previewSize,
        previewX = centerX - previewSize * 0.5,
        previewY = centerY - previewSize * 0.5,
        leftX = centerX - ringOuter - gap - panelWidth - slide,
        rightX = centerX + ringOuter + gap + slide,
        panelY = centerY - panelHeight * 0.5 + (1 - self.openFraction) * 12,
        panelWidth = panelWidth,
        panelHeight = panelHeight,
        hintWidth = hintWidth,
        hintHeight = 58,
        hintX = centerX - hintWidth * 0.5,
        hintY = height - math.max(86, base * 0.105),
        deadzone = ringInner - 14,
        edgePadding = 26
    }
end

function PANEL:Dismiss(shouldCommit)
    if ( self.dismissed ) then return end

    if ( shouldCommit and self:CommitItem(self.hoveredItem, false) ) then
        return
    end

    self:EmitUISound("ax.gui.menu.close")
    self.dismissed = true
    self:Remove()
end

function PANEL:OnMousePressed(mouseCode)
    if ( mouseCode == MOUSE_LEFT ) then
        local item = self.hoveredItem

        if ( item and item.kind == ENTRY_KIND_GROUP ) then
            self:EmitUISound("ax.gui.menu.switch")
            self:SetWheelData(item.groupId)
            return
        end

        self:CommitItem(item, true)
        return
    end

    if ( mouseCode == MOUSE_RIGHT ) then
        if ( self.currentGroupId and self.hoveredItem and self.hoveredItem.kind == ENTRY_KIND_EMOTE ) then
            self:ToggleFavorite(self.hoveredItem)
            return
        end

        if ( self.currentGroupId and self.hoveredItem and self.hoveredItem.kind == ENTRY_KIND_QUICK_PLAY and self.hoveredItem.favoriteEmoteId ) then
            self:ClearFavorite(self.hoveredItem.groupId)
            return
        end

        if ( !self.currentGroupId and self.hoveredItem and self.hoveredItem.kind == ENTRY_KIND_GROUP and self.hoveredItem.favoriteEmoteId ) then
            self:ClearFavorite(self.hoveredItem.groupId, self.hoveredItem.id)
            return
        end

        if ( self:BackOut() ) then
            return
        end

        self:Dismiss(false)
    end
end

function PANEL:OnKeyCodePressed(keyCode)
    if ( keyCode == KEY_ESCAPE ) then
        self:Dismiss(false)
    end
end

function PANEL:UpdateHoverState(layout)
    if ( self.wheelData.count == 0 ) then
        self.hoveredItem = nil
        self.hoveredSection = nil
        return
    end

    local mouseX, mouseY = gui.MouseX(), gui.MouseY()

    if ( mouseX < 0 or mouseY < 0 ) then
        mouseX = layout.centerX
        mouseY = layout.centerY
    end

    local dx = mouseX - layout.centerX
    local dy = mouseY - layout.centerY
    local distance = math.sqrt(dx * dx + dy * dy)
    local angle = NormalizeAngle(math.deg(math.atan2(dy, dx)) + 90)

    self.mouseX = mouseX
    self.mouseY = mouseY
    self.mouseAngle = angle
    self.mouseDistance = distance

    local hovered = nil

    if ( distance >= layout.deadzone and distance <= layout.ringOuter + layout.edgePadding ) then
        for _, item in ipairs(self.wheelData.items) do
            if ( AngleWithin(angle, item.startAngle, item.endAngle) ) then
                hovered = item
                break
            end
        end
    end

    local previousHoveredId = self.hoveredItem and self.hoveredItem.id or nil

    self.hoveredItem = hovered

    if ( hovered ) then
        self.previewItem = hovered
        self.hoveredSection = hovered.section
    elseif ( self.previewItem ) then
        self.hoveredSection = self.previewItem.section
    else
        self.hoveredSection = nil
    end

    local hoveredId = hovered and hovered.id or nil

    if ( self.releaseCommitBlocked and hoveredId != self.releaseCommitBlockItemId ) then
        self.releaseCommitBlocked = false
        self.releaseCommitBlockItemId = nil
    end

    if ( hoveredId != previousHoveredId ) then
        if ( self.suppressNextHoverSound ) then
            self.suppressNextHoverSound = false
        elseif ( hoveredId ) then
            self:EmitUISound("ax.gui.button.enter")
        end
    end
end

function PANEL:UpdatePreviewModel()
    if ( !IsValid(self.previewModel) ) then return end

    local client = LocalPlayer()

    if ( !IsValid(client) ) then return end

    if ( self.previewModel:GetModel() != client:GetModel() ) then
        ApplyPlayerAppearance(self.previewModel, client)
        self.lastPreviewState = nil
        self.lastPreviewStateKey = nil
        self.nextPreviewGestureRestart = nil
    end

    local targetItem = self:GetPreviewEntry(self.previewItem)
    local targetDistance = 1.24
    local targetFocus = 0.55
    local targetFOV = 34

    if ( targetItem and targetItem.data ) then
        local category = ResolveSectionId(targetItem.data)

        if ( targetItem.data.type == "gesture" ) then
            targetDistance = 0.96
            targetFocus = 0.72
            targetFOV = 30
        elseif ( category == "poses" ) then
            targetDistance = 1.36
            targetFocus = 0.42
            targetFOV = 36
        else
            targetDistance = 1.22
            targetFocus = 0.54
            targetFOV = 34
        end
    end

    self.previewDistance = EaseNumber(self.previewDistance, targetDistance, 8, "OutQuad")
    self.previewFocus = EaseNumber(self.previewFocus, targetFocus, 8, "OutQuad")
    self.previewFOV = EaseNumber(self.previewFOV, targetFOV, 8, "OutQuad")
    self.previewYaw = EaseNumber(self.previewYaw, 45 + math.sin(RealTime() * 0.75) * 5, 7, "OutSine")

    local targetState = ResolvePreviewSequence(self.previewModel, targetItem)

    if ( !targetState and !self.lastPreviewState ) then
        targetState = ResolvePreviewSequence(self.previewModel)
    end

    local targetStateKey = GetPreviewStateKey(targetState)

    if ( targetState and self.lastPreviewStateKey != targetStateKey ) then
        local gestureDuration = ApplyPreviewSequence(self.previewModel, targetState)

        self.lastPreviewState = targetState
        self.lastPreviewStateKey = targetStateKey
        self.nextPreviewGestureRestart = gestureDuration and (RealTime() + gestureDuration + 0.05) or nil
    elseif ( !targetState and self.lastPreviewState and self.previewModel:GetSequence() != self.lastPreviewState.baseSequence ) then
        local gestureDuration = ApplyPreviewSequence(self.previewModel, self.lastPreviewState)
        self.nextPreviewGestureRestart = gestureDuration and (RealTime() + gestureDuration + 0.05) or nil
    elseif ( targetState and targetState.gestureSequence and self.nextPreviewGestureRestart and RealTime() >= self.nextPreviewGestureRestart ) then
        local gestureDuration = RestartPreviewGesture(self.previewModel, targetState.gestureSequence)
        self.nextPreviewGestureRestart = gestureDuration and (RealTime() + gestureDuration + 0.05) or nil
    end

    if ( self.lastPreviewState and self.lastPreviewState.baseSequence ) then
        self.previewModel:FrameAdvance(FrameTime())
        self.previewModel:SetupBones()
    end
end

function PANEL:Think()
    if ( self:GetWide() != ScrW() or self:GetTall() != ScrH() ) then
        self:SetSize(ScrW(), ScrH())
    end

    self.openFraction = EaseNumber(self.openFraction, 1, 9, "OutCubic")
    self.previewFraction = EaseNumber(self.previewFraction, self.hoveredItem and 1 or 0.45, 8, "OutQuad")

    local layout = self:GetLayoutMetrics()
    self:UpdateHoverState(layout)
    self:UpdatePreviewModel()

    for _, item in ipairs(self.wheelData.items) do
        local target = 0

        if ( self.hoveredItem == item ) then
            target = 1
        elseif ( self.previewItem == item ) then
            target = 0.3
        end

        self.itemAnimations[item.id] = EaseNumber(self.itemAnimations[item.id] or 0, target, 10, "OutQuad")
    end

    for _, section in ipairs(self.wheelData.sections) do
        local target = 0.18

        if ( self.hoveredSection == section ) then
            target = 1
        elseif ( self.previewItem and self.previewItem.section == section ) then
            target = 0.45
        end

        self.sectionAnimations[section.id] = EaseNumber(self.sectionAnimations[section.id] or 0, target, 9, "OutQuad")
    end
end

function PANEL:PaintBackdrop(width, height, glass)
    ax.theme:DrawGlassBackdrop(0, 0, width, height, {
        radius = 0,
        blur = 1.15,
        fill = AlphaColor(glass.overlayStrong or glass.overlay, math.max(70, 170 * self.openFraction))
    })

    ax.theme:DrawGlassGradients(0, 0, width, height, {
        left = AlphaColor(glass.gradientLeft, math.min(70, 48 * self.openFraction)),
        right = AlphaColor(glass.gradientRight, math.min(70, 48 * self.openFraction)),
        top = AlphaColor(glass.gradientTop, math.min(80, 58 * self.openFraction)),
        bottom = AlphaColor(glass.gradientBottom, math.min(90, 64 * self.openFraction))
    })
end

function PANEL:PaintWheel(layout, glass)
    local centerX = layout.centerX
    local centerY = layout.centerY
    local ringWidth = layout.ringOuter - layout.ringInner
    local ringDiameter = layout.ringOuter * 2 + 30
    local outlineColor = AlphaColor(glass.panelBorder, 95)

    ax.render().Circle(centerX, centerY, ringDiameter)
        :Outline(ringWidth + 22)
        :Blur(1.15)
        :Color(AlphaColor(glass.overlayStrong or glass.overlay, 220))
        :Draw()

    ax.render.DrawCircleOutlined(centerX, centerY, layout.ringOuter * 2 + 10, AlphaColor(glass.panelBorder, 70), 1.5)
    ax.render.DrawCircleOutlined(centerX, centerY, layout.ringInner * 2 - 4, AlphaColor(glass.panelBorder, 55), 1)

    -- Not a big fan, really low poly.
    -- for _, section in ipairs(self.wheelData.sections) do
    --     local sectionFraction = self.sectionAnimations[section.id] or 0
    --     local sectionColor = BlendColors(
    --         AlphaColor(glass.button, 34),
    --         AlphaColor(section.color, 86),
    --         math.min(1, 0.25 + sectionFraction * 0.75)
    --     )
    --     DrawRingSegment(centerX, centerY, layout.ringOuter + 8, layout.ringOuter + 16 + sectionFraction * 3,
    --         section.startAngle + SECTION_GAP * 0.18, section.endAngle - SECTION_GAP * 0.18, sectionColor)
    -- end

    for _, item in ipairs(self.wheelData.items) do
        local itemFraction = self.itemAnimations[item.id] or 0
        local accent = item.section.color
        local secondaryLabel = string.upper(item.section.name)
        local fillColor = BlendColors(
            AlphaColor(glass.button, 92),
            AlphaColor(accent, 185),
            math.min(1, 0.2 + itemFraction * 0.8)
        )
        local borderColor = BlendColors(
            AlphaColor(glass.buttonBorder or glass.panelBorder, 40),
            AlphaColor(accent, 220),
            math.min(1, 0.25 + itemFraction * 0.75)
        )
        local expandedOuter = layout.ringOuter + itemFraction * 10

        DrawRingSegment(centerX, centerY, layout.ringInner, expandedOuter,
            item.drawStartAngle, item.drawEndAngle, fillColor)

        DrawDivider(centerX, centerY, layout.ringInner + 4, expandedOuter, item.startAngle, AlphaColor(outlineColor, 90))
        DrawDivider(centerX, centerY, layout.ringInner + 4, expandedOuter, item.endAngle, AlphaColor(outlineColor, 55))

        if ( itemFraction > 0.01 ) then
            DrawRingSegment(centerX, centerY, expandedOuter - 6, expandedOuter + 3,
                item.drawStartAngle, item.drawEndAngle, AlphaColor(borderColor, 190))
        end

        local labelRadius = layout.ringInner + ringWidth * (0.52 + itemFraction * 0.08)
        local labelX, labelY = PolarToScreen(centerX, centerY, labelRadius, item.midAngle)

        if ( item.kind == ENTRY_KIND_GROUP ) then
            secondaryLabel = item.favoriteEmoteId and "FAVORITE" or "QUICK PLAY"
        elseif ( item.kind == ENTRY_KIND_QUICK_PLAY ) then
            secondaryLabel = item.favoriteEmoteId and "FAVORITE" or "RANDOM"
        elseif ( item.favorite ) then
            secondaryLabel = "FAVORITE"
        end

        draw.SimpleText(item.data.name or item.id, "ax.small.bold", labelX, labelY - 8,
            itemFraction > 0.05 and glass.textHover or glass.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(secondaryLabel, "ax.tiny.bold", labelX, labelY + 9,
            AlphaColor(item.section.color, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    ax.render.DrawCircle(centerX, centerY, layout.ringInner * 2 - 18, AlphaColor(glass.panel, 185))
    ax.render.DrawCircleOutlined(centerX, centerY, layout.ringInner * 2 - 18, AlphaColor(glass.panelBorder, 85), 1)

    local titleColor = self.hoveredItem and AlphaColor(self.hoveredItem.section.color, 235) or glass.text
    draw.SimpleText(self:GetWheelTitle(), "ax.large.bold", centerX, centerY - layout.previewSize * 0.66, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local subtitle = self:GetWheelSubtitle()
    draw.SimpleText(subtitle, "ax.small", centerX, centerY - layout.previewSize * 0.56, glass.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PANEL:PaintSectionsPanel(layout, glass, metrics)
    local x, y = layout.leftX, layout.panelY
    local width, height = layout.panelWidth, layout.panelHeight
    local padding = 18
    local sections = self.wheelData.sections
    local sectionCount = math.max(1, #sections)
    local titleHeight = GetTextHeight("ax.large.bold")
    local subtitleLineHeight = GetTextHeight("ax.small")
    local rowTitleHeight = GetTextHeight("ax.regular.bold")
    local rowDescriptionHeight = GetTextHeight("ax.small")
    local subtitleText = self.currentGroupId and ((self.wheelData.group and self.wheelData.group.description) or "Select a specific emote or use Quick Play.") or "Grouped for faster selection and clearer scanning."
    local titleText = self.currentGroupId and "Group" or "Sections"
    local subtitleLines = LimitWrappedLines(ax.util:GetWrappedText(
        subtitleText,
        "ax.small",
        width - padding * 2
    ) or { subtitleText }, 2)
    local subtitleY = y + padding + titleHeight + 6
    local rowGap = math.Clamp(math.floor(height * 0.022), 6, 10)
    local headerHeight = titleHeight + 6 + (#subtitleLines * subtitleLineHeight)
    local rowY = y + padding + headerHeight + 12
    local availableHeight = math.max(42, (y + height - padding) - rowY)
    local rowHeight = math.Clamp(math.floor((availableHeight - rowGap * (sectionCount - 1)) / sectionCount), 42, 72)

    ax.render.DrawShadows(metrics.roundness + 2, x, y, width, height, AlphaColor(glass.highlight or glass.progress, 28), 18, 26, ax.render.SHAPE_IOS)
    ax.theme:DrawGlassPanel(x, y, width, height, {
        radius = metrics.roundness + 2,
        blur = 1.05,
        flags = ax.render.SHAPE_IOS,
        fill = glass.menu or glass.panel,
        border = glass.menuBorder or glass.panelBorder
    })

    ax.theme:DrawGlassGradients(x, y, width, height, {
        top = AlphaColor(glass.gradientTop, 40),
        bottom = AlphaColor(glass.gradientBottom, 58)
    })

    draw.SimpleText(titleText, "ax.large.bold", x + padding, y + padding, glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    for index, line in ipairs(subtitleLines) do
        draw.SimpleText(line, "ax.small", x + padding, subtitleY + (index - 1) * subtitleLineHeight, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    for _, section in ipairs(sections) do
        local fraction = self.sectionAnimations[section.id] or 0
        local rowFill = BlendColors(
            AlphaColor(glass.button, 98),
            AlphaColor(section.color, 105 + fraction * 60),
            math.min(1, 0.22 + fraction * 0.55)
        )
        local rowBorder = BlendColors(
            AlphaColor(glass.buttonBorder or glass.panelBorder, 50),
            AlphaColor(section.color, 220),
            math.min(1, 0.3 + fraction * 0.7)
        )
        local rowX = x + padding
        local rowWidth = width - padding * 2
        local countLabel = (section.emoteCount or #section.items) .. " emotes"
        local countWidth = GetTextWidth("ax.small.bold", countLabel) + 18
        local descWidth = math.max(72, rowWidth - 42 - countWidth)
        local maxDescriptionLines = math.max(1, math.floor((rowHeight - 16 - rowTitleHeight - 4) / rowDescriptionHeight))
        local descriptionText = tostring(section.description or "")
        local descriptionLines

        if ( maxDescriptionLines <= 1 ) then
            descriptionLines = {
                FitTextToWidth("ax.small", descriptionText, descWidth)
            }
        else
            descriptionLines = LimitWrappedLines(ax.util:GetWrappedText(
                descriptionText,
                "ax.small",
                descWidth
            ) or { descriptionText }, maxDescriptionLines)
        end

        ax.theme:DrawGlassButton(rowX, rowY, rowWidth, rowHeight, {
            radius = math.max(8, metrics.roundness),
            blur = 0.85,
            fill = rowFill,
            border = rowBorder
        })

        ax.render.Draw(6, rowX + 8, rowY + 8, 6, rowHeight - 16, AlphaColor(section.color, 220))
        draw.SimpleText(section.name, "ax.regular.bold", rowX + 26, rowY + 10, fraction > 0.5 and glass.textHover or glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        for index, line in ipairs(descriptionLines) do
            draw.SimpleText(line, "ax.small", rowX + 26, rowY + 10 + rowTitleHeight + 3 + (index - 1) * rowDescriptionHeight, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        draw.SimpleText(countLabel, "ax.small.bold", rowX + rowWidth - 14, rowY + 11, AlphaColor(section.color, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        rowY = rowY + rowHeight + rowGap
    end
end

function PANEL:PaintInfoPanel(layout, glass, metrics)
    local x, y = layout.rightX, layout.panelY
    local width, height = layout.panelWidth, layout.panelHeight
    local padding = 18
    local item = self.previewItem
    local previewEntry = self:GetPreviewEntry(item)
    local previewData = previewEntry and previewEntry.data or nil
    local accent = item and item.section.color or (glass.progress or glass.highlight)
    local title = item and (item.data.name or item.id) or "No Emotes Registered"
    local description = item and item.data.description or "Register emotes in the module to populate the wheel."
    local typeLabel = "Unavailable"

    if ( item and item.kind == ENTRY_KIND_GROUP ) then
        typeLabel = "Group"
        description = (item.group and item.group.description) or description
    elseif ( item and item.kind == ENTRY_KIND_QUICK_PLAY ) then
        typeLabel = "Quick Play"
    elseif ( item ) then
        if ( item.data.type == "gesture" ) then
            typeLabel = "Gesture"
        elseif ( item.data.type == "loop" ) then
            typeLabel = "Loop"
        else
            typeLabel = "Static"
        end
    end
    local sectionLabel = item and ((item.group and item.group.name) or item.section.name) or "Empty"
    local sequenceLabel = previewData and tostring(previewData.sequence or "n/a") or (item and tostring(item.data.sequence or "n/a") or "n/a")
    local wrapped = ax.util:GetWrappedText(description, "ax.regular", width - padding * 2) or { description }
    local headerHeight = GetTextHeight("ax.large.bold")
    local titleLineHeight = GetTextHeight("ax.medium.bold")
    local regularLineHeight = GetTextHeight("ax.regular")
    local smallLineHeight = GetTextHeight("ax.small")
    local titleLines = LimitWrappedLines(ax.util:GetWrappedText(title, "ax.medium.bold", width - padding * 2) or { title }, 2)
    local titleY = y + padding + headerHeight + 6

    ax.render.DrawShadows(metrics.roundness + 2, x, y, width, height, AlphaColor(accent, 28), 18, 26, ax.render.SHAPE_IOS)
    ax.theme:DrawGlassPanel(x, y, width, height, {
        radius = metrics.roundness + 2,
        blur = 1.05,
        flags = ax.render.SHAPE_IOS,
        fill = glass.panel,
        border = glass.panelBorder
    })

    ax.theme:DrawGlassGradients(x, y, width, height, {
        top = AlphaColor(accent, 26),
        bottom = AlphaColor(glass.gradientBottom, 52)
    })

    draw.SimpleText("Selection", "ax.large.bold", x + padding, y + padding, glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    for index, line in ipairs(titleLines) do
        draw.SimpleText(line, "ax.medium.bold", x + padding, titleY + (index - 1) * titleLineHeight, AlphaColor(accent, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local tagY = titleY + (#titleLines * titleLineHeight) + 12
    local tagSpacing = 8
    local sectionTagWidth = math.Clamp(GetTextWidth("ax.tiny.bold", sectionLabel) + 26, 74, 150)
    local typeTagWidth = math.Clamp(GetTextWidth("ax.tiny.bold", typeLabel) + 26, 74, 110)
    local stackTags = sectionTagWidth + typeTagWidth + tagSpacing > (width - padding * 2)

    local function DrawTag(text, tagX, tagYPos, tagWidth, tagColor)
        ax.theme:DrawGlassButton(tagX, tagYPos, tagWidth, 24, {
            radius = 10,
            blur = 0.65,
            fill = BlendColors(AlphaColor(glass.button, 92), AlphaColor(tagColor, 120), 0.45),
            border = AlphaColor(tagColor, 220)
        })

        draw.SimpleText(FitTextToWidth("ax.tiny.bold", text, tagWidth - 12), "ax.tiny.bold", tagX + tagWidth * 0.5, tagYPos + 12, glass.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    DrawTag(sectionLabel, x + padding, tagY, sectionTagWidth, accent)

    if ( stackTags ) then
        DrawTag(typeLabel, x + padding, tagY + 30, typeTagWidth, glass.progress or accent)
    else
        DrawTag(typeLabel, x + padding + sectionTagWidth + tagSpacing, tagY, typeTagWidth, glass.progress or accent)
    end

    local sequenceLabelY = tagY + (stackTags and 60 or 34)
    draw.SimpleText("Sequence", "ax.small.bold", x + padding, sequenceLabelY, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(sequenceLabel, "ax.regular.bold", x + padding, sequenceLabelY + smallLineHeight + 2, glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local textY = sequenceLabelY + smallLineHeight + regularLineHeight + 14

    for _, line in ipairs(wrapped) do
        draw.SimpleText(line, "ax.regular", x + padding, textY, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        textY = textY + regularLineHeight
    end

    local footerY = y + height - 48
    local footer = "Release with no selection to cancel."
    local footerHint = "Add emotes to restore the wheel."

    if ( item ) then
        if ( item.kind == ENTRY_KIND_GROUP ) then
            footer = item.favoriteEmoteId and ("Quick Play: " .. tostring(previewData and previewData.name or item.favoriteEmoteId)) or (tostring(#(item.members or {})) .. " emotes in this group. Release picks a random one.")
            footerHint = item.favoriteEmoteId and "Release to quick play | left click to open | right click to clear favorite." or "Release to quick play | left click to open."
        elseif ( item.kind == ENTRY_KIND_QUICK_PLAY ) then
            footer = item.favoriteEmoteId and ("Favorite: " .. tostring(previewData and previewData.name or item.favoriteEmoteId)) or "No favorite set. Plays a random emote."
            footerHint = item.favoriteEmoteId and "Left click or release to play | right click to clear favorite." or "Left click or release to play."
        elseif ( item.favorite ) then
            footer = "Favorite for " .. tostring(item.group and item.group.name or item.section.name) .. "."
            footerHint = "Left click or release to play | right click to remove favorite."
        elseif ( self.currentGroupId and item.groupId ) then
            footer = "Cooldown: " .. string.format("%.1fs", (MODULE.Config and MODULE.Config.Cooldown) or 2)
            footerHint = "Left click or release to play | right click to favorite."
        else
            footer = "Cooldown: " .. string.format("%.1fs", (MODULE.Config and MODULE.Config.Cooldown) or 2)
            footerHint = "Left click or release to play."
        end
    end

    if ( item and self:IsReleaseCommitBlocked(item) ) then
        footer = item.favorite and "Favorite updated for this group." or "Favorite cleared for this group."
        footerHint = "Move off this selection or left click to play."
    end

    draw.SimpleText(footer, "ax.small", x + padding, footerY, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(footerHint, "ax.small.bold", x + padding, footerY + 16, glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function PANEL:PaintHintPanel(layout, glass, metrics)
    local x, y = layout.hintX, layout.hintY
    local width, height = layout.hintWidth, layout.hintHeight
    local bindText = string.upper(input.LookupBinding("+emotewheel") or "UNBOUND")

    ax.theme:DrawGlassPanel(x, y, width, height, {
        radius = metrics.roundness + 2,
        blur = 0.95,
        flags = ax.render.SHAPE_IOS,
        fill = AlphaColor(glass.panel, 170),
        border = AlphaColor(glass.panelBorder, 90)
    })

    ax.theme:DrawGlassGradients(x, y, width, height, {
        top = AlphaColor(glass.gradientTop, 28),
        bottom = AlphaColor(glass.gradientBottom, 42)
    })

    local hintText = self.currentGroupId
        and "Release or left click to play  |  right click emote to favorite  |  right click Quick Play to clear  |  right click empty to go back  |  ESC to cancel"
        or "Release to play emotes or quick play groups  |  left click groups to open  |  right click favorite groups to clear  |  ESC to cancel"

    draw.SimpleText("HOLD " .. bindText, "ax.small.bold", x + 18, y + 15, glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(hintText, "ax.small", x + 18, y + 33, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function PANEL:PaintPointer(layout, glass)
    if ( !self.mouseX or !self.mouseY ) then return end
    if ( !self.hoveredItem ) then return end
    if ( !self.mouseDistance or self.mouseDistance < layout.deadzone - 18 or self.mouseDistance > layout.ringOuter + layout.edgePadding ) then return end

    local pointerColor = self.hoveredItem and self.hoveredItem.section.color or (self.previewItem and self.previewItem.section.color) or glass.progress
    ax.render().Circle(self.mouseX, self.mouseY, 8)
        :Outline(2)
        :Blur(0.35)
        :Color(AlphaColor(pointerColor, 130))
        :Draw()
    ax.render.DrawCircle(self.mouseX, self.mouseY, 3, AlphaColor(pointerColor, 185))
end

function PANEL:PaintPreview(layout, glass, metrics)
    local frameX = layout.previewX
    local frameY = layout.previewY
    local frameSize = layout.previewSize
    local padding = 12
    local modelX = frameX + padding
    local modelY = frameY + padding
    local modelSize = frameSize - padding * 2

    ax.render.DrawShadows(metrics.roundness + 4, frameX, frameY, frameSize, frameSize, AlphaColor(glass.highlight or glass.progress, 32), 20, 30, ax.render.SHAPE_IOS)
    ax.theme:DrawGlassPanel(frameX, frameY, frameSize, frameSize, {
        radius = metrics.roundness + 4,
        blur = 1.15,
        flags = ax.render.SHAPE_IOS,
        fill = AlphaColor(glass.panel, 190),
        border = AlphaColor(glass.panelBorder, 105)
    })

    ax.theme:DrawGlassGradients(frameX, frameY, frameSize, frameSize, {
        top = AlphaColor(glass.gradientTop, 42),
        bottom = AlphaColor(glass.gradientBottom, 68)
    })

    ax.render.DrawCircle(frameX + frameSize * 0.5, frameY + frameSize * 0.8, frameSize * 0.38, AlphaColor(glass.overlayStrong or glass.overlay, 120))

    if ( !IsValid(self.previewModel) ) then
        draw.SimpleText("Preview unavailable", "ax.regular.bold", frameX + frameSize * 0.5, frameY + frameSize * 0.5, glass.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    local entity = self.previewModel
    local mins, maxs = entity:GetRenderBounds()
    local bounds = maxs - mins
    local height = math.max(1, bounds.z)
    local width = math.max(bounds.x, bounds.y, 18)
    local lookZ = mins.z + height * self.previewFocus
    local camDistance = math.max(36, math.max(height, width * 1.35) * self.previewDistance)
    local camPos = Vector(camDistance, camDistance * 0.16, lookZ + 4)
    local lookAt = Vector(0, 0, lookZ)

    entity:SetPos(vector_origin)
    entity:SetAngles(Angle(0, self.previewYaw, 0))

    cam.Start3D(camPos, (lookAt - camPos):Angle(), self.previewFOV, modelX, modelY, modelSize, modelSize, 5, 4096)
        render.SuppressEngineLighting(true)
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)
        render.ResetModelLighting(0.35, 0.35, 0.35)
        render.SetModelLighting(BOX_TOP, 1, 1, 1)
        render.SetModelLighting(BOX_FRONT, 0.8, 0.8, 0.8)
        render.SetModelLighting(BOX_RIGHT, 0.55, 0.55, 0.65)
        render.SetModelLighting(BOX_LEFT, 0.35, 0.35, 0.42)
        entity:DrawModel()
        render.SuppressEngineLighting(false)
    cam.End3D()
end

function PANEL:PaintEmptyState(width, height, glass, metrics)
    local panelWidth = 420
    local panelHeight = 120
    local x = width * 0.5 - panelWidth * 0.5
    local y = height * 0.5 - panelHeight * 0.5

    ax.theme:DrawGlassPanel(x, y, panelWidth, panelHeight, {
        radius = metrics.roundness + 2,
        blur = 1.05,
        flags = ax.render.SHAPE_IOS,
        fill = glass.panel,
        border = glass.panelBorder
    })

    draw.SimpleText("No emotes registered", "ax.large.bold", width * 0.5, y + 30, glass.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Populate MODULE.Emotes to use the emote wheel.", "ax.regular", width * 0.5, y + 62, glass.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PANEL:Paint(width, height)
    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()

    self:PaintBackdrop(width, height, glass)

    if ( self.wheelData.count == 0 ) then
        self:PaintEmptyState(width, height, glass, metrics)
        return true
    end

    local layout = self:GetLayoutMetrics(width, height)

    self:PaintSectionsPanel(layout, glass, metrics)
    self:PaintInfoPanel(layout, glass, metrics)
    self:PaintHintPanel(layout, glass, metrics)
    self:PaintWheel(layout, glass)
    self:PaintPointer(layout, glass)
    self:PaintPreview(layout, glass, metrics)

    return true
end

vgui.Register("ax.emoteWheel", PANEL, "EditablePanel")

function MODULE:OpenWheel()
    if ( IsValid(ax.gui.emoteWheel) ) then return end

    vgui.Create("ax.emoteWheel")
end

function MODULE:CloseWheel(shouldCommit)
    if ( !IsValid(ax.gui.emoteWheel) ) then return end

    ax.gui.emoteWheel:Dismiss(shouldCommit == true)
end

concommand.Add("+emotewheel", function()
    MODULE:OpenWheel()
end)

concommand.Add("-emotewheel", function()
    MODULE:CloseWheel(true)
end)
