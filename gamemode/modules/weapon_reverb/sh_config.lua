--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Volume control
ax.config:Add("weaponReverbVolume", ax.type.number, 100, {min = 0, max = 200, decimals = 0, category = "audio", subCategory = "weapons", description = "Global volume multiplier (percent)."})

-- Sound speed and delay
ax.config:Add("weaponReverbSoundSpeed", ax.type.number, 343, {min = 0, max = 100000, decimals = 0, category = "audio", subCategory = "weapons", description = "Speed of sound (m/s)."})
ax.config:Add("weaponReverbDisableDelay", ax.type.bool, true, {category = "audio", subCategory = "weapons", description = "Disable delay caused by sound travel time."})

-- Indoor/outdoor control
ax.config:Add("weaponReverbDisableIndoors", ax.type.bool, false, {category = "audio", subCategory = "weapons", description = "Disable reverb if source is indoors."})
ax.config:Add("weaponReverbDisableOutdoors", ax.type.bool, false, {category = "audio", subCategory = "weapons", description = "Disable reverb if source is outdoors."})

-- General control
ax.config:Add("weaponReverbDisable", ax.type.bool, false, {category = "audio", subCategory = "weapons", description = "Disable all weapon reverb."})

-- Occlusion settings
ax.config:Add("weaponReverbOcclusionRays", ax.type.number, 32, {min = 0, max = 64, decimals = 0, category = "audio", subCategory = "weapons", description = "Amount of traces for occlusion detection."})
ax.config:Add("weaponReverbOcclusionReflections", ax.type.number, 0, {min = 0, max = 10, decimals = 0, category = "audio", subCategory = "weapons", description = "Maximum ray reflections (0 = disable)."})
ax.config:Add("weaponReverbOcclusionMaxDist", ax.type.number, 100000, {min = 1000, max = 500000, decimals = 0, category = "audio", subCategory = "weapons", description = "Max occlusion ray distance (units)."})

-- Bullet cracks
ax.config:Add("weaponReverbDisableCracks", ax.type.bool, false, {category = "audio", subCategory = "weapons", description = "Disable bullet crack sounds."})

-- Process all sounds
ax.config:Add("weaponReverbProcessAll", ax.type.bool, false, {category = "audio", subCategory = "weapons", description = "Apply reverb/occlusion to all entity sounds."})

-- Networking (server-side)
ax.config:Add("weaponReverbNetworkSounds", ax.type.bool, false, {category = "audio", subCategory = "weapons", description = "Network server gunshots to clients (adds delay)."})
