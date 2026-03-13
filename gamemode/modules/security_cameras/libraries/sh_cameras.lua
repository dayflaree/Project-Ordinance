--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

require("niknaks")

local CAMERA_MODEL = "models/props_blackmesa/securitycamera.mdl"
local STATION_MODEL = "models/props_blackmesa/securitystation.mdl"
local STATION_MODEL_BS = "models/props_blueshift/bs_generic/bs_securitystation.mdl"
local CAMERA_RT_BASE_SIZE = 256
local CAMERA_RT_NEAR_SIZE = 512
local CAMERA_RT_NEAR_DISTANCE_SQR = 256 ^ 2
local CAMERA_LOOP_SOUND_PATH = "riggs9162/bms/scripted/camera.ogg"
local CAMERA_LOOP_MAX_DISTANCE = 768
local CAMERA_LOOP_MAX_DISTANCE_SQR = CAMERA_LOOP_MAX_DISTANCE ^ 2
local CAMERA_LOOP_UPDATE_INTERVAL = 0.2
local CAMERA_LOOP_MAX_ACTIVE_CHANNELS = 8
local CAMERA_LOOP_BASE_VOLUME = 0.5
local CAMERA_LOOP_RETRY_DELAY = 3
local STATION_SCREEN_RANGE_DEFAULT = 128
local STATION_SCREEN_RANGE_SQR_DEFAULT = STATION_SCREEN_RANGE_DEFAULT ^ 2
local STATION_TRACE_RANGE_SQR = 2048 ^ 2
local STATION_TRACE_HIT_TOLERANCE_SQR = 12 ^ 2
local STATION_CONTEXT_CACHE_INTERVAL = 0.2
local CAMERA_MONOCHROME_CONFIG_KEY = "security.cameras.monochrome"
local STATION_INTERACT_DISTANCE_CONFIG_KEY = "security.cameras.interact_distance"

if ( CLIENT ) then
    sound.Add({
        name = "ax.security_cameras.background_tape",
        channel = CHAN_STATIC,
        volume = 1.0,
        level = 60,
        pitch = 100,
        sound = "fnaf/MiniDV_Tape_Eject_1.wav"
    })
end

local CAMERA_MONOCHROME_COLORMOD = {
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0,
    ["$pp_colour_contrast"] = 1,
    ["$pp_colour_colour"] = 0,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}

local STATION_SCREEN_LAYOUT = {
    {
        up = 76,
        forward = 0.55,
        right = 10,
        angleOffset = Angle(0, 90, 90),
        widthScale = 1,
        heightScale = 0.8
    },
    {
        up = 76,
        forward = 0.55,
        right = -22,
        angleOffset = Angle(0, 90, 90),
        widthScale = 1,
        heightScale = 0.8
    },
    {
        up = 76,
        forward = 0.55,
        right = 42,
        angleOffset = Angle(0, 90, 90),
        widthScale = 1,
        heightScale = 0.8
    },
    {
        up = 52.25,
        forward = 1.7,
        right = 38,
        angleOffset = Angle(0, 90, 52),
        widthScale = 1.1,
        heightScale = 0.95
    },
    {
        up = 102.6,
        forward = 10,
        right = 41,
        angleOffset = Angle(0, 90, 124.5),
        widthScale = 1.1,
        heightScale = 0.875
    },
    {
        up = 102.6,
        forward = 10,
        right = -19,
        angleOffset = Angle(0, 90, 124.5),
        widthScale = 1.1,
        heightScale = 0.875
    },
}

local mapObject = NikNaks.CurrentMap
local cameras = mapObject:FindByModel(CAMERA_MODEL)
local stations1 = mapObject:FindStaticByModel(STATION_MODEL)
local stations2 = mapObject:FindStaticByModel(STATION_MODEL_BS)

local function GetObjectPosition(object)
    if ( !object ) then return nil end
    if ( object.GetPos ) then
        return object:GetPos()
    end

    return object.Origin or object.origin
end

local function GetObjectAngles(object)
    if ( !object ) then return nil end
    if ( object.GetAngles ) then
        return object:GetAngles()
    end

    return object.Angles or object.angles
end

local function GetObjectRenderBounds(object)
    if ( !object or !object.GetModelRenderBounds ) then
        return nil, nil
    end

    return object:GetModelRenderBounds()
end

local function GetStationScreenPosition(position, angles, screenData)
    return position + angles:Up() * screenData.up + angles:Forward() * screenData.forward + angles:Right() * screenData.right
end

