--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Viewbob"
MODULE.description = "Enhanced viewmodel bobbing system for weapons."
MODULE.author = "Riggs, ARC-9, fzkm"

--- Heavily modified from ARC-9's bobbing code
-- https://github.com/HaodongMo/ARC-9/blob/main/lua/weapons/arc9_base/cl_sway.lua#L103
local affset = Angle()
local airtime = 0
local offset = Vector()
local stammer = 0
local tvL = 0
local v = 0
local function FesiugBob(client, weapon, pos, ang)
    local ft = FrameTime()
    if ( !weapon.ViewModelSprintRatio ) then
        weapon.ViewModelSprintRatio = 0
    else
        if ( client:IsSprinting() ) then
            weapon.ViewModelSprintRatio = ax.ease:Lerp("InOutQuad", ft * 7, weapon.ViewModelSprintRatio, 2)
        else
            weapon.ViewModelSprintRatio = ax.ease:Lerp("InOutQuad", ft * 9, weapon.ViewModelSprintRatio, 1)
        end
    end

    local cv = client:GetVelocity():Length()
    v = ax.ease:Lerp("InOutQuad", ft * 10, v, cv)
    v = math.Clamp(v, 0, 400)
    local tv = v / 800
    tv = tv * 1.5
    local mulp = 1
    local mulk = 1
    local tk = tv * mulk
    tv = tv * mulp
    weapon.BobScale = 0
    local p = math.pi

    tvL = ax.ease:Lerp("InOutQuad", ft * 10, tvL, tv)

    local grounded = (client:IsOnGround() or client:GetMoveType() == MOVETYPE_NOCLIP)
    airtime = math.Approach(airtime, grounded and 0 or 1, ft * 5 * (grounded and 10 or 1))

    offset:Set(vector_origin)
    affset:Set(angle_zero)

    local ct = ( (CurTime() * 1.6) / (0.975 * ((1 / 1.1) + 0.1)) )

    offset.x = offset.x + math.sin( ct * p * 2 ) * 0.2 * weapon.ViewModelSprintRatio
    offset.y = offset.y + math.pow(math.sin( ct * p * 2 ), 2) * -0.5 * weapon.ViewModelSprintRatio
    offset.z = offset.z + math.abs(math.sin( ct * p * -1 )) * -0.15

    offset.z = offset.z + math.pow(math.abs( math.sin(ct * p * 2) ), 6) * -0.395 * weapon.ViewModelSprintRatio

    offset.z = offset.z + ( (-0.395 / 2) * 3 * tvL )

    offset.z = offset.z + ( math.pow(math.sin((ct + 0) * p * 2.5), 2) * -0.3 )
    offset.z = offset.z + ( math.pow(math.sin((ct + 0.3) * p * 2.5), 2) * -0.3 )

    affset.x = affset.x - ( math.pow( math.sin( ct * p ) * 2.2, 2 ) - ( (2.2 / 2) * tvL ) ) * weapon.ViewModelSprintRatio
    affset.y = affset.y + math.sin( ct * p * -3 ) * 0.5 * 1.5

    -- Smoothly interpolate the abrupt toggle between -1 and 2 based on phase
    local phase = (ct / 2) % 1
    local transWidth = 0.15 -- how wide the smooth transition is around 0.5
    local x = math.Clamp((phase - (0.5 - transWidth * 0.5)) / transWidth, 0, 1)
    -- smoothstep (Hermite) for a pleasant ease
    local smooth = x * x * (3 - 2 * x)
    local coef1 = Lerp(smooth, -1, 2)
    local coef2 = Lerp(smooth, 2, -1)

    local sinv = math.sin(ct * p * 2) * 2 * 1.5 * weapon.ViewModelSprintRatio

    affset.z = affset.z + coef1 * sinv
    affset.z = affset.z + coef2 * sinv

    affset.x = affset.x + ( (-2) * tvL )

    pos:Add(ang:Right()     *   offset.x * tvL * weapon.ViewModelSprintRatio)
    pos:Add(ang:Forward()   *   offset.y * tvL * weapon.ViewModelSprintRatio)
    pos:Add(ang:Up()        *   offset.z * tvL * weapon.ViewModelSprintRatio)

    local stammertime_pos = Vector()
    local stammertime_ang = Angle()

    local pep = client:KeyDown(IN_FORWARD) or client:KeyDown(IN_BACK) or client:KeyDown(IN_MOVELEFT) or client:KeyDown(IN_MOVERIGHT)
    local target_stammer = (tk > 0.1) and 1 or 0
    stammer = ax.ease:Lerp("InOutQuad", ft * 10, stammer, target_stammer)
    stammer_moving = target_stammer == 1

    -- Smoothly interpolate the stammer effect (elistam) for a nicer transition
    weapon.ViewModelStammer = weapon.ViewModelStammer or 0
    local target_elistam = ( !pep and stammer or 0 )
    weapon.ViewModelStammer = ax.ease:Lerp("InOutQuad", ft * 10, weapon.ViewModelStammer, target_elistam)
    local elistam = weapon.ViewModelStammer / 10

    stammertime_pos.x = stammertime_pos.x + math.sin(ct * p * 5 * 1.334) * -0.05
    stammertime_pos.y = stammertime_pos.y + elistam * -0.5
    stammertime_pos.z = stammertime_pos.z + elistam * -0.25
    stammertime_ang.y = stammertime_ang.y + math.sin(ct * p * 2 * 1.334) * 0.8
    stammertime_ang.z = stammertime_ang.z + math.sin(ct * p * 5 * 1.334) * 0.5

    pos:Add(ang:Right()     *   stammertime_pos.x * elistam * weapon.ViewModelSprintRatio)
    pos:Add(ang:Forward()   *   stammertime_pos.y * elistam * weapon.ViewModelSprintRatio)
    pos:Add(ang:Up()        *   stammertime_pos.z * elistam * weapon.ViewModelSprintRatio)

    ang:RotateAroundAxis(ang:Forward(),        affset.x * tvL * weapon.ViewModelSprintRatio)
    ang:RotateAroundAxis(ang:Right(),          affset.y * tvL * weapon.ViewModelSprintRatio)
    ang:RotateAroundAxis(ang:Up(),             affset.z * tvL * weapon.ViewModelSprintRatio)

    ang:RotateAroundAxis(ang:Forward(),        stammertime_ang.x * elistam * weapon.ViewModelSprintRatio)
    ang:RotateAroundAxis(ang:Right(),          stammertime_ang.y * elistam * weapon.ViewModelSprintRatio)
    ang:RotateAroundAxis(ang:Up(),             stammertime_ang.z * elistam * weapon.ViewModelSprintRatio)
    weapon.ViewModelStrafe = weapon.ViewModelStrafe or 0
    local strafeTarget = (client:KeyDown(IN_MOVELEFT) and 2 or client:KeyDown(IN_MOVERIGHT) and -2 or 0) * tvL
    weapon.ViewModelStrafe = ax.ease:Lerp("InOutQuad", ft * 10, weapon.ViewModelStrafe, strafeTarget)
    ang:RotateAroundAxis(ang:Up(), weapon.ViewModelStrafe)

    ang:RotateAroundAxis(ang:Forward(),          math.sin(ct * p * 1) * airtime * -5 * mulp * 2)
    ang:RotateAroundAxis(ang:Right(),          (math.sin(ct * p * 1) * airtime * 3 * mulp) + ((3 / 2) * airtime * mulp))
    ang:RotateAroundAxis(ang:Up(),          math.sin(ct * p * 2) * airtime * 2 * mulp)

    return pos, ang
