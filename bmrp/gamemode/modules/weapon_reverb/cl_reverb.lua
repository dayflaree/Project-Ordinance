--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Constants
local UNITS_TO_METERS = 0.01905
local MASK_GLOBAL = CONTENTS_WINDOW + CONTENTS_SOLID + CONTENTS_AREAPORTAL + CONTENTS_MONSTERCLIP + CONTENTS_CURRENT_0
local DISTANT_THRESHOLD = 150 -- meters

-- Sound file cache
local entries_cache = {}

-- Get ear position (accounts for view entities)
local function getEarPos()
    local lp = ax.client
    local viewEntityPos = lp:GetViewEntity():GetPos()

    if viewEntityPos:IsEqualTol(lp:GetPos(), 2) then
        return lp:EyePos()
    end

    return viewEntityPos
end

-- Check if position can see sky (outdoors detection)
local function traceableToSky(pos, offset)
    local traceToOffset = util.TraceLine({
        start = pos,
        endpos = pos + offset,
        mask = MASK_GLOBAL
    })

    local traceToSky = util.TraceLine({
        start = traceToOffset.HitPos,
        endpos = traceToOffset.HitPos + vector_up * 56754,
        mask = MASK_GLOBAL
    })

    return traceToSky.HitSky
end

-- Determine if position is indoors or outdoors
local function getPositionState(pos)
    -- Check multiple directions for better accuracy
    local offsets = {
        Vector(0, 0, 0),
        Vector(120, 0, 0),
        Vector(0, 120, 0),
        Vector(-120, 0, 0),
        Vector(0, -120, 0)
    }

    for _, offset in ipairs(offsets) do
        if traceableToSky(pos, offset) then
            return "outdoors"
        end
    end

    return "indoors"
end

-- Get distance state (close or distant)
local function getDistanceState(pos1, pos2)
    local distance = pos1:Distance(pos2) * UNITS_TO_METERS

    if distance > DISTANT_THRESHOLD then
        return "distant"
    else
        return "close"
    end
end

-- Get sound files matching a pattern
local function getEntriesStartingWith(pattern, array)
    if entries_cache[pattern] then
        return entries_cache[pattern]
    end

    local tempArray = {}
    pattern = string.lower(pattern)

    for _, path in ipairs(array) do
        path = string.lower(path)
        if string.StartWith(path, pattern) then
            table.insert(tempArray, path)
        end
    end

    if table.IsEmpty(tempArray) then
        -- Fallback sound
        return {}
    end

    entries_cache[pattern] = tempArray
    return tempArray
end

-- Calculate delay based on distance and sound speed
local function calculateDelay(distance, speed)
    if speed == 0 then return 0 end
    return distance / speed
end

-- Reflect vector off a surface
local function reflectVector(pVector, normal)
    local dn = 2 * pVector:Dot(normal)
    return pVector - normal * dn
end

-- Check if position can be reached via ray tracing with reflections
local function traceableToPos(earpos, pos, offset)
    local bounceLimit = ax.config:Get("weaponReverbOcclusionReflections", 0)
    local lastTrace = {}
    local maxDistance = ax.config:Get("weaponReverbOcclusionMaxDist", 100000)
    local totalDistance = 0
    local vec1 = Vector(1, 1, 1) * 0.5
    local negvec1 = Vector(1, 1, 1) * -0.5

    -- Offset positions slightly to avoid getting stuck in walls
    earpos = earpos + vector_up * 10
    pos = pos + vector_up * 10

    -- Initial trace
    local traceToOffset = util.TraceHull({
        start = earpos,
        endpos = earpos + offset,
        mask = MASK_GLOBAL,
        maxs = vec1,
        mins = negvec1
    })

    totalDistance = traceToOffset.HitPos:Distance(traceToOffset.StartPos)
    lastTrace = traceToOffset

    -- Reflection bounces
    for i = 1, bounceLimit do
        local bounceTrace = util.TraceHull({
            start = lastTrace.HitPos,
            endpos = lastTrace.HitPos + reflectVector(lastTrace.HitPos, lastTrace.Normal) * 56754,
            mask = MASK_GLOBAL,
            maxs = vec1,
            mins = negvec1
        })

        if bounceTrace.StartSolid or bounceTrace.AllSolid then break end

        totalDistance = totalDistance + bounceTrace.HitPos:Distance(bounceTrace.StartPos)
        lastTrace = bounceTrace
    end

    -- Final trace to target
    local traceLastTraceToPos = util.TraceHull({
        start = lastTrace.HitPos,
        endpos = pos,
        mask = MASK_GLOBAL,
        maxs = vec1,
        mins = negvec1
    })

    totalDistance = totalDistance + traceLastTraceToPos.HitPos:Distance(traceLastTraceToPos.StartPos)

    if totalDistance > maxDistance then return false end

    return (traceLastTraceToPos.HitPos == pos)
