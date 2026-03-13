--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local REFRESH_INTERVAL = 0.1
local nextRefresh = 0

local function RefreshPlayer(client)
    if ( !ax.ultravision ) then return end
    if ( !ax.util:IsValidPlayer(client) ) then return end

    ax.ultravision:RefreshPlayerState(client)
end

local function HandleThink()
    if ( !ax.ultravision ) then return end

    local now = CurTime()
    if ( nextRefresh > now ) then return end

    nextRefresh = now + REFRESH_INTERVAL

    -- Polling fallback for sector systems that do not emit power/sector change events.
    ax.ultravision:RefreshAllStates()
end

local function HandlePlayerInitialSpawn(client)
    if ( !ax.ultravision ) then return end
    if ( !ax.util:IsValidPlayer(client) ) then return end

    -- Force a baseline so reconnects cannot keep stale clientside glow state.
    ax.ultravision:SetPlayerUltravision(client, false)

    timer.Simple(0, function()
        RefreshPlayer(client)
    end)
end

local function HandlePlayerReady(client)
    RefreshPlayer(client)
end

local function HandlePlayerSpawn(client)
    timer.Simple(0, function()
        RefreshPlayer(client)
    end)
end

local function HandlePlayerDeath(client)
    if ( !ax.ultravision ) then return end
    if ( !ax.util:IsValidPlayer(client) ) then return end

    ax.ultravision:SetPlayerUltravision(client, false)
end

local function HandlePlayerDisconnected(client)
    if ( !ax.ultravision ) then return end

    ax.ultravision:ClearPlayerState(client)
end

local function HandleOnReloaded()
    if ( !ax.ultravision ) then return end

    nextRefresh = 0
    ax.ultravision:RefreshAllStates()
end

hook.Add("Think", "ax.ultravision.Refresh", HandleThink)
hook.Add("PlayerInitialSpawn", "ax.ultravision.InitialSpawn", HandlePlayerInitialSpawn)
hook.Add("PlayerReady", "ax.ultravision.Ready", HandlePlayerReady)
hook.Add("PlayerSpawn", "ax.ultravision.Spawn", HandlePlayerSpawn)
hook.Add("PlayerDeath", "ax.ultravision.Death", HandlePlayerDeath)
hook.Add("PlayerDisconnected", "ax.ultravision.Cleanup", HandlePlayerDisconnected)
hook.Add("OnReloaded", "ax.ultravision.Reload", HandleOnReloaded)
