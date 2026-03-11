--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

AccessorFunc(PANEL, "gradientLeft", "GradientLeft", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientRight", "GradientRight", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientTop", "GradientTop", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientBottom", "GradientBottom", FORCE_NUMBER)

AccessorFunc(PANEL, "gradientLeftTarget", "GradientLeftTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientRightTarget", "GradientRightTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientTopTarget", "GradientTopTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientBottomTarget", "GradientBottomTarget", FORCE_NUMBER)

AccessorFunc(PANEL, "fadeStart", "FadeStart", FORCE_NUMBER)

function PANEL:Init()
    if ( IsValid(ax.gui.bodygroupEditor) ) then
        ax.gui.bodygroupEditor:Remove()
    end

    ax.gui.bodygroupEditor = self

    self.gradientLeft = 0
    self.gradientRight = 0
    self.gradientTop = 0
    self.gradientBottom = 0

    self.gradientLeftTarget = 0
    self.gradientRightTarget = 0
    self.gradientTopTarget = 0
    self.gradientBottomTarget = 0

    self.fadeStart = CurTime()

    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:MakePopup()

    self:DockPadding(ScreenScale(32), ScreenScaleH(32), ScreenScale(32), ScreenScaleH(32))

    self.header = self:Add("EditablePanel")
    self.header:Dock(TOP)
    self.header:SetTall(ScreenScaleH(32))
    self.header.Paint = function(panel, width, height)
        draw.RoundedBox(6, 0, 0, width, height, Color(0, 0, 0, 150))
    end

    self.headerTitle = self.header:Add("ax.text")
    self.headerTitle:Dock(LEFT)
    self.headerTitle:DockMargin(ScreenScale(10), ScreenScaleH(6), ScreenScale(8), 0)
    self.headerTitle:SetText("Bodygroup Editor")
    self.headerTitle:SetFont("ax.regular.bold")
    self.headerTitle:SetContentAlignment(4)

    self.headerHint = self.header:Add("ax.text")
    self.headerHint:Dock(FILL)
    self.headerHint:DockMargin(0, ScreenScaleH(8), ScreenScale(10), 0)
    self.headerHint:SetText("Drag sliders to preview changes, then save.")
    self.headerHint:SetFont("ax.regular")
    self.headerHint:SetContentAlignment(6)

    self.buttons = self:Add("EditablePanel")
    self.buttons:Dock(BOTTOM)
    self.buttons:DockMargin(0, ScreenScaleH(8), 0, 0)

    self.content = self:Add("EditablePanel")
    self.content:Dock(FILL)
    self.content:DockMargin(0, ScreenScaleH(8), 0, ScreenScaleH(8))

    self.sidePanel = self.content:Add("EditablePanel")
    self.sidePanel:Dock(LEFT)
    self.sidePanel:SetWide(ScreenScale(240))
    self.sidePanel:DockMargin(0, 0, ScreenScale(16), 0)
    self.sidePanel.Paint = function(panel, width, height)
        draw.RoundedBox(6, 0, 0, width, height, Color(0, 0, 0, 120))
    end

    self.sideTitle = self.sidePanel:Add("ax.text")
    self.sideTitle:Dock(TOP)
    self.sideTitle:DockMargin(ScreenScale(8), ScreenScaleH(8), ScreenScale(8), ScreenScaleH(4))
    self.sideTitle:SetText("Bodygroups")
    self.sideTitle:SetFont("ax.regular.bold")
    self.sideTitle:SetContentAlignment(4)

    self.infoPanel = self.sidePanel:Add("EditablePanel")
    self.infoPanel:Dock(TOP)
    self.infoPanel:DockMargin(ScreenScale(6), 0, ScreenScale(6), ScreenScaleH(8))
    self.infoPanel:SetTall(ScreenScaleH(64))
    self.infoPanel.Paint = function(panel, width, height)
        draw.RoundedBox(6, 0, 0, width, height, Color(0, 0, 0, 120))
    end

    self.infoName = self.infoPanel:Add("ax.text")
    self.infoName:Dock(TOP)
    self.infoName:DockMargin(ScreenScale(8), ScreenScaleH(6), ScreenScale(8), 0)
    self.infoName:SetText("Target: Unknown")
    self.infoName:SetFont("ax.regular.bold")
    self.infoName:SetContentAlignment(4)

    self.infoModel = self.infoPanel:Add("ax.text")
    self.infoModel:Dock(TOP)
    self.infoModel:DockMargin(ScreenScale(8), 0, ScreenScale(8), 0)
    self.infoModel:SetText("Model: n/a")
    self.infoModel:SetFont("ax.regular")
    self.infoModel:SetContentAlignment(4)

    self.infoCount = self.infoPanel:Add("ax.text")
    self.infoCount:Dock(TOP)
    self.infoCount:DockMargin(ScreenScale(8), 0, ScreenScale(8), ScreenScaleH(4))
    self.infoCount:SetText("Bodygroups: 0")
    self.infoCount:SetFont("ax.regular")
    self.infoCount:SetContentAlignment(4)

    self.buttonScroller = self.sidePanel:Add("ax.scroller.vertical")
    self.buttonScroller:Dock(FILL)
    self.buttonScroller:DockMargin(ScreenScale(6), 0, ScreenScale(6), ScreenScaleH(6))

    local close = self.buttons:Add("ax.button")
    close:SetText("Close")
    close:Dock(LEFT)
    close:DockMargin(0, 0, ScreenScale(8), 0)
    close.DoClick = function()
        self:AlphaTo(0, 0.2, 0, function()
            self:Remove()
        end)
    end

    self.save = self.buttons:Add("ax.button")
    self.save:SetText("Save")
    self.save:Dock(FILL)
    self.save.DoClick = function()
        local entity = self.model:GetEntity()
        local bodygroups = {}
        for _, v in ipairs(entity:GetBodyGroups()) do
            local id = entity:FindBodygroupByName(v.name)
            if ( id == -1 ) then continue end
            bodygroups[v.name] = entity:GetBodygroup(id)
        end

        net.Start("ax.bodygroup.apply")
            net.WriteUInt(self.target.id, 32)
            net.WriteTable(bodygroups)
        net.SendToServer()

        self:AlphaTo(0, 0.2, 0, function()
            self:Remove()
        end)
    end

    self.buttons:SetTall(math.max(close:GetTall(), self.save:GetTall()))

    -- Model Panel
    self.modelContainer = self.content:Add("EditablePanel")
    self.modelContainer:Dock(FILL)
    self.modelContainer:DockPadding(ScreenScale(8), ScreenScaleH(8), ScreenScale(8), ScreenScaleH(8))
    self.modelContainer.Paint = function(panel, width, height)
        draw.RoundedBox(6, 0, 0, width, height, Color(0, 0, 0, 120))
    end

    self.model = self.modelContainer:Add("DAdjustableModelPanel")
    self.model:Dock(FILL)
    self.model:SetFOV(45)
    self.model.LayoutEntity = function(panel, entity)
        local scrW, scrH = ScrW(), ScrH()
        local xRatio = gui.MouseX() / scrW
        local yRatio = gui.MouseY() / scrH
        local x, _ = panel:LocalToScreen(panel:GetWide() / 2)
        local xRatio2 = x / scrW

        entity:SetPoseParameter("head_pitch", yRatio * 90 - 30)
        entity:SetPoseParameter("head_yaw", ( xRatio - xRatio2 ) * 90 - 5)
        entity:SetAngles(Angle(0, 135, 0))
        entity:SetIK(false)
    end

    self:SetGradientLeftTarget(1)
    self:SetGradientRightTarget(1)
    self:SetGradientTopTarget(1)
    self:SetGradientBottomTarget(1)
end

function PANEL:Populate(target, groups)
    if ( !target ) then return end

    self.target = target
    self.model:SetModel(target:GetModel())

    local displayName = "Unknown"
    if ( IsValid(target) ) then
        if ( ax.util:IsValidPlayer(target) ) then
            displayName = target:Name()
        elseif ( isfunction(target.GetPrintName) and isstring(target:GetPrintName()) ) then
            displayName = target:GetPrintName()
        elseif ( isfunction(target.GetClass) ) then
            displayName = target:GetClass()
        end
    end

    local modelPath = "n/a"
    if ( isfunction(target.GetModel) and isstring(target:GetModel()) ) then
        modelPath = target:GetModel()
    end

    self.infoName:SetText("Target: " .. displayName)
    self.infoModel:SetText("Model: " .. modelPath)

    local entity = self.model:GetEntity()
    local pos = entity:GetPos()
    self.model:SetCamPos(pos + Vector(-128, 0, 32))
    self.model:SetFOV(55)
    self.model:SetLookAng((pos - Vector(-128, 0, 0)):Angle())

    local ent = self.model:GetEntity()
    local groupCount = 0
    for _, v in ipairs(ent:GetBodyGroups()) do
        local id = ent:FindBodygroupByName(v.name)
        if ( id == -1 or v.num <= 1 ) then continue end

        groupCount = groupCount + 1

        local panel = self.buttonScroller:Add("ax.button")
        panel:Dock(TOP)
        panel:DockMargin(0, 0, 0, ScreenScaleH(6))
        panel:SetTall(ScreenScaleH(26))
        panel:SetTextInset(ScreenScale(6), 0)
        panel:SetText("")
        panel:SetContentAlignment(4)

        local label = panel:Add("ax.text")
        label:Dock(LEFT)
        label:DockMargin(ScreenScale(4), 0, -ScreenScale(4), 0)
        label:SetText(string.Replace(v.name, "_", " "), true)
        label:SetFont("ax.regular.bold")
        label:SetWide(ScreenScale(90))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
        end

        local valueLabel = panel:Add("ax.text")
        valueLabel:Dock(RIGHT)
        valueLabel:DockMargin(0, 0, ScreenScale(6), 0)
        valueLabel:SetWide(ScreenScale(20))
        valueLabel:SetFont("ax.regular.bold")
        valueLabel:SetContentAlignment(6)
        valueLabel.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
        end

        local slider = panel:Add("DNumSlider")
        slider:Dock(FILL)
        slider:DockMargin(ScreenScale(8), ScreenScale(6), ScreenScale(8), ScreenScale(6))
        slider:SetMin(0)
        slider:SetMax(v.num - 1)
        slider:SetDecimals(0)
        slider:SetText("")

        local currentValue = groups and groups[v.name] or ent:GetBodygroup(id)
        valueLabel:SetText(tostring(currentValue))
        slider:SetValue(currentValue)
        slider.OnValueChanged = function(this, val)
            local rounded = math.Round(val)
            ent:SetBodygroup(id, rounded)
            valueLabel:SetText(tostring(rounded))
        end

        ent:SetBodygroup(id, groups and groups[v.name] or ent:GetBodygroup(id))
    end

    self.infoCount:SetText("Bodygroups: " .. groupCount)
end

function PANEL:Paint(width, height)
    local ft = FrameTime()
    local time = ft * 5

    local performanceAnimations = ax.option:Get("performanceAnimations", true)
    if ( !performanceAnimations ) then
        time = 1
    end

    local fraction = self:GetAlpha() / 255
    ax.util:DrawBlur(0, 0, 0, width, height, Color(255, 255, 255, 150 * fraction))

    self:SetGradientLeft(Lerp(time, self:GetGradientLeft(), self:GetGradientLeftTarget()))
    self:SetGradientRight(Lerp(time, self:GetGradientRight(), self:GetGradientRightTarget()))
    self:SetGradientTop(Lerp(time, self:GetGradientTop(), self:GetGradientTopTarget()))
    self:SetGradientBottom(Lerp(time, self:GetGradientBottom(), self:GetGradientBottomTarget()))

    ax.util:DrawGradient(0, "left", 0, 0, width, height, Color(0, 0, 0, 100 * self:GetGradientLeft()))
    ax.util:DrawGradient(0, "right", 0, 0, width, height, Color(0, 0, 0, 100 * self:GetGradientRight()))
    ax.util:DrawGradient(0, "top", 0, 0, width, height, Color(0, 0, 0, 100 * self:GetGradientTop()))
    ax.util:DrawGradient(0, "bottom", 0, 0, width, height, Color(0, 0, 0, 100 * self:GetGradientBottom()))
end

vgui.Register("ax.bodygroup.view", PANEL, "EditablePanel")

if ( IsValid(ax.gui.bodygroupEditor) ) then
    ax.gui.bodygroupEditor:Remove()
end
