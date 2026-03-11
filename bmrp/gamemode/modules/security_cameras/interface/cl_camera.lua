--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.activeCameraParams = MODULE.activeCameraParams or {
    active = false,
    transitioning = false,
    transitionProgress = 0,
    startOrigin = Vector(),
    startAngles = Angle(),
    startFOV = 90,
    stationData = nil,
    screen = nil,
    targetOrigin = nil,
    targetAngles = nil,
    lastFeedCycleTime = 0,
    lastNVGToggleTime = 0
}

local TRANSITION_DURATION = 0.5 -- Seconds

-- Quartic easing provides a much stronger "snap" and a longer, smoother slow-down than Sine or Cubic.
local function EaseInOutQuart(t)
    return t < 0.5 and 8 * t * t * t * t or 1 - math.pow(-2 * t + 2, 4) / 2
end

function MODULE:StartCameraView(stationData, screen)
    if ( !stationData or !screen ) then return end

    local params = self.activeCameraParams
    
    if ( !params.active ) then
        -- Starting fresh from player view
        params.startOrigin = EyePos()
        params.startAngles = EyeAngles()
        params.startFOV = ax.client:GetFOV() or 90
        params.transitionProgress = 0
        params.active = true
        params.transitioning = true

        -- Start background sound
        if ( !MODULE.backgroundTapeSound ) then
            MODULE.backgroundTapeSound = CreateSound(LocalPlayer(), "ax.security_cameras.background_tape")
        end
        if ( MODULE.backgroundTapeSound ) then
            MODULE.backgroundTapeSound:PlayEx(0.35, 100)
        end
    else
        params.startOrigin = params.lastRenderOrigin or params.targetOrigin or EyePos()
        params.startAngles = params.lastRenderAngles or params.targetAngles or EyeAngles()
        params.startFOV = 90
        params.transitionProgress = 0
        params.transitioning = true
        params.isSwitching = true

        -- Stop any active garble on switch
        if ( MODULE.activeGarbleSound ) then
            MODULE.activeGarbleSound:Stop()
            MODULE.activeGarbleSound = nil
        end

        -- Restart background sound
        if ( MODULE.backgroundTapeSound ) then
            MODULE.backgroundTapeSound:PlayEx(0.35, 100)
        end

        -- Trigger blackout on the new screen when switching
        if ( stationData and screen ) then
            self.stationScreenBlackouts = self.stationScreenBlackouts or {}
            self.stationScreenBlackouts[stationData.uniqueID] = self.stationScreenBlackouts[stationData.uniqueID] or {}
            self.stationScreenBlackouts[stationData.uniqueID][screen.index] = CurTime() + 0.1
        end
    end

    params.stationData = stationData
    params.screen = screen
    local screenScale = 0.1
    local screenSize = math.floor(20 * (1 / screenScale))
    local width = screenSize * (screen.widthScale or 1)
    local height = screenSize * (screen.heightScale or 1)
    
    local worldWidth = width * screenScale
    local worldHeight = height * screenScale

    -- In Garry's Mod 3D2D, X goes right (Forward), Y goes down (-Right)
    -- So the center of the drawn quad is at (width/2, height/2) in 2D space.
    local rightDir = screen.angles:Forward()
    local downDir = -screen.angles:Right()
    
    local screenCenter = screen.position + (rightDir * (worldWidth * 0.5)) + (downDir * (worldHeight * 0.5))
    local screenNormal = screen.angles:Up()
    
    -- Use FOV to calculate the exact distance needed to frame this monitor.
    local fov = ax.client:GetFOV() or 90
    local fovRad = math.rad(fov / 2)
    
    -- Calculate distance needed to fit the width
    local distanceForWidth = (worldWidth / 2) / math.tan(fovRad)
    
    -- Calculate distance needed to fit the height
    -- (Assuming standard 16:9 aspect ratio for vertical FOV mapping)
    local verticalFovRad = math.rad((fov / (16/9)) / 2)
    local distanceForHeight = (worldHeight / 2) / math.tan(verticalFovRad)
    
    -- Use whichever distance is larger so the whole screen fits, plus a 1.2x padding margin
    local perfectDistance = math.max(distanceForWidth, distanceForHeight) * 1.2
    local distance = math.max(25, perfectDistance)

    -- Because we're using raw FOV math to fit it in the center of the viewport,
    -- the raw math sits too high up (likely due to the screen bezel vs active draw area).
    -- Restoring the -15 offset we found feels natural.
    params.targetOrigin = screenCenter + (screenNormal * distance) - (downDir * 14)
    
    -- The user explicitly wants the camera to literally just face the same orientation as the UI
    -- In 3D2D, drawing on "screen.angles" means looking at it from "screenNormal". 
    -- So we just use exactly the reverse of the screen's normal, keeping the roll flat.
    local angleToScreen = (-screenNormal):Angle()
    
    -- Force roll to 0 so the player doesn't have a tilted head
    angleToScreen.r = 0

    params.targetAngles = angleToScreen
    
    -- Request PVS for the currently selected camera feed on this monitor
    local cameraData = MODULE:GetStationCameraData(stationData, screen.index)
    if ( cameraData ) then
        net.Start("ax.security_cameras.request_camera")
            net.WriteString(cameraData.uniqueID)
        net.SendToServer()
    end
