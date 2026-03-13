--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Trash Bin Base"
ENT.Category = "Parallax"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.BinModel = "models/props_generic/trashbin002.mdl"
ENT.BinUseRange = 140
ENT.BinMaxStoredWeight = 30

local DEFAULT_TRASH_WEIGHT = 0.2

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "StoredTrashCountDT")
    self:NetworkVar("Float", 0, "StoredTrashWeightDT")
    self:NetworkVar("Float", 1, "MaxStoredTrashWeightDT")
end

local function IsTrashClass(className)
    if ( !isstring(className) ) then return false end
    if ( string.StartWith(className, "trash_piece_") ) then return true end

    local stored = ax.item and ax.item.stored and ax.item.stored[className]
    return istable(stored) and stored.base == "trash_piece"
end

function ENT:GetUseRange()
    return tonumber(self.BinUseRange) or 140
end

function ENT:GetClassWeight(className)
    local stored = ax.item and ax.item.stored and ax.item.stored[className]
    local weight = istable(stored) and tonumber(stored.weight) or nil
    if ( !isnumber(weight) or weight <= 0 ) then
        weight = DEFAULT_TRASH_WEIGHT
    end

    return math.Round(weight, 2)
end

function ENT:GetMaxStoredWeight()
    if ( SERVER ) then
        if ( istable(TRASH) and isfunction(TRASH.GetBinMaxStoredWeight) ) then
            return TRASH:GetBinMaxStoredWeight()
        end

        return tonumber(self.BinMaxStoredWeight) or 30
    end

    local networked = tonumber(self:GetMaxStoredTrashWeightDT()) or 0
    if ( networked > 0 ) then
        return networked
    end

    if ( istable(TRASH) and isfunction(TRASH.GetBinMaxStoredWeight) ) then
        return TRASH:GetBinMaxStoredWeight()
    end

    return tonumber(self.BinMaxStoredWeight) or 30
end

function ENT:GetStoredWeight()
    if ( CLIENT ) then
        return math.Round(tonumber(self:GetStoredTrashWeightDT()) or 0, 2)
    end

    local total = 0
    local classes = self:GetStoredTrashClasses()
    for i = 1, #classes do
        total = total + self:GetClassWeight(classes[i])
    end

    return math.Round(total, 2)
end

function ENT:GetStoredCount()
    if ( CLIENT ) then
        return math.max(tonumber(self:GetStoredTrashCountDT()) or 0, 0)
    end

    return #self:GetStoredTrashClasses()
end

function ENT:CanStoreClass(className)
    if ( !IsTrashClass(className) ) then
        return false, "That item cannot be disposed here."
    end

    local nextWeight = self:GetStoredWeight() + self:GetClassWeight(className)
    if ( nextWeight > self:GetMaxStoredWeight() ) then
        return false, "This trash bin is full."
    end

    return true
end

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel(self.BinModel or "models/props_generic/trashbin002.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local physicsObject = self:GetPhysicsObject()
        if ( IsValid(physicsObject) ) then
            physicsObject:EnableMotion(false)
        end

        self.axStoredTrashClasses = {}
        self:SyncStorage()
    end

    function ENT:GetStoredTrashClasses()
        if ( !istable(self.axStoredTrashClasses) ) then
            self.axStoredTrashClasses = {}
        end

        return self.axStoredTrashClasses
    end

    function ENT:SyncStorage()
        self:SetStoredTrashCountDT(self:GetStoredCount())
        self:SetStoredTrashWeightDT(self:GetStoredWeight())
        self:SetMaxStoredTrashWeightDT(self:GetMaxStoredWeight())
    end

    function ENT:StoreClass(className)
        local canStore, reason = self:CanStoreClass(className)
        if ( !canStore ) then
            return false, reason or "This trash bin is full."
        end

        local classes = self:GetStoredTrashClasses()
        classes[#classes + 1] = className
        self:SyncStorage()

        return true
    end

    function ENT:ExtractClassesByWeight(maxWeight)
        maxWeight = tonumber(maxWeight) or 0
        if ( maxWeight <= 0 ) then
            return {}, 0
        end

        local classes = self:GetStoredTrashClasses()
        if ( #classes <= 0 ) then
            return {}, 0
        end

        local extracted = {}
        local total = 0
        local index = 1

        while ( index <= #classes ) do
            local className = classes[index]
            local classWeight = self:GetClassWeight(className)

            if ( total + classWeight <= maxWeight ) then
                extracted[#extracted + 1] = className
                total = total + classWeight
                table.remove(classes, index)
            else
                index = index + 1
            end
        end

        if ( #extracted > 0 ) then
            self:SyncStorage()
        end

        return extracted, math.Round(total, 2)
    end

    function ENT:Use(activator)
        if ( !ax.util:IsValidPlayer(activator) ) then return end

        local count = self:GetStoredCount()
        local weight = self:GetStoredWeight()
        local maxWeight = self:GetMaxStoredWeight()

        activator:Notify("Bin load: " .. count .. " items (" .. weight .. "/" .. maxWeight .. " kg)")
    end
end

if ( CLIENT ) then
    function ENT:Draw()
        self:DrawModel()
    end
end
