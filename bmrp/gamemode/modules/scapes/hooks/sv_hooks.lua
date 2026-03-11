--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( CLIENT ) then return end

--- Initialize Scapes ready state for connecting players.
-- @tparam Player client Joining player.
local function HandlePlayerInitialSpawn(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    ax.scapes.readyClients[client:SteamID64()] = false
    ax.scapes:LogDebug("Player initial spawn:", client:Nick(), "[" .. client:SteamID64() .. "]")

    if ( isfunction(ax.scapes.ClearAutoTriggerState) ) then
        ax.scapes:ClearAutoTriggerState(client)
    end
end

--- Cleanup session state when a player disconnects.
-- @tparam Player client Disconnecting player.
local function HandlePlayerDisconnected(client)
    if ( !client or !isfunction(client.SteamID64) ) then return end

    ax.scapes:LogDebug("Player disconnected:", tostring(client))
    ax.scapes:CleanupSession(client, true)
    ax.scapes.readyClients[client:SteamID64()] = nil
    ax.scapes.pendingSessions[client:SteamID64()] = nil

    if ( isfunction(ax.scapes.ClearAutoTriggerState) ) then
        ax.scapes:ClearAutoTriggerState(client)
    end
end

--- Parse NikNaks env_soundscape data after map entities initialize.
local function HandleInitPostEntity()
    if ( !isfunction(ax.scapes.RebuildAutoSoundscapes) ) then return end

    local ok, detail = ax.scapes:RebuildAutoSoundscapes()
    if ( !ok ) then
        ax.scapes:LogWarning("InitPostEntity auto-soundscape rebuild failed:", tostring(detail))
    else
        ax.scapes:LogDebug("InitPostEntity auto-soundscape rebuild succeeded:", tostring(detail))
    end
end

--- Cleanup all active sessions after map cleanup.
local function HandlePostCleanupMap()
    ax.scapes:CleanupAllSessions(true)
    ax.scapes:LogDebug("PostCleanupMap: sessions cleaned.")

    if ( isfunction(ax.scapes.RebuildAutoSoundscapes) ) then
        timer.Simple(0, function()
            ax.scapes:LogDebug("PostCleanupMap: rebuilding auto soundscapes.")
            ax.scapes:RebuildAutoSoundscapes()
        end)
    end
end

--- Cleanup all active sessions on shutdown.
local function HandleShutdown()
    ax.scapes:CleanupAllSessions(true)
    ax.scapes:LogDebug("ShutDown: cleaned active scape sessions.")

    if ( isfunction(ax.scapes.ClearAutoTriggerState) ) then
        ax.scapes:ClearAutoTriggerState()
    end
end

--- Reapply active scape DSP after player loadout.
-- @tparam Player client Spawned player.
local function HandlePostPlayerLoadout(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    if ( !isfunction(ax.scapes.ReapplyActiveDSP) ) then return end

    ax.scapes:ReapplyActiveDSP(client, "post_player_loadout")
end

--- Run periodic map auto-trigger evaluation.
local function HandleThink()
    if ( !isfunction(ax.scapes.AutoTriggerThink) ) then return end

    ax.scapes:AutoTriggerThink()
end

hook.Add("InitPostEntity", "ax.scapes.InitPostEntity", HandleInitPostEntity)
hook.Add("PlayerInitialSpawn", "ax.scapes.PlayerInitialSpawn", HandlePlayerInitialSpawn)
hook.Add("PlayerDisconnected", "ax.scapes.PlayerDisconnected", HandlePlayerDisconnected)
hook.Add("PostCleanupMap", "ax.scapes.PostCleanupMap", HandlePostCleanupMap)
hook.Add("Think", "ax.scapes.AutoTriggerThink", HandleThink)
hook.Add("ShutDown", "ax.scapes.ShutDown", HandleShutdown)
hook.Add("PostPlayerLoadout", "ax.scapes.PostPlayerLoadout", HandlePostPlayerLoadout)
