--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

util.AddNetworkString("ax.plants.request_hydration")
util.AddNetworkString("ax.plants.sync_hydration")
util.AddNetworkString("ax.plants.perform_irrigation")

net.Receive("ax.plants.request_hydration", function(len, ply)
    local key = net.ReadString()
    
    -- Initialize with random value if not set
    if ( MODULE.hydration[key] == nil ) then
        MODULE.hydration[key] = math.Rand(0.6, 0.9)
    end

    local val = MODULE.hydration[key]

    net.Start("ax.plants.sync_hydration")
        net.WriteString(key)
        net.WriteFloat(val)
    net.Send(ply)
end)

net.Receive("ax.plants.perform_irrigation", function(len, ply)
    local character = ply:GetCharacter()
    if ( !character ) then return end

    local inventory = character:GetInventory()
    local watercan = nil
    
    -- Find a watercan with at least 1 unit of water
    for id, item in pairs(inventory:GetItems()) do
        if ( item.class == "watercan" ) then
            local water = item:GetData("water", 0)
            if ( water >= 1 ) then
                watercan = item
                break
            end
        end
    end

    if ( !watercan ) then
        ply:Notify("Your watering can is empty! Refill it at a sink.")
        return
    end

    local key = net.ReadString()
    
    -- Ensure initialized before irrigate
    if ( MODULE.hydration[key] == nil ) then
        MODULE.hydration[key] = math.Rand(0.6, 0.9)
    end

    local current = MODULE.hydration[key]
    if ( current >= 1.0 ) then
        ply:Notify("This plant is already fully hydrated!")
        return
    end

    local amount = ax.config:Get("plants.irrigation_amount", 0.25)
    local neededHydration = math.min(amount, 1.0 - current)
    
    -- 1 unit = 5% hydration (0.05)
    local unitsRequired = math.ceil(neededHydration / 0.05)
    local currentWater = watercan:GetData("water", 0)
    
    local unitsToUse = math.min(currentWater, unitsRequired)
    local finalAddedHydration = unitsToUse * 0.05
    local newLevel = math.min(1.0, current + finalAddedHydration)

    MODULE.hydration[key] = newLevel
    
    -- Subtract water
    local remaining = currentWater - unitsToUse
    watercan:SetData("water", remaining)

    if ( unitsToUse <= 0 ) then
        ply:Notify("Your watering can is empty!")
    end

    -- Sync back to the player
    net.Start("ax.plants.sync_hydration")
        net.WriteString(key)
        net.WriteFloat(newLevel)
    net.Send(ply)
end)
