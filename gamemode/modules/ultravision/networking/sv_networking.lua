--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Send authoritative ultravision state to one client.
-- Net payload is a single bool: enabled.
function ax.ultravision:SendState(client, enabled)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    ax.net:Start(client, "ultravision.state", enabled == true)
end
