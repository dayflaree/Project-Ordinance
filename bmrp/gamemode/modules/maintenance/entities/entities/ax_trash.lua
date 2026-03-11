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
ENT.PrintName = "Trash"
ENT.Category = "Parallax"
ENT.Spawnable = true
ENT.AdminSpawnable = true

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/props_junk/garbage128_composite001a.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local physicsObject = self:GetPhysicsObject()
        if ( IsValid(physicsObject) ) then
            physicsObject:EnableMotion(false)
        end
    end

    function ENT:Use(activator, caller, useType, value)
        if ( !ax.util:IsValidPlayer(activator) ) then return end

        local character = activator:GetCharacter()
        if ( !istable(character) ) then return end

        local inventory = character:GetInventory()
        if ( !istable(inventory) ) then return end

        if ( self:GetRelay("trash.collector") ) then return end
        self:SetRelay("trash.collector", activator)

        activator:ForceSequence("d1_town05_daniels_kneel_entry", function()
            activator:ForceSequence("d1_town05_daniels_kneel_idle", nil, 0)
        end)

        activator:PerformEntityAction(self, "Collecting Trash", hook.Run("PlayerCanManageTrash", activator) and 20 or 60, function()
            local trashType = self:GetRelay("trash.type", "")
            if ( trashType == "" and TRASH and isfunction(TRASH.GetTypeFromModel) ) then
                trashType = TRASH:GetTypeFromModel(self:GetModel())
            end

            if ( trashType != "cardboard" and trashType != "composite" ) then
                trashType = "composite"
            end

            local itemClass
            if ( TRASH and isfunction(TRASH.GetRandomCollectibleClass) ) then
                itemClass = TRASH:GetRandomCollectibleClass(trashType)
            end

            if ( !isstring(itemClass) or itemClass == "" ) then
                self:SetRelay("trash.collector", nil)
                activator:Notify("No trash item classes are configured.", "error")
                activator:LeaveSequence()
                return
            end

            local canStore, reason = inventory:CanStoreItem(itemClass)
            if ( !canStore ) then
                self:SetRelay("trash.collector", nil)
                activator:Notify(reason or "You cannot carry any more trash.", "error")
                activator:LeaveSequence()
                return
            end

            inventory:AddItem(itemClass, {})

            local soundPath = "physics/plastic/plastic_barrel_break1.wav"
            if ( TRASH and isfunction(TRASH.GetPickupSound) ) then
                soundPath = TRASH:GetPickupSound(trashType)
            end

            self:SetRelay("trash.collector", nil)
            self:EmitSound(soundPath, 65, 100)
            ax.chat:Send(activator, "it", "You collect some trash and put it in your inventory.", nil, activator)
            SafeRemoveEntity(self)

            activator:LeaveSequence()
        end, function()
            self:SetRelay("trash.collector", nil)
            activator:LeaveSequence()
        end)
    end
end

if ( CLIENT ) then
    function ENT:Draw()
        self:DrawModel()
    end
end
