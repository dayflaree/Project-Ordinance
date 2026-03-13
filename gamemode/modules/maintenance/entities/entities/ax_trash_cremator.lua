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
ENT.PrintName = "Trash Cremator"
ENT.Category = "Parallax"
ENT.Spawnable = true
ENT.AdminSpawnable = true

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/props_questionableethics/qe_cremator.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local physicsObject = self:GetPhysicsObject()
        if ( IsValid(physicsObject) ) then
            physicsObject:EnableMotion(false)
        end
    end

    function ENT:FindFilledBag(inventory)
        if ( !istable(inventory) or !istable(inventory.items) ) then
            return nil
        end

        for _, item in pairs(inventory.items) do
            if ( !istable(item) or item.class != "trash_bag" ) then
                continue
            end

            local storedClasses = item:GetData("storedClasses", {})
            if ( istable(storedClasses) and #storedClasses > 0 ) then
                return item
            end
        end

        return nil
    end

    function ENT:Use(activator)
        if ( !ax.util:IsValidPlayer(activator) ) then return end

        local character = activator:GetCharacter()
        if ( !istable(character) ) then return end

        local inventory = character:GetInventory()
        if ( !istable(inventory) ) then
            activator:Notify("You cannot access your inventory right now.", "error")
            return
        end

        local bagItem = self:FindFilledBag(inventory)
        if ( !istable(bagItem) ) then
            activator:Notify("You need a filled trash bag to use the cremator.", "error")
            return
        end

        inventory:RemoveItem(bagItem.id)
        self:EmitSound("ambient/fire/mtov_flame2.wav", 70, 100)
        self:EmitSound("physics/cardboard/cardboard_box_break2.wav", 70, 100)
        ax.chat:Send(activator, "it", "You throw a filled trash bag into the cremator.", nil, activator)
    end
end

if ( CLIENT ) then
    function ENT:Draw()
        self:DrawModel()
    end
end
