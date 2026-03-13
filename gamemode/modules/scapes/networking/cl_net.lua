--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( SERVER ) then return end

--- Handle full session activation payload.
-- @tparam number sessionId Session id.
-- @tparam string scapeId Scape id.
-- @tparam number serverNow Server current time.
-- @tparam number startAt Session start timestamp.
-- @tparam number fadeIn Fade in duration.
-- @tparam number fadeOut Fade out duration.
-- @tparam boolean pauseLegacyAmbient Pause legacy ambient flag.
-- @tparam table ctxPayload Serialized context payload.
-- @tparam table definition Scape definition payload.
-- @tparam table events Initial events.
local function HandleActivate(sessionId, scapeId, serverNow, startAt, fadeIn, fadeOut, pauseLegacyAmbient, ctxPayload, definition, events)
    ax.scapes:LogDebug("NET Activate:", tostring(scapeId), "session", tostring(sessionId), "events", tostring(istable(events) and #events or 0))
    ax.scapes:ClientActivate(sessionId, scapeId, serverNow, startAt, fadeIn, fadeOut, pauseLegacyAmbient, ctxPayload, definition, events)
end

--- Handle incremental schedule payload.
-- @tparam number sessionId Session id.
-- @tparam number serverNow Server current time.
-- @tparam table events Event array.
local function HandleSchedule(sessionId, serverNow, events)
    ax.scapes:LogDebug("NET Schedule: session", tostring(sessionId), "events", tostring(istable(events) and #events or 0))
    ax.scapes:ClientSchedule(sessionId, serverNow, events)
end

--- Handle session deactivation payload.
-- @tparam number sessionId Session id.
-- @tparam number serverNow Server current time.
-- @tparam number fadeOut Fade out duration.
local function HandleDeactivate(sessionId, serverNow, fadeOut)
    ax.scapes:LogDebug("NET Deactivate: session", tostring(sessionId), "fadeOut", tostring(fadeOut))
    ax.scapes:ClientDeactivate(sessionId, serverNow, fadeOut)
end

--- Handle trigger payload.
-- @tparam number sessionId Session id.
-- @tparam number serverNow Server current time.
-- @tparam table event Single event payload.
local function HandleTrigger(sessionId, serverNow, event)
    ax.scapes:LogDebug("NET Trigger: session", tostring(sessionId), "layer", tostring(istable(event) and event.layerName or "?"))
    ax.scapes:ClientTrigger(sessionId, serverNow, event)
end

ax.net:Hook(ax.scapes.NET_ACTIVATE, HandleActivate)
ax.net:Hook(ax.scapes.NET_SCHEDULE, HandleSchedule)
ax.net:Hook(ax.scapes.NET_DEACTIVATE, HandleDeactivate)
ax.net:Hook(ax.scapes.NET_TRIGGER, HandleTrigger)
