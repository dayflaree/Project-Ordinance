--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( CLIENT ) then return end

--- NikNaks-based env_soundscape parser and per-player auto-trigger runtime.
-- @module ax.scapes

ax.scapes = ax.scapes or {}
ax.scapes.autoSoundscapes = ax.scapes.autoSoundscapes or {}
ax.scapes.autoSoundscapesByIndex = ax.scapes.autoSoundscapesByIndex or {}
ax.scapes.autoPlayerState = ax.scapes.autoPlayerState or {}
ax.scapes.nextAutoTriggerThink = ax.scapes.nextAutoTriggerThink or 0

local DEFAULT_ENV_SOUNDSCAPE_RADIUS = 1024
local MIN_ENV_SOUNDSCAPE_RADIUS = 64
local MAX_ENV_SOUNDSCAPE_RADIUS = 16384
local MAX_POSITION_KEY = 7

--- Resolve first non-nil field value from an entity payload.
-- @tparam table entity NikNaks entity data.
-- @tparam string ... Candidate field names.
-- @treturn any Field value or nil.
local function GetEntityField(entity, ...)
    for i = 1, select("#", ...) do
        local key = select(i, ...)
        local value = entity[key]
        if ( value != nil ) then
            return value
        end
    end

    return nil
end

--- Parse boolean-like map keyvalue to boolean.
-- @tparam any value Raw keyvalue.
-- @treturn boolean Parsed boolean.
local function ParseBool(value)
    if ( isbool(value) ) then
        return value
    end

    if ( isnumber(value) ) then
        return value != 0
    end

    if ( isstring(value) ) then
        local normalized = string.lower(string.Trim(value))
        if ( normalized == "1" or normalized == "true" or normalized == "yes" ) then
            return true
        end
    end

    return false
end

--- Parse origin-like values to a Vector.
-- @tparam any value Raw value from NikNaks entity data.
-- @treturn Vector|nil Parsed position vector.
local function ParseVector(value)
    if ( isvector(value) ) then
        return value
    end

    if ( istable(value) and isnumber(value.x) and isnumber(value.y) and isnumber(value.z) ) then
        return Vector(value.x, value.y, value.z)
    end

    if ( !isstring(value) ) then
        return nil
    end

    local x, y, z = string.match(value, "([%-%d%.]+)%s+([%-%d%.]+)%s+([%-%d%.]+)")
    if ( !x or !y or !z ) then
        return nil
    end

    return Vector(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0)
end

--- Normalize target lookup key for case-insensitive matching.
-- @tparam string value Raw target key.
-- @treturn string Normalized lookup key.
local function NormalizeLookupKey(value)
    return string.lower(string.Trim(tostring(value or "")))
end

--- Pick nearest candidate vector to an origin.
-- @tparam table candidates Vector candidate array.
-- @tparam Vector origin Origin vector.
-- @treturn Vector|nil Nearest vector.
local function PickNearestVector(candidates, origin)
    if ( !istable(candidates) or !isvector(origin) ) then
        return nil
    end

    local nearest = nil
    local nearestDistSqr = math.huge

    for i = 1, #candidates do
        local candidate = candidates[i]
        if ( !isvector(candidate) ) then
            continue
        end

        local distSqr = candidate:DistToSqr(origin)
        if ( distSqr < nearestDistSqr ) then
            nearest = candidate
            nearestDistSqr = distSqr
        end
    end

    return nearest
end

--- Pick nearest parsed soundscape node to an origin.
-- @tparam table candidates Parsed node candidate array.
-- @tparam Vector origin Origin vector.
-- @treturn table|nil Nearest node.
local function PickNearestNode(candidates, origin)
    if ( !istable(candidates) or !isvector(origin) ) then
        return nil
    end

    local nearest = nil
    local nearestDistSqr = math.huge

    for i = 1, #candidates do
        local candidate = candidates[i]
        if ( !istable(candidate) or !isvector(candidate.origin) ) then
            continue
        end

        local distSqr = candidate.origin:DistToSqr(origin)
        if ( distSqr < nearestDistSqr ) then
            nearest = candidate
            nearestDistSqr = distSqr
        end
    end

    return nearest
end