end

local _lastEyeAng = Angle(0, 0, 0)
local _rotPitchTarget, _rotYawTarget, _rotRollTarget = 0, 0, 0
local _rotPitch, _rotYaw, _rotRoll = 0, 0, 0
local _posLeadX, _posLeadY, _posLeadZ = 0, 0, 0
local _posLeadXTarget, _posLeadYTarget, _posLeadZTarget = 0, 0, 0
local function FesiugAimSway(client, weapon, pos, ang)
    local ft = FrameTime()

    local eye = EyeAngles()
    local dPitch = math.AngleDifference(eye.p, _lastEyeAng.p)
    local dYaw   = math.AngleDifference(eye.y, _lastEyeAng.y)
    _lastEyeAng = Angle(eye.p, eye.y, eye.r)

    _rotPitchTarget = math.Clamp(dPitch * 0.14, -3.5, 3.5)
    _rotYawTarget   = math.Clamp(dYaw   * 0.14, -3.5, 3.5)
    _rotRollTarget  = math.Clamp(-dYaw  * 0.22, -6.0, 6.0)

    local rotLerp = 24
    _rotPitch = ax.ease:Lerp("InOutQuad", ft * rotLerp, _rotPitch, _rotPitchTarget)
    _rotYaw   = ax.ease:Lerp("InOutQuad", ft * rotLerp, _rotYaw,   _rotYawTarget)
    _rotRoll  = ax.ease:Lerp("InOutQuad", ft * rotLerp, _rotRoll,  _rotRollTarget)

    local leadSide   = 2.2
    local leadUp     = 3.3
    local leadDepth  = 7.7
    local yawAbs     = math.abs(_rotYaw)
    local pitchAbs   = math.abs(_rotPitch)

    _posLeadXTarget = (-_rotYaw)  * leadSide
    _posLeadYTarget = _rotPitch * leadUp
    _posLeadZTarget = -(yawAbs + pitchAbs) * leadDepth

    local posLerp = 12
    _posLeadX = ax.ease:Lerp("InOutQuad", ft * posLerp, _posLeadX, _posLeadXTarget)
    _posLeadY = ax.ease:Lerp("InOutQuad", ft * posLerp, _posLeadY, _posLeadYTarget)
    _posLeadZ = ax.ease:Lerp("InOutQuad", ft * posLerp, _posLeadZ, _posLeadZTarget)

    local newAng = Angle(ang.p, ang.y, ang.r)
    newAng.p = newAng.p + _rotPitch
    newAng.y = newAng.y + _rotYaw
    newAng.r = newAng.r + _rotRoll

    local right  = newAng:Right()
    local up     = newAng:Up()
    local fwd    = newAng:Forward()
    pos = pos + right * _posLeadX + up * _posLeadY + fwd * _posLeadZ

    return pos, newAng
