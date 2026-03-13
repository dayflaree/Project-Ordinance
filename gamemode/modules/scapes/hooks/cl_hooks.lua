--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Send Scapes ready handshake after client entities initialize.
local function HandleInitPostEntity()
    ax.net:Start(ax.scapes.NET_READY, CurTime())
    ax.scapes:LogDebug("Sent ready handshake to server.")
end

--- Run client-side Scapes update loop.
local function HandleThink()
    ax.scapes:ClientThink()
end

--- Shutdown cleanup for client scapes runtime.
local function HandleShutdown()
    ax.scapes:LogDebug("Client shutdown cleanup.")
    ax.scapes:ClientShutdown()
end

--- Draw optional scapes debug overlay.
local function HandleHUDPaint()
    ax.scapes:DrawDebugOverlay()
end

--- Hook callback for legacy ambient pause checks.
-- @treturn boolean|nil True when legacy ambient should pause.
local function HandleAmbientMusicShouldPause()
    if ( ax.scapes:ShouldPauseLegacyAmbient() ) then
        return true
    end
end

hook.Add("InitPostEntity", "ax.scapes.InitPostEntity", HandleInitPostEntity)
hook.Add("Think", "ax.scapes.Think", HandleThink)
hook.Add("ShutDown", "ax.scapes.ShutDown", HandleShutdown)
hook.Add("HUDPaint", "ax.scapes.DebugHUD", HandleHUDPaint)
hook.Add("AmbientMusicShouldPause", "ax.scapes.LegacyAmbient", HandleAmbientMusicShouldPause)

--- Module hook fallback for legacy ambient pause checks.
-- @treturn boolean|nil True when legacy ambient should pause.
function MODULE:AmbientMusicShouldPause()
    return HandleAmbientMusicShouldPause()
end
