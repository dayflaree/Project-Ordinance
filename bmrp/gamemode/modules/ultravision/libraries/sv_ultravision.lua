--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Server-side ultravision authority.
-- @module ax.ultravision

ax.ultravision = ax.ultravision or {}
ax.ultravision.playerState = ax.ultravision.playerState or {}

local function GetPlayerStateKey(client)
    if ( !ax.util:IsValidPlayer(client) ) then return nil end

    local key = client:SteamID64()
    if ( !isstring(key) or key == "" or key == "0" ) then
        key = "bot:" .. tostring(client:EntIndex())
    end

    return key
end

function ax.ultravision:GetPlayerUltravision(client)
    local key = GetPlayerStateKey(client)
    if ( !key ) then return false end

    return self.playerState[key] == true
end

--- Server setter for per-player state with change-only networking.
-- @param client Player
-- @param enabled boolean
-- @return boolean changed
function ax.ultravision:SetPlayerUltravision(client, enabled)
    local key = GetPlayerStateKey(client)
    if ( !key ) then return false end

    enabled = enabled == true

    if ( self.playerState[key] == enabled ) then
        return false
    end

    self.playerState[key] = enabled

    if ( isfunction(self.SendState) ) then
        self:SendState(client, enabled)
    else
        ax.net:Start(client, "ultravision.state", enabled)
    end

    return true
end

function ax.ultravision:ClearPlayerState(client)
    local key = GetPlayerStateKey(client)
    if ( !key ) then return end

    self.playerState[key] = nil
end

function ax.ultravision:ShouldEnableForPlayer(client)
    if ( !ax.util:IsValidPlayer(client) ) then return false end
    if ( !self:IsModuleEnabled() ) then return false end

    -- Schema override hook entry point.
    if ( hook.Run("ShouldEnableUltravision", client) == false ) then
        return false
    end

    return true
end

function ax.ultravision:RefreshPlayerState(client)
    if ( !ax.util:IsValidPlayer(client) ) then return false end

    return self:SetPlayerUltravision(client, self:ShouldEnableForPlayer(client))
end

function ax.ultravision:RefreshAllStates()
    for _, client in ipairs(player.GetAll()) do
        if ( !ax.util:IsValidPlayer(client) ) then continue end
        self:RefreshPlayerState(client)
    end
end