end

ax.viewstack:RegisterViewModelModifier("bobbing", function(weapon, patch)
    if ( ax.client:GetMoveType() != MOVETYPE_WALK ) then return end

    local pos = patch.pos
    local ang = patch.ang

    pos, ang = FesiugBob(ax.client, weapon, pos, ang)
    pos, ang = FesiugAimSway(ax.client, weapon, pos, ang)

    return { pos = pos, ang = ang }
end, 1)

-- Shamelessly adapted from https://steamcommunity.com/sharedfiles/filedetails/?id=3627442686

local cfg = {
    enabled = true,
    smoothSpeed = 8,
    walkCycleSpeed = 6,
    verticalAmp = 0.3,
    horizontalAmp = 0.15,
    rollAmp = 1,
    pitchAmp = 0.5,
    lookSway = 1.0,
    lookSwayReturn = 5,
    strafeTilt = 2,
    strafeTiltSpeed = 8,
    landingIntensity = 4.0,
    jumpTilt = 0.5,
    jumpFovEffect = 8,
    airControlTilt = 0.5,
    crouchTransition = 4.0,
    crouchTilt = 0.5,
    crouchRoll = 0.3,
    adsDamping = 0.3,
    breathingIntensity = 0.25,
    breathingSpeed = 1.5,
    speedTilt = 0.5,
    speedFov = 5,
    damageShake = 24.0,
    stepImpact = 0.25
}

