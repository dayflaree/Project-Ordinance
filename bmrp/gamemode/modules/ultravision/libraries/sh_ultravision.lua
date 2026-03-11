--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Shared ultravision helpers.
-- @module ax.ultravision

ax.ultravision = ax.ultravision or {}

ax.ultravision.active = ax.ultravision.active or false
ax.ultravision.nextLightUpdate = ax.ultravision.nextLightUpdate or 0
ax.ultravision.playerState = ax.ultravision.playerState or {}

local RADIUS_MIN, RADIUS_MAX = 64, 1024
local BRIGHTNESS_MIN, BRIGHTNESS_MAX = 0.05, 3
local DECAY_MIN, DECAY_MAX = 100, 3000
local DIETIME_MIN, DIETIME_MAX = 0.05, 1
local INTERVAL_MIN, INTERVAL_MAX = 0.01, 0.5

function ax.ultravision:IsModuleEnabled()
    return ax.config:Get("ultravision.enabled", true) == true
end

function ax.ultravision:GetRadius()
    local value = tonumber(ax.config:Get("ultravision.radius", 220)) or 220
    return math.Clamp(value, RADIUS_MIN, RADIUS_MAX)
end

function ax.ultravision:GetBrightness()
    local value = tonumber(ax.config:Get("ultravision.brightness", 0.6)) or 0.6
    return math.Clamp(value, BRIGHTNESS_MIN, BRIGHTNESS_MAX)
end

function ax.ultravision:GetDecay()
    local value = tonumber(ax.config:Get("ultravision.decay", 120)) or 120
    return math.Clamp(value, DECAY_MIN, DECAY_MAX)
end

function ax.ultravision:GetDietime()
    local value = tonumber(ax.config:Get("ultravision.dietime", 0.12)) or 0.12
    return math.Clamp(value, DIETIME_MIN, DIETIME_MAX)
end

function ax.ultravision:GetMinInterval()
    local value = tonumber(ax.config:Get("ultravision.minInterval", 0.05)) or 0.05
    return math.Clamp(value, INTERVAL_MIN, INTERVAL_MAX)
end

function ax.ultravision:OnConfigChanged(key, oldValue, value)
    if ( key != "ultravision.enabled" ) then return end

    if ( SERVER and isfunction(self.RefreshAllStates) ) then
        self:RefreshAllStates()
    elseif ( CLIENT and value == false and isfunction(self.SetActive) ) then
        self:SetActive(false)
    end
end
