--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( CLIENT ) then return end

--- Scapes server runtime and scheduling.
-- @module ax.scapes

ax.scapes = ax.scapes or {}
ax.scapes.sessions = ax.scapes.sessions or {}
ax.scapes.readyClients = ax.scapes.readyClients or {}
ax.scapes.pendingSessions = ax.scapes.pendingSessions or {}
ax.scapes.nextSessionId = ax.scapes.nextSessionId or 0

--- Check if a player can receive Scapes updates.
-- @tparam Player client Player entity.
-- @treturn boolean True when valid.
local function IsValidClient(client)
    return ax.util:IsValidPlayer(client)
end

--- Build a readable client label for diagnostics.
-- @tparam Player client Player entity.
-- @treturn string Client label.
local function GetClientDebugLabel(client)
    if ( !ax.util:IsValidPlayer(client) ) then
        return "<invalid>"
    end

    local steamID64 = isfunction(client.SteamID64) and client:SteamID64() or "unknown"
    local nick = isfunction(client.Nick) and client:Nick() or tostring(client)

    return string.format("%s[%s]", nick, tostring(steamID64))
end

--- Normalize a DSP preset number to server-safe bounds.
-- @tparam any value Raw DSP value.
-- @treturn number|nil Normalized DSP preset.
local function NormalizeSessionDSPPreset(value)
    local preset = tonumber(value)
    if ( !isnumber(preset) ) then
        return nil
    end

    return math.Clamp(math.floor(preset), 0, 255)
end

--- Build deterministic per-player timer name.
-- @tparam Player|string clientOrSteamID64 Player entity or SteamID64.
-- @treturn string Timer name.
local function GetTimerName(clientOrSteamID64)
    local steamID64

    if ( isstring(clientOrSteamID64) ) then
        steamID64 = clientOrSteamID64
    elseif ( IsValid(clientOrSteamID64) and isfunction(clientOrSteamID64.SteamID64) ) then
        steamID64 = clientOrSteamID64:SteamID64()
    end

    if ( !isstring(steamID64) or steamID64 == "" ) then
        return nil
    end

    return "ax.scapes.schedule." .. steamID64
end

--- Build deterministic session seed text.
-- @tparam Player client Player entity.
-- @tparam string scapeId Scape id.
-- @tparam number sessionId Session id.
-- @treturn string Seed string.
local function BuildSeed(client, scapeId, sessionId)
    return string.format("%s.%s.%s.%d", game.GetMap(), client:SteamID64(), tostring(scapeId), sessionId)
end

--- Build a shared random key for session rolls.
-- @tparam table session Session data.
-- @tparam table layerState Layer state table.
-- @tparam string key Roll key.
-- @treturn string Shared random key.
local function BuildSharedRandomKey(session, layerState, key)
    return string.format("ax.scapes.%s.%s.%d.%s", session.seed, layerState.layerId, layerState.rollIndex, key)
end

--- Roll a deterministic random number for a session layer.
-- @tparam table session Session data.
-- @tparam table layerState Layer state.
-- @tparam string key Key suffix.
-- @tparam number minimum Minimum value.
-- @tparam number maximum Maximum value.
-- @treturn number Random number.
local function SharedRoll(session, layerState, key, minimum, maximum)
    layerState.rollIndex = layerState.rollIndex + 1
    local sharedKey = BuildSharedRandomKey(session, layerState, key)
    local additionalSeed = tonumber(util.CRC(session.seed)) or 0

    return util.SharedRandom(sharedKey, minimum, maximum, additionalSeed)
end

--- Pick a deterministic array index for a layer.
-- @tparam table session Session data.
-- @tparam table layerState Layer state.
-- @tparam number count Item count.
-- @treturn number Picked index.
local function PickIndex(session, layerState, count)
    if ( count <= 1 ) then
        return 1
    end

    local roll = SharedRoll(session, layerState, "index", 1, count + 0.999)
    return math.Clamp(math.floor(roll), 1, count)
end

--- Resolve a random value inside an inclusive min/max range.
-- @tparam table session Session data.
-- @tparam table layerState Layer state.
-- @tparam string key Key suffix.
-- @tparam number rangeMin Minimum value.
-- @tparam number rangeMax Maximum value.
-- @treturn number Rolled value.
local function PickRange(session, layerState, key, rangeMin, rangeMax)
    if ( rangeMin == rangeMax ) then
        return rangeMin
    end

    return SharedRoll(session, layerState, key, rangeMin, rangeMax)
end

--- Stop a session timer for a player.
-- @tparam Player|string clientOrSteamID64 Player entity or SteamID64.
function ax.scapes:StopTimer(clientOrSteamID64)
    local timerName = GetTimerName(clientOrSteamID64)
    if ( !isstring(timerName) ) then
        return
    end

    if ( timer.Exists(timerName) ) then
        timer.Remove(timerName)
        self:LogDebug("Removed schedule timer:", timerName)
    end
end

--- Remove stale recent position records.
-- @tparam table layerState Layer state.
-- @tparam number nowTime Current time.
local function CullRecentPositions(layerState, nowTime)
    if ( !istable(layerState.recentPositions) ) then
        layerState.recentPositions = {}
        return
    end

    for i = #layerState.recentPositions, 1, -1 do
        if ( nowTime - layerState.recentPositions[i].at > 30 ) then
            table.remove(layerState.recentPositions, i)
        end
    end
