--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( SERVER ) then return end

--- Scapes client playback engine.
-- @module ax.scapes

ax.scapes = ax.scapes or {}
ax.scapes.clientState = ax.scapes.clientState or {
    activeSessionId = 0,
    activeScapeId = nil,
    activePriority = 0,
    activeDSPPreset = nil,
    activePauseLegacyAmbient = false,
    sessionStartAt = 0,
    serverOffset = 0,
    fadeOut = 1,
    context = {
        positions = {},
        entities = {},
    },
    definition = nil,
    queue = {},
    playedEventIds = {},
    loops = {},
    fadingLoops = {},
    mix = {},
    layerHistory = {},
    debug = false,
}

local OCCLUSION_TRACE_MASK = MASK_BLOCKLOS
local OCCLUSION_TRACE_OFFSET = 2
local OCCLUSION_TRACE_MINS = Vector(-2, -2, -2)
local OCCLUSION_TRACE_MAXS = Vector(2, 2, 2)
local OCCLUSION_MAX_BLOCKERS = 3
local OCCLUSION_MIN_BLOCK_RATIO = 0.24
local OCCLUSION_RECHECK_INTERVAL = 0.15

--- Resolve 3D position for a loop runtime.
-- @tparam table runtime Loop runtime.
-- @treturn Vector|nil Position vector.
local function ResolveLoopPosition(runtime)
    local spatial = runtime.spatial
    if ( !istable(spatial) ) then return nil end

    if ( spatial.mode == "entity" and isnumber(spatial.entIndex) ) then
        local ent = Entity(spatial.entIndex)
        if ( IsValid(ent) ) then
            return ent:GetPos()
        end
    end

    if ( (spatial.mode == "positional" or spatial.mode == "relative") and istable(spatial.pos) ) then
        return ax.scapes:DeserializeVector(spatial.pos)
    end

    if ( isnumber(spatial.positionKey) and runtime.ctx ) then
        local entIndex = runtime.ctx.entities and runtime.ctx.entities[spatial.positionKey]
        if ( isnumber(entIndex) ) then
            local ent = Entity(entIndex)
            if ( IsValid(ent) ) then
                return ent:GetPos()
            end
        end

        local pos = runtime.ctx.positions and runtime.ctx.positions[spatial.positionKey]
        if ( isvector(pos) ) then
            return pos
        end
    end

    return nil
end

--- Stop a BASS channel safely.
-- @tparam table runtime Loop runtime.
local function StopLoopChannel(runtime)
    if ( !istable(runtime) or !runtime.channel ) then return end

    if ( runtime.channel.Stop ) then
        runtime.channel:Stop()
    end

    runtime.channel = nil
end

--- Build fade multiplier for a runtime at current time.
-- @tparam table runtime Loop runtime.
-- @treturn number Fade multiplier.
local function GetFadeMultiplier(runtime)
    local nowTime = CurTime()

    if ( runtime.fadingOut ) then
        local fadeOut = math.max(0, runtime.fadeOut)
        if ( fadeOut <= 0 ) then
            return 0
        end

        local elapsed = nowTime - runtime.fadeOutStart
        return math.Clamp(1 - (elapsed / fadeOut), 0, 1)
    end

    local fadeIn = math.max(0, runtime.fadeIn)
    if ( fadeIn <= 0 ) then
        return 1
    end

    local elapsed = nowTime - runtime.startTime
    return math.Clamp(elapsed / fadeIn, 0, 1)
end

--- Resolve effective mix multiplier from tag list.
-- @tparam table tags Tag array.
-- @treturn number Mix multiplier.
local function GetTagMultiplier(tags)
    local state = ax.scapes.clientState
    if ( !istable(tags) or !tags[1] ) then
        return 1
    end

    local total = 1

    for i = 1, #tags do
        local tag = tostring(tags[i] or "")
        if ( tag == "" ) then continue end

        local value = state.mix[tag]
        if ( isnumber(value) ) then
            total = total * math.Clamp(value, 0, 2)
        end
    end

    return total
end

--- Read a numeric Scapes option with clamping.
-- @tparam string key Option key.
-- @tparam number fallback Fallback numeric value.
-- @tparam number minimum Minimum value clamp.
-- @tparam number maximum Maximum value clamp.
-- @treturn number Resolved option value.
local function GetScapesNumberOption(key, fallback, minimum, maximum)
    local value = fallback

    if ( ax.option and isfunction(ax.option.Get) ) then
        value = tonumber(ax.option:Get(key, fallback)) or fallback
    end

    if ( isnumber(minimum) ) then
        value = math.max(minimum, value)
    end

    if ( isnumber(maximum) ) then
        value = math.min(maximum, value)
    end

    return value
end

--- Read a boolean Scapes option.
-- @tparam string key Option key.
-- @tparam boolean fallback Fallback value.
-- @treturn boolean Resolved option value.
local function GetScapesBoolOption(key, fallback)
    fallback = fallback == true

    if ( ax.option and isfunction(ax.option.Get) ) then
        return ax.option:Get(key, fallback) == true
    end

    return fallback
end

