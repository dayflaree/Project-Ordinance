--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local panel = {}

-- Physics Constants
local SPRING_K = 0.008 -- Tension of the water surface
local DAMPING = 0.015  -- Friction/Viscosity
local SPREAD = 0.1     -- Rate of wave transmission
local COLUMN_COUNT = 50 -- Balance between fidelity and performance

function panel:Init()
    self:SetSize(80, 245)
    self:Center()
    self:MakePopup()
    
    self.waterLevel = 0.75 
    self.openTime = CurTime() + 0.2
    
    -- Initialize Water Columns
    self.columns = {}
    for i = 1, COLUMN_COUNT do
        self.columns[i] = {
            height = 0,
            velocity = 0
        }
    end

    local parent = self
    self.Paint = function(s, w, h)
        local meterH = 200
        -- Container
        draw.RoundedBox(6, 0, 0, w, meterH, Color(25, 25, 30, 255))
        surface.SetDrawColor(70, 70, 75, 255)
        surface.DrawOutlinedRect(0, 0, w, meterH, 1)
        
        local targetY = meterH - (meterH * parent.waterLevel)

        -- Physics Update (Spring Dynamics)
        for i = 1, COLUMN_COUNT do
            local col = parent.columns[i]
            local acceleration = SPRING_K * (targetY - col.height) - col.velocity * DAMPING
            col.velocity = col.velocity + acceleration
            col.height = col.height + col.velocity
        end

        -- Natural Wave Propagation (Reflection and Tension)
        local lDeltas = {}
        local rDeltas = {}
        for i = 1, COLUMN_COUNT do
            if ( i > 1 ) then
                lDeltas[i] = SPREAD * (parent.columns[i].height - parent.columns[i-1].height)
                parent.columns[i-1].velocity = parent.columns[i-1].velocity + lDeltas[i]
            end
            if ( i < COLUMN_COUNT ) then
                rDeltas[i] = SPREAD * (parent.columns[i].height - parent.columns[i+1].height)
                parent.columns[i+1].velocity = parent.columns[i+1].velocity + rDeltas[i]
            end
        end

        local x1, y1 = s:LocalToScreen(2, 2)
        local x2, y2 = s:LocalToScreen(w-2, meterH-2)
        render.SetScissorRect(x1, y1, x2, y2, true)
            local colWidth = w / COLUMN_COUNT
            for i = 1, COLUMN_COUNT do
                local col = parent.columns[i]
                local drawY = col.height
                
                -- Fluid gradient (Approximating depth)
                surface.SetDrawColor(0, 110, 210, 200)
                surface.DrawRect((i-1) * colWidth, drawY, colWidth + 1, meterH - drawY)
                
                -- Surface tension line (Crisp highlight)
                surface.SetDrawColor(180, 240, 255, 255)
                surface.DrawRect((i-1) * colWidth, drawY, colWidth + 1, 1)
                
                -- Light refraction at surface
                surface.SetDrawColor(0, 180, 255, 30)
                surface.DrawRect((i-1) * colWidth, drawY + 1, colWidth + 1, 15)
            end
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    -- Irrigate Button (Separate below meter)
    self.irrigate = self:Add("DButton")
    self.irrigate:SetText("IRRIGATE")
    self.irrigate:SetSize(80, 25)
    self.irrigate:SetPos(0, 220) -- 20px gap below meter
    self.irrigate:CenterHorizontal()
    self.irrigate:SetFont("DermaDefaultBold")
    self.irrigate:SetTextColor(Color(100, 200, 255, 200))
    self.irrigate.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 40, 255))
        surface.SetDrawColor(80, 200, 255, 50)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        if ( s:IsHovered() ) then
            draw.RoundedBox(4, 0, 0, w, h, Color(80, 200, 255, 30))
            surface.SetDrawColor(80, 200, 255, 100)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
    end
    self.irrigate.DoClick = function()
        if ( !parent.plantKey ) then return end
        
        local character = LocalPlayer():GetCharacter()
        local inventory = character and character:GetInventory()
        
        if ( !inventory or !inventory:HasItem("watercan") ) then
            LocalPlayer():Notify("You need a watering can to irrigate plants!")
            return
        end
        
        local hasWater = false
        for id, item in pairs(inventory:GetItems()) do
            if ( item.class == "watercan" and item:GetData("water", 0) >= 1 ) then
                hasWater = true
                break
            end
        end
        
        if ( !hasWater ) then
            LocalPlayer():Notify("Your watering can is empty!")
            return
        end

        net.Start("ax.plants.perform_irrigation")
            net.WriteString(parent.plantKey)
        net.SendToServer()
        
        -- Physical splash effect on click
        local impactIdx = math.random(1, COLUMN_COUNT)
        parent.columns[impactIdx].velocity = parent.columns[impactIdx].velocity - 15
    end

    -- Movement Reactivity
    self.lastAngles = LocalPlayer():EyeAngles()
    self.lastPos = LocalPlayer():GetPos()

    -- Slosh Disturbance
    local dripTimer = "PlantUIDrip_" .. tostring(self)
    timer.Create(dripTimer, 1.5, 0, function()
        if ( !IsValid(self) ) then
            timer.Remove(dripTimer)
            return
        end
        local colIdx = math.random(1, COLUMN_COUNT)
        self.columns[colIdx].velocity = self.columns[colIdx].velocity + math.Rand(-5, 5)
    end)
end

function panel:UpdateWaterLevel(level)
    self.waterLevel = level
end

function panel:Think()
    local ply = LocalPlayer()
    if ( !IsValid(ply) ) then return end

    local curAngles = ply:EyeAngles()
    local curPos = ply:GetPos()

    local angDiff = (curAngles - self.lastAngles)
    local sloshForce = (angDiff.y * 1.5) + (angDiff.p * 0.3)
    local posDiff = (curPos - self.lastPos):Length()
    sloshForce = sloshForce + (posDiff * 0.4)

    if ( math.abs(sloshForce) > 0.05 ) then
        for i = 1, COLUMN_COUNT do
            local edgeBias = math.abs(i - (COLUMN_COUNT/2)) / (COLUMN_COUNT/2)
            self.columns[i].velocity = self.columns[i].velocity + (sloshForce * edgeBias * 0.3)
        end
    end

    -- Smooth dynamic decrease (Client-side approximation of server decay)
    local decayRate = ax.config:Get("plants.decay_rate", 0.0001)
    local decayPerFrame = decayRate * FrameTime()
    self.waterLevel = math.max(0, (self.waterLevel or 0.75) - decayPerFrame)

    self.lastAngles = curAngles
    self.lastPos = curPos

    -- Close on USE key (Wait for initial release then press)
    if ( (self.openTime or 0) < CurTime() ) then
        if ( input.IsKeyDown(KEY_E) ) then
            if ( self.canClose ) then
                self:Remove()
            end
        else
            self.canClose = true -- Key was released at least once
        end
    end
end

vgui.Register("axPlantMenu", panel, "EditablePanel")

function MODULE:OpenPlantMenu(plantData)
    if ( IsValid(self.menu) ) then
        self.menu:Remove()
    end
    
    local key = self:GetPlantKey(plantData)
    self.menu = vgui.Create("axPlantMenu")
    self.menu.plantKey = key
    
    -- Request current level from server
    net.Start("ax.plants.request_hydration")
        net.WriteString(key)
    net.SendToServer()
end