end

function MODULE:StopCameraView()
    local params = self.activeCameraParams
    if ( !params.active ) then return end
    
    -- Transition back to player view. Our new 'start' is the exact last frame we rendered so we don't snap away from the parallax/sway loop
    if ( params.lastRenderOrigin and params.lastRenderAngles ) then
        params.startOrigin = params.lastRenderOrigin
        params.startAngles = params.lastRenderAngles
        params.startFOV = 90
    elseif ( params.targetOrigin and params.targetAngles ) then
        params.startOrigin = params.targetOrigin
        params.startAngles = params.targetAngles
        params.startFOV = 90
    else
        params.startOrigin = EyePos()
        params.startAngles = EyeAngles()
        params.startFOV = ax.client:GetFOV() or 90
    end
    
    params.targetOrigin = nil
    params.targetAngles = nil
    params.stationData = nil
    params.screen = nil
    params.transitioning = true
    params.transitionProgress = 0
    params.active = false
    params.isSwitching = false

    -- Stop audio on exit
    if ( MODULE.backgroundTapeSound ) then
        MODULE.backgroundTapeSound:FadeOut(0.5)
    end
    if ( MODULE.activeGarbleSound ) then
        MODULE.activeGarbleSound:FadeOut(0.5)
    end

    params.viewYawOffset = 0
    params.viewPitchOffset = 0
    params.smoothYawOffset = 0
    params.smoothPitchOffset = 0

    net.Start("ax.security_cameras.request_camera")
        net.WriteString("")
    net.SendToServer()
end