end

--- Resolve a positional key from layer and context.
-- @tparam table layer Layer definition.
-- @tparam table ctx Activation context.
-- @treturn number|nil Position key.
local function ResolvePositionKey(layer, ctx)
    local key = layer.spatial.positionKey
    if ( isnumber(key) ) then
        return key
    end

    for positionKey in pairs(ctx.positions or {}) do
        return positionKey
    end

    for positionKey in pairs(ctx.entities or {}) do
        return positionKey
    end

    return nil
end

--- Resolve world-space relative event position.
-- @tparam Player client Player entity.
-- @tparam table session Session data.
-- @tparam table layerState Layer state.
-- @treturn Vector Position vector.
local function ResolveRelativePosition(client, session, layerState)
    local layer = layerState.layer
    local radius = PickRange(session, layerState, "radius", layer.spatial.radiusMin, layer.spatial.radiusMax)
    local angle = math.rad(PickRange(session, layerState, "angle", 0, 360))

    local direction = Vector(math.cos(angle), math.sin(angle), 0)
    local pos = client:GetPos() + direction * radius

    if ( layer.spatial.hemisphere ) then
        local zOffset = PickRange(session, layerState, "z", 0, radius * 0.5)
        pos.z = pos.z + zOffset
    end

    return pos
end

--- Resolve event spatial payload.
-- @tparam Player client Target player.
-- @tparam table session Session data.
-- @tparam table layerState Layer state.
-- @tparam number playAt Scheduled server time.
-- @treturn table Spatial payload.
local function ResolveSpatialPayload(client, session, layerState, playAt)
    local layer = layerState.layer
    local mode = layer.spatial.mode

    if ( mode == "ambient" ) then
        return { mode = "ambient" }, nil
    end

    if ( mode == "relative" ) then
        local blockDistance = layer.limit.blockDistance or 0
        local chosenPos = nil

        for _ = 1, 4 do
            local candidate = ResolveRelativePosition(client, session, layerState)
            local blocked = false

            if ( blockDistance > 0 ) then
                CullRecentPositions(layerState, CurTime())

                for i = 1, #layerState.recentPositions do
                    if ( candidate:DistToSqr(layerState.recentPositions[i].pos) <= blockDistance * blockDistance ) then
                        blocked = true
                        break
                    end
                end
            end

            if ( !blocked ) then
                chosenPos = candidate
                break
            end
        end

        chosenPos = chosenPos or ResolveRelativePosition(client, session, layerState)
        layerState.recentPositions[#layerState.recentPositions + 1] = {
            pos = chosenPos,
            at = playAt,
        }

        return {
            mode = "relative",
            pos = ax.scapes:SerializeVector(chosenPos),
            attenuation = layer.spatial.attenuation,
            soundLevel = layer.spatial.soundLevel,
        }, chosenPos
    end

    local positionKey = ResolvePositionKey(layer, session.ctx)

    if ( isnumber(positionKey) ) then
        local entIndex = session.ctx.entities[positionKey]
        if ( isnumber(entIndex) and entIndex > -1 ) then
            return {
                mode = "entity",
                entIndex = entIndex,
                positionKey = positionKey,
                attenuation = layer.spatial.attenuation,
                soundLevel = layer.spatial.soundLevel,
            }, nil
        end

        local position = session.ctx.positions[positionKey]
        if ( isvector(position) ) then
            return {
                mode = "positional",
                pos = ax.scapes:SerializeVector(position),
                positionKey = positionKey,
                attenuation = layer.spatial.attenuation,
                soundLevel = layer.spatial.soundLevel,
            }, position
        end
    end

    return {
        mode = "ambient",
        attenuation = layer.spatial.attenuation,
        soundLevel = layer.spatial.soundLevel,
    }, nil
end

--- Resolve world position for server debug visualization.
-- @tparam Player client Target player.
-- @tparam table spatial Spatial payload.
-- @tparam Vector|nil fallbackPosition Optional pre-resolved position.
-- @treturn Vector|nil Debug world position.
local function ResolveEventDebugPosition(client, spatial, fallbackPosition)
    if ( isvector(fallbackPosition) ) then
        return fallbackPosition
    end

    if ( !istable(spatial) ) then
        return nil
    end

    if ( istable(spatial.pos) ) then
        return ax.scapes:DeserializeVector(spatial.pos)
    end

    if ( spatial.mode == "entity" and isnumber(spatial.entIndex) ) then
        local ent = Entity(math.floor(spatial.entIndex))
        if ( IsValid(ent) ) then
            return ent:GetPos()
        end
    end

    if ( spatial.mode == "ambient" and ax.util:IsValidPlayer(client) ) then
        return client:EyePos()
    end

    return nil
end

--- Draw debugoverlay markers for a scheduled event.
-- @tparam Player client Target player.
-- @tparam string kind Event kind.
-- @tparam string layerName Layer name.
-- @tparam number playAt Scheduled server timestamp.
-- @tparam table spatial Spatial payload.
-- @tparam Vector|nil fallbackPosition Optional world position.
local function DrawScheduledEventOverlay(client, kind, layerName, playAt, spatial, fallbackPosition)
    if ( ax.scapes:GetDebugOverlayEnabled() != true ) then
        return
    end

    local mode = tostring(spatial and spatial.mode or "ambient")
    local position = ResolveEventDebugPosition(client, spatial, fallbackPosition)
    local timeUntil = math.max(0, (tonumber(playAt) or CurTime()) - CurTime())
    local text = string.format("%s %s [%s] +%.2fs", tostring(kind), tostring(layerName), mode, timeUntil)
    local color = kind == "stinger" and Color(255, 150, 80, 70) or Color(80, 190, 255, 70)

    if ( !isvector(position) ) then
        return
    end

    ax.scapes:DebugDrawSphere(position, 16, color, 1, true)
    ax.scapes:DebugDrawText(position + Vector(0, 0, 18), text, 1, true)

    if ( ax.util:IsValidPlayer(client) ) then
        ax.scapes:DebugDrawLine(position, client:EyePos(), color, 0.25, true)
    end
