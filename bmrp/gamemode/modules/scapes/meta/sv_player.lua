--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Get a copied active server scape session.
-- @treturn table|nil Active session copy.
function ax.player.meta:GetActiveScapeSessionData()
    if ( !isfunction(self.GetScapeSession) ) then
        return nil
    end

    local session = self:GetScapeSession()
    if ( !istable(session) ) then
        return nil
    end

    return table.Copy(session)
end

--- Get active scape resolved definition payload.
-- @treturn table|nil Resolved scape payload copy.
function ax.player.meta:GetActiveScapeResolved()
    if ( !isfunction(self.GetScapeSession) ) then
        return nil
    end

    local session = self:GetScapeSession()
    if ( !istable(session) or !istable(session.resolved) ) then
        return nil
    end

    return table.Copy(session.resolved)
end

--- Get DSP preset that Scapes will restore to when session ends.
-- @treturn number|nil Restore DSP preset.
function ax.player.meta:GetScapeDSPRestorePreset()
    if ( !isfunction(self.GetScapeSession) ) then
        return nil
    end

    local session = self:GetScapeSession()
    if ( !istable(session) ) then
        return nil
    end

    local restorePreset = tonumber(session.restoreDSP)
    if ( !isnumber(restorePreset) ) then
        return nil
    end

    return math.floor(restorePreset)
end
