--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( CLIENT ) then return end

--- Handle Scapes client-ready handshake.
-- @tparam Player client Sender player.
-- @tparam number clientNow Client current time (informational).
local function HandleReady(client, clientNow)
    if ( !ax.util:IsValidPlayer(client) ) then
        ax.scapes:LogWarning("Received ready handshake from invalid client.")
        return
    end

    ax.scapes:LogDebug("Received ready handshake from", client:Nick(), "[" .. client:SteamID64() .. "]", "at", tostring(clientNow))
    ax.scapes:MarkClientReady(client)
end

ax.net:Hook(ax.scapes.NET_READY, HandleReady, true)
