--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Resolve active scapes session for a player.
-- On client, only `LocalPlayer()` has scapes runtime state.
-- @treturn table|nil Session-like scapes state.
function ax.player.meta:GetScapeSession()
    if ( !IsValid(self) or !self:IsPlayer() ) then
        return nil
    end

    if ( SERVER ) then
        if ( !ax.scapes or !isfunction(ax.scapes.GetSession) ) then
            return nil
        end

        return ax.scapes:GetSession(self)
    end

    local localPlayer = LocalPlayer()
    if ( !IsValid(localPlayer) or self != localPlayer ) then
        return nil
    end

    local state = ax.scapes and ax.scapes.clientState
    if ( !istable(state) or (tonumber(state.activeSessionId) or 0) <= 0 ) then
        return nil
    end

    return {
        id = tonumber(state.activeSessionId) or 0,
        scapeId = tostring(state.activeScapeId or ""),
        priority = tonumber(state.activePriority) and math.floor(tonumber(state.activePriority)) or 0,
        dspPreset = tonumber(state.activeDSPPreset) and math.floor(tonumber(state.activeDSPPreset)) or nil,
        pauseLegacyAmbient = state.activePauseLegacyAmbient == true,
        ctx = state.context,
    }
end

--- Check whether the player has an active scape session.
-- @treturn boolean True when a scape is currently active.
function ax.player.meta:HasActiveScape()
    return istable(self:GetScapeSession())
end

--- Get active scape id for this player.
-- @treturn string|nil Active scape id.
function ax.player.meta:GetActiveScapeID()
    local session = self:GetScapeSession()
    if ( !istable(session) ) then
        return nil
    end

    local scapeId = tostring(session.scapeId or "")
    if ( scapeId == "" ) then
        return nil
    end

    return scapeId
end

--- Get active scape session id for this player.
-- @treturn number|nil Active session id.
function ax.player.meta:GetActiveScapeSessionID()
    local session = self:GetScapeSession()
    if ( !istable(session) ) then
        return nil
    end

    local sessionId = tonumber(session.id)
    if ( !isnumber(sessionId) ) then
        return nil
    end

    return math.floor(sessionId)
end

--- Get active scape priority for this player.
-- @treturn number Active priority (defaults to `0`).
function ax.player.meta:GetActiveScapePriority()
    local session = self:GetScapeSession()
    if ( !istable(session) ) then
        return 0
    end

    local priority = tonumber(session.priority)
    if ( !isnumber(priority) ) then
        return 0
    end

    return math.floor(priority)
end

--- Get active scape DSP preset for this player.
-- @treturn number|nil DSP preset id.
function ax.player.meta:GetActiveScapeDSPPreset()
    local session = self:GetScapeSession()
    if ( !istable(session) ) then
        return nil
    end

    local preset = tonumber(session.dspPreset)
    if ( !isnumber(preset) ) then
        return nil
    end

    return math.floor(preset)
end

--- Get active scape context for this player.
-- Returns a copied context table to avoid accidental mutation of runtime state.
-- @treturn table|nil Context table.
function ax.player.meta:GetActiveScapeContext()
    local session = self:GetScapeSession()
    if ( !istable(session) or !istable(session.ctx) ) then
        return nil
    end

    return table.Copy(session.ctx)
end

--- Check whether the active scape requests legacy ambient pause.
-- @treturn boolean True when legacy ambient should pause.
function ax.player.meta:ShouldPauseLegacyAmbientFromScape()
    local session = self:GetScapeSession()
    if ( !istable(session) ) then
        return false
    end

    return session.pauseLegacyAmbient == true
end