end

-- Calculate occlusion percentage (how blocked is the sound path)
local function getOcclusionPercent(earpos, pos)
    local traceAmount = math.floor(ax.config:Get("weaponReverbOcclusionRays", 32) / 4)
    local degrees = 360 / traceAmount
    local successfulTraces = 0
    local failedTraces = 0
    local x_vector_offset = Vector(56754, 0, 0)

    for j = 1, 4 do
        local singletrace = x_vector_offset
        singletrace.x = 56754
        singletrace.y = 0
        singletrace.z = 0

        local angle
        if j == 1 then
            angle = Angle(degrees, 0)
        elseif j == 2 then
            angle = Angle(degrees, degrees)
        elseif j == 3 then
            angle = Angle(-degrees, degrees)
        elseif j == 4 then
            angle = Angle(0, degrees)
        end

        for i = 1, traceAmount do
            singletrace:Rotate(angle)
            local traceToPos = traceableToPos(earpos, pos, singletrace)
            successfulTraces = successfulTraces + (traceToPos and 1 or 0)
            failedTraces = failedTraces + (traceToPos and 0 or 1)
        end
    end

    return failedTraces / (traceAmount * 4)
end

-- Process sound data (occlusion, volume falloff)
local function processSound(data, isWeapon)
    local earpos = getEarPos()
    local src = data.Pos
    local dsp = 0
    local distance = earpos:Distance(src) * UNITS_TO_METERS
    local volume = data.Volume

    -- Trace to sound source
    local traceToSrc = util.TraceLine({
        start = earpos,
        endpos = src,
        mask = MASK_GLOBAL
    })

    if not traceToSrc then return data end

    local direct = traceToSrc.HitPos:IsEqualTol(src, 2)

    -- Apply occlusion
    if not direct then
        local occlusionPercentage = getOcclusionPercent(earpos, src)

        if occlusionPercentage == 1 then
            dsp = 30 -- Lowpass filter
        end

        volume = volume * (1 - math.Clamp(occlusionPercentage - 0.5, 0, 0.5))
    end

    -- Distance-based volume falloff (only for non-weapons)
    if not isWeapon then
        local distanceState = getDistanceState(src, earpos)

        if distanceState == "close" then
            local distanceMultiplier = math.Clamp(5000 / distance ^ 2, 0, 1)
            volume = volume * distanceMultiplier
        elseif distanceState == "distant" then
            local distanceMultiplier = math.Clamp(9000 / distance ^ 2, 0, 1)
            volume = volume * distanceMultiplier
        end
    end

    data.Volume = volume
    data.DSP = dsp

    return data
end

