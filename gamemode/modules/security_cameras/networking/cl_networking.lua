--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

net.Receive("ax.security_cameras.fetch_camera", function()
    local uniqueID = net.ReadString()
    
    -- When the server replies confirming our requested camera PVS relay,
    -- we don't strictly need to do anything client-side anymore as our
    -- local prediction already handles the view switch.
end)

net.Receive("ax.security_cameras.sync_night_vision", function()
    local uniqueID = net.ReadString()
    local nightVision = net.ReadBool()

    local cameraData = MODULE:GetCameraByID(uniqueID)
    if ( cameraData ) then
        cameraData.nightVision = nightVision
    end
end)

net.Receive("ax.security_cameras.sync_station_selection", function()
    local stationUniqueID = net.ReadString()
    local screenIndex = net.ReadInt(8)
    local cameraUniqueID = net.ReadString()

    MODULE:SetStationCameraSelection(stationUniqueID, screenIndex, cameraUniqueID)
end)

net.Receive("ax.security_cameras.initial_sync", function()
    local selections = net.ReadTable()
    local nvStates = net.ReadTable()

    MODULE.stationCameraSelections = selections

    for uniqueID, state in pairs(nvStates) do
        local cameraData = MODULE:GetCameraByID(uniqueID)
        if ( cameraData ) then
            cameraData.nightVision = true
        end
    end
end)
