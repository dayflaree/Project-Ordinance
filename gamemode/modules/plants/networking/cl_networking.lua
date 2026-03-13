--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

net.Receive("ax.plants.sync_hydration", function(len)
    local key = net.ReadString()
    local val = net.ReadFloat()

    if ( IsValid(MODULE.menu) and MODULE.menu.plantKey == key ) then
        MODULE.menu:UpdateWaterLevel(val)
    end
end)