function MODULE:CycleCameraFeed(direction)
    local params = self.activeCameraParams
    if ( !params.active or params.transitioning or !self.cameras ) then return end
    if ( !params.stationData or !params.screen ) then return end

    -- 0.5s cooldown anti-spam
    if ( CurTime() < (params.lastFeedCycleTime or 0) + 0.5 ) then return end
    params.lastFeedCycleTime = CurTime()

    local currentCameraData = self:GetStationCameraData(params.stationData, params.screen.index)
    local currentIndex = 1
    if ( currentCameraData ) then
        for i, cam in ipairs(self.cameras) do
            if ( cam.uniqueID == currentCameraData.uniqueID ) then
                currentIndex = i
                break
            end
        end
    end

    local newIndex = currentIndex + direction
    if ( newIndex > #self.cameras ) then newIndex = 1 end
    if ( newIndex < 1 ) then newIndex = #self.cameras end

    local newCamera = self.cameras[newIndex]
    if ( newCamera ) then
        -- Play switching sounds
        surface.PlaySound("fnaf/Camera_Change.wav")
        
        if ( math.random() > 0.5 and CurTime() - (self.lastGarbleTime or 0) > 5 ) then
            -- Stop current garble before playing new one
            if ( MODULE.activeGarbleSound ) then
                MODULE.activeGarbleSound:Stop()
            end

            local garbleSounds = {
                "fnaf/garble1.wav",
                "fnaf/garble2.wav",
                "fnaf/garble3.wav",
                "fnaf/Glitch.wav",
                "fnaf/Glitch Short.wav"
            }
            local chosenSound = garbleSounds[math.random(#garbleSounds)]

            MODULE.activeGarbleSound = CreateSound(LocalPlayer(), chosenSound)
            if ( MODULE.activeGarbleSound ) then
                MODULE.activeGarbleSound:PlayEx(0.4, 100)
            end

            self.lastGarbleTime = CurTime()
        end

        -- Update the feed on the physical screen
        self:SetStationCameraSelection(params.stationData.uniqueID, params.screen.index, newCamera.uniqueID)
        
        -- Sync this choice to other players
        net.Start("ax.security_cameras.sync_station_selection")
            net.WriteString(params.stationData.uniqueID)
            net.WriteInt(params.screen.index, 8)
            net.WriteString(newCamera.uniqueID)
        net.SendToServer()

        -- And tell the server we want PVS for the new camera feed
        net.Start("ax.security_cameras.request_camera")
            net.WriteString(newCamera.uniqueID)
        net.SendToServer()
    end
end

function MODULE:SwitchScreen(dirX, dirY)
    local params = self.activeCameraParams
    if ( !params.active or params.transitioning ) then return end
    if ( !params.stationData or !params.screen ) then return end

    -- Based on sh_cameras.lua: Forward() is Right (X), -Right() is Down (Y)
    local rightDir = params.screen.angles:Forward()
    local downDir = -params.screen.angles:Right()
    
    local function findBest(isLocalOnly)
        local bestS = nil
        local bestD = nil
        local bestScore = math.huge

        for _, stationData in ipairs(self.stations or {}) do
            local isOtherStation = (stationData.uniqueID ~= params.stationData.uniqueID)
            if ( isLocalOnly and isOtherStation ) then continue end
            if ( !isLocalOnly and !isOtherStation ) then continue end

            local screens = self:GetStationScreens(stationData)
            if ( !screens ) then continue end

            for _, screen in ipairs(screens) do
                -- Don't switch to the current screen
                if ( stationData.uniqueID == params.stationData.uniqueID and screen.index == params.screen.index ) then
                    continue
                end

                local diff = screen.position - params.screen.position
                local xDiff = diff:Dot(rightDir)
                local yDiff = diff:Dot(downDir)

                -- Adjacency check for station-jumping (150 units max Jump)
                if ( !isLocalOnly and diff:Length() > 150 ) then continue end

                local isValid = false
                local primaryDist = 0
                local secondaryDist = 0

                if ( dirX ~= 0 ) then
                    if ( dirX * xDiff > 15 ) then 
                        isValid = true
                        primaryDist = math.abs(xDiff)
                        secondaryDist = math.abs(yDiff)
                    end
                elseif ( dirY ~= 0 ) then 
                    if ( dirY * yDiff > 15 ) then 
                        isValid = true
                        primaryDist = math.abs(yDiff)
                        secondaryDist = math.abs(xDiff)
                    end
                end

                if ( isValid ) then
                    -- Score: Closer is better.
                    local score = primaryDist + (secondaryDist * 3)
                    if ( score < bestScore ) then
                        bestScore = score
                        bestS = screen
                        bestD = stationData
                    end
                end
            end
        end
        return bestS, bestD
    end

    -- 1. Try to find a screen on the CURRENT station first (prevent switching if we have local options)
    local bestScreen, bestStation = findBest(true)

    -- 2. If at the edge (no local screens in that direction), check for ADJACENT stations
    if ( !bestScreen ) then
        bestScreen, bestStation = findBest(false)
    end

    if ( bestScreen and bestStation ) then
        self:StartCameraView(bestStation, bestScreen)
    end
end

function MODULE:Think()
    if ( !CLIENT ) then return end
    
    -- Ensure shared audio logic still runs
    if ( self.UpdateSecurityCameraLoopAudio ) then
        self:UpdateSecurityCameraLoopAudio()
    end

    local params = self.activeCameraParams
    
    -- Manage background tape loop
    if ( MODULE.backgroundTapeSound and !MODULE.backgroundTapeSound:IsPlaying() and params.active ) then
        MODULE.backgroundTapeSound:PlayEx(0.35, 100)
    end

    -- Volume management
    if ( params.active ) then
        if ( params.transitioning and params.isSwitching ) then
            -- Silent during swoop
            if ( MODULE.backgroundTapeSound ) then
                MODULE.backgroundTapeSound:ChangeVolume(0, 0.4)
            end
            if ( MODULE.activeGarbleSound ) then
                MODULE.activeGarbleSound:ChangeVolume(0, 0.4)
            end
        else
            -- Full volume
            if ( MODULE.backgroundTapeSound ) then
                MODULE.backgroundTapeSound:ChangeVolume(0.35, 0.4)
            end
            if ( MODULE.activeGarbleSound ) then
                MODULE.activeGarbleSound:ChangeVolume(0.4, 0.4)
            end
        end
    end

    if ( params.transitioning ) then
        params.transitionProgress = math.min(params.transitionProgress + (FrameTime() / TRANSITION_DURATION), 1)
        if ( params.transitionProgress >= 1 ) then
            params.transitioning = false
            if ( !params.targetOrigin ) then
                params.active = false
            end
        end
    end
end

function MODULE:CalcView(ply, origin, angles, fov)
    local params = self.activeCameraParams
    if ( !params.active and !params.transitioning ) then return end

    -- Base target angles to apply sway and parallax to
    local currentTargetOrigin = params.active and params.targetOrigin or origin
    local currentTargetAngles = params.active and params.targetAngles or angles
    local currentTargetFOV = params.active and 90 or fov

    if ( !currentTargetOrigin or !currentTargetAngles ) then return end

    local finalAngles = Angle(currentTargetAngles.p, currentTargetAngles.y, currentTargetAngles.r)

    if ( params.active ) then
        -- Smooth mouse parallax
        params.smoothYawOffset = Lerp(FrameTime() * 4, params.smoothYawOffset or 0, params.viewYawOffset or 0)
        params.smoothPitchOffset = Lerp(FrameTime() * 4, params.smoothPitchOffset or 0, params.viewPitchOffset or 0)
        
        -- Noticeable idle head sway
        local swayPitch = math.sin(CurTime() * 0.8) * 0.8
        local swayYaw = math.cos(CurTime() * 0.6) * 1.2
        
        finalAngles.p = finalAngles.p + params.smoothPitchOffset + swayPitch
        finalAngles.y = finalAngles.y + params.smoothYawOffset + swayYaw
    end

    if ( params.transitioning ) then
        local t = EaseInOutQuart(params.transitionProgress)
        
        local outOrigin
        if ( params.isSwitching and params.active ) then
            -- Quadratic Bezier Curve for a smooth swooping arc between the monitors
            local p0 = params.startOrigin
            local p2 = currentTargetOrigin
            
            -- Set the control point (p1) halfway between the two monitors, but pulled backward 40 units
            -- We use the current target's backward direction for a consistent pull-away
            local p1 = ((p0 + p2) / 2) - (currentTargetAngles:Forward() * 40)
            
            -- Standard Quadratic Bezier function: B(t) = (1-t)^2*P0 + 2(1-t)t*P1 + t^2*P2
            local u = 1 - t
            outOrigin = (p0 * (u * u)) + (p1 * (2 * u * t)) + (p2 * (t * t))
        else
            outOrigin = LerpVector(t, params.startOrigin, currentTargetOrigin)
        end

        local outAngles = LerpAngle(t, params.startAngles, finalAngles)
        local outFOV = Lerp(t, params.startFOV, currentTargetFOV)
        
        params.lastRenderOrigin = outOrigin
        params.lastRenderAngles = outAngles

        return {
            origin = outOrigin,
            angles = outAngles,
            fov = outFOV,
            drawviewer = true
        }
    else
        params.lastRenderOrigin = currentTargetOrigin
        params.lastRenderAngles = finalAngles

        return {
            origin = currentTargetOrigin,
            angles = finalAngles,
            fov = currentTargetFOV,
            drawviewer = true
        }
    end
end

function MODULE:CreateMove(cmd)
    local params = self.activeCameraParams
    if ( params.active ) then
        cmd:ClearMovement()
        cmd:ClearButtons()
        
        -- Accumulate mouse look for parallax effect (Reduced intensity)
        local mX = cmd:GetMouseX()
        local mY = cmd:GetMouseY()
        
        -- Mouse X maps to Yaw (left/right) -> higher X = looking right = negative yaw in Source
        -- Mouse Y maps to Pitch (up/down) -> higher Y = looking down = positive pitch
        params.viewYawOffset = math.Clamp((params.viewYawOffset or 0) - (mX * 0.008), -5, 5)
        params.viewPitchOffset = math.Clamp((params.viewPitchOffset or 0) + (mY * 0.008), -3, 3)
        
        if ( params.targetAngles and !params.transitioning ) then
            -- We don't apply the parallax to the actual engine view angles so we don't permanently mess up the player's head,
            -- but locking them to targetAngles ensures GetMouseX/Y generate continuous relative input.
            cmd:SetViewAngles(params.targetAngles)
        end
    end
end

function MODULE:PlayerBindPress(ply, bind, pressed)
    if ( !pressed ) then return end

    local params = self.activeCameraParams

    if ( string.find(bind, "+use") ) then
        if ( params.transitioning ) then
            return true
        end

        if ( params.active ) then
            self:StopCameraView()
            return true
        else
            -- Check if we are near a station and looking at a screen
            local hasStationContext, nearStations, visibleStations = self:GetViewerStationContext(ply)
            if ( hasStationContext ) then
                local eyePos = ply:EyePos()
                local eyeDir = ply:GetAimVector()

                local bestScreen = nil
                local bestStation = nil
                local bestDot = 0.9 -- Require at least a fairly direct look

                for _, stationData in ipairs(self.stations or {}) do
                    local stationUniqueID = stationData.uniqueID
                    if ( nearStations[stationUniqueID] and visibleStations[stationUniqueID] ) then
                        local screens = self:GetStationScreens(stationData)
                        for _, screen in ipairs(screens) do
                            local toScreen = (screen.position - eyePos):GetNormalized()
                            local dot = eyeDir:Dot(toScreen)
                            if ( dot > bestDot ) then
                                bestDot = dot
                                bestScreen = screen
                                bestStation = stationData
                            end
                        end
                    end
                end

                if ( bestStation and bestScreen ) then
                    self:StartCameraView(bestStation, bestScreen)
                    return true
                end
            end
        end
    end

    if ( params.active ) then
        if ( string.find(bind, "+attack2") ) then
            self:CycleCameraFeed(-1)
            return true
        elseif ( string.find(bind, "+attack") ) then
            self:CycleCameraFeed(1)
            return true
        end

        -- Block standard keys
        if ( string.find(bind, "+forward") or string.find(bind, "+back") or string.find(bind, "+moveleft") or string.find(bind, "+moveright") or string.find(bind, "+jump") or string.find(bind, "+duck") ) then
            return true
        end
    end
end

hook.Add("PlayerButtonDown", "ax.security_cameras.ButtonDown", function(ply, button)
    if ( !IsFirstTimePredicted() ) then return end
    
    local params = MODULE.activeCameraParams
    if ( !params.active ) then return end
    if ( params.transitioning ) then return end

    if ( button == KEY_LEFT or button == KEY_A ) then
        MODULE:SwitchScreen(-1, 0)
    elseif ( button == KEY_RIGHT or button == KEY_D ) then
        MODULE:SwitchScreen(1, 0)
    elseif ( button == KEY_UP or button == KEY_W ) then
        MODULE:SwitchScreen(0, 1)
    elseif ( button == KEY_DOWN or button == KEY_S ) then
        MODULE:SwitchScreen(0, -1)
    elseif ( button == KEY_F ) then
        local cameraData = MODULE:GetStationCameraData(params.stationData, params.screen.index)
        if ( cameraData ) then
            -- 0.5s cooldown anti-spam
            if ( CurTime() < (params.lastNVGToggleTime or 0) + 0.5 ) then return end
            params.lastNVGToggleTime = CurTime()

            local newState = !cameraData.nightVision
            
            net.Start("ax.security_cameras.sync_night_vision")
                net.WriteString(cameraData.uniqueID)
                net.WriteBool(newState)
            net.SendToServer()

            if ( newState ) then
                surface.PlaySound("fnaf/Night_Vision.wav")
            else
                surface.PlaySound("fnaf/Night_Vision_OFF.wav")
            end
        end
    elseif ( button == KEY_ESCAPE ) then
        MODULE:StopCameraView()
        gui.HideGameUI()
    end
end)

hook.Add("PrePlayerDraw", "ax.security_cameras.HideLocalPlayer", function(ply)
    if ( ply != LocalPlayer() ) then return end
    
    local params = MODULE.activeCameraParams
    if ( params and (params.active or params.transitioning) ) then
        return true
    end
end)
