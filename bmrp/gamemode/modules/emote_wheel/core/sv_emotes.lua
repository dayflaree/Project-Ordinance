--[[
    Emote Wheel Server Logic
]]

local MODULE = MODULE

local function GetFavoriteTable(client)
    local favorites = client:GetData("emoteFavorites", {})

    if ( !istable(favorites) ) then
        return {}
    end

    return table.Copy(favorites)
end

local function SaveFavoriteTable(client, favorites)
    client:SetData("emoteFavorites", favorites or {})
end

-- Command to play emote
ax.command:Add("emote", {
    description = "Play an emote.",
    arguments = {
        {
            name = "name",
            type = ax.type.string,
            required = true
        }
    },
    OnRun = function(this, client, name)
        MODULE:PlayEmote(client, name)
    end
})

function MODULE:PlayResolvedEmote(client, emoteId, emote, skipRateLimit)
    local cooldown = ( MODULE.Config and MODULE.Config.Cooldown ) or 2

    if ( !skipRateLimit and !client:RateLimit("emote", cooldown) ) then
        client:Notify("Please wait before using another emote!")
        return
    end

    if ( !emote ) then
        client:Notify("Emote not found!")
        return
    end

    if ( client:GetRelay("sequence.id") ) then
        client:LeaveSequence()
    end

    -- Play Animation based on type
    if ( emote.type == "gesture" ) then
        client:PlayGesture(GESTURE_SLOT_VCD, emote.sequence)
    elseif ( emote.type == "loop" ) then
        client:ForceSequence(emote.sequence, nil, 0)
    elseif ( emote.type == "static" ) then
        client:ForceSequence(emote.sequence)
    end
end

function MODULE:PlayEmote(client, emoteId)
    local resolvedId, emote = self:ResolveEmote(emoteId)

    if ( !emote ) then
        client:Notify("Emote not found!")
        return
    end

    return self:PlayResolvedEmote(client, resolvedId, emote)
end

function MODULE:GetGroupFavoriteEmote(client, groupId)
    local favorites = GetFavoriteTable(client)
    local favoriteId = favorites[groupId]

    if ( !isstring(favoriteId) or favoriteId == "" ) then
        return nil, nil
    end

    local members = self:GetEmoteGroupMembers(groupId)

    for _, member in ipairs(members) do
        if ( member.id == favoriteId ) then
            return favoriteId, member.data
        end
    end

    favorites[groupId] = nil
    SaveFavoriteTable(client, favorites)

    return nil, nil
end

function MODULE:SetFavoriteEmote(client, groupId, emoteId)
    if ( !isstring(groupId) or groupId == "" ) then
        return nil
    end

    local groupMeta = self:GetEmoteGroupMeta(groupId)

    if ( !groupMeta ) then
        return nil
    end

    local favorites = GetFavoriteTable(client)

    if ( !isstring(emoteId) or emoteId == "" ) then
        favorites[groupId] = nil
        SaveFavoriteTable(client, favorites)

        return nil
    end

    local resolvedId = nil

    for _, member in ipairs(self:GetEmoteGroupMembers(groupId)) do
        if ( member.id == emoteId ) then
            resolvedId = member.id
            break
        end
    end

    if ( !resolvedId ) then
        return favorites[groupId]
    end

    favorites[groupId] = resolvedId

    SaveFavoriteTable(client, favorites)

    return favorites[groupId]
end

function MODULE:ResolveGroupPlayEmote(client, groupId)
    local members = self:GetEmoteGroupMembers(groupId)

    if ( #members == 0 ) then
        return nil, nil
    end

    local favoriteId, favoriteEmote = self:GetGroupFavoriteEmote(client, groupId)

    if ( favoriteEmote ) then
        return favoriteId, favoriteEmote
    end

    local randomIndex = math.random(#members)
    local member = members[randomIndex]

    return member.id, member.data
end

function MODULE:PlayGroupDefault(client, groupId)
    local cooldown = ( MODULE.Config and MODULE.Config.Cooldown ) or 2

    if ( !client:RateLimit("emote", cooldown) ) then
        client:Notify("Please wait before using another emote!")
        return
    end

    local emoteId, emote = self:ResolveGroupPlayEmote(client, groupId)

    if ( !emote ) then
        client:Notify("That emote group is empty.")
        return
    end

    return self:PlayResolvedEmote(client, emoteId, emote, true)
end

ax.net:Hook("emote", function(client, id)
    MODULE:PlayEmote(client, id)
end)

ax.net:Hook("emote.group", function(client, groupId)
    MODULE:PlayGroupDefault(client, groupId)
end)

ax.net:Hook("emote.favorite", function(client, groupId, emoteId)
    MODULE:SetFavoriteEmote(client, groupId, emoteId)
end)
