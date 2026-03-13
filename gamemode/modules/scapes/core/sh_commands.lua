--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Resolve target players for scapes console command.
-- @tparam string identifier Optional player identifier.
-- @treturn table Target player array.
local function ResolveTargets(identifier)
    local targets = {}

    if ( !isstring(identifier) or identifier == "" ) then
        for _, client in player.Iterator() do
            if ( ax.util:IsValidPlayer(client) ) then
                targets[#targets + 1] = client
            end
        end

        return targets
    end

    local found = ax.util:FindPlayer(identifier)
    if ( ax.util:IsValidPlayer(found) ) then
        targets[1] = found
    end

    return targets
end

--- Server command helper for scape activation/deactivation.
-- @tparam Player caller Console caller (if player).
-- @tparam table args Raw argument list.
local function RunServerSetCommand(caller, args)
    if ( IsValid(caller) and !caller:IsAdmin() ) then
        caller:Notify("You do not have permission to use ax_scapes_set.")
        return
    end

    local scapeId = tostring(args[1] or "")
    local targetArg = tostring(args[2] or "")

    if ( scapeId == "" ) then
        ax.scapes:LogWarning("Usage: ax_scapes_set <scapeId|off> [player]")
        return
    end

    local targets = ResolveTargets(targetArg)
    if ( !targets[1] ) then
        ax.scapes:LogWarning("No valid targets found for ax_scapes_set.")
        return
    end

    local isOff = scapeId == "off" or scapeId == "none" or scapeId == "stop"
    local changed = 0

    for i = 1, #targets do
        local client = targets[i]

        if ( isOff ) then
            if ( ax.scapes:Deactivate(client, {}) ) then
                changed = changed + 1
            end
        else
            local ok, err = ax.scapes:Activate(client, scapeId, {forced = true})
            if ( ok ) then
                changed = changed + 1
            else
                ax.scapes:LogWarning(string.format("Failed to activate '%s' for %s: %s", scapeId, client:Nick(), tostring(err or "unknown")))
            end
        end
    end

    if ( isOff ) then
        ax.scapes:Log(string.format("Deactivated scapes for %d player(s).", changed))
    else
        ax.scapes:Log(string.format("Activated '%s' for %d player(s).", scapeId, changed))
    end
end

--- Client debug command helper.
-- @tparam table args Raw argument list.
local function RunClientDebugCommand(args)
    local value = tonumber(args[1])
    local enabled = value == 1

    ax.scapes:SetDebugEnabled(enabled)

    ax.scapes:Log("Debug overlay " .. (enabled and "enabled" or "disabled"))
end

--- Server command helper for triggering stingers.
-- @tparam Player caller Console caller (if player).
-- @tparam table args Raw argument list.
local function RunServerTriggerCommand(caller, args)
    if ( IsValid(caller) and !caller:IsAdmin() ) then
        caller:Notify("You do not have permission to use ax_scapes_trigger.")
        return
    end

    local triggerName = tostring(args[1] or "")
    local targetArg = tostring(args[2] or "")

    if ( triggerName == "" ) then
        ax.scapes:LogWarning("Usage: ax_scapes_trigger <triggerName> [player]")
        return
    end

    local targets = ResolveTargets(targetArg)
    if ( !targets[1] ) then
        ax.scapes:LogWarning("No valid targets found for ax_scapes_trigger.")
        return
    end

    local changed = 0
    for i = 1, #targets do
        local client = targets[i]
        local ok, err = ax.scapes:Trigger(client, triggerName, {})
        if ( ok ) then
            changed = changed + 1
        else
            ax.scapes:LogWarning(string.format("Failed to trigger '%s' for %s: %s", triggerName, client:Nick(), tostring(err or "unknown")))
        end
    end

    ax.scapes:Log(string.format("Triggered '%s' for %d player(s).", triggerName, changed))
end

--- Handler wrapper for the `ax_scapes_set` concommand.
-- @tparam Player caller Command caller.
-- @tparam string cmd Command name.
-- @tparam table args Argument array.
local function HandleServerSetConCommand(caller, cmd, args)
    RunServerSetCommand(caller, args)
end

--- Handler wrapper for the `ax_scapes_trigger` concommand.
-- @tparam Player caller Command caller.
-- @tparam string cmd Command name.
-- @tparam table args Argument array.
local function HandleServerTriggerConCommand(caller, cmd, args)
    RunServerTriggerCommand(caller, args)
end

--- Handler wrapper for the `ax_scapes_debug` concommand.
-- @tparam Player caller Command caller.
-- @tparam string cmd Command name.
-- @tparam table args Argument array.
local function HandleClientDebugConCommand(caller, cmd, args)
    RunClientDebugCommand(args)
end

if ( SERVER ) then
    concommand.Add("ax_scapes_set", HandleServerSetConCommand)
    concommand.Add("ax_scapes_trigger", HandleServerTriggerConCommand)
end

if ( CLIENT ) then
    concommand.Add("ax_scapes_debug", HandleClientDebugConCommand)
end