--- Resolve per-client volume customization multiplier.
-- @tparam string kind Sound class (`loop`, `random`, `stinger`).
-- @tparam string spatialMode Spatial mode (`ambient`, `positional`, `relative`, `entity`).
-- @treturn number Effective local multiplier.
local function GetClientVolumeMultiplier(kind, spatialMode)
    if ( !GetScapesBoolOption("scapes.enabled", true) ) then
        return 0
    end

    local total = GetScapesNumberOption("scapes.master_volume", 1, 0, 1)

    if ( kind == "loop" ) then
        total = total * GetScapesNumberOption("scapes.loop_volume", 1, 0, 1)
    elseif ( kind == "stinger" ) then
        total = total * GetScapesNumberOption("scapes.stinger_volume", 1, 0, 1)
    else
        total = total * GetScapesNumberOption("scapes.random_volume", 1, 0, 1)
    end

    if ( spatialMode == "ambient" ) then
        total = total * GetScapesNumberOption("scapes.ambient_volume", 1, 0, 1)
    else
        total = total * GetScapesNumberOption("scapes.positional_volume", 1, 0, 1)
    end

    return math.Clamp(total, 0, 1)
end

--- Check whether debug overlay should be rendered.
-- @treturn boolean True when overlay is enabled.
local function IsDebugOverlayEnabled()
    local state = ax.scapes.clientState
    return state.debug == true or GetScapesBoolOption("scapes.debug_overlay", false)
end

--- Get the current listener position for client-side scape playback.
-- @treturn Vector|nil Listener position.
local function GetListenerPosition()
    local client = ax.client
    if ( !ax.util:IsValidPlayer(client) ) then
        return nil
    end

    local viewEntity = client:GetViewEntity()
    if ( IsValid(viewEntity) ) then
        local viewPos = viewEntity:GetPos()
        if ( !viewPos:IsEqualTol(client:GetPos(), 2) ) then
            return viewPos
        end
    end

    return client:EyePos()
end

--- Get whether positional Scapes occlusion is enabled.
-- @treturn boolean True when occlusion should be evaluated.
local function GetOcclusionEnabled()
    if ( ax.scapes and isfunction(ax.scapes.GetOcclusionEnabled) ) then
        return ax.scapes:GetOcclusionEnabled()
    end

    return ax.config:Get("audio.scapes.occlusion_enabled", true) == true
end

--- Get approximate thickness needed to reach maximum occlusion loss.
-- @treturn number Thickness in Hammer units.
local function GetOcclusionThicknessScale()
    if ( ax.scapes and isfunction(ax.scapes.GetOcclusionThicknessScale) ) then
        return ax.scapes:GetOcclusionThicknessScale()
    end

    return math.max(16, tonumber(ax.config:Get("audio.scapes.occlusion_thickness_scale", 96)) or 96)
end

--- Get maximum volume loss caused by positional occlusion.
-- @treturn number Volume loss clamped to 0..1.
local function GetOcclusionMaxVolumeLoss()
    if ( ax.scapes and isfunction(ax.scapes.GetOcclusionMaxVolumeLoss) ) then
        return ax.scapes:GetOcclusionMaxVolumeLoss()
    end

    return math.Clamp(tonumber(ax.config:Get("audio.scapes.occlusion_max_volume_loss", 0.92)) or 0.92, 0, 1)
end

--- Build a trace filter that ignores the local listener and optional source entity.
-- @tparam[opt] Entity sourceEntity Source entity for entity-bound playback.
-- @treturn function Trace filter callback.
local function BuildOcclusionFilter(sourceEntity)
    local client = ax.client
    local viewEntity = ax.util:IsValidPlayer(client) and client:GetViewEntity() or nil

    return function(ent)
        if ( !IsValid(ent) ) then
            return false
        end

        if ( ent == client or ent == sourceEntity ) then
            return true
        end

        return ent == viewEntity
    end
end

--- Trace a small hull between the listener and a sound source.
-- @tparam Vector startPos Trace start position.
-- @tparam Vector endPos Trace end position.
-- @tparam[opt] Entity sourceEntity Optional entity used as the sound source.
-- @treturn table Trace result.
local function TraceOcclusionPath(startPos, endPos, sourceEntity)
    return util.TraceHull({
        start = startPos,
        endpos = endPos,
        mins = OCCLUSION_TRACE_MINS,
        maxs = OCCLUSION_TRACE_MAXS,
        mask = OCCLUSION_TRACE_MASK,
        filter = BuildOcclusionFilter(sourceEntity),
    })
end