--- Parse env_soundscape style radius value.
-- Supports `-1` as infinite range.
-- @tparam any value Raw radius field value.
-- @tparam number fallbackRadius Fallback radius when value is missing/invalid.
-- @treturn number radius Parsed radius (`-1` means infinite).
-- @treturn number radiusSqr Parsed radius squared (`-1` means infinite).
-- @treturn boolean infiniteRange True when radius is infinite.
local function ParseSoundscapeRadius(value, fallbackRadius)
    local rawRadius = tonumber(value)
    if ( rawRadius == -1 ) then
        return -1, -1, true
    end

    if ( !isnumber(rawRadius) or rawRadius <= 0 ) then
        rawRadius = tonumber(fallbackRadius) or DEFAULT_ENV_SOUNDSCAPE_RADIUS
    end

    if ( rawRadius == -1 ) then
        return -1, -1, true
    end

    local radius = math.Clamp(rawRadius, MIN_ENV_SOUNDSCAPE_RADIUS, MAX_ENV_SOUNDSCAPE_RADIUS)
    return radius, (radius * radius), false
end

--- Parse a DSP preset value from entity keyvalues.
-- @tparam any value Raw DSP value.
-- @treturn number|nil Parsed DSP preset (`0..255`) or nil.
local function ParseDSPPreset(value)
    local preset = tonumber(value)
    if ( !isnumber(preset) ) then
        return nil
    end

    return math.Clamp(math.floor(preset), 0, 255)
end

--- Find best env_soundscape node for a world position.
-- @tparam table scapes `ax.scapes` namespace table.
-- @tparam Player client Target player.
-- @tparam Vector position Position to test.
-- @tparam Vector viewPosition Position used for visibility checks.
-- @tparam table nodes Parsed soundscape node array.
-- @treturn table|nil node Best node or nil.
-- @treturn number|nil score Closest distance squared score.
local function FindBestNode(scapes, client, position, viewPosition, nodes)
    if ( !ax.util:IsValidPlayer(client) or !isvector(position) or !isvector(viewPosition) or !istable(nodes) ) then
        return nil, nil
    end

    local bestNode = nil
    local bestScore = nil

    for i = 1, #nodes do
        local node = nodes[i]
        if ( scapes:IsValid(node.scapeId) != true ) then
            continue
        end

        local distSqr = position:DistToSqr(node.origin)
        if ( node.infiniteRange != true and distSqr > node.radiusSqr ) then
            continue
        end

        if ( !scapes:CanNodeSeeClient(node, client, viewPosition) ) then
            continue
        end

        local score = distSqr
        if ( !isnumber(bestScore) or score < bestScore ) then
            bestNode = node
            bestScore = score
        end
    end

    return bestNode, bestScore
end

--- Ask schema/game hooks whether auto-triggered scapes should be suppressed.
-- @tparam Player client Target player.
-- @tparam Vector position Player position.
-- @tparam table state Auto-trigger state table.
-- @treturn boolean suppressed True when auto-trigger should be suppressed.
-- @treturn string|nil reason Optional suppress reason.
local function ShouldSuppressAutoTrigger(client, position, state)
    local suppress, reason = hook.Run("ScapesShouldSuppressAutoTrigger", client, position, state)

    return suppress == true, reason
end

--- Ask schema/game hooks for an override scape id/context.
-- @tparam Player client Target player.
-- @tparam Vector position Player position.
-- @tparam table state Auto-trigger state table.
-- @treturn string|nil scapeId Override scape id.
-- @treturn table|nil ctx Optional activation context overrides.
local function GetAutoTriggerOverride(client, position, state)
    local scapeId, ctx = hook.Run("ScapesGetAutoTriggerOverride", client, position, state)
    if ( !isstring(scapeId) ) then
        return nil, nil
    end

    scapeId = string.Trim(scapeId)
    if ( scapeId == "" ) then
        return nil, nil
    end

    return scapeId, istable(ctx) and ctx or nil
end

--- Emit debug output for auto-trigger runtime.
-- @tparam string message Message text.
function ax.scapes:DebugAutoTrigger(message)
    self:LogDebug("[Auto]", tostring(message or ""))
end

--- Emit warning output for auto-trigger runtime.
-- @tparam string message Message text.
function ax.scapes:WarnAutoTrigger(message)
    self:LogWarning("[Auto]", tostring(message or ""))
end

