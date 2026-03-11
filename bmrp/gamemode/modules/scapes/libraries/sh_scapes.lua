--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Scapes shared registry and builder DSL.
-- @module ax.scapes

ax.scapes = ax.scapes or {}
ax.scapes.stored = ax.scapes.stored or {}

ax.scapes.NET_ACTIVATE = "Scapes.Activate"
ax.scapes.NET_SCHEDULE = "Scapes.Schedule"
ax.scapes.NET_DEACTIVATE = "Scapes.Deactivate"
ax.scapes.NET_TRIGGER = "Scapes.Trigger"
ax.scapes.NET_READY = "Scapes.Ready"

local MAX_POSITION_KEYS = 7
local MAX_DSP_PRESET = 255
local SCAPES_LOG_PREFIX = "[Scapes]"

--- Build a prefixed vararg list for Scapes logs.
-- @tparam any ... Message arguments.
-- @treturn table Argument array with Scapes prefix.
local function BuildPrefixedLogArgs(...)
    local args = {SCAPES_LOG_PREFIX}

    for i = 1, select("#", ...) do
        args[#args + 1] = select(i, ...)
    end

    return args
end

local BUILDER = {}
BUILDER.__index = BUILDER

--- Normalize a DSP preset value.
-- @tparam any value Input preset value.
-- @treturn number|nil Normalized DSP preset in `0..255` or nil.
local function NormalizeDSPPreset(value)
    local preset = tonumber(value)
    if ( !isnumber(preset) ) then
        return nil
    end

    return math.Clamp(math.floor(preset), 0, MAX_DSP_PRESET)
end

--- Parse a DSP preset from mixer profile metadata.
-- Accepts values like `dsp:7` or `dsp=19`.
-- @tparam any profileName Mixer profile metadata.
-- @treturn number|nil Parsed DSP preset.
local function ParseDSPPresetFromMixerProfile(profileName)
    if ( !isstring(profileName) ) then
        return nil
    end

    local normalized = string.lower(string.Trim(profileName))
    local preset = string.match(normalized, "^dsp%s*[:=]%s*(%-?%d+)$")
    if ( !isstring(preset) ) then
        return nil
    end

    return NormalizeDSPPreset(tonumber(preset))
end

--- Clamp and normalize a numeric value.
-- @tparam any value Input value.
-- @tparam number minimum Minimum allowed value.
-- @tparam number maximum Maximum allowed value.
-- @tparam number fallback Fallback value.
-- @treturn number Clamped number.
local function ClampNumber(value, minimum, maximum, fallback)
    local num = tonumber(value)
    if ( !isnumber(num) ) then
        num = fallback
    end

    return math.Clamp(num, minimum, maximum)
end

--- Parse a boolean-like input value.
-- @tparam any value Input value.
-- @treturn boolean|nil Parsed boolean or nil when not parseable.
local function ParseBoolish(value)
    if ( isbool(value) ) then
        return value
    end

    if ( isnumber(value) ) then
        return value != 0
    end

    if ( isstring(value) ) then
        local normalized = string.lower(string.Trim(value))
        if ( normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "on" ) then
            return true
        end

        if ( normalized == "0" or normalized == "false" or normalized == "no" or normalized == "off" ) then
            return false
        end
    end

    return nil
end

--- Normalize a numeric range represented as number or table.
-- @tparam number|table value Number or {min, max} table.
-- @tparam number fallbackMin Fallback minimum.
-- @tparam number fallbackMax Fallback maximum.
-- @tparam number minimum Global minimum.
-- @tparam number maximum Global maximum.
-- @treturn number rangeMin
-- @treturn number rangeMax
local function NormalizeRange(value, fallbackMin, fallbackMax, minimum, maximum)
    local rangeMin = fallbackMin
    local rangeMax = fallbackMax

    if ( isnumber(value) ) then
        rangeMin = value
        rangeMax = value
    elseif ( istable(value) ) then
        rangeMin = tonumber(value[1] or value.min or fallbackMin) or fallbackMin
        rangeMax = tonumber(value[2] or value.max or fallbackMax) or fallbackMax
    end

    rangeMin = math.Clamp(rangeMin, minimum, maximum)
    rangeMax = math.Clamp(rangeMax, minimum, maximum)

    if ( rangeMin > rangeMax ) then
        rangeMin, rangeMax = rangeMax, rangeMin
    end

    return rangeMin, rangeMax
end

--- Normalize a sound list to an array of valid paths.
-- @tparam any sounds Input sounds payload.
-- @treturn table Normalized string array.
local function NormalizeSounds(sounds)
    local output = {}

    if ( isstring(sounds) and sounds != "" ) then
        output[1] = sounds
        return output
    end

    if ( !istable(sounds) ) then
        return output
    end

    for i = 1, #sounds do
        local path = tostring(sounds[i] or "")
        if ( path != "" ) then
            output[#output + 1] = path
        end
    end

    return output
end

--- Normalize tag input to a string array.
-- @tparam any tags Input tags.
-- @treturn table Normalized tags.
local function NormalizeTags(tags)
    local output = {}

    if ( isstring(tags) and tags != "" ) then
        output[1] = tags
        return output
    end

    if ( !istable(tags) ) then
        return output
    end

    for i = 1, #tags do
        local tag = tostring(tags[i] or "")
        if ( tag != "" ) then
            output[#output + 1] = tag
        end
    end

    return output
end

--- Normalize layer spatial settings.
-- @tparam table spatial Spatial input table.
-- @treturn table Normalized spatial table.
local function NormalizeSpatial(spatial)
    spatial = istable(spatial) and spatial or {}

    local mode = tostring(spatial.mode or "ambient")
    if ( mode != "ambient" and mode != "positional" and mode != "relative" and mode != "entity" ) then
        mode = "ambient"
    end

    local positionKey = tonumber(spatial.positionKey or spatial.key)
    if ( isnumber(positionKey) ) then
        positionKey = math.floor(positionKey)
        positionKey = math.Clamp(positionKey, 0, MAX_POSITION_KEYS)
    else
        positionKey = nil
    end

    local radiusMin, radiusMax = NormalizeRange(spatial.radius, 64, 256, 0, 32768)

    return {
        mode = mode,
        positionKey = positionKey,
        attenuation = ClampNumber(spatial.attenuation, 0.1, 4, 1),
        soundLevel = ClampNumber(spatial.soundLevel, 0, 140, 75),
        radiusMin = radiusMin,
        radiusMax = radiusMax,
        hemisphere = spatial.hemisphere == true,
    }
end

--- Normalize loop drift settings.
-- @tparam table drift Drift settings.
-- @treturn table Normalized drift.
local function NormalizeDrift(drift)
    drift = istable(drift) and drift or {}

    local volumeDriftMin, volumeDriftMax = NormalizeRange(drift.volume, 0, 0, 0, 1)
    local pitchDriftMin, pitchDriftMax = NormalizeRange(drift.pitch, 0, 0, 0, 100)
    local periodMin, periodMax = NormalizeRange(drift.period, 6, 16, 0.1, 120)

    return {
        volumeMin = volumeDriftMin,
        volumeMax = volumeDriftMax,
        pitchMin = pitchDriftMin,
        pitchMax = pitchDriftMax,
        periodMin = periodMin,
        periodMax = periodMax,
    }
end

--- Normalize a shared layer payload.
-- @tparam string layerType Layer type identifier.
-- @tparam string name Layer name.
-- @tparam table params Layer parameters.
-- @treturn table Normalized layer table.
local function NormalizeLayer(layerType, name, params)
    params = istable(params) and params or {}

    local volumeMin, volumeMax = NormalizeRange(params.volume, 0.5, 0.5, 0, 1)
    local pitchMin, pitchMax = NormalizeRange(params.pitch, 100, 100, 20, 255)

    return {
        layerType = layerType,
        name = tostring(name or ""),
        sounds = NormalizeSounds(params.sounds),
        volumeMin = volumeMin,
        volumeMax = volumeMax,
        pitchMin = pitchMin,
        pitchMax = pitchMax,
        preload = params.preload == true,
        tags = NormalizeTags(params.tags),
        spatial = NormalizeSpatial(params.spatial),
        persist = params.persist == true,
    }
end

--- Normalize random layer specific options.
-- @tparam table layer Normalized base layer.
-- @tparam table params Raw params.
local function NormalizeRandomLayer(layer, params)
    local intervalMin, intervalMax = NormalizeRange(params.interval, 6, 14, 0.1, 3600)
    local burstCountMin, burstCountMax = NormalizeRange(params.burst and params.burst.count, 2, 2, 1, 16)
    local burstSpacingMin, burstSpacingMax = NormalizeRange(params.burst and params.burst.spacing, 0.15, 0.45, 0.01, 30)

    layer.intervalMin = intervalMin
    layer.intervalMax = intervalMax
    layer.limit = {
        instance = math.max(1, math.floor(tonumber(params.limit and params.limit.instance) or 1)),
        blockDistance = math.max(0, tonumber(params.limit and params.limit.blockDistance) or 0),
    }
    layer.burst = {
        chance = math.Clamp(tonumber(params.burst and params.burst.chance) or 0, 0, 1),
        countMin = burstCountMin,
        countMax = burstCountMax,
        spacingMin = burstSpacingMin,
        spacingMax = burstSpacingMax,
    }
end

--- Normalize sub-scape params.
-- @tparam table params Raw params.
-- @treturn table Normalized params.
local function NormalizeSubScapeParams(params)
    params = istable(params) and params or {}

    local mapOut = {}
    local mapIn = params.positionKeyMap
    if ( istable(mapIn) ) then
        for key, value in pairs(mapIn) do
            local fromKey = tonumber(key)
            local toKey = tonumber(value)
            if ( isnumber(fromKey) and isnumber(toKey) ) then
                fromKey = math.Clamp(math.floor(fromKey), 0, MAX_POSITION_KEYS)
                toKey = math.Clamp(math.floor(toKey), 0, MAX_POSITION_KEYS)
                mapOut[fromKey] = toKey
            end
        end
    end

    local forcePositionKey = tonumber(params.forcePositionKey)
    if ( isnumber(forcePositionKey) ) then
        forcePositionKey = math.Clamp(math.floor(forcePositionKey), 0, MAX_POSITION_KEYS)
    else
        forcePositionKey = nil
    end

    return {
        volumeMultiplier = ClampNumber(params.volumeMultiplier or params.volume, 0, 4, 1),
        positionKeyMap = mapOut,
        forcePositionKey = forcePositionKey,
    }
end

--- Register a unique sound path in a sound key map.
-- @tparam table keyMap Path -> key table.
-- @tparam table reverseMap Key -> path table.
-- @tparam string path Sound path.
local function RegisterSoundPath(keyMap, reverseMap, path)
    if ( !isstring(path) or path == "" ) then return end

    local existing = keyMap[path]
    if ( existing ) then return end

    local key = #reverseMap + 1
    keyMap[path] = key
    reverseMap[key] = path
end

--- Build deterministic sound key tables for a resolved scape.
-- @tparam table resolved Resolved scape table.
local function BuildSoundKeys(resolved)
    local keyMap = {}
    local reverseMap = {}

    for i = 1, #resolved.loops do
        local layer = resolved.loops[i]
        for j = 1, #layer.sounds do
            RegisterSoundPath(keyMap, reverseMap, layer.sounds[j])
        end
    end

    for i = 1, #resolved.randoms do
        local layer = resolved.randoms[i]
        for j = 1, #layer.sounds do
            RegisterSoundPath(keyMap, reverseMap, layer.sounds[j])
        end
    end

    for i = 1, #resolved.stingers do
        local layer = resolved.stingers[i]
        for j = 1, #layer.sounds do
            RegisterSoundPath(keyMap, reverseMap, layer.sounds[j])
        end
    end

    resolved.pathToSoundKey = keyMap
    resolved.soundKeyToPath = reverseMap
end

--- Clone and scale a layer for resolved output.
-- @tparam table layer Source layer.
-- @tparam number volumeMultiplier Effective volume multiplier.
-- @tparam table subParams Sub-scape transform params.
-- @treturn table Cloned layer.
local function CloneLayer(layer, volumeMultiplier, subParams)
    local clone = table.Copy(layer)

    clone.volumeMin = math.Clamp(clone.volumeMin * volumeMultiplier, 0, 1)
    clone.volumeMax = math.Clamp(clone.volumeMax * volumeMultiplier, 0, 1)

    if ( isnumber(subParams.forcePositionKey) ) then
        clone.spatial.positionKey = subParams.forcePositionKey
    elseif ( isnumber(clone.spatial.positionKey) and subParams.positionKeyMap[clone.spatial.positionKey] != nil ) then
        clone.spatial.positionKey = subParams.positionKeyMap[clone.spatial.positionKey]
    end

    return clone
end

--- Create a new builder instance.
-- @tparam string id Scape identifier.
-- @treturn table Builder object.
function ax.scapes:CreateBuilder(id)
    local builder = setmetatable({}, BUILDER)
    local fadeInDefault = self:GetDefaultFadeIn()
    local fadeOutDefault = self:GetDefaultFadeOut()

    builder.definition = {
        id = id,
        fadetime_in = fadeInDefault,
        fadetime_out = fadeOutDefault,
        priority = 0,
        mixTag = nil,
        mixerProfile = nil,
        dspPreset = nil,
        dspFastReset = nil,
        pauseLegacyAmbient = nil,
        loops = {},
        randoms = {},
        stingers = {},
        subScapes = {},
    }

    return builder
end

--- Set scape fade in and out values.
-- @tparam number fadeIn Fade in seconds.
-- @tparam number fadeOut Fade out seconds.
function BUILDER:SetFade(fadeIn, fadeOut)
    self.definition.fadetime_in = ClampNumber(fadeIn, 0, 60, self.definition.fadetime_in)
    self.definition.fadetime_out = ClampNumber(fadeOut, 0, 60, self.definition.fadetime_out)

    return self
end

--- Set scape activation priority.
-- Higher priority scapes can replace lower priority active sessions.
-- @tparam number priority Priority value.
function BUILDER:SetPriority(priority)
    self.definition.priority = math.floor(ClampNumber(priority, -1024, 1024, self.definition.priority))

    return self
end

--- Set default mix tag for this scape.
-- @tparam string tag Mix tag.
function BUILDER:SetMixTag(tag)
    tag = tostring(tag or "")
    if ( tag != "" ) then
        self.definition.mixTag = tag
    end

    return self
end

--- Set mixer profile metadata.
-- @tparam string profileName Mixer profile name.
function BUILDER:SetMixerProfile(profileName)
    profileName = tostring(profileName or "")
    if ( profileName != "" ) then
        self.definition.mixerProfile = profileName

        local dspPreset = ParseDSPPresetFromMixerProfile(profileName)
        if ( isnumber(dspPreset) ) then
            self.definition.dspPreset = dspPreset
        end
    end

    return self
end

--- Set DSP preset metadata for this scape.
-- @tparam number|nil dspPreset DSP preset id (`0..255`) or nil to clear.
-- @tparam[opt] boolean fastReset Optional fast-reset flag for SetDSP.
function BUILDER:SetDSPPreset(dspPreset, fastReset)
    local normalized = NormalizeDSPPreset(dspPreset)
    self.definition.dspPreset = normalized

    if ( fastReset != nil ) then
        self.definition.dspFastReset = fastReset == true
    elseif ( normalized == nil ) then
        self.definition.dspFastReset = nil
    end

    return self
end

--- Alias for `SetDSPPreset`.
-- @tparam number|nil dspPreset DSP preset id (`0..255`) or nil to clear.
-- @tparam[opt] boolean fastReset Optional fast-reset flag for SetDSP.
function BUILDER:SetDSP(dspPreset, fastReset)
    return self:SetDSPPreset(dspPreset, fastReset)
end

--- Set whether this scape pauses legacy ambient music.
-- @tparam boolean enabled Whether legacy ambient should pause.
function BUILDER:SetPauseLegacyAmbient(enabled)
    if ( enabled == nil ) then
        self.definition.pauseLegacyAmbient = nil
    else
        self.definition.pauseLegacyAmbient = enabled == true
    end

    return self
end

--- Add a loop layer.
-- @tparam string name Layer name.
-- @tparam table params Layer params.
function BUILDER:AddLoop(name, params)
    local layer = NormalizeLayer("loop", name, params)
    layer.drift = NormalizeDrift(params and params.drift)

    self.definition.loops[#self.definition.loops + 1] = layer

    return self
end

--- Add a random layer.
-- @tparam string name Layer name.
-- @tparam table params Layer params.
function BUILDER:AddRandom(name, params)
    local layer = NormalizeLayer("random", name, params)
    NormalizeRandomLayer(layer, params and params or {})

    self.definition.randoms[#self.definition.randoms + 1] = layer

    return self
end

--- Add a stinger layer.
-- @tparam string name Trigger name.
-- @tparam table params Layer params.
function BUILDER:AddStinger(name, params)
    local layer = NormalizeLayer("stinger", name, params)

    self.definition.stingers[#self.definition.stingers + 1] = layer

    return self
end

--- Add a sub-scape include.
-- @tparam string scapeId Included scape id.
-- @tparam table params Include params.
function BUILDER:AddSubScape(scapeId, params)
    scapeId = tostring(scapeId or "")
    if ( scapeId == "" ) then return self end

    self.definition.subScapes[#self.definition.subScapes + 1] = {
        scapeId = scapeId,
        params = NormalizeSubScapeParams(params),
    }

    return self
end

--- Register a scape definition function.
-- @tparam string id Unique scape id.
-- @tparam function defFn Definition callback.
-- @treturn boolean success
-- @treturn string? err
function ax.scapes:Register(id, defFn)
    id = tostring(id or "")
    if ( id == "" ) then
        return false, "invalid_id"
    end

    if ( !isfunction(defFn) ) then
        return false, "invalid_defFn"
    end

    local builder = self:CreateBuilder(id)

    local ok, err = pcall(defFn, builder)
    if ( !ok ) then
        return false, tostring(err)
    end

    self.stored[id] = builder.definition

    return true
end

--- Get a registered scape definition.
-- @tparam string id Scape id.
-- @treturn table|nil Definition table.
function ax.scapes:Get(id)
    id = tostring(id or "")
    if ( id == "" ) then return nil end

    return self.stored[id]
end

--- Check if a scape id is valid.
-- @tparam string id Scape id.
-- @treturn boolean valid
function ax.scapes:IsValid(id)
    return istable(self:Get(id))
end

--- Serialize a vector for network payloads.
-- @tparam Vector vec Vector to serialize.
-- @treturn table Serializable table.
function ax.scapes:SerializeVector(vec)
    if ( !isvector(vec) ) then
        return {x = 0, y = 0, z = 0}
    end

    return {
        x = vec.x,
        y = vec.y,
        z = vec.z,
    }
end

--- Deserialize a vector payload table.
-- @tparam table data Serialized vector table.
-- @treturn Vector Vector result.
function ax.scapes:DeserializeVector(data)
    if ( !istable(data) ) then
        return vector_origin
    end

    return Vector(
        tonumber(data.x) or 0,
        tonumber(data.y) or 0,
        tonumber(data.z) or 0
    )
end

--- Normalize activation context.
-- @tparam table ctx Raw context.
-- @treturn table Normalized context.
function ax.scapes:NormalizeContext(ctx)
    ctx = istable(ctx) and table.Copy(ctx) or {}

    local positions = {}
    if ( istable(ctx.positions) ) then
        for key, value in pairs(ctx.positions) do
            local positionKey = tonumber(key)
            if ( !isnumber(positionKey) ) then continue end

            positionKey = math.Clamp(math.floor(positionKey), 0, MAX_POSITION_KEYS)

            if ( isvector(value) ) then
                positions[positionKey] = value
            elseif ( istable(value) ) then
                positions[positionKey] = self:DeserializeVector(value)
            end
        end
    end

    local entities = {}
    if ( istable(ctx.entities) ) then
        for key, value in pairs(ctx.entities) do
            local positionKey = tonumber(key)
            if ( !isnumber(positionKey) ) then continue end

            positionKey = math.Clamp(math.floor(positionKey), 0, MAX_POSITION_KEYS)

            if ( isentity(value) and IsValid(value) ) then
                entities[positionKey] = value:EntIndex()
            elseif ( isnumber(value) ) then
                entities[positionKey] = math.floor(value)
            end
        end
    end

    ctx.positions = positions
    ctx.entities = entities
    ctx.seed = tostring(ctx.seed or "")
    ctx.startAt = tonumber(ctx.startAt) or nil
    ctx.priority = tonumber(ctx.priority) and math.floor(tonumber(ctx.priority)) or nil
    ctx.dspPreset = NormalizeDSPPreset(ctx.dspPreset or ctx.dsp or ctx.roomType or ctx.room_type)

    local dspFastResetRaw = ctx.dspFastReset
    if ( dspFastResetRaw == nil ) then
        dspFastResetRaw = ctx.dsp_fast_reset
    end

    ctx.dspFastReset = ParseBoolish(dspFastResetRaw)

    ctx.force = ctx.force == true

    return ctx
end

--- Serialize activation context for networking.
-- @tparam table ctx Normalized context.
-- @treturn table Serializable context.
function ax.scapes:SerializeContext(ctx)
    ctx = self:NormalizeContext(ctx)

    local payload = {
        positions = {},
        entities = {},
    }

    for key, vec in pairs(ctx.positions) do
        payload.positions[key] = self:SerializeVector(vec)
    end

    for key, entIndex in pairs(ctx.entities) do
        payload.entities[key] = entIndex
    end

    if ( ctx.seed != "" ) then
        payload.seed = ctx.seed
    end

    if ( isnumber(ctx.startAt) ) then
        payload.startAt = ctx.startAt
    end

    if ( isnumber(ctx.priority) ) then
        payload.priority = ctx.priority
    end

    if ( isnumber(ctx.dspPreset) ) then
        payload.dspPreset = ctx.dspPreset
    end

    if ( isbool(ctx.dspFastReset) ) then
        payload.dspFastReset = ctx.dspFastReset
    end

    if ( ctx.force == true ) then
        payload.force = true
    end

    return payload
end

--- Deserialize activation context received on client.
-- @tparam table payload Serialized context payload.
-- @treturn table Normalized context.
function ax.scapes:DeserializeContext(payload)
    payload = istable(payload) and payload or {}

    local ctx = {
        positions = {},
        entities = {},
        seed = tostring(payload.seed or ""),
        startAt = tonumber(payload.startAt) or nil,
        priority = tonumber(payload.priority) and math.floor(tonumber(payload.priority)) or nil,
        dspPreset = NormalizeDSPPreset(payload.dspPreset),
        dspFastReset = ParseBoolish(payload.dspFastReset),
        force = payload.force == true,
    }

    if ( istable(payload.positions) ) then
        for key, vecData in pairs(payload.positions) do
            local positionKey = tonumber(key)
            if ( !isnumber(positionKey) ) then continue end

            positionKey = math.Clamp(math.floor(positionKey), 0, MAX_POSITION_KEYS)
            ctx.positions[positionKey] = self:DeserializeVector(vecData)
        end
    end

    if ( istable(payload.entities) ) then
        for key, entIndex in pairs(payload.entities) do
            local positionKey = tonumber(key)
            if ( !isnumber(positionKey) ) then continue end

            positionKey = math.Clamp(math.floor(positionKey), 0, MAX_POSITION_KEYS)
            ctx.entities[positionKey] = math.floor(tonumber(entIndex) or -1)
        end
    end

    return ctx
end

--- Resolve a scape including nested sub-scapes.
-- @tparam string scapeId Root scape id.
-- @tparam table ctx Activation context.
-- @treturn table|nil Resolved scape.
-- @treturn string? err
function ax.scapes:ResolveScape(scapeId, ctx)
    local root = self:Get(scapeId)
    if ( !istable(root) ) then
        return nil, "invalid_scape"
    end

    local dspPreset = NormalizeDSPPreset(root.dspPreset)
    if ( !isnumber(dspPreset) ) then
        dspPreset = ParseDSPPresetFromMixerProfile(root.mixerProfile)
    end

    local resolved = {
        id = scapeId,
        fadetime_in = root.fadetime_in,
        fadetime_out = root.fadetime_out,
        priority = tonumber(root.priority) and math.floor(tonumber(root.priority)) or 0,
        mixTag = root.mixTag,
        mixerProfile = root.mixerProfile,
        dspPreset = dspPreset,
        dspFastReset = ParseBoolish(root.dspFastReset),
        pauseLegacyAmbient = root.pauseLegacyAmbient,
        loops = {},
        randoms = {},
        stingers = {},
        stingersByName = {},
    }

    local stack = {}

    --- Internal recursive append helper.
    -- @tparam string currentId Current scape id.
    -- @tparam number volumeMultiplier Effective volume multiplier.
    -- @tparam table subParams Sub-scape transform params.
    local function Append(currentId, volumeMultiplier, subParams)
        if ( stack[currentId] ) then
            return
        end

        local current = self:Get(currentId)
        if ( !istable(current) ) then
            return
        end

        stack[currentId] = true

        for i = 1, #current.loops do
            local layer = CloneLayer(current.loops[i], volumeMultiplier, subParams)
            layer.id = currentId .. "." .. layer.name

            if ( current.mixTag and layer.tags[1] == nil ) then
                layer.tags[1] = current.mixTag
            end

            resolved.loops[#resolved.loops + 1] = layer
        end

        for i = 1, #current.randoms do
            local layer = CloneLayer(current.randoms[i], volumeMultiplier, subParams)
            layer.id = currentId .. "." .. layer.name

            if ( current.mixTag and layer.tags[1] == nil ) then
                layer.tags[1] = current.mixTag
            end

            resolved.randoms[#resolved.randoms + 1] = layer
        end

        for i = 1, #current.stingers do
            local layer = CloneLayer(current.stingers[i], volumeMultiplier, subParams)
            layer.id = currentId .. "." .. layer.name

            if ( current.mixTag and layer.tags[1] == nil ) then
                layer.tags[1] = current.mixTag
            end

            resolved.stingers[#resolved.stingers + 1] = layer
            resolved.stingersByName[layer.name] = resolved.stingersByName[layer.name] or {}
            table.insert(resolved.stingersByName[layer.name], layer)
        end

        for i = 1, #current.subScapes do
            local include = current.subScapes[i]
            local includeParams = NormalizeSubScapeParams(include.params)

            local mergedParams = {
                volumeMultiplier = includeParams.volumeMultiplier,
                positionKeyMap = table.Copy(includeParams.positionKeyMap),
                forcePositionKey = includeParams.forcePositionKey,
            }

            Append(include.scapeId, volumeMultiplier * includeParams.volumeMultiplier, mergedParams)
        end

        stack[currentId] = nil
    end

    Append(scapeId, 1, {
        volumeMultiplier = 1,
        positionKeyMap = {},
        forcePositionKey = nil,
    })

    BuildSoundKeys(resolved)

    return resolved
end

--- Get default fade-in duration for newly registered scapes.
-- @treturn number Default fade-in seconds.
function ax.scapes:GetDefaultFadeIn()
    return math.max(0, tonumber(ax.config:Get("audio.scapes.default_fade_in", 1)) or 1)
end

--- Get default fade-out duration for newly registered scapes.
-- @treturn number Default fade-out seconds.
function ax.scapes:GetDefaultFadeOut()
    return math.max(0, tonumber(ax.config:Get("audio.scapes.default_fade_out", 1)) or 1)
end

--- Get default schedule window.
-- @treturn number Window size in seconds.
function ax.scapes:GetScheduleWindow()
    return math.max(4, tonumber(ax.config:Get("audio.scapes.schedule_window", 20)) or 20)
end

--- Get default schedule refill interval.
-- @treturn number Refill interval in seconds.
function ax.scapes:GetScheduleRefillInterval()
    return math.max(0.1, tonumber(ax.config:Get("audio.scapes.schedule_refill_interval", 4)) or 4)
end

--- Get default schedule refill threshold.
-- @treturn number Threshold in seconds.
function ax.scapes:GetScheduleRefillThreshold()
    return math.max(1, tonumber(ax.config:Get("audio.scapes.schedule_refill_threshold", 8)) or 8)
end

--- Get default event batch size.
-- @treturn number Batch count.
function ax.scapes:GetBatchSize()
    return math.max(8, math.floor(tonumber(ax.config:Get("audio.scapes.batch_events", 48)) or 48))
end

--- Get default network lead time.
-- @treturn number Lead time in seconds.
function ax.scapes:GetNetLeadTime()
    return math.max(0.05, tonumber(ax.config:Get("audio.scapes.net_lead_time", 0.25)) or 0.25)
end

--- Get whether map-based NikNaks auto triggering is enabled.
-- @treturn boolean True when enabled.
function ax.scapes:GetAutoTriggerEnabled()
    return ax.config:Get("audio.scapes.auto_trigger_from_map", true) == true
end

--- Get map auto-trigger scan interval.
-- @treturn number Interval in seconds.
function ax.scapes:GetAutoTriggerInterval()
    return math.max(0.1, tonumber(ax.config:Get("audio.scapes.auto_trigger_interval", 0.75)) or 0.75)
end

--- Get map auto-trigger hysteresis.
-- @treturn number Normalized hysteresis value.
function ax.scapes:GetAutoTriggerHysteresis()
    return math.Clamp(tonumber(ax.config:Get("audio.scapes.auto_trigger_hysteresis", 0.08)) or 0.08, 0, 1)
end

--- Get whether auto-trigger should keep last scape as fallback.
-- @treturn boolean True when fallback remains active outside all radii.
function ax.scapes:GetAutoTriggerStickyFallback()
    return ax.config:Get("audio.scapes.auto_trigger_sticky_fallback", true) == true
end

--- Get map auto-trigger exit delay.
-- @treturn number Delay in seconds.
function ax.scapes:GetAutoTriggerExitDelay()
    return math.max(0, tonumber(ax.config:Get("audio.scapes.auto_trigger_exit_delay", 1)) or 1)
end

--- Get whether map auto-trigger diagnostics are enabled.
-- @treturn boolean True when debug logging is enabled.
function ax.scapes:GetAutoTriggerDebugEnabled()
    return ax.config:Get("audio.scapes.auto_trigger_debug", false) == true
end

--- Get whether Scapes debug logging is enabled.
-- @treturn boolean True when verbose debug logging is enabled.
function ax.scapes:GetDebugLoggingEnabled()
    return ax.config:Get("audio.scapes.debug_logging", false) == true or self:GetAutoTriggerDebugEnabled() == true
end

--- Get whether Scapes debug overlays are enabled.
-- @treturn boolean True when debugoverlay diagnostics are enabled.
function ax.scapes:GetDebugOverlayEnabled()
    return ax.config:Get("audio.scapes.debug_overlay", false) == true
end

--- Get server debug overlay duration.
-- @treturn number Overlay lifetime in seconds.
function ax.scapes:GetDebugOverlayDuration()
    return math.Clamp(tonumber(ax.config:Get("audio.scapes.debug_overlay_duration", 0.2)) or 0.2, 0.01, 5)
end

--- Get whether DSP integration is enabled for Scapes.
-- @treturn boolean True when server-side DSP should be applied.
function ax.scapes:GetDSPEnabled()
    return ax.config:Get("audio.scapes.dsp_enabled", true) == true
end

--- Get whether positional Scapes occlusion is enabled.
-- @treturn boolean True when occlusion should be evaluated.
function ax.scapes:GetOcclusionEnabled()
    return ax.config:Get("audio.scapes.occlusion_enabled", true) == true
end

--- Get approximate thickness needed to reach maximum occlusion loss.
-- @treturn number Thickness in Hammer units.
function ax.scapes:GetOcclusionThicknessScale()
    return math.max(16, tonumber(ax.config:Get("audio.scapes.occlusion_thickness_scale", 96)) or 96)
end

--- Get maximum volume loss caused by positional occlusion.
-- @treturn number Volume loss clamped to 0..1.
function ax.scapes:GetOcclusionMaxVolumeLoss()
    return math.Clamp(tonumber(ax.config:Get("audio.scapes.occlusion_max_volume_loss", 0.92)) or 0.92, 0, 1)
end

--- Get default DSP preset used when restoring from Scapes sessions.
-- @treturn number Default DSP preset.
function ax.scapes:GetDefaultDSPPreset()
    return NormalizeDSPPreset(ax.config:Get("audio.scapes.dsp_default", 1)) or 1
end

--- Get default fast-reset flag used when restoring DSP.
-- @treturn boolean True when DSP reset should use fast mode.
function ax.scapes:GetDefaultDSPFastReset()
    return ax.config:Get("audio.scapes.dsp_default_fast_reset", false) == true
end

--- Print a regular Scapes log line.
-- @tparam any ... Message arguments.
function ax.scapes:Log(...)
    ax.util:Print(unpack(BuildPrefixedLogArgs(...)))
end

--- Print a warning Scapes log line.
-- @tparam any ... Message arguments.
function ax.scapes:LogWarning(...)
    ax.util:PrintWarning(unpack(BuildPrefixedLogArgs(...)))
end

--- Print a debug Scapes log line when debug logging is enabled.
-- @tparam any ... Message arguments.
function ax.scapes:LogDebug(...)
    if ( self:GetDebugLoggingEnabled() != true ) then return end

    ax.util:PrintDebug(unpack(BuildPrefixedLogArgs(...)))
end

--- Draw a debug sphere when Scapes debug overlays are enabled.
-- @tparam Vector position Sphere center.
-- @tparam number radius Sphere radius.
-- @tparam[opt] Color color Overlay color.
-- @tparam[opt] number duration Lifetime in seconds.
-- @tparam[opt] boolean ignoreZ True to ignore depth test.
function ax.scapes:DebugDrawSphere(position, radius, color, duration, ignoreZ)
    if ( self:GetDebugOverlayEnabled() != true ) then return end
    if ( !isvector(position) ) then return end

    debugoverlay.Sphere(
        position,
        math.max(1, tonumber(radius) or 16),
        tonumber(duration) or self:GetDebugOverlayDuration(),
        color or Color(80, 190, 255, 40),
        ignoreZ == true
    )
end

--- Draw a debug line when Scapes debug overlays are enabled.
-- @tparam Vector startPosition Line start.
-- @tparam Vector endPosition Line end.
-- @tparam[opt] Color color Overlay color.
-- @tparam[opt] number duration Lifetime in seconds.
-- @tparam[opt] boolean ignoreZ True to ignore depth test.
function ax.scapes:DebugDrawLine(startPosition, endPosition, color, duration, ignoreZ)
    if ( self:GetDebugOverlayEnabled() != true ) then return end
    if ( !isvector(startPosition) or !isvector(endPosition) ) then return end

    debugoverlay.Line(
        startPosition,
        endPosition,
        tonumber(duration) or self:GetDebugOverlayDuration(),
        color or Color(80, 190, 255, 40),
        ignoreZ == true
    )
end

--- Draw debug text when Scapes debug overlays are enabled.
-- @tparam Vector position Text anchor.
-- @tparam string text Overlay text.
-- @tparam[opt] number duration Lifetime in seconds.
-- @tparam[opt] boolean ignoreZ True to ignore depth test.
function ax.scapes:DebugDrawText(position, text, duration, ignoreZ)
    if ( self:GetDebugOverlayEnabled() != true ) then return end
    if ( !isvector(position) ) then return end

    debugoverlay.Text(
        position,
        tostring(text or ""),
        tonumber(duration) or self:GetDebugOverlayDuration(),
        ignoreZ == true
    )
end

--- Get whether activation priority checks are enabled.
-- @treturn boolean True when scape priority should gate replacement.
function ax.scapes:GetUsePriority()
    return ax.config:Get("audio.scapes.use_priority", false) == true
end

--- Activate a scape for a player (server only).
-- @tparam Player client Target player.
-- @tparam string scapeId Scape id.
-- @tparam table ctx Activation context.
-- @treturn boolean success
-- @treturn string? err
function ax.scapes:Activate(client, scapeId, ctx)
    if ( !SERVER ) then
        return false, "server_only"
    end

    if ( !isfunction(self.ServerActivate) ) then
        return false, "missing_server_implementation"
    end

    return self:ServerActivate(client, scapeId, ctx)
end

--- Activate a scape for multiple players (server only).
-- @tparam function|table filterFnOrPlayers Player filter function or player array.
-- @tparam string scapeId Scape id.
-- @tparam table ctx Activation context.
-- @treturn number activatedCount
function ax.scapes:ActivateArea(filterFnOrPlayers, scapeId, ctx)
    if ( !SERVER ) then
        return 0
    end

    if ( !isfunction(self.ServerActivateArea) ) then
        return 0
    end

    return self:ServerActivateArea(filterFnOrPlayers, scapeId, ctx)
end

--- Deactivate a player's active scape (server only).
-- @tparam Player client Target player.
-- @tparam table opts Deactivation options.
-- @treturn boolean success
function ax.scapes:Deactivate(client, opts)
    if ( !SERVER ) then
        return false
    end

    if ( !isfunction(self.ServerDeactivate) ) then
        return false
    end

    return self:ServerDeactivate(client, opts)
end

--- Trigger a stinger for a player's active scape (server only).
-- @tparam Player client Target player.
-- @tparam string triggerName Trigger id.
-- @tparam table payload Trigger payload.
-- @treturn boolean success
-- @treturn string? err
function ax.scapes:Trigger(client, triggerName, payload)
    if ( !SERVER ) then
        return false, "server_only"
    end

    if ( !isfunction(self.ServerTrigger) ) then
        return false, "missing_server_implementation"
    end

    return self:ServerTrigger(client, triggerName, payload)
end

--- Optional helper for zone-based activation.
-- @tparam Player client Target player.
-- @tparam string|number zoneId Zone identifier.
-- @treturn boolean success
-- @treturn string? err
function ax.scapes:ActivateByZone(client, zoneId)
    if ( !SERVER ) then
        return false, "server_only"
    end

    local zone = ax.zones and ax.zones.Get and ax.zones:Get(zoneId) or nil
    if ( !istable(zone) ) then
        return false, "zone_not_found"
    end

    local scapeId = zone.data and (zone.data.scapeId or zone.data.scape)
    scapeId = tostring(scapeId or "")
    if ( scapeId == "" ) then
        return false, "zone_missing_scape"
    end

    return self:Activate(client, scapeId, {
        positions = zone.data and zone.data.positions or nil,
        entities = zone.data and zone.data.entities or nil,
    })
end

--- Set a global client mix multiplier for a tag.
-- @tparam string tag Mix tag.
-- @tparam number volume Volume multiplier.
function ax.scapes:SetGlobalMix(tag, volume)
    if ( !CLIENT ) then return end
    if ( !isfunction(self.ClientSetGlobalMix) ) then return end

    self:ClientSetGlobalMix(tag, volume)
end