--- Estimate one occluding blocker along the listener-to-source path.
-- @tparam Vector startPos Trace start position.
-- @tparam Vector sourcePos Sound source position.
-- @tparam Vector direction Normalized direction toward the source.
-- @tparam[opt] Entity sourceEntity Optional entity used as the sound source.
-- @treturn number Thickness in Hammer units.
-- @treturn table|nil Enter trace result.
-- @treturn Vector|nil Next start position after the blocker.
local function EstimateOcclusionBlocker(startPos, sourcePos, direction, sourceEntity)
    local enterTrace = TraceOcclusionPath(startPos, sourcePos, sourceEntity)
    if ( enterTrace.Hit != true ) then
        return 0, enterTrace, nil
    end

    if ( IsValid(sourceEntity) and enterTrace.Entity == sourceEntity ) then
        return 0, enterTrace, nil
    end

    local insideStart = enterTrace.HitPos + direction * OCCLUSION_TRACE_OFFSET
    local remainingDistance = insideStart:Distance(sourcePos)
    if ( remainingDistance <= 0 ) then
        return 0, enterTrace, nil
    end

    local exitTrace = TraceOcclusionPath(insideStart, sourcePos, sourceEntity)
    local thickness = 0

    if ( exitTrace.StartSolid == true and isnumber(exitTrace.FractionLeftSolid) and exitTrace.FractionLeftSolid > 0 ) then
        thickness = remainingDistance * exitTrace.FractionLeftSolid
    elseif ( exitTrace.Hit == true and isvector(exitTrace.HitPos) ) then
        thickness = insideStart:Distance(exitTrace.HitPos)
    else
        thickness = OCCLUSION_TRACE_OFFSET * 6
    end

    thickness = math.max(OCCLUSION_TRACE_OFFSET * 4, thickness)

    local nextStart = insideStart + direction * (thickness + OCCLUSION_TRACE_OFFSET)
    if ( nextStart:DistToSqr(sourcePos) <= (OCCLUSION_TRACE_OFFSET * OCCLUSION_TRACE_OFFSET) ) then
        nextStart = nil
    end

    return thickness, enterTrace, nextStart
end

--- Estimate blocker thickness between the listener and a sound source.
-- @tparam Vector listenerPos Listener position.
-- @tparam Vector sourcePos Sound source position.
-- @tparam[opt] Entity sourceEntity Optional entity used as the sound source.
-- @treturn number Estimated thickness in Hammer units.
-- @treturn number Blocker count along the path.
-- @treturn table|nil Initial trace hit data for debug use.
local function EstimateOcclusionThickness(listenerPos, sourcePos, sourceEntity)
    if ( !isvector(listenerPos) or !isvector(sourcePos) ) then
        return 0, 0, nil
    end

    local direction = sourcePos - listenerPos
    local distance = direction:Length()
    if ( distance <= 1 ) then
        return 0, 0, nil
    end

    direction:Normalize()

    local thickness = 0
    local blockers = 0
    local firstTrace
    local currentStart = listenerPos

    for _ = 1, OCCLUSION_MAX_BLOCKERS do
        local blockThickness, enterTrace, nextStart = EstimateOcclusionBlocker(currentStart, sourcePos, direction, sourceEntity)
        if ( !firstTrace ) then
            firstTrace = enterTrace
        end

        if ( blockThickness <= 0 ) then
            break
        end

        blockers = blockers + 1
        thickness = thickness + blockThickness

        if ( !isvector(nextStart) ) then
            break
        end

        currentStart = nextStart

        if ( currentStart:DistToSqr(sourcePos) <= (OCCLUSION_TRACE_OFFSET * OCCLUSION_TRACE_OFFSET) ) then
            break
        end
    end

    return thickness, blockers, firstTrace
end

--- Resolve occlusion multiplier for a positional sound source.
-- @tparam Vector sourcePos Sound source position.
-- @tparam[opt] Entity sourceEntity Optional entity used as the sound source.
-- @tparam[opt] string layerName Layer label for debug output.
-- @treturn number Volume multiplier.
-- @treturn number Estimated thickness in Hammer units.
local function GetOcclusionMultiplier(sourcePos, sourceEntity, layerName)
    if ( GetOcclusionEnabled() != true ) then
        return 1, 0
    end

    if ( !GetScapesBoolOption("scapes.occlusion_enabled", true) ) then
        return 1, 0
    end

    local strength = GetScapesNumberOption("scapes.occlusion_strength", 1, 0, 2)
    if ( strength <= 0 ) then
        return 1, 0
    end

    local listenerPos = GetListenerPosition()
    if ( !isvector(listenerPos) or !isvector(sourcePos) ) then
        return 1, 0
    end

    local thickness, blockers, trace = EstimateOcclusionThickness(listenerPos, sourcePos, sourceEntity)
    if ( thickness <= 0 ) then
        return 1, 0
    end

    local scale = GetOcclusionThicknessScale()
    local maxLoss = GetOcclusionMaxVolumeLoss()
    local ratio = math.Clamp((thickness / scale) * strength, 0, 1)
    local blockerRatio = math.Clamp(blockers * OCCLUSION_MIN_BLOCK_RATIO * strength, 0, 1)
    ratio = math.max(ratio, blockerRatio)
    local multiplier = 1 - (ratio * maxLoss)

    if ( IsDebugOverlayEnabled() ) then
        local midPoint = LerpVector(0.5, listenerPos, sourcePos)
        debugoverlay.Line(sourcePos, listenerPos, 0.15, Color(255, 170, 70, 80), true)
        debugoverlay.Text(midPoint + Vector(0, 0, 8), string.format("occ %.0fu b%d x%.2f %s", thickness, blockers, multiplier, tostring(layerName or "")), 0.15, true)

        if ( istable(trace) and isvector(trace.HitPos) ) then
            debugoverlay.Sphere(trace.HitPos, 6, 0.15, Color(255, 120, 70, 90), true)
        end
    end

    return math.Clamp(multiplier, 0, 1), thickness
end

local ResolveEventPosition