--- Draw debug overlays for one parsed auto-trigger node.
-- @tparam table node Parsed node table.
-- @tparam[opt] Color color Overlay color.
-- @tparam[opt] string label Optional text label.
-- @tparam[opt] number duration Overlay lifetime.
function ax.scapes:DebugDrawAutoNode(node, color, label, duration)
    if ( !istable(node) or !isvector(node.origin) ) then
        return
    end

    local radius = node.infiniteRange == true and 96 or node.radius
    local tag = tostring(node.sourceClass or "env_soundscape")
    local dsp = isnumber(node.dspPreset) and (" dsp:" .. tostring(node.dspPreset)) or ""
    local text = label or string.format("%s #%d %s%s", tag, tonumber(node.index) or -1, tostring(node.scapeId or ""), dsp)

    self:DebugDrawSphere(node.origin, radius, color or Color(80, 190, 255, 45), duration, true)
    self:DebugDrawText(node.origin + Vector(0, 0, 18), text, duration, true)
end

--- Draw debug line for node to player visibility checks.
-- @tparam table node Parsed node table.
-- @tparam Vector viewPosition Player eye position.
-- @tparam boolean visible True when node sees player.
-- @tparam[opt] number duration Overlay lifetime.
function ax.scapes:DebugDrawAutoLOS(node, viewPosition, visible, duration)
    if ( !istable(node) or !isvector(node.origin) or !isvector(viewPosition) ) then
        return
    end

    local color = visible == true and Color(100, 220, 120, 70) or Color(220, 90, 90, 70)
    self:DebugDrawLine(node.origin + Vector(0, 0, 8), viewPosition, color, duration, true)
end

--- Ensure NikNaks is loaded and ready.
-- @treturn boolean loaded True when NikNaks is available.
function ax.scapes:EnsureNikNaksLoaded()
    if ( self._niknaksAttempted == true ) then
        return self._niknaksAvailable == true
    end

    self._niknaksAttempted = true

    local ok, err = pcall(require, "niknaks")
    if ( !ok ) then
        self._niknaksAvailable = false
        self:WarnAutoTrigger("NikNaks require failed: " .. tostring(err))
        return false
    end

    self._niknaksAvailable = istable(NikNaks) and NikNaks.CurrentMap != nil
    if ( self._niknaksAvailable != true ) then
        self:WarnAutoTrigger("NikNaks loaded but NikNaks.CurrentMap is unavailable.")
    end

    return self._niknaksAvailable == true
end