end

--- Build layer runtime state for random scheduling.
-- @tparam table session Session data.
-- @tparam table layer Layer definition.
-- @treturn table Layer state.
local function BuildLayerState(session, layer)
    local state = {
        layer = layer,
        layerId = layer.id or layer.name,
        rollIndex = 0,
        recentPositions = {},
        nextAt = session.startAt,
    }

    state.nextAt = state.nextAt + PickRange(session, state, "firstInterval", layer.intervalMin, layer.intervalMax)

    return state
end

--- Create a deterministic loop payload set for a session.
-- @tparam table session Session data.
-- @treturn table Loop payload array.
local function BuildLoopPayload(session)
    local payload = {}

    for i = 1, #session.resolved.loops do
        local layer = session.resolved.loops[i]
        if ( !layer.sounds[1] ) then
            continue
        end

        local layerState = {
            layerId = layer.id or layer.name,
            rollIndex = 0,
        }

        local soundIndex = PickIndex(session, layerState, #layer.sounds)
        local soundPath = layer.sounds[soundIndex]
        local volume = PickRange(session, layerState, "loopVolume", layer.volumeMin, layer.volumeMax)
        local pitch = PickRange(session, layerState, "loopPitch", layer.pitchMin, layer.pitchMax)

        local driftVolume = PickRange(session, layerState, "driftVolume", layer.drift.volumeMin, layer.drift.volumeMax)
        local driftPitch = PickRange(session, layerState, "driftPitch", layer.drift.pitchMin, layer.drift.pitchMax)
        local driftPeriod = PickRange(session, layerState, "driftPeriod", layer.drift.periodMin, layer.drift.periodMax)
        local driftPhase = PickRange(session, layerState, "driftPhase", 0, math.pi * 2)

        payload[#payload + 1] = {
            id = layer.id,
            name = layer.name,
            soundPath = soundPath,
            soundKey = session.resolved.pathToSoundKey[soundPath],
            volume = volume,
            pitch = pitch,
            spatial = table.Copy(layer.spatial),
            tags = table.Copy(layer.tags),
            preload = layer.preload == true,
            persist = layer.persist == true,
            drift = {
                volume = driftVolume,
                pitch = driftPitch,
                period = driftPeriod,
                phase = driftPhase,
            },
        }
    end

    return payload
end

--- Build trigger event payload from a stinger layer.
-- @tparam Player client Target player.
-- @tparam table session Session data.
-- @tparam table layer Stinger layer.
-- @tparam table payload Trigger payload overrides.
-- @treturn table Event payload.
local function BuildStingerEvent(client, session, layer, payload)
    payload = istable(payload) and payload or {}
    if ( !layer.sounds[1] ) then
        return nil
    end

    local layerState = {
        layer = layer,
        layerId = layer.id or layer.name,
        rollIndex = 0,
        recentPositions = {},
    }

    local soundIndex = PickIndex(session, layerState, #layer.sounds)
    local soundPath = layer.sounds[soundIndex]
    local volume = PickRange(session, layerState, "stingerVolume", layer.volumeMin, layer.volumeMax)
    local pitch = PickRange(session, layerState, "stingerPitch", layer.pitchMin, layer.pitchMax)

    if ( isnumber(payload.volume) ) then
        volume = math.Clamp(payload.volume, 0, 1)
    end

    if ( isnumber(payload.pitch) ) then
        pitch = math.Clamp(payload.pitch, 20, 255)
    end

    local playAt = CurTime() + ax.scapes:GetNetLeadTime() + math.max(0, tonumber(payload.delay) or 0)

    local spatial, debugPosition = ResolveSpatialPayload(client, session, layerState, playAt)

    if ( isvector(payload.position) ) then
        spatial.mode = "positional"
        spatial.pos = ax.scapes:SerializeVector(payload.position)
        debugPosition = payload.position
    elseif ( isnumber(payload.entIndex) ) then
        spatial.mode = "entity"
        spatial.entIndex = math.floor(payload.entIndex)
        debugPosition = nil
    elseif ( isentity(payload.entity) and IsValid(payload.entity) ) then
        spatial.mode = "entity"
        spatial.entIndex = payload.entity:EntIndex()
        debugPosition = payload.entity:GetPos()
    end

    session.nextEventId = session.nextEventId + 1

    DrawScheduledEventOverlay(client, "stinger", layer.name, playAt, spatial, debugPosition)
    ax.scapes:LogDebug("Queued stinger event:", layer.name, "for", GetClientDebugLabel(client), "at", string.format("%.2f", playAt))

    return {
        eventId = session.nextEventId,
        kind = "stinger",
        layerId = layer.id,
        layerName = layer.name,
        playAt = playAt,
        soundPath = soundPath,
        soundKey = session.resolved.pathToSoundKey[soundPath],
        volume = volume,
        pitch = pitch,
        spatial = spatial,
        tags = table.Copy(layer.tags),
        limit = {
            instance = 1,
            blockDistance = 0,
        },
        persist = layer.persist == true,
    }
end

--- Build one random event and append it to an output array.
-- @tparam Player client Target player.
-- @tparam table session Session data.
-- @tparam table layerState Random layer runtime state.
-- @tparam table events Output events array.
-- @tparam number playAt Server time to schedule at.
local function AppendRandomEvent(client, session, layerState, events, playAt)
    local layer = layerState.layer
    if ( !layer.sounds[1] ) then
        return
    end

    local soundIndex = PickIndex(session, layerState, #layer.sounds)
    local soundPath = layer.sounds[soundIndex]

    local volume = PickRange(session, layerState, "randomVolume", layer.volumeMin, layer.volumeMax)
    local pitch = PickRange(session, layerState, "randomPitch", layer.pitchMin, layer.pitchMax)

    local spatial, debugPosition = ResolveSpatialPayload(client, session, layerState, playAt)

    session.nextEventId = session.nextEventId + 1

    events[#events + 1] = {
        eventId = session.nextEventId,
        kind = "random",
        layerId = layer.id,
        layerName = layer.name,
        playAt = playAt,
        soundPath = soundPath,
        soundKey = session.resolved.pathToSoundKey[soundPath],
        volume = volume,
        pitch = pitch,
        spatial = spatial,
        tags = table.Copy(layer.tags),
        limit = {
            instance = layer.limit.instance,
            blockDistance = layer.limit.blockDistance,
        },
        persist = layer.persist == true,
    }

    DrawScheduledEventOverlay(client, "random", layer.name, playAt, spatial, debugPosition)
end

--- Generate schedule events up to a target time.
-- @tparam Player client Target player.
-- @tparam table session Session data.
-- @tparam number targetEnd Target server timestamp.
-- @treturn table Generated event array.
local function GenerateEvents(client, session, targetEnd)
    local events = {}
    local maxEvents = ax.scapes:GetBatchSize()

    for i = 1, #session.randomStates do
        local layerState = session.randomStates[i]
        local layer = layerState.layer

        while ( layerState.nextAt <= targetEnd and #events < maxEvents ) do
            local currentAt = layerState.nextAt
            AppendRandomEvent(client, session, layerState, events, currentAt)

            if ( layer.burst.chance > 0 and #events < maxEvents ) then
                local burstRoll = SharedRoll(session, layerState, "burstChance", 0, 1)
                if ( burstRoll <= layer.burst.chance ) then
                    local burstCount = math.floor(PickRange(session, layerState, "burstCount", layer.burst.countMin, layer.burst.countMax))
                    burstCount = math.max(1, burstCount)

                    local burstAt = currentAt
                    for _ = 2, burstCount do
                        burstAt = burstAt + PickRange(session, layerState, "burstSpacing", layer.burst.spacingMin, layer.burst.spacingMax)
                        if ( burstAt > targetEnd or #events >= maxEvents ) then
                            break
                        end

                        AppendRandomEvent(client, session, layerState, events, burstAt)
                        currentAt = burstAt
                    end
                end
            end

            layerState.nextAt = currentAt + PickRange(session, layerState, "interval", layer.intervalMin, layer.intervalMax)
        end

        if ( #events >= maxEvents ) then
            break
        end
    end

    table.sort(events, function(a, b)
        if ( a.playAt == b.playAt ) then
            return a.eventId < b.eventId
        end

        return a.playAt < b.playAt
    end)

    if ( events[1] ) then
        ax.scapes:LogDebug(
            "Generated",
            #events,
            "event(s) for",
            GetClientDebugLabel(client),
            "session",
            tostring(session.id),
            "until",
            string.format("%.2f", targetEnd)
        )
    end

    return events
end

--- Resolve loop debug position from loop spatial metadata and session context.
-- @tparam table session Session data.
-- @tparam table loop Loop payload entry.
-- @treturn Vector|nil World position when available.
local function ResolveLoopDebugPosition(session, loop)
    if ( !istable(session) or !istable(loop) or !istable(loop.spatial) ) then
        return nil
    end

    local spatial = loop.spatial
    if ( istable(spatial.pos) ) then
        return ax.scapes:DeserializeVector(spatial.pos)
    end

    if ( spatial.mode == "entity" and isnumber(spatial.entIndex) ) then
        local ent = Entity(math.floor(spatial.entIndex))
        if ( IsValid(ent) ) then
            return ent:GetPos()
        end
    end

    if ( !isnumber(spatial.positionKey) ) then
        return nil
    end

    local entIndex = session.ctx.entities and session.ctx.entities[spatial.positionKey]
    if ( isnumber(entIndex) ) then
        local ent = Entity(math.floor(entIndex))
        if ( IsValid(ent) ) then
            return ent:GetPos()
        end
    end

    local position = session.ctx.positions and session.ctx.positions[spatial.positionKey]
    if ( isvector(position) ) then
        return position
    end

    return nil
end

--- Send an activate payload to a ready client.
-- @tparam Player client Target player.
-- @tparam table session Session data.
local function SendActivate(client, session)
    local initialEnd = CurTime() + ax.scapes:GetScheduleWindow()
    local initialEvents = GenerateEvents(client, session, initialEnd)

    session.scheduledUntil = initialEnd

    ax.net:Start(client, ax.scapes.NET_ACTIVATE,
        session.id,
        session.scapeId,
        CurTime(),
        session.startAt,
        session.resolved.fadetime_in,
        session.resolved.fadetime_out,
        session.pauseLegacyAmbient,
        ax.scapes:SerializeContext(session.ctx),
        {
            id = session.resolved.id,
            priority = session.priority,
            mixTag = session.resolved.mixTag,
            mixerProfile = session.resolved.mixerProfile,
            dspPreset = session.dspPreset,
            dspFastReset = session.dspFastReset == true,
            loops = table.Copy(session.loopPayload),
            soundKeyToPath = table.Copy(session.resolved.soundKeyToPath),
        },
        initialEvents
    )

    ax.scapes:LogDebug("Activate:", tostring(session.scapeId), "->", GetClientDebugLabel(client), "(session", session.id .. ")")
    ax.scapes:LogDebug("Activate payload:", #session.loopPayload, "loop(s),", #initialEvents, "event(s), dsp=", tostring(session.dspPreset))

    if ( ax.scapes:GetDebugOverlayEnabled() == true ) then
        for i = 1, #session.loopPayload do
            local loop = session.loopPayload[i]
            local position = ResolveLoopDebugPosition(session, loop)
            if ( isvector(position) ) then
                ax.scapes:DebugDrawSphere(position, 24, Color(120, 255, 120, 50), 1, true)
                ax.scapes:DebugDrawText(position + Vector(0, 0, 20), "loop: " .. tostring(loop.name), 1, true)
            end
        end
    end
end

--- Send a schedule payload to a client.
-- @tparam Player client Target player.
-- @tparam table session Session data.
-- @tparam table events Events payload.
local function SendSchedule(client, session, events)
    if ( !events[1] ) then return end

    ax.net:Start(client, ax.scapes.NET_SCHEDULE,
        session.id,
        CurTime(),
        events
    )

    ax.scapes:LogDebug("Schedule push:", #events, "event(s) ->", GetClientDebugLabel(client), "(session", session.id .. ")")
end

--- Start periodic schedule refill timer for a session.
-- @tparam Player client Target player.
-- @tparam table session Session data.
function ax.scapes:StartTimer(client, session)
    self:StopTimer(client)

    local steamID64 = client:SteamID64()
    local timerName = GetTimerName(steamID64)
    if ( !isstring(timerName) ) then
        return
    end

    local interval = self:GetScheduleRefillInterval()
    self:LogDebug("Starting schedule timer:", timerName, "interval", string.format("%.2f", interval))

    timer.Create(timerName, interval, 0, function()
        if ( !ax.util:IsValidPlayer(client) ) then
            self:StopTimer(steamID64)
            self.sessions[steamID64] = nil
            self.pendingSessions[steamID64] = nil
            self.readyClients[steamID64] = nil
            self:LogDebug("Stopped schedule timer due to invalid client:", tostring(steamID64))
            return
        end

        if ( !IsValidClient(client) ) then
            self:LogWarning("Schedule timer cleanup for invalid client:", GetClientDebugLabel(client))
            self:CleanupSession(steamID64, true)
            return
        end

        local active = self.sessions[steamID64]
        if ( active != session ) then
            self:StopTimer(steamID64)
            self:LogDebug("Stopped stale schedule timer for:", GetClientDebugLabel(client))
            return
        end

        if ( !self:IsClientReady(client) ) then
            return
        end

        local threshold = self:GetScheduleRefillThreshold()
        if ( session.scheduledUntil - CurTime() > threshold ) then
            return
        end

        local targetEnd = CurTime() + self:GetScheduleWindow()
        local events = GenerateEvents(client, session, targetEnd)

        session.scheduledUntil = targetEnd

        SendSchedule(client, session, events)
    end)
end

--- Resolve active session for a client.
-- @tparam Player client Target player.
-- @treturn table|nil Session table.
function ax.scapes:GetSession(client)
    if ( !IsValidClient(client) ) then return nil end

    return self.sessions[client:SteamID64()]
end

--- Check if a client completed Scapes ready handshake.
-- @tparam Player client Target player.
-- @treturn boolean True if ready.
function ax.scapes:IsClientReady(client)
    if ( !IsValidClient(client) ) then return false end

    return self.readyClients[client:SteamID64()] == true
end

--- Resolve effective DSP preset for a session.
-- Context overrides take precedence over resolved scape metadata.
-- @tparam table session Session table.
-- @treturn number|nil DSP preset or nil when no DSP should be applied.
function ax.scapes:ResolveSessionDSPPreset(session)
    if ( !istable(session) ) then
        return nil
    end

    local preset = nil
    if ( istable(session.ctx) ) then
        preset = NormalizeSessionDSPPreset(session.ctx.dspPreset)
    end

    if ( !isnumber(preset) and istable(session.resolved) ) then
        preset = NormalizeSessionDSPPreset(session.resolved.dspPreset)
    end

    return preset
end

--- Resolve effective fast-reset flag for a session DSP change.
-- @tparam table session Session table.
-- @treturn boolean True when DSP should use fast-reset mode.
function ax.scapes:ResolveSessionDSPFastReset(session)
    if ( !istable(session) ) then
        return self:GetDefaultDSPFastReset()
    end

    if ( istable(session.ctx) and isbool(session.ctx.dspFastReset) ) then
        return session.ctx.dspFastReset == true
    end

    if ( istable(session.resolved) and isbool(session.resolved.dspFastReset) ) then
        return session.resolved.dspFastReset == true
    end

    return self:GetDefaultDSPFastReset()
end

--- Apply session DSP preset to a client when configured.
-- @tparam Player client Target player.
-- @tparam table session Session table.
-- @tparam[opt] string reason Diagnostic reason text.
-- @treturn boolean success True when DSP was applied.
function ax.scapes:ApplySessionDSP(client, session, reason)
    if ( self:GetDSPEnabled() != true ) then
        return false
    end

    if ( !IsValidClient(client) or !istable(session) ) then
        return false
    end

    if ( !isfunction(client.SetDSP) ) then
        self:LogWarning("DSP apply skipped: SetDSP unavailable for", GetClientDebugLabel(client))
        return false
    end

    local preset = NormalizeSessionDSPPreset(session.dspPreset)
    if ( !isnumber(preset) ) then
        return false
    end

    local fastReset = session.dspFastReset == true
    client:SetDSP(preset, fastReset)

    session.appliedDSP = true
    self:LogDebug(
        "Applied DSP",
        tostring(preset),
        "to",
        GetClientDebugLabel(client),
        "(" .. tostring(reason or "session") .. ", fastReset=" .. tostring(fastReset) .. ")"
    )

    return true
end

--- Restore previous/default DSP after a session ends.
-- @tparam Player client Target player.
-- @tparam table session Session table.
-- @tparam[opt] string reason Diagnostic reason text.
-- @treturn boolean success True when DSP was restored.
function ax.scapes:RestoreSessionDSP(client, session, reason)
    if ( !IsValidClient(client) or !istable(session) ) then
        return false
    end

    if ( !isfunction(client.SetDSP) ) then
        return false
    end

    if ( session.appliedDSP != true ) then
        return false
    end

    local restorePreset = NormalizeSessionDSPPreset(session.restoreDSP)
    if ( !isnumber(restorePreset) ) then
        restorePreset = self:GetDefaultDSPPreset()
    end

    local fastReset = self:GetDefaultDSPFastReset()
    client:SetDSP(restorePreset, fastReset)

    session.appliedDSP = false
    self:LogDebug(
        "Restored DSP",
        tostring(restorePreset),
        "for",
        GetClientDebugLabel(client),
        "(" .. tostring(reason or "session_end") .. ", fastReset=" .. tostring(fastReset) .. ")"
    )

    return true
end

--- Reapply active session DSP for a client.
-- Useful after external systems overwrite player DSP (spawn/loadout).
-- @tparam Player client Target player.
-- @tparam[opt] string reason Diagnostic reason.
-- @treturn boolean success True when DSP was reapplied.
function ax.scapes:ReapplyActiveDSP(client, reason)
    local session = self:GetSession(client)
    if ( !istable(session) ) then
        return false
    end

    return self:ApplySessionDSP(client, session, reason or "reapply")
end

--- Mark a client as Scapes-ready and flush pending session.
-- @tparam Player client Target player.
function ax.scapes:MarkClientReady(client)
    if ( !IsValidClient(client) ) then return end

    local steamID64 = client:SteamID64()
    self.readyClients[steamID64] = true
    self:LogDebug("Client ready:", GetClientDebugLabel(client))

    local pending = self.pendingSessions[steamID64]
    if ( !istable(pending) ) then return end

    self.pendingSessions[steamID64] = nil

    SendActivate(client, pending)
    self:StartTimer(client, pending)
    self:ApplySessionDSP(client, pending, "mark_ready")
end

--- Cleanup session state and timers for a player.
-- @tparam Player|string clientOrSteamID64 Target player or SteamID64.
-- @tparam boolean silent True to skip deactivate net message.
function ax.scapes:CleanupSession(clientOrSteamID64, silent)
    local client = nil
    local steamID64 = nil

    if ( isstring(clientOrSteamID64) ) then
        steamID64 = clientOrSteamID64
    elseif ( IsValid(clientOrSteamID64) and isfunction(clientOrSteamID64.SteamID64) ) then
        client = clientOrSteamID64
        steamID64 = client:SteamID64()
    end

    if ( !isstring(steamID64) or steamID64 == "" ) then
        return
    end

    local session = self.sessions[steamID64]

    self:StopTimer(steamID64)

    self.pendingSessions[steamID64] = nil
    self.sessions[steamID64] = nil
    self:LogDebug("Cleanup session:", tostring(steamID64), "silent=", tostring(silent == true))

    if ( ax.util:IsValidPlayer(client) and istable(session) ) then
        self:RestoreSessionDSP(client, session, "cleanup")
    end

    if ( !istable(session) or silent == true ) then
        return
    end

    if ( !ax.util:IsValidPlayer(client) ) then
        return
    end

    ax.net:Start(client, self.NET_DEACTIVATE, session.id, CurTime(), session.resolved.fadetime_out)
    self:LogDebug("Sent cleanup deactivate:", GetClientDebugLabel(client), "session", tostring(session.id))
end

--- Build and store a new server session.
-- @tparam Player client Target player.
-- @tparam string scapeId Scape id.
-- @tparam table ctx Activation context.
-- @treturn table|nil Session table.
-- @treturn string? err
function ax.scapes:CreateSession(client, scapeId, ctx)
    local resolved, err = self:ResolveScape(scapeId, ctx)
    if ( !resolved ) then
        self:LogWarning("CreateSession failed for", tostring(scapeId), ":", tostring(err))
        return nil, err
    end

    self.nextSessionId = self.nextSessionId + 1

    local seed = ctx.seed != "" and ctx.seed or BuildSeed(client, scapeId, self.nextSessionId)
    local startAt = tonumber(ctx.startAt) or (CurTime() + self:GetNetLeadTime())

    local pauseLegacyAmbient = resolved.pauseLegacyAmbient
    if ( pauseLegacyAmbient == nil ) then
        pauseLegacyAmbient = ax.config:Get("audio.scapes.pause_legacy_music", true)
    end

    local priority = tonumber(ctx.priority)
    if ( !isnumber(priority) ) then
        priority = tonumber(resolved.priority) or 0
    end

    local session = {
        id = self.nextSessionId,
        client = client,
        scapeId = scapeId,
        priority = math.floor(priority),
        ctx = ctx,
        seed = seed,
        startAt = startAt,
        resolved = resolved,
        randomStates = {},
        loopPayload = {},
        nextEventId = 0,
        scheduledUntil = CurTime(),
        pauseLegacyAmbient = pauseLegacyAmbient == true,
        dspPreset = nil,
        dspFastReset = false,
        restoreDSP = nil,
        appliedDSP = false,
    }

    session.dspPreset = self:ResolveSessionDSPPreset({
        ctx = ctx,
        resolved = resolved,
    })
    session.dspFastReset = self:ResolveSessionDSPFastReset({
        ctx = ctx,
        resolved = resolved,
    })

    if ( isfunction(client.GetDSP) ) then
        session.restoreDSP = NormalizeSessionDSPPreset(client:GetDSP())
    end

    if ( !isnumber(session.restoreDSP) ) then
        session.restoreDSP = self:GetDefaultDSPPreset()
    end

    session.loopPayload = BuildLoopPayload(session)

    for i = 1, #resolved.randoms do
        if ( resolved.randoms[i].sounds[1] ) then
            session.randomStates[#session.randomStates + 1] = BuildLayerState(session, resolved.randoms[i])
        end
    end

    self:LogDebug(
        "Created session",
        session.id,
        "for",
        GetClientDebugLabel(client),
        "scape",
        tostring(scapeId),
        "(loops:",
        #session.loopPayload,
        "random layers:",
        #session.randomStates .. ", dsp:",
        tostring(session.dspPreset) .. ")"
    )

    return session
end

--- Activate a scape for one player.
-- @tparam Player client Target player.
-- @tparam string scapeId Scape id.
-- @tparam table ctx Activation context.
-- @treturn boolean success
-- @treturn string? err
function ax.scapes:ServerActivate(client, scapeId, ctx)
    if ( !IsValidClient(client) ) then
        self:LogWarning("Activate rejected: invalid client.")
        return false, "invalid_client"
    end

    if ( ax.config:Get("audio.scapes.enabled", true) == false ) then
        self:LogDebug("Activate rejected: scapes disabled for", GetClientDebugLabel(client))
        return false, "disabled"
    end

    scapeId = tostring(scapeId or "")
    if ( scapeId == "" ) then
        self:LogWarning("Activate rejected for", GetClientDebugLabel(client), ": empty scape id")
        return false, "invalid_scape"
    end

    if ( !self:IsValid(scapeId) ) then
        self:LogWarning("Activate rejected for", GetClientDebugLabel(client), ": unknown scape", scapeId)
        return false, "unknown_scape"
    end

    ctx = self:NormalizeContext(ctx)

    local session, err = self:CreateSession(client, scapeId, ctx)
    if ( !session ) then
        return false, err
    end

    local existing = self:GetSession(client)
    if ( istable(existing) and existing.id != session.id ) then
        if ( isnumber(existing.restoreDSP) ) then
            session.restoreDSP = existing.restoreDSP
        end

        local force = ctx.force == true
        if ( self:GetUsePriority() and !force and existing.priority > session.priority ) then
            self:LogDebug(
                "Activate blocked by priority for",
                GetClientDebugLabel(client),
                "(existing:",
                existing.priority,
                "new:",
                session.priority .. ")"
            )
            return false, "blocked_by_priority"
        end
    end

    self:CleanupSession(client, false)

    local steamID64 = client:SteamID64()
    self.sessions[steamID64] = session
    self:ApplySessionDSP(client, session, "activate")

    if ( self:IsClientReady(client) ) then
        SendActivate(client, session)
        self:StartTimer(client, session)
    else
        self.pendingSessions[steamID64] = session
        self:LogDebug("Queued pending activation for unready client:", GetClientDebugLabel(client), "(session", session.id .. ")")
    end

    return true
end

--- Activate a scape for multiple players.
-- @tparam function|table filterFnOrPlayers Player filter function or list.
-- @tparam string scapeId Scape id.
-- @tparam table ctx Activation context.
-- @treturn number activatedCount
function ax.scapes:ServerActivateArea(filterFnOrPlayers, scapeId, ctx)
    local targets = {}

    if ( isfunction(filterFnOrPlayers) ) then
        for _, client in player.Iterator() do
            if ( IsValidClient(client) and filterFnOrPlayers(client) ) then
                targets[#targets + 1] = client
            end
        end
    elseif ( istable(filterFnOrPlayers) ) then
        for i = 1, #filterFnOrPlayers do
            local client = filterFnOrPlayers[i]
            if ( IsValidClient(client) ) then
                targets[#targets + 1] = client
            end
        end
    else
        for _, client in player.Iterator() do
            if ( IsValidClient(client) ) then
                targets[#targets + 1] = client
            end
        end
    end

    if ( !targets[1] ) then
        self:LogDebug("ActivateArea skipped: no targets for", tostring(scapeId))
        return 0
    end

    ctx = self:NormalizeContext(ctx)

    local sharedSeed = ctx.seed
    if ( sharedSeed == "" ) then
        sharedSeed = string.format("%s.%d.%d", tostring(scapeId), os.time(), math.floor(SysTime() * 1000))
    end

    local sharedStartAt = ctx.startAt or (CurTime() + self:GetNetLeadTime())

    local count = 0

    for i = 1, #targets do
        local ok = self:ServerActivate(targets[i], scapeId, {
            positions = table.Copy(ctx.positions),
            entities = table.Copy(ctx.entities),
            seed = sharedSeed,
            startAt = sharedStartAt,
            dspPreset = ctx.dspPreset,
            dspFastReset = ctx.dspFastReset,
            priority = ctx.priority,
        })

        if ( ok ) then
            count = count + 1
        end
    end

    self:LogDebug("ActivateArea:", tostring(scapeId), "for", count, "player(s).")

    return count
end

--- Deactivate a player's active session.
-- @tparam Player client Target player.
-- @tparam table opts Deactivation options.
-- @treturn boolean success
function ax.scapes:ServerDeactivate(client, opts)
    if ( !IsValidClient(client) ) then
        self:LogWarning("Deactivate rejected: invalid client.")
        return false
    end

    opts = istable(opts) and opts or {}

    local session = self:GetSession(client)
    if ( !istable(session) ) then
        self:LogDebug("Deactivate skipped: no active session for", GetClientDebugLabel(client))
        return false
    end

    local fadeOut = tonumber(opts.fadeOut)
    if ( !isnumber(fadeOut) ) then
        fadeOut = session.resolved.fadetime_out
    end

    local steamID64 = client:SteamID64()

    self:StopTimer(client)
    self:RestoreSessionDSP(client, session, "deactivate")

    self.pendingSessions[steamID64] = nil
    self.sessions[steamID64] = nil

    if ( opts.silent != true ) then
        ax.net:Start(client, self.NET_DEACTIVATE, session.id, CurTime(), math.max(0, fadeOut))
        self:LogDebug("Deactivate:", GetClientDebugLabel(client), "(session", session.id .. ")")
    end

    return true
end

--- Trigger a stinger inside the active session.
-- @tparam Player client Target player.
-- @tparam string triggerName Trigger id.
-- @tparam table payload Trigger payload.
-- @treturn boolean success
-- @treturn string? err
function ax.scapes:ServerTrigger(client, triggerName, payload)
    if ( !IsValidClient(client) ) then
        self:LogWarning("Trigger rejected: invalid client.")
        return false, "invalid_client"
    end

    local session = self:GetSession(client)
    if ( !istable(session) ) then
        self:LogDebug("Trigger rejected: no active session for", GetClientDebugLabel(client))
        return false, "no_active_session"
    end

    triggerName = tostring(triggerName or "")
    if ( triggerName == "" ) then
        self:LogWarning("Trigger rejected for", GetClientDebugLabel(client), ": empty trigger")
        return false, "invalid_trigger"
    end

    local candidates = session.resolved.stingersByName[triggerName]
    if ( !istable(candidates) or !candidates[1] ) then
        self:LogWarning("Trigger missing for", GetClientDebugLabel(client), ":", triggerName)
        return false, "trigger_missing"
    end

    local pickLayer = candidates[1]
    if ( #candidates > 1 ) then
        local layerState = {
            layerId = "trigger." .. triggerName,
            rollIndex = 0,
        }

        pickLayer = candidates[PickIndex(session, layerState, #candidates)]
    end

    local event = BuildStingerEvent(client, session, pickLayer, payload)
    if ( !istable(event) ) then
        self:LogWarning("Trigger event build failed for", GetClientDebugLabel(client), ":", triggerName)
        return false, "trigger_missing_sounds"
    end

    ax.net:Start(client, self.NET_TRIGGER, session.id, CurTime(), event)
    self:LogDebug("Trigger:", triggerName, "for", GetClientDebugLabel(client), "(session", session.id .. ")")

    return true
end

--- Set all connected clients to not ready.
function ax.scapes:ResetReadyState()
    self.readyClients = {}

    for _, client in player.Iterator() do
        if ( IsValidClient(client) ) then
            self.readyClients[client:SteamID64()] = false
        end
    end

    self:LogDebug("Reset ready state for all connected players.")
end

--- Cleanup all sessions and timers.
-- @tparam boolean silent Skip net deactivation when true.
function ax.scapes:CleanupAllSessions(silent)
    for _, client in player.Iterator() do
        if ( IsValidClient(client) ) then
            if ( silent == true ) then
                self:CleanupSession(client, true)
            else
                self:ServerDeactivate(client, {
                    silent = false,
                })
            end
        end
    end

    self.pendingSessions = {}
    self:LogDebug("CleanupAllSessions complete. silent=", tostring(silent == true))
end