--- Draw debugoverlay markers for a client-side playback event.
-- @tparam table event Event payload.
-- @tparam string soundPath Resolved sound path.
-- @tparam Vector|nil fallbackPosition Optional fallback position.
local function DebugDrawClientEvent(event, soundPath, fallbackPosition)
    if ( !IsDebugOverlayEnabled() ) then return end

    local spatial = istable(event and event.spatial) and event.spatial or {mode = "ambient"}
    local position = fallbackPosition
    if ( !isvector(position) ) then
        position = ResolveEventPosition(event)
    end

    local localPlayer = ax.client
    if ( !isvector(position) and IsValid(localPlayer) ) then
        position = localPlayer:EyePos()
    end

    if ( !isvector(position) ) then return end

    local mode = tostring(spatial.mode or "ambient")
    local label = string.format("%s [%s]", tostring(event.layerName or event.kind or "event"), mode)
    local color = tostring(event.kind or "random") == "stinger" and Color(255, 150, 80, 70) or Color(80, 190, 255, 70)

    debugoverlay.Sphere(position, 14, 1.2, color, true)
    debugoverlay.Text(position + Vector(0, 0, 16), label, 1.2, true)
    debugoverlay.Text(position + Vector(0, 0, 28), tostring(soundPath or "?"), 1.2, true)

    if ( IsValid(localPlayer) ) then
        debugoverlay.Line(position, localPlayer:EyePos(), 0.2, color, true)
    end
end

--- Resolve sound path from event payload.
-- @tparam table event Event payload.
-- @treturn string|nil Sound path.
local function ResolveEventPath(event)
    if ( isstring(event.soundPath) and event.soundPath != "" ) then
        return event.soundPath
    end

    local state = ax.scapes.clientState
    if ( !istable(state.definition) ) then return nil end

    local key = tonumber(event.soundKey)
    if ( !isnumber(key) ) then return nil end

    local tableRef = state.definition.soundKeyToPath
    if ( !istable(tableRef) ) then return nil end

    return tableRef[key]
end

--- Resolve event world position when available.
-- @tparam table event Event payload.
-- @treturn Vector|nil World position.
ResolveEventPosition = function(event)
    local spatial = event.spatial
    if ( !istable(spatial) ) then return nil end

    if ( istable(spatial.pos) ) then
        return ax.scapes:DeserializeVector(spatial.pos)
    end

    if ( spatial.mode == "entity" and isnumber(spatial.entIndex) ) then
        local ent = Entity(spatial.entIndex)
        if ( IsValid(ent) ) then
            return ent:GetPos()
        end
    end

    return nil
end

--- Check per-layer limits for a queued event.
-- @tparam table event Event payload.
-- @treturn boolean True when event should be played.
local function PassesEventLimits(event)
    local state = ax.scapes.clientState
    local layerId = tostring(event.layerId or event.layerName or "unknown")

    state.layerHistory[layerId] = state.layerHistory[layerId] or {}
    local history = state.layerHistory[layerId]

    local nowTime = CurTime()
    for i = #history, 1, -1 do
        if ( nowTime - history[i].time > 2 ) then
            table.remove(history, i)
        end
    end

    local limit = istable(event.limit) and event.limit or {}
    local maxInstances = math.max(1, math.floor(tonumber(limit.instance) or 1))

    local activeCount = 0
    for i = 1, #history do
        if ( nowTime - history[i].time <= 0.6 ) then
            activeCount = activeCount + 1
        end
    end

    if ( activeCount >= maxInstances ) then
        return false
    end

    local blockDistance = math.max(0, tonumber(limit.blockDistance) or 0)
    if ( blockDistance > 0 ) then
        local pos = ResolveEventPosition(event)
        if ( isvector(pos) ) then
            local blockDistanceSqr = blockDistance * blockDistance

            for i = 1, #history do
                if ( isvector(history[i].pos) and history[i].pos:DistToSqr(pos) <= blockDistanceSqr ) then
                    return false
                end
            end
        end
    end

    history[#history + 1] = {
        time = nowTime,
        pos = ResolveEventPosition(event),
    }

    return true
end

