--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

util.AddNetworkString("ax.security_cameras.request_camera")
util.AddNetworkString("ax.security_cameras.fetch_camera")
util.AddNetworkString("ax.security_cameras.sync_night_vision")
util.AddNetworkString("ax.security_cameras.sync_station_selection")
util.AddNetworkString("ax.security_cameras.initial_sync")

net.Receive("ax.security_cameras.sync_night_vision", function(len, client)
    local uniqueID = net.ReadString()
    local nightVision = net.ReadBool()

    local cameraData = MODULE:GetCameraByID(uniqueID)
    if ( !cameraData ) then return end

    cameraData.nightVision = nightVision

    -- Broadcast to all clients
    net.Start("ax.security_cameras.sync_night_vision")
        net.WriteString(uniqueID)
        net.WriteBool(nightVision)
    net.Broadcast()
end)

net.Receive("ax.security_cameras.sync_station_selection", function(len, client)
    local stationUniqueID = net.ReadString()
    local screenIndex = net.ReadInt(8)
    local cameraUniqueID = net.ReadString()

    -- Update server state
    if ( MODULE:SetStationCameraSelection(stationUniqueID, screenIndex, cameraUniqueID) ) then
        -- Broadcast to all other clients
        net.Start("ax.security_cameras.sync_station_selection")
            net.WriteString(stationUniqueID)
            net.WriteInt(screenIndex, 8)
            net.WriteString(cameraUniqueID)
        net.Broadcast()
    end
end)

net.Receive("ax.security_cameras.request_camera", function(len, client)
    local uniqueID = net.ReadString()

    -- Validate the requested camera
    local cameraData = nil
    for index, data in ipairs(MODULE.cameras) do
        if ( data.uniqueID == uniqueID ) then
            cameraData = data
            break
        end
    end

    if ( !cameraData ) then
        if ( uniqueID == "" ) then
            client:SetRelay("security_camera", "")
            return
        end

        ax.util:PrintWarning("Client " .. tostring(client) .. " requested invalid security camera ID: " .. tostring(uniqueID))
        return
    end

    client:SetRelay("security_camera", cameraData.uniqueID)

    -- Send the camera data back to the client
    net.Start("ax.security_cameras.fetch_camera")
        net.WriteString(cameraData.uniqueID)
    net.Send(client)
end)

function MODULE:SyncToPlayer(player)
    -- Sync station selections
    local selections = self.stationCameraSelections or {}
    
    -- Sync night vision states
    local nvStates = {}
    for _, camera in ipairs(self.cameras or {}) do
        if ( camera.nightVision ) then
            nvStates[camera.uniqueID] = true
        end
    end

    net.Start("ax.security_cameras.initial_sync")
        net.WriteTable(selections)
        net.WriteTable(nvStates)
    net.Send(player)
end
