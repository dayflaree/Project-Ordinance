--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]


ITEM.name = "Watering Can"
ITEM.description = "A heavy industrial can repurposed for watering plants."
ITEM.model = "models/props_industrial/petrolcan.mdl"
ITEM.width = 2
ITEM.height = 2
ITEM.weight = 5.0
ITEM.category = "Tools"

-- Capacity
ITEM.maxWater = 30
ITEM.data = nil -- Shadow any inherited class-level data to ensure instance uniqueness

-- Actions
ITEM:AddAction("check", {
    name = "Check Water Level",
    icon = "parallax/icons/glass-half.png",
    OnRun = function(action, item, ply)
        local amount = item:GetData("water", 0)
        local status = "empty"
        
        if ( amount >= item.maxWater ) then
            status = "full"
        elseif ( amount >= 25 ) then
            status = "nearly full"
        elseif ( amount >= 18 ) then
            status = "above half"
        elseif ( amount >= 12 ) then
            status = "about half full"
        elseif ( amount >= 6 ) then
            status = "below half"
        elseif ( amount > 0 ) then
            status = "mostly empty"
        end

        ply:Notify(string.format("The watering can is %s.", status))
        return false
    end
})

ITEM:AddAction("fill", {
    name = "Fill Watering Can",
    icon = "parallax/icons/drop-fill.png",
    CanUse = function(action, item, ply)
        if ( !IsValid(ply) ) then return false end
        
        local plants = ax.module:Get("plants")
        local sinkData = plants and plants:GetSinkInteraction(ply)
        if ( !sinkData ) then
            return false, "You must be near a kitchen sink to fill this!"
        end
        
        if ( item:GetData("water", 0) >= item.maxWater ) then
            return false, "This can is already full!"
        end
        
        return true
    end,
    OnRun = function(action, item, ply)
        local plants = ax.module:Get("plants")
        local sinkData = plants and plants:GetSinkInteraction(ply)
        if ( !sinkData ) then return false end

        if ( SERVER ) then
            -- Find closest sink button to the sink itself
            local closestBtn = nil
            local minDist = 22500 -- 150 units squared
            
            for _, ent in ipairs(ents.FindByClass("func_door")) do
                local name = ent:GetName():lower()
                if ( name:find("sink") and name:find("btn") ) then
                    local dist = sinkData.pos:DistToSqr(ent:GetPos())
                    if ( dist < minDist ) then
                        minDist = dist
                        closestBtn = ent
                    end
                end
            end
            
            if ( IsValid(closestBtn) ) then
                -- Try common activation inputs
                closestBtn:Fire("Open")
                closestBtn:Fire("Use", "", 0, ply, ply)
                closestBtn:Fire("Toggle")
            end
        end
        
        item:SetData("water", item.maxWater)
        ply:Notify("You have filled the watering can to full.")
        
        return false -- Don't consume/remove the item
    end
})
