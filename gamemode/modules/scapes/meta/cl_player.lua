--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Get the local active scape queue size.
-- Returns `0` for non-local players.
-- @treturn number Queued event count.
function ax.player.meta:GetActiveScapeQueueSize()
    local localPlayer = LocalPlayer()
    if ( !IsValid(localPlayer) or self != localPlayer ) then
        return 0
    end

    local state = ax.scapes and ax.scapes.clientState
    if ( !istable(state) or !istable(state.queue) ) then
        return 0
    end

    return #state.queue
end

--- Get current local active scape loop count.
-- Returns `0` for non-local players.
-- @treturn number Active loop count.
function ax.player.meta:GetActiveScapeLoopCount()
    local localPlayer = LocalPlayer()
    if ( !IsValid(localPlayer) or self != localPlayer ) then
        return 0
    end

    local state = ax.scapes and ax.scapes.clientState
    if ( !istable(state) or !istable(state.loops) ) then
        return 0
    end

    return table.Count(state.loops)
end

--- Get current local server clock offset used by Scapes.
-- Returns `0` for non-local players.
-- @treturn number Server offset in seconds.
function ax.player.meta:GetActiveScapeServerOffset()
    local localPlayer = LocalPlayer()
    if ( !IsValid(localPlayer) or self != localPlayer ) then
        return 0
    end

    local state = ax.scapes and ax.scapes.clientState
    if ( !istable(state) ) then
        return 0
    end

    return tonumber(state.serverOffset) or 0
end
