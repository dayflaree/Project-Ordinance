--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Client-side ultravision rendering.
-- @module ax.ultravision

ax.ultravision = ax.ultravision or {}
ax.ultravision.active = ax.ultravision.active or false
ax.ultravision.nextLightUpdate = ax.ultravision.nextLightUpdate or 0

local LIGHT_COLOR = Color(196, 212, 224)

function ax.ultravision:SetActive(enabled)
    enabled = enabled == true

    if ( self.active == enabled ) then return end

    self.active = enabled
    self.nextLightUpdate = 0

    if ( !enabled ) then
        self:ClearDynamicLight()
    end
end

function ax.ultravision:ShouldRender()
    if ( !self:IsModuleEnabled() ) then return false end
    if ( !self.active ) then return false end

    local client = LocalPlayer()
    if ( !ax.util:IsValidPlayer(client) ) then return false end
    if ( !client:Alive() ) then return false end

    return true
end

function ax.ultravision:ClearDynamicLight()
    local client = LocalPlayer()
    if ( !ax.util:IsValidPlayer(client) ) then return end

    local dlight = DynamicLight(client:EntIndex())
    if ( !dlight ) then return end

    dlight.dietime = CurTime()
    dlight.size = 0
end

function ax.ultravision:UpdateDynamicLight()
    if ( !self:ShouldRender() ) then return end

    local now = CurTime()
    if ( self.nextLightUpdate > now ) then return end

    self.nextLightUpdate = now + self:GetMinInterval()

    local client = LocalPlayer()
    local dlight = DynamicLight(client:EntIndex())
    if ( !dlight ) then return end

    dlight.pos = client:EyePos()
    dlight.r = LIGHT_COLOR.r
    dlight.g = LIGHT_COLOR.g
    dlight.b = LIGHT_COLOR.b
    dlight.brightness = self:GetBrightness()
    dlight.size = self:GetRadius()
    dlight.decay = self:GetDecay()
    dlight.dietime = now + self:GetDietime()
end
