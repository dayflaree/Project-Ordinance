--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

-- Register Configs
ax.config:Add("plants.decay_rate", ax.type.number, 0.0001, {
    description = "How much hydration a plant loses per second.",
    category = "plants",
    min = 0,
    max = 0.1,
    decimals = 4
})

ax.config:Add("plants.irrigation_amount", ax.type.number, 0.25, {
    description = "How much hydration is restored per irrigation action.",
    category = "plants",
    min = 0.05,
    max = 1,
    decimals = 2
})

ax.config:Add("plants.interaction_distance", ax.type.number, 100, {
    description = "Maximum distance (in units) to interact with a plant.",
    category = "plants",
    min = 32,
    max = 512,
    decimals = 0
})

require("niknaks")

MODULE.models = {
    ["models/props_generic/plant_office.mdl"] = true,
    ["models/props_foliage/palm_plant.mdl"] = true,
    ["models/props_foliage/desert_brush/desertplant_small01.mdl"] = true,
    ["models/props_foliage/fern.mdl"] = true,
    ["models/riggs9162/rp_black_mesa_facility/plant_pot_01.mdl"] = true,
}

MODULE.sinkModels = {
    ["models/props_interiors/sinkkitchen01a.mdl"] = true,
}

MODULE.staticPlants = MODULE.staticPlants or {}
MODULE.staticSinks = MODULE.staticSinks or {}

function MODULE:OnSchemaLoaded()
    local mapObject = NikNaks.CurrentMap
    if ( !mapObject ) then return end

    self.staticPlants = {}
    self.staticSinks = {}

    for model, _ in pairs(self.models) do
        local statics = mapObject:FindStaticByModel(model)
        for _, static in ipairs(statics) do
            table.insert(self.staticPlants, {
                model = model,
                pos = static.Origin,
                angles = static.Angles,
                static = true
            })
        end
    end

    for model, _ in pairs(self.sinkModels) do
        local statics = mapObject:FindStaticByModel(model)
        for _, static in ipairs(statics) do
            table.insert(self.staticSinks, {
                model = model,
                pos = static.Origin,
                angles = static.Angles,
                static = true
            })
        end
    end
end

function MODULE:IsPlant(ent)
    if ( !IsValid(ent) ) then return false end
    return self.models[ent:GetModel()] == true
end

function MODULE:GetPlantInteraction(ply)
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    local dist = ax.config:Get("plants.interaction_distance", 100)
    local distSqr = dist * dist

    if ( self:IsPlant(ent) and tr.HitPos:DistToSqr(ply:EyePos()) < distSqr ) then
        return {
            entity = ent,
            static = false,
            pos = ent:GetPos()
        }
    end

    -- Check static plants
    for _, plant in ipairs(self.staticPlants) do
        if ( tr.HitPos:DistToSqr(plant.pos) < distSqr * 0.25 ) then -- Static plants use a tighter tolerance
            return {
                entity = nil,
                static = true,
                pos = plant.pos,
                model = plant.model
            }
        end
    end

    return nil
end

MODULE.hydration = MODULE.hydration or {}

function MODULE:GetPlantKey(plantData)
    if ( !plantData.static and IsValid(plantData.entity) ) then
        return "ent_" .. plantData.entity:EntIndex()
    end
    -- Hash position for static plants (round to avoid float precision issues in keys)
    local p = plantData.pos
    return "static_" .. math.Round(p.x) .. "_" .. math.Round(p.y) .. "_" .. math.Round(p.z)
end

function MODULE:GetHydration(plantData)
    local key = self:GetPlantKey(plantData)
    return self.hydration[key] or 0.75 -- Default hydration
end

function MODULE:GetSinkInteraction(ply)
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    local dist = 32
    local distSqr = dist * dist

    if ( IsValid(ent) and self.sinkModels[ent:GetModel()] and tr.HitPos:DistToSqr(ply:EyePos()) < distSqr ) then
        return {
            entity = ent,
            static = false,
            pos = ent:GetPos()
        }
    end

    -- Check static sinks
    for _, sink in ipairs(self.staticSinks) do
        if ( tr.HitPos:DistToSqr(sink.pos) < distSqr * 0.25 ) then
            return {
                entity = nil,
                static = true,
                pos = sink.pos,
                model = sink.model
            }
        end
    end

    return nil
end

if ( SERVER ) then
    function MODULE:SetHydration(plantData, level)
        local key = self:GetPlantKey(plantData)
        self.hydration[key] = math.Clamp(level, 0, 1)
        
        -- Sync to interested clients or everyone? 
        -- For now, we'll sync on request to save bandwidth.
    end
end

if ( CLIENT ) then
    function MODULE:PlayerBindPress(ply, bind, pressed)
        if ( !pressed ) then return end
        if ( string.find(bind, "+use") ) then
            local plantData = self:GetPlantInteraction(ply)
            if ( plantData ) then
                self:OpenPlantMenu(plantData)
                return true
            end
        end
    end
end