-- Play reverb sound for weapon fire
function weapon_reverb:PlayReverb(src, ammotype, isSuppressed, weapon)
    -- Check if reverb is disabled
    if ax.config:Get("weaponReverbDisable", false) then return end
    if weapon.dwr_reverbDisable then return end

    local earpos = getEarPos()
    local volume = weapon.dwr_customVolume or 1

    local positionState = getPositionState(src)
    local earposState = getPositionState(earpos)

    -- Check indoor/outdoor toggles
    if ax.config:Get("weaponReverbDisableIndoors", false) and positionState == "indoors" then return end
    if ax.config:Get("weaponReverbDisableOutdoors", false) and positionState == "outdoors" then return end

    local distanceState = getDistanceState(src, earpos)
    ammotype = weapon.dwr_customAmmoType or self:FormatAmmoType(ammotype)

    -- Apply suppression volume reduction
    if weapon.dwr_customIsSuppressed ~= nil then
        isSuppressed = weapon.dwr_customIsSuppressed
    end

    if isSuppressed then
        volume = volume * 0.25
    end

    local soundLevel = 0 -- Play everywhere
    local soundFlags = SND_DO_NOT_OVERWRITE_EXISTING_ON_CHANNEL
    local pitch = math.random(94, 107)
    local dsp = 0
    local distance = earpos:Distance(src) * UNITS_TO_METERS

    -- Direct line of sight check
    local traceToSrc = util.TraceLine({
        start = earpos,
        endpos = src,
        mask = MASK_GLOBAL
    })

    local direct = traceToSrc.HitPos:IsEqualTol(src, 2)
    local occlusionPercentage = 0

    if not direct then
        occlusionPercentage = getOcclusionPercent(earpos, src)

        -- Apply lowpass if heavily occluded and not both outdoors
        if positionState ~= "outdoors" or earposState ~= "outdoors" then
            if occlusionPercentage == 1 then
                dsp = 30
            end
        end

        volume = volume * (1 - math.Clamp(occlusionPercentage - 0.5, 0, 0.5))
    end

    -- Distance-based volume
    if distanceState == "close" then
        local distanceMultiplier = math.Clamp(5000 / distance ^ 2, 0, 1)
        volume = volume * distanceMultiplier
    elseif distanceState == "distant" then
        local distanceMultiplier = math.Clamp(10000 / distance ^ 2, 0, 1)

        if positionState == "outdoors" then
            volume = volume * distanceMultiplier * 2
        else
            volume = volume * distanceMultiplier * 0.5
        end
    end

    -- Select reverb sounds
    local soundspeed = ax.config:Get("weaponReverbSoundSpeed", 343)
    if ax.config:Get("weaponReverbDisableDelay", true) then
        soundspeed = 0
    end

    local reverbQueue = {}
    local reverbOptions = getEntriesStartingWith("dwr/" .. ammotype .. "/" .. positionState .. "/" .. distanceState .. "/", self.reverbFiles)
    local reverbSoundFile = reverbOptions[math.random(#reverbOptions)]
    table.insert(reverbQueue, reverbSoundFile)

    -- Add outdoor reverb if player is outdoors and source is indoors
    if earposState == "outdoors" and positionState == "indoors" then
        local outdoorOptions = getEntriesStartingWith("dwr/" .. ammotype .. "/outdoors/" .. distanceState .. "/", self.reverbFiles)
        local outdoorSound = outdoorOptions[math.random(#outdoorOptions)]
        table.insert(reverbQueue, outdoorSound)
    end

    -- Play reverb with delay
    timer.Simple(calculateDelay(distance, soundspeed), function()
        for _, path in ipairs(reverbQueue) do
            local mult = 1

            if #reverbQueue > 1 and string.find(path, "indoors") then
                mult = 0.5
            elseif #reverbQueue > 1 then
                mult = 1
            end

            EmitSound(path, earpos, -2, CHAN_AUTO, volume * (ax.config:Get("weaponReverbVolume", 100) / 100) / #reverbQueue * mult, soundLevel, soundFlags, pitch, dsp)
        end
    end)
end

-- Play bullet crack sound
function weapon_reverb:PlayBulletCrack(src, dir, vel, spread, ammotype, weapon)
    if ax.config:Get("weaponReverbDisableCracks", false) then return end
    if weapon.dwr_cracksDisable then return end

    local earpos = getEarPos()
    local distanceState = getDistanceState(src, earpos)
    local volume = 1
    local dsp = 0
    local soundLevel = 140
    local soundFlags = SND_DO_NOT_OVERWRITE_EXISTING_ON_CHANNEL
    local pitch = math.random(94, 107)

    -- Calculate bullet trajectory
    local calculateSpread = function(dir, spread)
        local radius = math.Rand(0, 1)
        local theta = math.Rand(0, math.rad(360))
        local bulletang = dir:Angle()
        local forward, right, up = bulletang:Forward(), bulletang:Right(), bulletang:Up()
        local x = radius * math.sin(theta)
        local y = radius * math.cos(theta)

        return (dir + right * spread.x * x + up * spread.y * y)
    end

    local trajectory = util.TraceLine({
        start = src,
        endpos = src + calculateSpread(dir, spread) * 56754,
        mask = MASK_GLOBAL
    })

    -- Distance to bullet path
    local distanceToLine, point = util.DistanceToLine(trajectory.StartPos, trajectory.HitPos, earpos)

    if distanceToLine * UNITS_TO_METERS > 10 then
        return -- Too far from bullet path
    end

    -- Check occlusion
    local traceToSrc = util.TraceLine({
        start = earpos,
        endpos = point,
        mask = MASK_GLOBAL
    })

    local direct = traceToSrc.HitPos:IsEqualTol(point, 2)

    if not direct then
        dsp = 30
    end

    local crackOptions = getEntriesStartingWith("dwr/bulletcracks/" .. distanceState .. "/", self.reverbFiles)
    local crackSound = crackOptions[math.random(#crackOptions)]
    if not crackSound or crackSound == "" then return end

    local delay = calculateDelay(trajectory.StartPos:Distance(trajectory.HitPos), vel:Length())

    timer.Simple(delay, function()
        EmitSound(crackSound, point, -1, CHAN_AUTO, volume * (ax.config:Get("weaponReverbVolume", 100) / 100), soundLevel, soundFlags, pitch, dsp)
    end)
end

-- Export processSound function for use in hooks
weapon_reverb.ProcessSound = processSound