--- Play one scheduled random or stinger event.
-- @tparam table event Event payload.
local function PlayEvent(event)
    local soundPath = ResolveEventPath(event)
    if ( !isstring(soundPath) or soundPath == "" ) then
        ax.scapes:LogWarning("Skipping event with missing sound path for layer:", tostring(event and event.layerName or "unknown"))
        return
    end

    if ( !PassesEventLimits(event) ) then
        ax.scapes:LogDebug("Event blocked by limits:", tostring(event.layerName or event.layerId or "unknown"))
        return
    end

    local volume = math.Clamp(tonumber(event.volume) or 1, 0, 1)
    local pitch = math.Clamp(tonumber(event.pitch) or 100, 20, 255)
    local spatial = istable(event.spatial) and event.spatial or { mode = "ambient" }

    volume = volume * GetTagMultiplier(event.tags) * GetClientVolumeMultiplier(tostring(event.kind or "random"), spatial.mode)
    if ( volume <= 0 ) then
        ax.scapes:LogDebug("Event suppressed by local volume settings:", tostring(event.layerName or event.layerId or "unknown"))
        return
    end

    local soundLevel = math.Clamp(tonumber(spatial.soundLevel) or 75, 0, 140)

    if ( spatial.mode == "ambient" ) then
        local client = ax.client
        if ( ax.util:IsValidPlayer(client) ) then
            client:EmitSound(soundPath, soundLevel, pitch, volume, CHAN_STATIC)
            DebugDrawClientEvent(event, soundPath, client:EyePos())
            ax.scapes:LogDebug("Played ambient event:", tostring(event.layerName or "unknown"), "vol", string.format("%.2f", volume))
        end

        return
    end

    if ( spatial.mode == "entity" and isnumber(spatial.entIndex) ) then
        local ent = Entity(math.floor(spatial.entIndex))
        if ( IsValid(ent) ) then
            local occlusionMultiplier = GetOcclusionMultiplier(ent:GetPos(), ent, event.layerName)
            volume = volume * occlusionMultiplier
            if ( volume <= 0 ) then return end

            ent:EmitSound(soundPath, soundLevel, pitch, volume, CHAN_STATIC)
            DebugDrawClientEvent(event, soundPath, ent:GetPos())
            ax.scapes:LogDebug("Played entity event:", tostring(event.layerName or "unknown"), "ent", tostring(spatial.entIndex), "vol", string.format("%.2f", volume))
            return
        end

        ax.scapes:LogDebug("Entity event fallback (invalid entity):", tostring(spatial.entIndex))
    end

    local pos = ResolveEventPosition(event)
    if ( isvector(pos) ) then
        local occlusionMultiplier, thickness = GetOcclusionMultiplier(pos, nil, event.layerName)
        volume = volume * occlusionMultiplier
        if ( volume <= 0 ) then return end

        sound.Play(soundPath, pos, soundLevel, pitch, volume)
        DebugDrawClientEvent(event, soundPath, pos)
        ax.scapes:LogDebug("Played positional event:", tostring(event.layerName or "unknown"), "at", tostring(pos), "occ", string.format("%.0f", thickness), "vol", string.format("%.2f", volume))
        return
    end

    local client = ax.client
    if ( ax.util:IsValidPlayer(client) ) then
        client:EmitSound(soundPath, soundLevel, pitch, volume, CHAN_STATIC)
        DebugDrawClientEvent(event, soundPath, client:EyePos())
        ax.scapes:LogDebug("Played fallback local event:", tostring(event.layerName or "unknown"))
    end
end