--- Build `info_target` lookup keyed by targetname.
-- @tparam table mapObject NikNaks current map object.
-- @treturn table Lookup table `{[targetnameLower] = {Vector, ...}}`.
function ax.scapes:BuildInfoTargetLookup(mapObject)
    local lookup = {}
    local infoTargets = mapObject:FindByClass("info_target") or {}

    for i = 1, #infoTargets do
        local raw = infoTargets[i]
        local targetname = tostring(GetEntityField(raw, "targetname", "TargetName", "name", "Name") or "")
        targetname = NormalizeLookupKey(targetname)
        if ( targetname == "" ) then
            continue
        end

        local origin = ParseVector(GetEntityField(raw, "origin", "Origin"))
        if ( !isvector(origin) ) then
            continue
        end

        lookup[targetname] = lookup[targetname] or {}
        lookup[targetname][#lookup[targetname] + 1] = origin
    end

    return lookup
end

--- Build resolved position key table for one env_soundscape.
-- @tparam table rawSoundscape Raw env_soundscape entity data.
-- @tparam table infoTargetLookup info_target lookup table.
-- @tparam Vector origin env_soundscape origin.
-- @treturn table Position table keyed by `0..7`.
function ax.scapes:BuildPositionContext(rawSoundscape, infoTargetLookup, origin)
    local positions = {}

    for positionKey = 0, MAX_POSITION_KEY do
        local key = "position" .. tostring(positionKey)
        local targetName = tostring(GetEntityField(rawSoundscape, key, string.upper(key), "Sound Position " .. tostring(positionKey)) or "")
        targetName = NormalizeLookupKey(targetName)
        if ( targetName == "" ) then
            continue
        end

        local candidates = infoTargetLookup[targetName]
        local resolved = PickNearestVector(candidates, origin)
        if ( isvector(resolved) ) then
            positions[positionKey] = resolved
        end
    end

    return positions
end

--- Build lookup map for main env_soundscape entities by targetname.
-- @tparam table nodes Parsed env_soundscape nodes.
-- @treturn table Lookup table `{[targetnameLower] = {node, ...}}`.
function ax.scapes:BuildMainSoundscapeLookup(nodes)
    local lookup = {}
    if ( !istable(nodes) ) then
        return lookup
    end

    for i = 1, #nodes do
        local node = nodes[i]
        if ( !istable(node) ) then
            continue
        end

        local name = NormalizeLookupKey(node.entityName)
        if ( name == "" ) then
            continue
        end

        lookup[name] = lookup[name] or {}
        lookup[name][#lookup[name] + 1] = node
    end

    return lookup
end

--- Resolve a proxy entity's main env_soundscape node reference.
-- @tparam table rawProxy Raw env_soundscape_proxy entity data.
-- @tparam table lookup Main soundscape lookup map.
-- @treturn table|nil node Referenced main node.
function ax.scapes:ResolveProxyMainNode(rawProxy, lookup)
    if ( !istable(rawProxy) or !istable(lookup) ) then
        return nil
    end

    local mainName = tostring(GetEntityField(
        rawProxy,
        "MainSoundscapeName",
        "mainsoundscapename",
        "Soundscape Entity",
        "soundscapeentity",
        "Main Soundscape Name"
    ) or "")
    mainName = NormalizeLookupKey(mainName)
    if ( mainName == "" ) then
        return nil
    end

    local candidates = lookup[mainName]
    if ( !istable(candidates) or !candidates[1] ) then
        return nil
    end

    local origin = ParseVector(GetEntityField(rawProxy, "origin", "Origin"))
    if ( !isvector(origin) ) then
        return candidates[1]
    end

    return PickNearestNode(candidates, origin) or candidates[1]
end

--- Build parsed env_soundscape node list.
-- @tparam table mapObject NikNaks current map object.
-- @tparam table infoTargetLookup info_target lookup table.
-- @treturn table Parsed node array.
function ax.scapes:BuildAutoSoundscapeNodes(mapObject, infoTargetLookup)
    local nodes = {}
    local mainNodes = {}
    local envSoundscapes = mapObject:FindByClass("env_soundscape") or {}
    local skippedMain = 0

    for i = 1, #envSoundscapes do
        local raw = envSoundscapes[i]

        if ( ParseBool(GetEntityField(raw, "startdisabled", "StartDisabled", "startDisabled")) ) then
            continue
        end

        local scapeId = tostring(GetEntityField(raw, "soundscape", "Soundscape") or "")
        scapeId = string.Trim(scapeId)
        if ( scapeId == "" ) then
            skippedMain = skippedMain + 1
            continue
        end

        local origin = ParseVector(GetEntityField(raw, "origin", "Origin"))
        if ( !isvector(origin) ) then
            skippedMain = skippedMain + 1
            continue
        end

        local radius, radiusSqr, infiniteRange = ParseSoundscapeRadius(
            GetEntityField(raw, "radius", "Radius"),
            DEFAULT_ENV_SOUNDSCAPE_RADIUS
        )

        local nodeIndex = #nodes + 1
        local node = {
            index = nodeIndex,
            entityName = tostring(GetEntityField(raw, "targetname", "TargetName", "name", "Name") or ""),
            scapeId = scapeId,
            origin = origin,
            radius = radius,
            radiusSqr = radiusSqr,
            infiniteRange = infiniteRange == true,
            positions = self:BuildPositionContext(raw, infoTargetLookup, origin),
            dspPreset = ParseDSPPreset(GetEntityField(raw, "roomtype", "RoomType", "dsp", "DSP", "DSPPreset", "dsp_preset")),
            sourceClass = "env_soundscape",
        }

        node.uniqueID = util.CRC(string.format("%s:%s:%s:%.2f", game.GetMap(), node.scapeId, tostring(node.origin), node.radius))
        nodes[nodeIndex] = node
        mainNodes[#mainNodes + 1] = node
    end

    local mainLookup = self:BuildMainSoundscapeLookup(mainNodes)
    local proxyEntities = mapObject:FindByClass("env_soundscape_proxy") or {}
    local skippedProxy = 0

    for i = 1, #proxyEntities do
        local rawProxy = proxyEntities[i]

        if ( ParseBool(GetEntityField(rawProxy, "startdisabled", "StartDisabled", "startDisabled")) ) then
            continue
        end

        local mainNode = self:ResolveProxyMainNode(rawProxy, mainLookup)
        if ( !istable(mainNode) ) then
            skippedProxy = skippedProxy + 1
            continue
        end

        local origin = ParseVector(GetEntityField(rawProxy, "origin", "Origin"))
        if ( !isvector(origin) ) then
            skippedProxy = skippedProxy + 1
            continue
        end

        local fallbackRadius = mainNode.infiniteRange == true and -1 or mainNode.radius
        local radius, radiusSqr, infiniteRange = ParseSoundscapeRadius(
            GetEntityField(rawProxy, "radius", "Radius"),
            fallbackRadius
        )

        local nodeIndex = #nodes + 1
        local node = {
            index = nodeIndex,
            entityName = tostring(GetEntityField(rawProxy, "targetname", "TargetName", "name", "Name") or ""),
            scapeId = mainNode.scapeId,
            origin = origin,
            radius = radius,
            radiusSqr = radiusSqr,
            infiniteRange = infiniteRange == true,
            positions = table.Copy(mainNode.positions or {}),
            dspPreset = ParseDSPPreset(GetEntityField(rawProxy, "roomtype", "RoomType", "dsp", "DSP", "DSPPreset", "dsp_preset")) or mainNode.dspPreset,
            sourceClass = "env_soundscape_proxy",
            proxyTarget = NormalizeLookupKey(tostring(GetEntityField(
                rawProxy,
                "MainSoundscapeName",
                "mainsoundscapename",
                "Soundscape Entity",
                "soundscapeentity",
                "Main Soundscape Name"
            ) or "")),
            proxyMainNodeIndex = mainNode.index,
        }

        node.uniqueID = util.CRC(string.format(
            "%s:proxy:%s:%s:%.2f",
            game.GetMap(),
            tostring(node.proxyTarget or ""),
            tostring(node.origin),
            node.radius
        ))
        nodes[nodeIndex] = node
    end

    self:DebugAutoTrigger(string.format(
        "Node parse summary: %d mains, %d proxies, %d skipped mains, %d skipped proxies.",
        #mainNodes,
        math.max(0, #nodes - #mainNodes),
        skippedMain,
        skippedProxy
    ))

    return nodes
end

--- Check whether a parsed node has line of sight to a client view point.
-- @tparam table node Parsed env_soundscape node.
-- @tparam Player client Target player.
-- @tparam Vector viewPosition Client view position.
-- @treturn boolean visible True when node origin can see the client.
function ax.scapes:CanNodeSeeClient(node, client, viewPosition)
    if ( !istable(node) or !isvector(node.origin) ) then
        return false
    end

    if ( !ax.util:IsValidPlayer(client) or !isvector(viewPosition) ) then
        return false
    end

    local trace = util.TraceLine({
        start = node.origin + Vector(0, 0, 8),
        endpos = viewPosition,
        mask = MASK_BLOCKLOS,
        filter = function(ent)
            if ( !IsValid(ent) ) then
                return false
            end

            if ( ent == client ) then
                return true
            end

            return ax.util:IsValidPlayer(ent) or ent:IsNPC()
        end,
    })

    local visible = trace.Hit != true
    self:DebugDrawAutoLOS(node, viewPosition, visible)

    return visible
end

--- Clear auto-trigger state for one player or all players.
-- @tparam[opt] Player|string clientOrSteamID64 Target player or SteamID64.
function ax.scapes:ClearAutoTriggerState(clientOrSteamID64)
    local steamID64 = nil

    if ( isstring(clientOrSteamID64) ) then
        steamID64 = clientOrSteamID64
    elseif ( clientOrSteamID64 and isfunction(clientOrSteamID64.SteamID64) ) then
        steamID64 = clientOrSteamID64:SteamID64()
    end

    if ( isstring(steamID64) and steamID64 != "" ) then
        self.autoPlayerState[steamID64] = nil
        return
    end

    self.autoPlayerState = {}
end

--- Get or create auto-trigger state for a player.
-- @tparam Player client Target player.
-- @treturn table|nil State table.
function ax.scapes:GetAutoTriggerState(client)
    if ( !ax.util:IsValidPlayer(client) ) then
        return nil
    end

    local steamID64 = client:SteamID64()
    self.autoPlayerState[steamID64] = self.autoPlayerState[steamID64] or {
        nodeIndex = nil,
        scapeId = nil,
        overrideScapeId = nil,
        nextSwitchAt = 0,
        outsideSince = nil,
        suppressed = false,
        suppressReason = nil,
    }

    return self.autoPlayerState[steamID64]
end

--- Check whether a session was created by map auto-trigger runtime.
-- @tparam table session Server session table.
-- @treturn boolean True when auto managed.
function ax.scapes:IsAutoManagedSession(session)
    return istable(session)
        and istable(session.ctx)
        and (session.ctx.autoSource == "niknaks_env_soundscape" or session.ctx.autoSource == "niknaks_override")
end

--- Parse env_soundscape and info_target data for the current map.
-- @treturn boolean success
-- @treturn string|number detail Error id or parsed node count.
function ax.scapes:RebuildAutoSoundscapes()
    self:LogDebug("[Auto] Rebuilding map soundscape nodes.")

    self.autoSoundscapes = {}
    self.autoSoundscapesByIndex = {}
    self:ClearAutoTriggerState()
    self.nextAutoTriggerThink = 0

    if ( self:GetAutoTriggerEnabled() != true ) then
        self:LogDebug("[Auto] Rebuild skipped: auto trigger disabled.")
        return false, "disabled"
    end

    if ( !self:EnsureNikNaksLoaded() ) then
        self:WarnAutoTrigger("Rebuild failed: NikNaks unavailable.")
        return false, "niknaks_unavailable"
    end

    local mapObject = NikNaks and NikNaks.CurrentMap
    if ( !mapObject ) then
        self:WarnAutoTrigger("Rebuild failed: NikNaks.CurrentMap missing.")
        return false, "missing_map"
    end

    local infoTargets = self:BuildInfoTargetLookup(mapObject)
    local nodes = self:BuildAutoSoundscapeNodes(mapObject, infoTargets)

    self.autoSoundscapes = nodes
    self.autoSoundscapesByIndex = {}

    for i = 1, #nodes do
        local node = nodes[i]
        self.autoSoundscapesByIndex[node.index] = node

        if ( self:GetDebugOverlayEnabled() == true ) then
            local color = node.sourceClass == "env_soundscape_proxy" and Color(120, 120, 255, 45) or Color(80, 190, 255, 45)
            self:DebugDrawAutoNode(node, color, nil, 12)
        end
    end

    local nameCount = table.Count(infoTargets)
    self:DebugAutoTrigger(string.format("Parsed %d env_soundscape nodes with %d info_target names.", #nodes, nameCount))

    return true, #nodes
end

--- Activate a parsed auto-trigger node for a player.
-- @tparam Player client Target player.
-- @tparam table node Parsed soundscape node.
-- @tparam table state Player auto-trigger state.
-- @treturn boolean success
-- @treturn string? err
function ax.scapes:ActivateAutoNode(client, node, state)
    if ( !self:IsValid(node.scapeId) ) then
        return false, "unknown_scape"
    end

    local ctx = {
        positions = table.Copy(node.positions),
        seed = string.format("niknaks.envsoundscape.%s.%s", game.GetMap(), tostring(node.uniqueID)),
        autoSource = "niknaks_env_soundscape",
        autoNodeIndex = node.index,
        dspPreset = node.dspPreset,
    }

    local ok, err = self:Activate(client, node.scapeId, ctx)
    if ( !ok ) then
        return false, err
    end

    state.nodeIndex = node.index
    state.scapeId = node.scapeId
    state.nextSwitchAt = CurTime() + 0.5
    state.outsideSince = nil

    self:DebugAutoTrigger(string.format("Activated '%s' for %s via node #%d.", node.scapeId, client:Nick(), node.index))
    self:DebugDrawAutoNode(node, Color(80, 255, 120, 60), "active #" .. tostring(node.index) .. " " .. tostring(node.scapeId), 1.5)
    self:DebugDrawLine(node.origin + Vector(0, 0, 8), client:EyePos(), Color(80, 255, 120, 80), 1.5, true)

    return true
end

--- Activate an override scape selected by schema logic.
-- @tparam Player client Target player.
-- @tparam string scapeId Override scape id.
-- @tparam table|nil overrideCtx Optional context overrides.
-- @tparam table state Player auto-trigger state.
-- @treturn boolean success
-- @treturn string? err
function ax.scapes:ActivateAutoOverride(client, scapeId, overrideCtx, state)
    scapeId = string.Trim(tostring(scapeId or ""))
    if ( scapeId == "" ) then
        return false, "invalid_override_scape"
    end

    if ( !self:IsValid(scapeId) ) then
        return false, "unknown_override_scape"
    end

    local ctx = istable(overrideCtx) and table.Copy(overrideCtx) or {}
    ctx.autoSource = "niknaks_override"
    ctx.autoOverride = true
    ctx.autoOverrideScapeId = scapeId

    local seed = tostring(ctx.seed or "")
    if ( seed == "" ) then
        seed = string.format("niknaks.override.%s.%s", game.GetMap(), scapeId)
        ctx.seed = seed
    end

    local ok, err = self:Activate(client, scapeId, ctx)
    if ( !ok ) then
        return false, err
    end

    state.nodeIndex = nil
    state.scapeId = scapeId
    state.overrideScapeId = scapeId
    state.nextSwitchAt = CurTime() + 0.5
    state.outsideSince = nil

    self:DebugAutoTrigger(string.format("Activated override '%s' for %s.", scapeId, client:Nick()))
    self:DebugDrawText(client:EyePos() + Vector(0, 0, 12), string.format("override: %s", scapeId), 1.5, true)

    return true
end

--- Deactivate auto-managed session for a player and clear state.
-- @tparam Player client Target player.
-- @tparam table state Player auto-trigger state.
function ax.scapes:DeactivateAutoNode(client, state)
    local session = self:GetSession(client)
    if ( self:IsAutoManagedSession(session) ) then
        self:Deactivate(client, {})
        self:DebugAutoTrigger(string.format("Deactivated auto scape for %s.", client:Nick()))
        self:DebugDrawText(client:EyePos() + Vector(0, 0, 12), "auto deactivated", 1.5, true)
    end

    state.nodeIndex = nil
    state.scapeId = nil
    state.overrideScapeId = nil
    state.nextSwitchAt = 0
    state.outsideSince = nil
end

--- Evaluate and apply map auto-trigger for one player.
-- @tparam Player client Target player.
function ax.scapes:EvaluateAutoTriggerForClient(client)
    local state = self:GetAutoTriggerState(client)
    if ( !state ) then
        return
    end

    local position = client:GetPos()
    local nowTime = CurTime()
    self:DebugDrawSphere(position + Vector(0, 0, 6), 12, Color(255, 255, 255, 20), 0.1, true)

    local overrideScapeId, overrideCtx = GetAutoTriggerOverride(client, position, state)
    if ( overrideScapeId ) then
        state.outsideSince = nil

        local session = self:GetSession(client)
        local alreadyActive = self:IsAutoManagedSession(session)
            and session.scapeId == overrideScapeId
            and istable(session.ctx)
            and session.ctx.autoSource == "niknaks_override"

        if ( alreadyActive ) then
            state.overrideScapeId = overrideScapeId
            state.scapeId = overrideScapeId
            state.nodeIndex = nil
            return
        end

        if ( nowTime < (state.nextSwitchAt or 0) ) then
            return
        end

        local ok, err = self:ActivateAutoOverride(client, overrideScapeId, overrideCtx, state)
        if ( !ok and err != "blocked_by_priority" ) then
            self:DebugAutoTrigger(string.format("Failed to activate override '%s' for %s: %s", overrideScapeId, client:Nick(), tostring(err)))
            self:WarnAutoTrigger(string.format("Override activation failed for %s (%s): %s", client:Nick(), overrideScapeId, tostring(err)))
        end

        return
    elseif ( state.overrideScapeId ) then
        self:DebugAutoTrigger(string.format("Auto scape override ended for %s.", client:Nick()))
        state.overrideScapeId = nil
        state.nextSwitchAt = 0
    end

    local suppress, suppressReason = ShouldSuppressAutoTrigger(client, position, state)
    if ( suppress ) then
        local reasonText = tostring(suppressReason or "schema")

        if ( state.suppressed != true ) then
            self:DebugAutoTrigger(string.format("Suppressing auto scapes for %s: %s", client:Nick(), reasonText))
            self:DebugDrawText(client:EyePos() + Vector(0, 0, 12), "suppressed: " .. reasonText, 1.0, true)
        end

        local session = self:GetSession(client)
        if ( self:IsAutoManagedSession(session) or state.nodeIndex != nil ) then
            self:DeactivateAutoNode(client, state)
        else
            state.outsideSince = nil
        end

        state.suppressed = true
        state.suppressReason = reasonText
        return
    end

    if ( state.suppressed == true ) then
        self:DebugAutoTrigger(string.format("Auto scape suppression ended for %s.", client:Nick()))
        state.suppressed = false
        state.suppressReason = nil
        state.nextSwitchAt = 0
    end

    local nodes = self.autoSoundscapes
    if ( !istable(nodes) or !nodes[1] ) then
        self:DeactivateAutoNode(client, state)
        return
    end

    local viewPosition = client:EyePos()
    local bestNode, bestScore = FindBestNode(self, client, position, viewPosition, nodes)

    local currentNode = state.nodeIndex and self.autoSoundscapesByIndex[state.nodeIndex] or nil
    local currentScore = nil
    if ( currentNode ) then
        local distSqr = position:DistToSqr(currentNode.origin)
        local inRange = currentNode.infiniteRange == true or distSqr <= currentNode.radiusSqr
        if ( inRange and self:CanNodeSeeClient(currentNode, client, viewPosition) ) then
            currentScore = distSqr
        else
            currentNode = nil
        end
    end

    if ( currentNode and bestNode and currentNode.index != bestNode.index and isnumber(currentScore) ) then
        local hysteresis = self:GetAutoTriggerHysteresis()
        local threshold = bestScore * (1 + hysteresis)
        if ( currentScore <= threshold ) then
            bestNode = currentNode
            bestScore = currentScore
        end
    end

    if ( currentNode ) then
        self:DebugDrawAutoNode(currentNode, Color(255, 215, 0, 45), "current #" .. tostring(currentNode.index), 0.2)
    end

    if ( bestNode ) then
        local dist = math.sqrt(math.max(0, tonumber(bestScore) or 0))
        self:DebugDrawAutoNode(bestNode, Color(80, 255, 120, 55), string.format("best #%d (%.0f u)", bestNode.index, dist), 0.2)
        self:DebugDrawLine(bestNode.origin + Vector(0, 0, 8), viewPosition, Color(80, 255, 120, 70), 0.2, true)
    end

    if ( bestNode ) then
        state.outsideSince = nil

        local session = self:GetSession(client)
        local alreadyActive = self:IsAutoManagedSession(session)
            and session.scapeId == bestNode.scapeId
            and state.nodeIndex == bestNode.index

        if ( alreadyActive ) then
            return
        end

        if ( nowTime < (state.nextSwitchAt or 0) ) then
            return
        end

        local ok, err = self:ActivateAutoNode(client, bestNode, state)
        if ( !ok and err != "blocked_by_priority" ) then
            self:DebugAutoTrigger(string.format("Failed to activate '%s' for %s: %s", bestNode.scapeId, client:Nick(), tostring(err)))
            self:WarnAutoTrigger(string.format("Auto-node activation failed for %s (%s): %s", client:Nick(), bestNode.scapeId, tostring(err)))
        end

        return
    end

    if ( !state.nodeIndex ) then
        return
    end

    if ( self:GetAutoTriggerStickyFallback() == true ) then
        state.outsideSince = nil
        self:DebugDrawText(client:EyePos() + Vector(0, 0, 12), "sticky fallback", 0.2, true)
        return
    end

    if ( !isnumber(state.outsideSince) ) then
        state.outsideSince = nowTime
        return
    end

    if ( (nowTime - state.outsideSince) < self:GetAutoTriggerExitDelay() ) then
        return
    end

    self:DeactivateAutoNode(client, state)
end

--- Periodic auto-trigger tick for all players.
function ax.scapes:AutoTriggerThink()
    if ( self:GetAutoTriggerEnabled() != true ) then
        return
    end

    local nowTime = CurTime()
    if ( nowTime < self.nextAutoTriggerThink ) then
        return
    end

    self.nextAutoTriggerThink = nowTime + self:GetAutoTriggerInterval()

    for _, client in player.Iterator() do
        if ( ax.util:IsValidPlayer(client) ) then
            self:EvaluateAutoTriggerForClient(client)
        end
    end
end