local state = {
    offset = Vector(0, 0, 0),
    angles = Angle(0, 0, 0),
    fovOffset = 0,

    walkPhase = 0,
    walkIntensity = 0,
    lastStepPhase = 0,
    stepImpact = 0,

    lastEyeAngles = Angle(0, 0, 0),
    lookSwayOffset = Angle(0, 0, 0),

    strafeRoll = 0,

    wasOnGround = true,
    isInAir = false,
    fallStartTime = 0,
    airTime = 0,

    landingImpact = 0,
    landingTime = 0,

    jumpPitch = 0,
    jumpFov = 0,
    jumpStartTime = 0,

    airTilt = Angle(0, 0, 0),

    wasCrouching = false,
    crouchTransition = 0,
    crouchPitch = 0,
    crouchRoll = 0,
    crouchStartTime = 0,

    sprintTilt = 0,
    sprintFov = 0,

    breathPhase = 0,

    damageShake = Angle(0, 0, 0),
    lastHealth = 100
}

local function FILerp(dt, current, target, speed)
    local factor = 1 - math.exp(-speed * dt)
    return current + (target - current) * factor
end

local function FILerpAngle(dt, current, target, speed)
    local factor = 1 - math.exp(-speed * dt)
    return Angle(
        current.p + (target.p - current.p) * factor,
        current.y + (target.y - current.y) * factor,
        current.r + (target.r - current.r) * factor
    )
end

local function FILerpVector(dt, current, target, speed)
    local factor = 1 - math.exp(-speed * dt)
    return Vector(
        current.x + (target.x - current.x) * factor,
        current.y + (target.y - current.y) * factor,
        current.z + (target.z - current.z) * factor
    )
end

local function Figure8Pattern(phase, intensity)
    local x = math.sin(phase) * intensity
    local y = math.sin(phase * 2) * intensity * 0.5
    return x, y
end

function MODULE:Think()
    if !cfg.enabled then return end
    local client = ax.client
    if !ax.util:IsValidPlayer(client) then return end

    local currentHealth = client:Health()
    if currentHealth < state.lastHealth and cfg.damageShake > 0 then
        local damage = state.lastHealth - currentHealth
        local intensity = math.Clamp(damage / 30, 0.3, 2) * cfg.damageShake
        state.damageShake = Angle(
            math.Rand(-intensity, intensity) * 2,
            math.Rand(-intensity, intensity),
            math.Rand(-intensity, intensity) * 1.5
        )
    end
    state.lastHealth = currentHealth
end