--- Insert an event into a sorted queue.
-- @tparam table event Event payload.
local function QueueEvent(event)
    local state = ax.scapes.clientState

    local inserted = false
    for i = 1, #state.queue do
        local queued = state.queue[i]
        if ( event.playAtClient < queued.playAtClient ) then
            table.insert(state.queue, i, event)
            inserted = true
            break
        end
    end

    if ( !inserted ) then
        state.queue[#state.queue + 1] = event
    end
end

--- Convert and queue batch events from server time.
-- @tparam number serverNow Server current time.
-- @tparam table events Event array.
function ax.scapes:ClientQueueEvents(serverNow, events)
    local state = self.clientState
    if ( !istable(events) or !events[1] ) then return end

    local offset = tonumber(serverNow) and (serverNow - CurTime()) or state.serverOffset

    state.serverOffset = offset

    for i = 1, #events do
        local incoming = events[i]
        if ( !istable(incoming) ) then continue end

        local eventId = tonumber(incoming.eventId)
        if ( !isnumber(eventId) ) then continue end

        if ( state.playedEventIds[eventId] ) then
            continue
        end

        local event = table.Copy(incoming)
        event.playAtClient = (tonumber(event.playAt) or CurTime()) - offset

        state.playedEventIds[eventId] = true
        QueueEvent(event)
    end

    self:LogDebug("Queued", #events, "event(s). Queue length:", #state.queue)
end

--- Start a loop runtime and load its channel.
-- @tparam table loop Loop payload.
local function StartLoop(loop)
    local state = ax.scapes.clientState

    local runtime = {
        id = loop.id,
        name = loop.name,
        soundPath = loop.soundPath,
        soundKey = loop.soundKey,
        baseVolume = math.Clamp(tonumber(loop.volume) or 0.5, 0, 1),
        currentVolume = 0,
        pitch = math.Clamp(tonumber(loop.pitch) or 100, 20, 255),
        tags = istable(loop.tags) and table.Copy(loop.tags) or {},
        spatial = istable(loop.spatial) and table.Copy(loop.spatial) or {mode = "ambient"},
        ctx = state.context,
        drift = istable(loop.drift) and table.Copy(loop.drift) or {
            volume = 0,
            pitch = 0,
            period = 12,
            phase = 0,
        },
        fadeIn = math.max(0, tonumber(loop.fadeIn) or 1),
        fadeOut = math.max(0, tonumber(loop.fadeOut) or state.fadeOut),
        fadingOut = false,
        fadeOutStart = 0,
        startTime = CurTime(),
        channel = nil,
        is3D = false,
        occlusionVolume = 1,
        occlusionNextSample = 0,
    }

    local soundPath = runtime.soundPath
    if ( (!isstring(soundPath) or soundPath == "") and isnumber(runtime.soundKey) and istable(state.definition and state.definition.soundKeyToPath) ) then
        soundPath = state.definition.soundKeyToPath[runtime.soundKey]
        runtime.soundPath = soundPath
    end

    if ( !isstring(soundPath) or soundPath == "" ) then
        ax.scapes:LogWarning("Skipping loop with missing sound path:", tostring(runtime.name or runtime.id))
        return
    end

    local flags = "noplay noblock"
    if ( runtime.spatial.mode == "positional" or runtime.spatial.mode == "relative" or runtime.spatial.mode == "entity" ) then
        flags = "3d noplay noblock"
        runtime.is3D = true
    end

    state.loops[runtime.id] = runtime
    ax.scapes:LogDebug("Starting loop:", tostring(runtime.name or runtime.id), "mode", tostring(runtime.spatial.mode))

    sound.PlayFile("sound/" .. soundPath, flags, function(channel)
        if ( !channel ) then
            state.loops[runtime.id] = nil
            ax.scapes:LogWarning("Failed to load loop channel:", tostring(runtime.name or runtime.id), tostring(soundPath))
            return
        end

        local current = state.loops[runtime.id]
        if ( !current or current != runtime ) then
            channel:Stop()
            return
        end

        runtime.channel = channel

        if ( channel.EnableLooping ) then
            channel:EnableLooping(true)
        end

        if ( runtime.is3D ) then
            local pos = ResolveLoopPosition(runtime)
            if ( isvector(pos) and channel.SetPos ) then
                channel:SetPos(pos)
            end
        end

        if ( channel.SetVolume ) then
            channel:SetVolume(0)
        end

        if ( channel.Play ) then
            channel:Play()
        end

        local debugPos = ResolveLoopPosition(runtime)
        DebugDrawClientEvent({
            kind = "loop",
            layerName = runtime.name,
            spatial = runtime.spatial,
        }, soundPath, debugPos)
    end)
end

--- Flag all active loops to fade out.
-- @tparam number fadeOut Fade out duration.
local function FadeOutAllLoops(fadeOut)
    local state = ax.scapes.clientState
    local moved = 0

    for id, runtime in pairs(state.loops) do
        runtime.fadingOut = true
        runtime.fadeOut = math.max(0, tonumber(fadeOut) or runtime.fadeOut or 1)
        runtime.fadeOutStart = CurTime()
        state.fadingLoops[id] = runtime
        state.loops[id] = nil
        moved = moved + 1
    end

    if ( moved > 0 ) then
        ax.scapes:LogDebug("Fading out", moved, "loop(s) over", string.format("%.2f", math.max(0, tonumber(fadeOut) or 0)), "s")
    end
end

--- Stop and clear all loops immediately.
local function StopAllLoopsImmediate()
    local state = ax.scapes.clientState
    local count = table.Count(state.loops) + table.Count(state.fadingLoops)

    for _, runtime in pairs(state.loops) do
        StopLoopChannel(runtime)
    end

    for _, runtime in pairs(state.fadingLoops) do
        StopLoopChannel(runtime)
    end

    state.loops = {}
    state.fadingLoops = {}

    if ( count > 0 ) then
        ax.scapes:LogDebug("Stopped", count, "loop(s) immediately.")
    end
end

--- Update all active loop channels.
local function ThinkLoops()
    local state = ax.scapes.clientState
    local frameFraction = math.min(1, FrameTime() * 6)

    --- Internal updater for one runtime bucket.
    -- @tparam table bucket Runtime table map.
    -- @tparam boolean allowRemove Whether runtime may be removed.
    local function UpdateBucket(bucket, allowRemove)
        for id, runtime in pairs(bucket) do
            local channel = runtime.channel
            if ( !channel ) then
                if ( allowRemove and runtime.fadingOut and CurTime() - runtime.fadeOutStart > runtime.fadeOut + 1 ) then
                    bucket[id] = nil
                end
                continue
            end

            local fadeMultiplier = GetFadeMultiplier(runtime)

            if ( runtime.fadingOut and fadeMultiplier <= 0 ) then
                StopLoopChannel(runtime)
                bucket[id] = nil
                continue
            end

            local driftScale = GetScapesNumberOption("scapes.loop_drift_scale", 1, 0, 2)
            local wave = math.sin(((CurTime() - state.sessionStartAt) / math.max(0.1, runtime.drift.period)) + runtime.drift.phase)
            local driftVolume = runtime.baseVolume * runtime.drift.volume * driftScale * wave
            runtime.occlusionVolume = math.Clamp(tonumber(runtime.occlusionVolume) or 1, 0, 1)
            runtime.occlusionNextSample = tonumber(runtime.occlusionNextSample) or 0

            if ( runtime.is3D and CurTime() >= runtime.occlusionNextSample ) then
                local pos = ResolveLoopPosition(runtime)
                runtime.occlusionVolume = 1

                if ( isvector(pos) ) then
                    local sourceEntity
                    if ( runtime.spatial.mode == "entity" and isnumber(runtime.spatial.entIndex) ) then
                        sourceEntity = Entity(math.floor(runtime.spatial.entIndex))
                        if ( !IsValid(sourceEntity) ) then
                            sourceEntity = nil
                        end
                    end

                    runtime.occlusionVolume = GetOcclusionMultiplier(pos, sourceEntity, runtime.name)
                end

                runtime.occlusionNextSample = CurTime() + OCCLUSION_RECHECK_INTERVAL
            end

            local targetVolume = math.Clamp((runtime.baseVolume + driftVolume) * GetTagMultiplier(runtime.tags) * GetClientVolumeMultiplier("loop", runtime.spatial and runtime.spatial.mode) * runtime.occlusionVolume * fadeMultiplier, 0, 1)
            runtime.currentVolume = ax.util:ApproachNumber(frameFraction, runtime.currentVolume, targetVolume, {
                linear = true,
                transition = "linear",
            })

            if ( channel.SetVolume ) then
                channel:SetVolume(runtime.currentVolume)
            end

            if ( channel.SetPlaybackRate ) then
                local driftPitch = runtime.drift.pitch * driftScale * wave
                local playbackRate = math.Clamp((runtime.pitch + driftPitch) / 100, 0.2, 3)
                channel:SetPlaybackRate(playbackRate)
            end

            if ( runtime.is3D and channel.SetPos ) then
                local pos = ResolveLoopPosition(runtime)
                if ( isvector(pos) ) then
                    channel:SetPos(pos)
                end
            end
        end
    end

    UpdateBucket(state.loops, false)
    UpdateBucket(state.fadingLoops, true)
end

--- Dispatch due queue events.
local function ThinkQueue()
    local state = ax.scapes.clientState
    if ( !state.queue[1] ) then return end

    local nowTime = CurTime()

    while ( state.queue[1] and state.queue[1].playAtClient <= nowTime + 0.01 ) do
        local event = table.remove(state.queue, 1)
        PlayEvent(event)
    end
end

--- Activate a new client session payload.
-- @tparam number sessionId Session id.
-- @tparam string scapeId Scape id.
-- @tparam number serverNow Server current time.
-- @tparam number startAt Session start time on server.
-- @tparam number fadeIn Fade in duration.
-- @tparam number fadeOut Fade out duration.
-- @tparam boolean pauseLegacyAmbient Pause legacy ambient music.
-- @tparam table ctxPayload Serialized context.
-- @tparam table definition Resolved definition payload.
-- @tparam table events Initial event list.
function ax.scapes:ClientActivate(sessionId, scapeId, serverNow, startAt, fadeIn, fadeOut, pauseLegacyAmbient, ctxPayload, definition, events)
    local state = self.clientState

    sessionId = tonumber(sessionId)
    if ( !isnumber(sessionId) ) then
        self:LogWarning("ClientActivate rejected: invalid session id payload.")
        return
    end

    local oldFade = math.max(0, tonumber(state.fadeOut) or 1)
    FadeOutAllLoops(oldFade)

    state.activeSessionId = sessionId
    state.activeScapeId = tostring(scapeId or "")
    state.activePriority = math.floor(tonumber(definition and definition.priority) or 0)
    state.activeDSPPreset = tonumber(definition and definition.dspPreset) and math.floor(tonumber(definition.dspPreset)) or nil
    state.activePauseLegacyAmbient = pauseLegacyAmbient == true
    state.serverOffset = tonumber(serverNow) and (serverNow - CurTime()) or 0
    state.sessionStartAt = (tonumber(startAt) or CurTime()) - state.serverOffset
    state.fadeOut = math.max(0, tonumber(fadeOut) or 1)
    state.context = self:DeserializeContext(ctxPayload)
    state.definition = istable(definition) and table.Copy(definition) or nil
    state.queue = {}
    state.playedEventIds = {}
    state.layerHistory = {}

    self:LogDebug("ClientActivate:", tostring(scapeId), "(session", tostring(sessionId) .. ")")
    self:LogDebug(
        "Client activate details:",
        "fadeIn=" .. string.format("%.2f", math.max(0, tonumber(fadeIn) or 0)),
        "fadeOut=" .. string.format("%.2f", math.max(0, tonumber(fadeOut) or 0)),
        "dspPreset=" .. tostring(state.activeDSPPreset or "none"),
        "pauseLegacyAmbient=" .. tostring(state.activePauseLegacyAmbient)
    )

    local loops = istable(definition and definition.loops) and definition.loops or {}
    for i = 1, #loops do
        local loop = table.Copy(loops[i])
        loop.fadeIn = math.max(0, tonumber(fadeIn) or 1)
        loop.fadeOut = math.max(0, tonumber(fadeOut) or 1)

        StartLoop(loop)
    end

    self:ClientQueueEvents(serverNow, events)

    if ( IsDebugOverlayEnabled() ) then
        for key, position in pairs(state.context.positions or {}) do
            if ( isvector(position) ) then
                debugoverlay.Sphere(position, 20, 1.5, Color(120, 255, 120, 50), true)
                debugoverlay.Text(position + Vector(0, 0, 18), "ctx pos[" .. tostring(key) .. "]", 1.5, true)
            end
        end

        for key, entIndex in pairs(state.context.entities or {}) do
            local ent = Entity(math.floor(tonumber(entIndex) or -1))
            if ( IsValid(ent) ) then
                local pos = ent:GetPos()
                debugoverlay.Sphere(pos, 20, 1.5, Color(255, 180, 90, 50), true)
                debugoverlay.Text(pos + Vector(0, 0, 18), "ctx ent[" .. tostring(key) .. "]", 1.5, true)
            end
        end
    end
end

--- Apply an incremental schedule payload.
-- @tparam number sessionId Session id.
-- @tparam number serverNow Server current time.
-- @tparam table events Event payload array.
function ax.scapes:ClientSchedule(sessionId, serverNow, events)
    local state = self.clientState
    if ( tonumber(sessionId) != state.activeSessionId ) then
        self:LogDebug("Ignoring stale schedule payload for session", tostring(sessionId), "(active", tostring(state.activeSessionId) .. ")")
        return
    end

    self:ClientQueueEvents(serverNow, events)
end

--- Apply a stinger trigger payload.
-- @tparam number sessionId Session id.
-- @tparam number serverNow Server current time.
-- @tparam table event Single event payload.
function ax.scapes:ClientTrigger(sessionId, serverNow, event)
    local state = self.clientState
    if ( tonumber(sessionId) != state.activeSessionId ) then
        self:LogDebug("Ignoring stale trigger payload for session", tostring(sessionId), "(active", tostring(state.activeSessionId) .. ")")
        return
    end

    self:ClientQueueEvents(serverNow, {event})
end

--- Deactivate the current client session.
-- @tparam number sessionId Session id.
-- @tparam number serverNow Server current time.
-- @tparam number fadeOut Fade out duration.
function ax.scapes:ClientDeactivate(sessionId, serverNow, fadeOut)
    local state = self.clientState

    if ( tonumber(sessionId) != state.activeSessionId ) then
        self:LogDebug("Ignoring stale deactivate payload for session", tostring(sessionId), "(active", tostring(state.activeSessionId) .. ")")
        return
    end

    state.activeSessionId = 0
    state.activeScapeId = nil
    state.activePriority = 0
    state.activeDSPPreset = nil
    state.activePauseLegacyAmbient = false
    state.queue = {}
    state.playedEventIds = {}
    state.layerHistory = {}

    self:LogDebug("ClientDeactivate: session", tostring(sessionId))

    FadeOutAllLoops(math.max(0, tonumber(fadeOut) or state.fadeOut))
end

--- Per-frame client update.
function ax.scapes:ClientThink()
    ThinkLoops()
    ThinkQueue()
end

--- Stop all runtime audio and clear client session state.
function ax.scapes:ClientShutdown()
    local state = self.clientState

    state.activeSessionId = 0
    state.activeScapeId = nil
    state.activePriority = 0
    state.activeDSPPreset = nil
    state.activePauseLegacyAmbient = false
    state.queue = {}
    state.playedEventIds = {}
    state.layerHistory = {}

    StopAllLoopsImmediate()
    self:LogDebug("Client scapes runtime shutdown complete.")
end

--- Set a client-side global mix multiplier.
-- @tparam string tag Mix tag.
-- @tparam number volume Volume multiplier.
function ax.scapes:ClientSetGlobalMix(tag, volume)
    tag = tostring(tag or "")
    if ( tag == "" ) then return end

    self.clientState.mix[tag] = math.Clamp(tonumber(volume) or 1, 0, 2)
    self:LogDebug("Updated global mix tag:", tag, "=", tostring(self.clientState.mix[tag]))
end

--- Toggle client debug overlay.
-- @tparam boolean enabled True to enable overlay.
function ax.scapes:SetDebugEnabled(enabled)
    self.clientState.debug = enabled == true
    self:Log("Client debug overlay " .. (self.clientState.debug and "enabled" or "disabled") .. ".")
end

--- Check whether active scape requests legacy ambient pause.
-- @treturn boolean True when ambient should pause.
function ax.scapes:ShouldPauseLegacyAmbient()
    local state = self.clientState
    if ( !GetScapesBoolOption("scapes.pause_legacy_music", true) ) then
        return false
    end

    if ( !GetScapesBoolOption("scapes.enabled", true) ) then
        return false
    end

    return state.activeSessionId > 0 and state.activePauseLegacyAmbient == true
end

--- Draw a lightweight scapes debug overlay.
function ax.scapes:DrawDebugOverlay()
    local state = self.clientState
    if ( !IsDebugOverlayEnabled() ) then return end

    local x = 10
    local y = ScrH() / 2

    draw.SimpleText("SCAPES DEBUG", "DermaDefaultBold", x, y, Color(150, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    x, y = x + 10, y + 20

    draw.SimpleText("Session: " .. tostring(state.activeSessionId), "DermaDefault", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    y = y + 15

    draw.SimpleText("Scape: " .. tostring(state.activeScapeId or "none"), "DermaDefault", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    y = y + 15

    draw.SimpleText("Priority: " .. tostring(state.activePriority or 0), "DermaDefault", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    y = y + 15

    draw.SimpleText("DSP: " .. tostring(state.activeDSPPreset or "none"), "DermaDefault", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    y = y + 15

    draw.SimpleText("Queue: " .. tostring(#state.queue), "DermaDefault", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    y = y + 15

    local loopCount = table.Count(state.loops)
    local fadingCount = table.Count(state.fadingLoops)
    draw.SimpleText("Loops: " .. tostring(loopCount) .. " (fading: " .. tostring(fadingCount) .. ")", "DermaDefault", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    x, y = x + 10, y + 15

    local shown = 0
    local maxShown = math.floor(GetScapesNumberOption("scapes.debug_events", 5, 1, 20))
    for _, event in ipairs(state.queue) do
        shown = shown + 1
        if ( shown > maxShown ) then break end

        local inTime = math.max(0, event.playAtClient - CurTime())
        draw.SimpleText(string.format("%s in %.2fs", tostring(event.layerName or "event"), inTime), "DermaDefault", x, y, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        y = y + 15
    end
end