local function BuildViewerTraceFilter(viewer)
    if ( !IsValid(viewer) ) then return nil end

    local filter = { viewer }

    if ( viewer.GetVehicle ) then
        local vehicle = viewer:GetVehicle()
        if ( IsValid(vehicle) ) then
            filter[#filter + 1] = vehicle
        end
    end

    return filter
end

local function IsPositionVisibleByTrace(startPos, targetPos, traceFilter)
    if ( !startPos or !targetPos ) then return false end

    local trace = util.TraceLine({
        start = startPos,
        endpos = targetPos,
        filter = traceFilter,
        mask = MASK_VISIBLE
    })

    if ( !trace.Hit ) then
        return true
    end

    return trace.HitPos:DistToSqr(targetPos) <= STATION_TRACE_HIT_TOLERANCE_SQR
end

local function ShouldRenderMonochrome()
    if ( !CLIENT ) then return false end
    return ax.config:Get(CAMERA_MONOCHROME_CONFIG_KEY, false)
end

local function ApplyMonochromeColorModify()
    if ( !ShouldRenderMonochrome() ) then return end

    render.UpdateScreenEffectTexture()
    DrawColorModify(CAMERA_MONOCHROME_COLORMOD)
end

local function GetStationScreenRangeSqr()
    local distance = STATION_SCREEN_RANGE_DEFAULT
    if ( ax.config and ax.config.Get ) then
        distance = ax.config:Get(STATION_INTERACT_DISTANCE_CONFIG_KEY, STATION_SCREEN_RANGE_DEFAULT)
    end

    distance = tonumber(distance) or STATION_SCREEN_RANGE_DEFAULT
    if ( distance <= 0 ) then
        distance = STATION_SCREEN_RANGE_DEFAULT
    end

    return distance * distance
end

function MODULE:GetCameraByID(uniqueID)
    if ( !isstring(uniqueID) or uniqueID == "" ) then return nil end
    return self.cameraLookup and self.cameraLookup[uniqueID]
end

function MODULE:GetDefaultStationCamera(stationUniqueID, screenIndex)
    if ( !self.cameras or #self.cameras == 0 ) then return nil end

    local hash = tonumber(util.CRC(tostring(stationUniqueID) .. ":" .. tostring(screenIndex))) or 0
    local cameraIndex = (hash % #self.cameras) + 1

    return self.cameras[cameraIndex]
end

function MODULE:EnsureStationCameraSelections()
    self.stationCameraSelections = self.stationCameraSelections or {}

    for _, stationData in ipairs(self.stations or {}) do
        local stationUniqueID = stationData.uniqueID
        local selections = self.stationCameraSelections[stationUniqueID] or {}

        for screenIndex = 1, #STATION_SCREEN_LAYOUT do
            local cameraUniqueID = selections[screenIndex]
            local cameraData = self:GetCameraByID(cameraUniqueID)

            if ( !cameraData ) then
                local fallbackCamera = self:GetDefaultStationCamera(stationUniqueID, screenIndex)
                selections[screenIndex] = fallbackCamera and fallbackCamera.uniqueID or nil
            end
        end

        self.stationCameraSelections[stationUniqueID] = selections
    end
end

function MODULE:SetStationCameraSelection(stationUniqueID, screenIndex, cameraUniqueID)
    screenIndex = tonumber(screenIndex)
    if ( !isstring(stationUniqueID) ) then return false end
    if ( !screenIndex ) then return false end
    if ( screenIndex < 1 or screenIndex > #STATION_SCREEN_LAYOUT ) then return false end

    local cameraData = self:GetCameraByID(cameraUniqueID)
    if ( !cameraData ) then return false end

    self.stationCameraSelections = self.stationCameraSelections or {}
    self.stationCameraSelections[stationUniqueID] = self.stationCameraSelections[stationUniqueID] or {}
    
    local oldCameraID = self.stationCameraSelections[stationUniqueID][screenIndex]
    if ( oldCameraID != cameraData.uniqueID ) then
        self.stationCameraSelections[stationUniqueID][screenIndex] = cameraData.uniqueID
        
        -- Set blackout timer for 1 second on this specific screen
        if ( CLIENT ) then
            self.stationScreenBlackouts = self.stationScreenBlackouts or {}
            self.stationScreenBlackouts[stationUniqueID] = self.stationScreenBlackouts[stationUniqueID] or {}
            self.stationScreenBlackouts[stationUniqueID][screenIndex] = CurTime() + 0.1
        end
    end

    return true
end

function MODULE:GetStationCameraData(stationData, screenIndex)
    if ( !stationData ) then return nil end
    screenIndex = tonumber(screenIndex)
    if ( !screenIndex ) then return nil end

    local stationUniqueID = stationData.uniqueID
    local selectedCameraUniqueID

    local selections = self.stationCameraSelections and self.stationCameraSelections[stationUniqueID]
    if ( istable(selections) ) then
        selectedCameraUniqueID = selections[screenIndex]
    end

    local cameraData = self:GetCameraByID(selectedCameraUniqueID)
    if ( cameraData ) then
        return cameraData
    end

    cameraData = self:GetDefaultStationCamera(stationUniqueID, screenIndex)
    if ( cameraData ) then
        self.stationCameraSelections = self.stationCameraSelections or {}
        self.stationCameraSelections[stationUniqueID] = self.stationCameraSelections[stationUniqueID] or {}
        self.stationCameraSelections[stationUniqueID][screenIndex] = cameraData.uniqueID
    end

    return cameraData
end

function MODULE:GetStationScreens(stationData)
    local object = stationData and stationData.object
    local position = GetObjectPosition(object)
    local angles = GetObjectAngles(object)

    if ( !position or !angles ) then
        return {}, nil, nil
    end

    local screens = {}
    for screenIndex, screenData in ipairs(STATION_SCREEN_LAYOUT) do
        screens[#screens + 1] = {
            index = screenIndex,
            position = GetStationScreenPosition(position, angles, screenData),
            angles = angles + screenData.angleOffset,
            widthScale = screenData.widthScale,
            heightScale = screenData.heightScale,
            cameraData = self:GetStationCameraData(stationData, screenIndex)
        }
    end

    return screens, position, angles
end

function MODULE:IsPositionNearAnyStationScreen(position)
    if ( !position ) then return false end

    local rangeSqr = GetStationScreenRangeSqr()

    for _, stationData in ipairs(self.stations or {}) do
        local object = stationData.object
        local stationPosition = GetObjectPosition(object)
        local stationAngles = GetObjectAngles(object)
        if ( !stationPosition or !stationAngles ) then continue end

        for _, screenData in ipairs(STATION_SCREEN_LAYOUT) do
            local screenPosition = GetStationScreenPosition(stationPosition, stationAngles, screenData)
            if ( position:DistToSqr(screenPosition) <= rangeSqr ) then
                return true
            end
        end
    end

    return false
end

function MODULE:GetViewerStationContext(viewer)
    if ( !IsValid(viewer) ) then
        return false, {}, {}
    end

    self._viewerStationContextCache = self._viewerStationContextCache or {}

    local cacheKey = SERVER and viewer:EntIndex() or 0
    local curTime = CurTime()
    local cached = self._viewerStationContextCache[cacheKey]

    if ( cached and cached.expiresAt > curTime ) then
        return cached.hasStationContext, cached.nearStations, cached.visibleStations
    end

    local nearStations = {}
    local visibleStations = {}
    local hasStationContext = false

    local rangeSqr = GetStationScreenRangeSqr()
    local viewerPos = viewer:GetPos()
    local eyePos = viewer.EyePos and viewer:EyePos() or viewerPos
    local traceFilter = BuildViewerTraceFilter(viewer)

    for _, stationData in ipairs(self.stations or {}) do
        local stationUniqueID = stationData.uniqueID
        if ( !stationUniqueID ) then continue end

        local object = stationData.object
        local stationPosition = GetObjectPosition(object)
        local stationAngles = GetObjectAngles(object)
        if ( !stationPosition or !stationAngles ) then continue end

        local stationIsNear = false
        local stationIsVisible = false

        for _, screenData in ipairs(STATION_SCREEN_LAYOUT) do
            local screenPosition = GetStationScreenPosition(stationPosition, stationAngles, screenData)

            if ( !stationIsNear and viewerPos:DistToSqr(screenPosition) <= rangeSqr ) then
                stationIsNear = true
            end

            if ( !stationIsVisible and eyePos:DistToSqr(screenPosition) <= STATION_TRACE_RANGE_SQR ) then
                if ( IsPositionVisibleByTrace(eyePos, screenPosition, traceFilter) ) then
                    stationIsVisible = true
                end
            end

            if ( stationIsNear and stationIsVisible ) then
                break
            end
        end

        if ( stationIsNear and stationIsVisible ) then
            nearStations[stationUniqueID] = true
            visibleStations[stationUniqueID] = true
            hasStationContext = true
        end
    end

    self._viewerStationContextCache[cacheKey] = {
        expiresAt = curTime + STATION_CONTEXT_CACHE_INTERVAL,
        hasStationContext = hasStationContext,
        nearStations = nearStations,
        visibleStations = visibleStations
    }

    return hasStationContext, nearStations, visibleStations
end

function MODULE:GetRenderableScreensForViewer(viewer, nearStations, visibleStations)
    local screens = {}
    if ( !IsValid(viewer) ) then return screens end

    local viewerPos = viewer:GetPos()
    local rangeSqr = GetStationScreenRangeSqr()

    for _, stationData in ipairs(self.stations or {}) do
        local stationUniqueID = stationData.uniqueID
        local stationIsNear = stationUniqueID and nearStations[stationUniqueID] == true
        local stationIsVisible = stationUniqueID and visibleStations[stationUniqueID] == true
        if ( !stationIsNear or !stationIsVisible ) then continue end

        local stationScreens = self:GetStationScreens(stationData)
        for _, screen in ipairs(stationScreens) do
            if ( viewerPos:DistToSqr(screen.position) > rangeSqr ) then continue end
            screens[#screens + 1] = screen
        end
    end

    return screens
end

function MODULE:GetRenderableCamerasForViewer(viewer)
    if ( !IsValid(viewer) ) then
        return {}, {}, {}, false
    end

    local hasStationContext, nearStations, visibleStations = self:GetViewerStationContext(viewer)
    if ( !hasStationContext ) then
        return {}, nearStations, visibleStations, false
    end

    local screens = self:GetRenderableScreensForViewer(viewer, nearStations, visibleStations)
    if ( #screens == 0 ) then
        return {}, nearStations, visibleStations, true
    end

    local renderableCameras = {}
    local seen = {}
    for _, screen in ipairs(screens) do
        local cameraData = screen.cameraData
        local uniqueID = cameraData and cameraData.uniqueID
        if ( !cameraData or !isstring(uniqueID) or uniqueID == "" ) then continue end
        if ( seen[uniqueID] ) then continue end

        seen[uniqueID] = true
        renderableCameras[#renderableCameras + 1] = cameraData
    end

    return renderableCameras, nearStations, visibleStations, true
end

function MODULE:OnSchemaLoaded()
    if ( CLIENT ) then
        self:StopSecurityCameraLoopChannels()
    end

    self.cameras = {}
    self.cameraLookup = {}

    for _, camera in ipairs(cameras) do
        local cameraData = {
            object = camera,
            uniqueID = util.CRC(tostring(camera.origin) .. "_" .. tostring(camera.angles)),
            nightVision = false
        }

        table.insert(self.cameras, cameraData)
        self.cameraLookup[cameraData.uniqueID] = cameraData
    end

    self.stations = {}

    local function add(station)
        table.insert(self.stations, {
            object = station,
            uniqueID = util.CRC(tostring(station.Origin) .. "_" .. tostring(station.Angles))
        })
    end

    for _, station in ipairs(stations1) do
        add(station)
    end

    for _, station in ipairs(stations2) do
        add(station)
    end

    self.stationCameraSelections = self.stationCameraSelections or {}
    self._nextCameraRenderIndex = 1
    self._nextPVSCameraRenderIndexByClient = {}
    self._viewerStationContextCache = {}
    self._nextSecurityCameraLoopThink = 0
    self._securityCameraLoopSoundExists = nil
    self:EnsureStationCameraSelections()
end

local function GetDesiredCameraRTSize(cameraData)
    if ( !CLIENT or !IsValid(ax.client) ) then
        ax.util:PrintWarning("Client not valid, defaulting to base RT size")
        return CAMERA_RT_BASE_SIZE
    end

    local object = cameraData and cameraData.object
    if ( !object or !object.origin ) then
        ax.util:PrintWarning("Camera data is missing object or origin, defaulting to base RT size")
        return CAMERA_RT_BASE_SIZE
    end

    local distSqr = ax.client:GetPos():DistToSqr(object.origin)
    if ( distSqr <= CAMERA_RT_NEAR_DISTANCE_SQR ) then
        return CAMERA_RT_NEAR_SIZE
    end

    return CAMERA_RT_BASE_SIZE
end

local function EnsureCameraRT(cameraData)
    if ( !cameraData ) then return end

    local id = cameraData.uniqueID or util.CRC(tostring(cameraData.object.origin) .. tostring(cameraData.object.angles))
    local desiredSize = GetDesiredCameraRTSize(cameraData)
    if ( cameraData.rt and cameraData.mat and cameraData.rtSize == desiredSize ) then
        return
    end

    cameraData.rt = GetRenderTarget("ax_security_cam_" .. id .. "_" .. tostring(desiredSize), desiredSize, desiredSize)
    cameraData.mat = CreateMaterial("ax_security_cam_mat_" .. id .. "_" .. tostring(desiredSize), "UnlitGeneric", {
        ["$basetexture"] = cameraData.rt:GetName(),
        ["$translucent"] = "1"
    })
    cameraData.rtSize = desiredSize
end

local cachedCameraEntities = {}
local nextCameraEntityRefresh = 0
local function FindCameraEntity(origin)
    if ( !CLIENT or !origin ) then return nil end

    local curTime = CurTime()
    if ( curTime >= nextCameraEntityRefresh ) then
        cachedCameraEntities = ents.FindByModel(CAMERA_MODEL)
        nextCameraEntityRefresh = curTime + 1
    end

    for _, ent in ipairs(cachedCameraEntities) do
        if ( IsValid(ent) and ent:GetPos():DistToSqr(origin) < 1 ) then
            return ent
        end
    end
end

local function ResolveCameraView(cameraData)
    local object = cameraData and cameraData.object
    if ( !object ) then return nil, nil end

    local origin = object.origin
    local angles = object.angles

    local entity = FindCameraEntity(origin)
    if ( IsValid(entity) ) then
        origin = entity:GetPos()
        angles = entity:GetAngles()

        local cameraBone = entity:LookupBone("Camera")
        if ( cameraBone ) then
            local matrix = entity:GetBoneMatrix(cameraBone)
            if ( matrix ) then
                origin = matrix:GetTranslation()
                angles = matrix:GetAngles()

                angles:RotateAroundAxis(angles:Up(), 90)
                angles:RotateAroundAxis(angles:Right(), 180)
                angles:RotateAroundAxis(angles:Forward(), 180)

                origin = origin + angles:Up() * 4 + angles:Forward() * 8
            end
        end
    end

    return origin, angles
end

local function GetCameraLoopVolume(distSqr)
    local dist = math.sqrt(math.max(0, distSqr))
    local fraction = math.Clamp(1 - (dist / CAMERA_LOOP_MAX_DISTANCE), 0, 1)
    return CAMERA_LOOP_BASE_VOLUME * fraction
end

local function StopCameraLoopRuntime(runtime)
    if ( !runtime ) then return end

    local channel = runtime.channel
    if ( IsValid(channel) and channel.Stop ) then
        channel:Stop()
    end

    runtime.channel = nil
    runtime.loading = false
end

function MODULE:StopSecurityCameraLoopChannels()
    if ( !CLIENT ) then return end

    for _, runtime in pairs(self._securityCameraLoopRuntimes or {}) do
        StopCameraLoopRuntime(runtime)
    end

    self._securityCameraLoopRuntimes = {}
end

function MODULE:UpdateSecurityCameraLoopAudio()
    if ( !CLIENT ) then return end

    local curTime = CurTime()
    self._nextSecurityCameraLoopThink = self._nextSecurityCameraLoopThink or 0
    if ( self._nextSecurityCameraLoopThink > curTime ) then return end
    self._nextSecurityCameraLoopThink = curTime + CAMERA_LOOP_UPDATE_INTERVAL

    if ( !IsValid(ax.client) ) then
        self:StopSecurityCameraLoopChannels()
        return
    end

    if ( !self.cameras or #self.cameras == 0 ) then
        self:StopSecurityCameraLoopChannels()
        return
    end

    if ( self._securityCameraLoopSoundExists == nil ) then
        self._securityCameraLoopSoundExists = file.Exists("sound/" .. CAMERA_LOOP_SOUND_PATH, "GAME")
    end

    if ( !self._securityCameraLoopSoundExists ) then
        self:StopSecurityCameraLoopChannels()
        return
    end

    self._securityCameraLoopRuntimes = self._securityCameraLoopRuntimes or {}

    local clientPos = ax.client:GetPos()
    local candidates = {}

    for _, cameraData in ipairs(self.cameras) do
        local object = cameraData and cameraData.object
        if ( !object ) then continue end

        local origin = object.origin or GetObjectPosition(object)
        if ( !origin ) then continue end

        local distSqr = clientPos:DistToSqr(origin)
        if ( distSqr > CAMERA_LOOP_MAX_DISTANCE_SQR ) then continue end

        candidates[#candidates + 1] = {
            cameraData = cameraData,
            origin = origin,
            distSqr = distSqr
        }
    end

    table.sort(candidates, function(left, right)
        return left.distSqr < right.distSqr
    end)

    local desiredRuntimeIDs = {}
    local limit = math.min(#candidates, CAMERA_LOOP_MAX_ACTIVE_CHANNELS)

    for index = 1, limit do
        local candidate = candidates[index]
        local cameraData = candidate.cameraData
        local uniqueID = cameraData and cameraData.uniqueID
        if ( !isstring(uniqueID) or uniqueID == "" ) then continue end

        desiredRuntimeIDs[uniqueID] = true

        local runtime = self._securityCameraLoopRuntimes[uniqueID]
        if ( !runtime ) then
            runtime = {
                uniqueID = uniqueID,
                channel = nil,
                loading = false,
                nextRetryAt = 0,
                position = candidate.origin,
                targetVolume = 0
            }

            self._securityCameraLoopRuntimes[uniqueID] = runtime
        end

        runtime.position = candidate.origin
        runtime.targetVolume = GetCameraLoopVolume(candidate.distSqr)

        local channel = runtime.channel
        if ( IsValid(channel) ) then
            if ( channel.SetPos ) then
                channel:SetPos(runtime.position)
            end

            if ( channel.SetVolume ) then
                channel:SetVolume(runtime.targetVolume)
            end

            continue
        end
        runtime.channel = nil

        if ( runtime.loading ) then continue end
        if ( runtime.nextRetryAt > curTime ) then continue end

        runtime.loading = true

        sound.PlayFile("sound/" .. CAMERA_LOOP_SOUND_PATH, "3d noplay noblock", function(newChannel)
            runtime.loading = false

            local currentRuntime = self._securityCameraLoopRuntimes and self._securityCameraLoopRuntimes[uniqueID]
            if ( currentRuntime != runtime ) then
                if ( IsValid(newChannel) and newChannel.Stop ) then
                    newChannel:Stop()
                end

                return
            end

            if ( !IsValid(newChannel) ) then
                runtime.nextRetryAt = CurTime() + CAMERA_LOOP_RETRY_DELAY
                return
            end

            runtime.channel = newChannel
            runtime.nextRetryAt = 0

            if ( newChannel.EnableLooping ) then
                newChannel:EnableLooping(true)
            end

            if ( newChannel.Set3DFadeDistance ) then
                newChannel:Set3DFadeDistance(0, CAMERA_LOOP_MAX_DISTANCE)
            end

            if ( newChannel.SetPos ) then
                newChannel:SetPos(runtime.position)
            end

            if ( newChannel.SetVolume ) then
                newChannel:SetVolume(runtime.targetVolume)
            end

            if ( newChannel.Play ) then
                newChannel:Play()
            end
        end)
    end

    local staleRuntimeIDs = {}
    for uniqueID in pairs(self._securityCameraLoopRuntimes) do
        if ( desiredRuntimeIDs[uniqueID] != true ) then
            staleRuntimeIDs[#staleRuntimeIDs + 1] = uniqueID
        end
    end

    for _, uniqueID in ipairs(staleRuntimeIDs) do
        local runtime = self._securityCameraLoopRuntimes[uniqueID]
        StopCameraLoopRuntime(runtime)
        self._securityCameraLoopRuntimes[uniqueID] = nil
    end
end

function MODULE:GetNextCameraToRender(cameraList)
    local cameraCount = cameraList and #cameraList or 0
    if ( cameraCount == 0 ) then return nil end

    self._nextCameraRenderIndex = self._nextCameraRenderIndex or 1
    for _ = 1, cameraCount do
        if ( self._nextCameraRenderIndex > cameraCount ) then
            self._nextCameraRenderIndex = 1
        end

        local cameraData = cameraList[self._nextCameraRenderIndex]
        self._nextCameraRenderIndex = self._nextCameraRenderIndex + 1

        if ( cameraData and cameraData.object ) then
            return cameraData
        end
    end
end

function MODULE:RenderSecurityCamera(cameraData)
    if ( !cameraData or !cameraData.object ) then return end

    EnsureCameraRT(cameraData)
    if ( !cameraData.rt ) then return end

    local origin, angles = ResolveCameraView(cameraData)
    if ( !origin or !angles ) then return end

    local rtSize = cameraData.rtSize or CAMERA_RT_BASE_SIZE
    local hadViewstack = false
    if ( CLIENT and ax.viewstack and ax.viewstack.enabled and ax.viewstack.Disable and ax.viewstack.Enable ) then
        hadViewstack = true
        ax.viewstack:Disable()
    end

    self._renderingSecurityCameraView = true
    render.PushRenderTarget(cameraData.rt, 0, 0, rtSize, rtSize)
        local ok, err = xpcall(function()
            render.Clear(0, 0, 0, 255, true, true)

            local view = {
                origin        = origin,
                angles        = angles,
                x             = 0,
                y             = 0,
                w             = rtSize,
                h             = rtSize,
                fov           = 90,
                viewid        = VIEW_MONITOR or 2,
                drawviewmodel = false,
                drawviewer    = false,
                drawhud       = false,
                drawmonitors  = false,
                bloomtone     = false,
                dopostprocess = false
            }

            local params = self.activeCameraParams
            local isNVG = cameraData.nightVision

            if ( isNVG ) then
                render.SetLightingMode(1) -- Fullbright
            end

            render.RenderView(view)

            if ( isNVG ) then
                render.SetLightingMode(0) -- Reset lighting
                
                render.UpdateScreenEffectTexture()
                DrawColorModify({
                    ["$pp_colour_addr"] = 0,
                    ["$pp_colour_addg"] = 0,
                    ["$pp_colour_addb"] = 0,
                    ["$pp_colour_brightness"] = 0,
                    ["$pp_colour_contrast"] = 1,
                    ["$pp_colour_colour"] = 0, -- Zero saturation
                    ["$pp_colour_mulr"] = 0,
                    ["$pp_colour_mulg"] = 0,
                    ["$pp_colour_mulb"] = 0
                })
            end
        end, debug.traceback)

        if ( !ok and err ) then
            ax.util:PrintError("ax.security_cameras: RenderSecurityCamera failed: " .. tostring(err))
        end
    render.PopRenderTarget()
    self._renderingSecurityCameraView = false

    if ( hadViewstack ) then
        ax.viewstack:Enable()
    end
end

function MODULE:CalcViewModelView(weapon, viewmodel, oldPos, oldAng, newPos, newAng)
    if ( !CLIENT ) then return end
    if ( !self._renderingSecurityCameraView ) then return end

    -- Block stateful viewmodel modifiers from running during offscreen camera renders.
    return newPos, newAng
end

function MODULE:RenderAllSecurityCameras()
    if ( self._renderingSecurityCameras ) then return end
    self._renderingSecurityCameras = true

    if ( !CLIENT ) then
        self._renderingSecurityCameras = false
        return
    end

    if ( !self.cameras or #self.cameras == 0 ) then
        self._renderingSecurityCameras = false
        return
    end

    if ( !self.stations or #self.stations == 0 ) then
        self._renderingSecurityCameras = false
        return
    end

    if ( !IsValid(ax.client) ) then
        self._renderingSecurityCameras = false
        return
    end

    local renderableCameras = self:GetRenderableCamerasForViewer(ax.client)
    if ( #renderableCameras == 0 ) then
        self._renderingSecurityCameras = false
        return
    end

    local cameraData = self:GetNextCameraToRender(renderableCameras)
    if ( cameraData ) then
        self:RenderSecurityCamera(cameraData)
    end

    self._renderingSecurityCameras = false
end

function MODULE:PreRender()
    if ( !CLIENT ) then return end
    self:RenderAllSecurityCameras()
end

function MODULE:Think()
    if ( !CLIENT ) then return end
    self:UpdateSecurityCameraLoopAudio()
end

local imgui = ax.imgui
local overlayMaterialBlank = ax.util:GetMaterial("effects/screen_monitor_blank")
local overlayMaterial = ax.util:GetMaterial("riggs9162/bms/overlays/overlay_surveillance.png")
function MODULE:PostDrawOpaqueRenderables()
    if ( !CLIENT ) then return end
    if ( !IsValid(ax.client) ) then return end

    local hasStationContext, nearStations, visibleStations = self:GetViewerStationContext(ax.client)
    if ( !hasStationContext ) then return end

    -- Debugging: still show camera & station helpers
    for _, cameraData in ipairs(self.cameras or {}) do
        if ( cameraData.object ) then
            debugoverlay.Axis(cameraData.object.origin, cameraData.object.angles, 5, 0.01, true)
            debugoverlay.Text(cameraData.object.origin + Vector(0, 0, 10), "Camera ID: " .. tostring(cameraData.uniqueID), 0.01, false)
        end
    end

    local clientPos = ax.client:GetPos()
    local rangeSqr = GetStationScreenRangeSqr()
    for _, stationData in ipairs(self.stations or {}) do
        local stationUniqueID = stationData.uniqueID
        local stationIsNear = stationUniqueID and nearStations[stationUniqueID] == true
        local stationIsVisible = stationUniqueID and visibleStations[stationUniqueID] == true
        if ( !stationIsNear or !stationIsVisible ) then continue end

        local object = stationData.object
        if ( !object ) then continue end

        local screens, position, angles = self:GetStationScreens(stationData)
        if ( !position or !angles ) then continue end

        local min, max = GetObjectRenderBounds(object)
        if ( min and max ) then
            debugoverlay.BoxAngles(position, min, max, angles, 0.01, Color(0, 255, 0, 1))
        end
        debugoverlay.Text(position + Vector(0, 0, 10), "Security Station: " .. tostring(stationData.uniqueID), 0.01, false)

        local screenScale = 0.1
        local screenSize = math.floor(20 * (1 / screenScale))
        for _, screen in ipairs(screens) do
            if ( clientPos:DistToSqr(screen.position) > rangeSqr ) then continue end

            debugoverlay.Axis(screen.position, screen.angles, 10, 0.01, true)
            debugoverlay.Text(screen.position + Vector(0, 0, 5), "Screen Index: " .. tostring(screen.index), 0.01, false)

            local cameraData = screen.cameraData
            if ( cameraData ) then
                EnsureCameraRT(cameraData)
            end

            local width = screenSize * (screen.widthScale or 1)
            local height = screenSize * (screen.heightScale or 1)

            if ( imgui.Start3D2D(screen.position, screen.angles, screenScale, 256, 128) ) then
                ax.render.Draw(0, 0, 0, width, height, Color(10, 10, 10, 255))

                local blackoutUntil = self.stationScreenBlackouts and self.stationScreenBlackouts[stationUniqueID] and self.stationScreenBlackouts[stationUniqueID][screen.index] or 0
                local isBlackout = CurTime() < blackoutUntil

                if ( !isBlackout ) then
                    if ( cameraData and cameraData.mat ) then
                        ax.render.DrawMaterial(0, 0, 0, width, height, color_white, cameraData.mat)
                    elseif ( overlayMaterialBlank ) then
                        ax.render.DrawMaterial(0, 0, 0, width, height, color_white, overlayMaterialBlank)
                    end
                end

                if ( overlayMaterial ) then
                    ax.render.DrawMaterial(0, 0, 0, width, height, color_white, overlayMaterial)
                end

                imgui.End3D2D()
            end
        end
    end
end

function MODULE:RenderScreenspaceEffects()
    if ( !CLIENT ) then return end
    -- The actual implementation is in cl_camera.lua, but we need it here to ensure it's called
    -- (cl_camera is currently evaluated *after* sh_cameras, so adding it here is safer if it wasn't there before, but since it's the same table it's fine)
end

function MODULE:CreateMove(cmd)
    if ( !CLIENT ) then return end
    -- Hook defined in cl_camera.lua
end

function MODULE:PlayerBindPress(ply, bind, pressed)
    if ( !CLIENT ) then return end
    -- Hook defined in cl_camera.lua
end

function MODULE:SetupPlayerVisibility(client)
    if ( CLIENT ) then return end
    if ( !ax.util:IsValidPlayer(client) ) then return end
    if ( !self.stations or !self.cameras ) then return end

    local renderableCameras = self:GetRenderableCamerasForViewer(client)

    local addedCameraOrigins = {}

    local function AddCameraOrigin(cameraData)
        if ( !cameraData or !cameraData.object ) then return end

        local uniqueID = cameraData.uniqueID
        if ( uniqueID and addedCameraOrigins[uniqueID] ) then
            return
        end

        local origin = cameraData.object.origin or GetObjectPosition(cameraData.object)
        if ( !origin ) then return end

        AddOriginToPVS(origin)
        if ( uniqueID ) then
            addedCameraOrigins[uniqueID] = true
        end
    end

    if ( #renderableCameras > 0 ) then
        self._nextPVSCameraRenderIndexByClient = self._nextPVSCameraRenderIndexByClient or {}
        local entIndex = client:EntIndex()
        local nextIndex = self._nextPVSCameraRenderIndexByClient[entIndex] or 1
        if ( nextIndex > #renderableCameras ) then
            nextIndex = 1
        end

        self._nextPVSCameraRenderIndexByClient[entIndex] = nextIndex + 1
        AddCameraOrigin(renderableCameras[nextIndex])
    end

    if ( client.GetRelay ) then
        local cameraUniqueID = client:GetRelay("security_camera")
        if ( isstring(cameraUniqueID) and cameraUniqueID != "" ) then
            AddCameraOrigin(self:GetCameraByID(cameraUniqueID))
        end
    end
end

function MODULE:ShutDown()
    if ( !CLIENT ) then return end
    self:StopSecurityCameraLoopChannels()
end

if ( SERVER ) then
    function MODULE:OnPlayerInitialSpawn(ply)
        self:SyncToPlayer(ply)
    end
end