local function CalculateCameraEffects(client, ang)
    local dt = FrameTime()
    local currentTime = CurTime()
    local vel = client:GetVelocity()
    local speed2D = vel:Length2D()
    local isOnGround = client:OnGround()
    local isAiming = client:KeyDown(IN_ATTACK2)
    local isSprinting = client:KeyDown(IN_SPEED) and speed2D > 50 and isOnGround
    local isCrouching = client:Crouching()

    local adsMult = isAiming and cfg.adsDamping or 1

    local targetWalkIntensity = 0
    if isOnGround and speed2D > 20 then
        local speedFactor = math.Clamp(speed2D / 250, 0, 1)
        if isSprinting then speedFactor = speedFactor * 1.3 end
        if isCrouching then speedFactor = speedFactor * 0.6 end
        targetWalkIntensity = speedFactor
    end

    state.walkIntensity = FILerp(dt, state.walkIntensity, targetWalkIntensity, cfg.smoothSpeed)

    if state.walkIntensity > 0.01 then
        local cycleSpeed = cfg.walkCycleSpeed * (isSprinting and 1.4 or 1) * (isCrouching and 0.7 or 1)
        state.walkPhase = state.walkPhase + dt * cycleSpeed
    end

    local currentStepPhase = math.floor(state.walkPhase * 2 / math.pi) % 2
    if currentStepPhase != state.lastStepPhase and state.walkIntensity > 0.3 then
        state.stepImpact = cfg.stepImpact * state.walkIntensity
    end
    state.lastStepPhase = currentStepPhase
    state.stepImpact = FILerp(dt, state.stepImpact, 0, 15)

    local walkHoriz = Figure8Pattern(state.walkPhase, cfg.horizontalAmp * state.walkIntensity * adsMult)
    local walkVert = math.abs(math.sin(state.walkPhase * 2)) * cfg.verticalAmp * state.walkIntensity * adsMult - state.stepImpact
    local walkRoll = math.sin(state.walkPhase) * cfg.rollAmp * state.walkIntensity * adsMult
    local walkPitch = math.sin(state.walkPhase * 2 + 0.5) * cfg.pitchAmp * state.walkIntensity * adsMult

    local currentEyeAngles = client:EyeAngles()
    local angleDelta = Angle(
        math.AngleDifference(currentEyeAngles.p, state.lastEyeAngles.p),
        math.AngleDifference(currentEyeAngles.y, state.lastEyeAngles.y),
        0
    )
    state.lastEyeAngles = currentEyeAngles

    local swayAmount = cfg.lookSway * adsMult * 0.1
    state.lookSwayOffset.p = math.Clamp(state.lookSwayOffset.p - angleDelta.p * swayAmount, -3, 3)
    state.lookSwayOffset.y = math.Clamp(state.lookSwayOffset.y - angleDelta.y * swayAmount, -5, 5)
    state.lookSwayOffset = FILerpAngle(dt, state.lookSwayOffset, Angle(0, 0, 0), cfg.lookSwayReturn)

    local targetStrafeRoll = 0
    if speed2D > 20 then
        local rightDir = ang:Right()
        local strafeAmount = vel:Dot(rightDir) / 200
        targetStrafeRoll = math.Clamp(strafeAmount, -1, 1) * cfg.strafeTilt * adsMult
    end
    state.strafeRoll = FILerp(dt, state.strafeRoll, targetStrafeRoll, cfg.strafeTiltSpeed)

    if !isOnGround and state.wasOnGround then
        state.fallStartTime = currentTime
        state.jumpStartTime = currentTime
        state.isInAir = true
    elseif isOnGround and !state.wasOnGround then
        state.airTime = currentTime - state.fallStartTime
        state.landingImpact = math.Clamp(state.airTime * 3, 0.3, 4) * cfg.landingIntensity
        state.landingTime = currentTime
        state.isInAir = false
    end
    state.wasOnGround = isOnGround

    local landingOffset = 0
    local landingPitch = 0
    local landingRoll = 0
    if state.landingTime > 0 then
        local timeSince = currentTime - state.landingTime
        local duration = 0.3
        if timeSince < duration then
            local progress = timeSince / duration
            local curve = math.sin(progress * math.pi) * (1 - progress * 0.3)
            landingOffset = -state.landingImpact * curve
            landingPitch = state.landingImpact * 0.7 * curve
            if state.landingImpact > 1.5 then
                landingRoll = math.sin(progress * math.pi * 3) * state.landingImpact * 0.2
            end
        end
    end

    local targetJumpPitch = 0
    local targetJumpFov = 0
    if state.isInAir then
        if vel.z > 50 then
            targetJumpPitch = -cfg.jumpTilt * math.Clamp(vel.z / 300, 0, 1)
            targetJumpFov = cfg.jumpFovEffect * 0.5
        elseif vel.z < -100 then
            targetJumpPitch = cfg.jumpTilt * 0.3 * math.Clamp(-vel.z / 500, 0, 1)
            targetJumpFov = cfg.jumpFovEffect * math.Clamp(-vel.z / 400, 0, 1.5)
        end
    end
    state.jumpPitch = FILerp(dt, state.jumpPitch, targetJumpPitch, cfg.smoothSpeed)
    state.jumpFov = FILerp(dt, state.jumpFov, targetJumpFov, cfg.smoothSpeed * 0.7)

    local targetAirTilt = Angle(0, 0, 0)
    if state.isInAir and cfg.airControlTilt > 0 then
        local rightDir = ang:Right()
        local forwardDir = ang:Forward()
        local sideVel = vel:Dot(rightDir) / 200
        local forwardVel = vel:Dot(forwardDir) / 300
        targetAirTilt.r = math.Clamp(sideVel, -1, 1) * cfg.airControlTilt * 2
        targetAirTilt.p = math.Clamp(-forwardVel, -1, 1) * cfg.airControlTilt
    end
    state.airTilt = FILerpAngle(dt, state.airTilt, targetAirTilt, cfg.smoothSpeed)

    local targetCrouchPitch = 0
    local targetCrouchRoll = 0

    if isCrouching and !state.wasCrouching then
        state.crouchStartTime = currentTime
        state.crouchTransition = 1
    elseif !isCrouching and state.wasCrouching then
        state.crouchStartTime = currentTime
        state.crouchTransition = -1
    end
    state.wasCrouching = isCrouching

    local crouchTransitionOffset = 0
    if state.crouchStartTime > 0 then
        local timeSince = currentTime - state.crouchStartTime
        local duration = 0.2
        if timeSince < duration then
            local progress = timeSince / duration
            local curve = math.sin(progress * math.pi)
            crouchTransitionOffset = curve * cfg.crouchTransition * state.crouchTransition * 0.5
        end
    end

    if isCrouching then
        targetCrouchPitch = cfg.crouchTilt
        if state.walkIntensity > 0.1 then
            targetCrouchRoll = math.sin(state.walkPhase * 1.5) * cfg.crouchRoll * state.walkIntensity
        end
    end

    state.crouchPitch = FILerp(dt, state.crouchPitch, targetCrouchPitch, cfg.smoothSpeed)
    state.crouchRoll = FILerp(dt, state.crouchRoll, targetCrouchRoll, cfg.smoothSpeed)

    local targetSprintTilt = 0
    local targetSprintFov = 0
    if isSprinting then
        targetSprintTilt = cfg.speedTilt
        targetSprintFov = cfg.speedFov
    end
    state.sprintTilt = FILerp(dt, state.sprintTilt, targetSprintTilt, cfg.smoothSpeed * 0.5)
    state.sprintFov = FILerp(dt, state.sprintFov, targetSprintFov, cfg.smoothSpeed * 0.5)

    state.breathPhase = state.breathPhase + dt * cfg.breathingSpeed
    local breathingMult = (1 - state.walkIntensity * 0.7) * cfg.breathingIntensity * adsMult
    local breathPitch = (math.sin(state.breathPhase) + math.sin(state.breathPhase * 0.5) * 0.3) * breathingMult
    local breathRoll = math.sin(state.breathPhase * 0.7 + 1) * breathingMult * 0.3
    local breathOffset = math.sin(state.breathPhase) * breathingMult * 0.1

    state.damageShake = FILerpAngle(dt, state.damageShake, Angle(0, 0, 0), 8)

    local finalOffset = Vector(
        walkHoriz,
        0,
        walkVert + landingOffset + crouchTransitionOffset + breathOffset
    )

    local finalAngles = Angle(
        walkPitch + state.lookSwayOffset.p + landingPitch + state.jumpPitch +
        state.crouchPitch + state.sprintTilt + breathPitch +
        state.airTilt.p + state.damageShake.p,

        state.lookSwayOffset.y + state.damageShake.y,

        walkRoll + state.strafeRoll + landingRoll + state.crouchRoll +
        breathRoll + state.airTilt.r + state.damageShake.r
    )

    local finalFovOffset = state.jumpFov + state.sprintFov

    state.offset = FILerpVector(dt, state.offset, finalOffset, cfg.smoothSpeed)
    state.angles = FILerpAngle(dt, state.angles, finalAngles, cfg.smoothSpeed)
    state.fovOffset = FILerp(dt, state.fovOffset, finalFovOffset, cfg.smoothSpeed)

    return state.offset, state.angles, state.fovOffset
end

ax.viewstack:RegisterModifier("weapon_effects", function(client, patch)
    if ( hook.Run("ShouldDrawLocalPlayer", client) ) then return end
    if ( client:GetMoveType() != MOVETYPE_WALK ) then return end

    local pos = patch.origin
    local ang = patch.angles
    local fov = patch.fov

    local offset, anglesOffset, fovOffset = CalculateCameraEffects(client, ang)
    pos = pos + ang:Right() * offset.x + ang:Forward() * offset.y + ang:Up() * offset.z
    ang:RotateAroundAxis(ang:Right(),    anglesOffset.p)
    ang:RotateAroundAxis(ang:Up(),       anglesOffset.y)
    ang:RotateAroundAxis(ang:Forward(),  anglesOffset.r)
    fov = fov + fovOffset

    return { origin = pos, angles = ang, fov = fov }
end, 1)
