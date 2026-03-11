--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_canteen/soda_machine.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local physicsObject = self:GetPhysicsObject()
    if ( IsValid(physicsObject) ) then
        physicsObject:Wake()
    end

    self.buttons = {}

    PrintTable(self:GetTable())

    for i = 1, 8 do
        local button = ents.Create("prop_dynamic")
        button:SetModel("models/props_canteen/soda_machine_button.mdl")
        button:SetParent(self)
        button:Spawn()

        local offset = Vector(-21.25, 17, 53.25) - Vector(0, 0, (i - 1) * 2.05)
        button:SetAngles(self:GetAngles())
        button:SetPos(self:WorldToLocal(self:GetPos()) + offset)

        debugoverlay.Sphere(button:GetPos(), 5, 5, Color(255, 0, 0, 1), true)

        self.buttons[i] = button

        self["SetButton" .. i](self, button)
    end
end

function ENT:Use(activator, caller, useType, value)
    if ( !IsValid(activator) or !activator:IsPlayer() ) then
        return
    end

    -- TODO: Implement use logic
end
