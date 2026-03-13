--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

BMS_BUTTON_HOVER_COLOR = Color(228, 113, 37)
BMS_BUTTON_RESUME_TEXT_HOVER = Color(15, 15, 15)

local PANEL = {}

DEFINE_BASECLASS("ax.button.core")

AccessorFunc(PANEL, "toggled", "Toggled", FORCE_BOOL)
AccessorFunc(PANEL, "fillColor", "FillColor")
AccessorFunc(PANEL, "fillHeightHover", "FillHeightHover", FORCE_NUMBER)
AccessorFunc(PANEL, "fillHeightMotion", "FillHeightMotion", FORCE_NUMBER)
AccessorFunc(PANEL, "textColorToggled", "TextColorToggled")
AccessorFunc(PANEL, "animationDuration", "AnimationDuration", FORCE_NUMBER)

function PANEL:Init()
    BaseClass.Init(self)

    self:SetContentAlignment(5)
    self:SetToggled(false)
    self:SetFillColor(color_white)
    self:SetFillHeightHover(0.10)
    self:SetFillHeightMotion(0)
    self:SetTextColorToggled(BMS_BUTTON_HOVER_COLOR)
    self:SetAnimationDuration(0.2)

    self.lastFillHeightTarget = 0
    self.lastToggledState = self:GetToggled()

    self:SetTextColorMotion(self.textColor)
end

function PANEL:SetTextInternal(text)
    text = utf8.upper(text)

    BaseClass.SetTextInternal(self, text)
end

function PANEL:OnMousePressed(mouseCode)
    if ( !self:IsEnabled() or self:CanClick(mouseCode) == false ) then return end

    BaseClass.OnMousePressed(self, mouseCode)

    if ( mouseCode == MOUSE_LEFT ) then
        self:SetToggled(!self:GetToggled())
    end
end

function PANEL:Think()
    local hovering = self:IsHovered() and self:IsEnabled()

    if ( hovering and !self:GetWasHovered() ) then
        if ( self.soundEnter ) then
            ax.client:EmitSound(self.soundEnter)
        end

        self:SetWasHovered(true)

        if ( self.OnHovered ) then
            self:OnHovered()
        end
    elseif ( !hovering and self:GetWasHovered() ) then
        self:SetWasHovered(false)

        if ( self.OnUnHovered ) then
            self:OnUnHovered()
        end
    end

    local fillHeightTarget = self:GetToggled() and 1 or (hovering and self:GetFillHeightHover() or 0)
    if ( self.lastFillHeightTarget != fillHeightTarget ) then
        self.lastFillHeightTarget = fillHeightTarget

        self:Motion(self:GetAnimationDuration(), {
            Target = {
                fillHeightMotion = fillHeightTarget
            },
            Easing = self.easing
        })
    end

    local toggled = self:GetToggled()
    if ( self.lastToggledState != toggled ) then
        self.lastToggledState = toggled

        local textColorTarget = toggled and self:GetTextColorToggled() or self.textColor

        self:Motion(self:GetAnimationDuration(), {
            Target = {
                textColorMotion = textColorTarget
            },
            Easing = self.easing,
            Think = function(this)
                self:SetTextColorInternal(this.textColorMotion)
            end
        })
    end

    if ( self.OnThink ) then
        self:OnThink()
    end
end

function PANEL:Paint(width, height)
    local fillHeight = math.Round(height * math.Clamp(self:GetFillHeightMotion(), 0, 1))
    if ( fillHeight > 0 ) then
        surface.SetDrawColor(self:GetFillColor())
        surface.DrawRect(0, height - fillHeight, width, fillHeight)
    end

    if ( self.PaintAdditional ) then
        self:PaintAdditional(width, height)
    end
end

vgui.Register("bms.button", PANEL, "ax.button.core")

PANEL = {}

DEFINE_BASECLASS("ax.button.core")

AccessorFunc(PANEL, "fillColor", "FillColor")
AccessorFunc(PANEL, "fillHeightIdle", "FillHeightIdle", FORCE_NUMBER)
AccessorFunc(PANEL, "fillHeightMotion", "FillHeightMotion", FORCE_NUMBER)
AccessorFunc(PANEL, "outlineColor", "OutlineColor")
AccessorFunc(PANEL, "outlineThickness", "OutlineThickness", FORCE_NUMBER)
AccessorFunc(PANEL, "baseBackgroundColor", "BaseBackgroundColor")
AccessorFunc(PANEL, "animationDuration", "AnimationDuration", FORCE_NUMBER)

function PANEL:Init()
    BaseClass.Init(self)

    self:SetContentAlignment(5)
    self:SetFont("ax.regular.bold")

    self:SetFillColor(BMS_BUTTON_HOVER_COLOR)
    self:SetFillHeightIdle(0.125)
    self:SetFillHeightMotion(self:GetFillHeightIdle())
    self:SetOutlineColor(BMS_BUTTON_HOVER_COLOR)
    self:SetOutlineThickness(4)
    self:SetBaseBackgroundColor(Color(0, 0, 0, 150))
    self:SetAnimationDuration(0.2)
    self:SetTextColor(color_white)
    self:SetTextColorHovered(self.textColor)
    self:SetTextColorMotion(self.textColor)

    self.lastFillHeightTarget = self:GetFillHeightIdle()
    self.lastTextColorTarget = self.textColor
end

function PANEL:Think()
    local hovering = self:IsHovered() and self:IsEnabled()

    if ( hovering and !self:GetWasHovered() ) then
        if ( self.soundEnter ) then
            ax.client:EmitSound(self.soundEnter)
        end

        self:SetWasHovered(true)

        if ( self.OnHovered ) then
            self:OnHovered()
        end
    elseif ( !hovering and self:GetWasHovered() ) then
        self:SetWasHovered(false)

        if ( self.OnUnHovered ) then
            self:OnUnHovered()
        end
    end

    local fillHeightTarget = hovering and 1 or self:GetFillHeightIdle()
    if ( self.lastFillHeightTarget != fillHeightTarget ) then
        self.lastFillHeightTarget = fillHeightTarget

        self:Motion(self:GetAnimationDuration(), {
            Target = {
                fillHeightMotion = fillHeightTarget
            },
            Easing = self.easing
        })
    else
        -- Add Text Y Inset of 0.125 when not hovering, transition to 0 when hovering.
        self:SetTextInset(0, -math.Round(self:GetTall() * 0.125 / 4 * (1 - self:GetFillHeightMotion() / 1)))
    end

    local textColorTarget = hovering and self:GetTextColorHovered() or self.textColor
    if ( self.lastTextColorTarget != textColorTarget ) then
        self.lastTextColorTarget = textColorTarget

        self:Motion(self:GetAnimationDuration(), {
            Target = {
                textColorMotion = textColorTarget
            },
            Easing = self.easing,
            Think = function(this)
                self:SetTextColorInternal(this.textColorMotion)
            end
        })
    end

    if ( self.OnThink ) then
        self:OnThink()
    end
end

function PANEL:Paint(width, height)
    local outlineThickness = math.max(1, math.Round(self:GetOutlineThickness()))
    local innerX, innerY = outlineThickness, outlineThickness
    local innerWidth = math.max(0, width - outlineThickness * 2)
    local innerHeight = math.max(0, height - outlineThickness * 2)

    if ( innerWidth > 0 and innerHeight > 0 ) then
        surface.SetDrawColor(self:GetBaseBackgroundColor())
        surface.DrawRect(innerX, innerY, innerWidth, innerHeight)

        local fillHeight = math.Round(innerHeight * math.Clamp(self:GetFillHeightMotion(), 0, 1))
        if ( fillHeight > 0 ) then
            surface.SetDrawColor(self:GetFillColor())
            surface.DrawRect(innerX, innerY + innerHeight - fillHeight, innerWidth, fillHeight)
        end
    end

    surface.SetDrawColor(self:GetOutlineColor())
    for i = 0, outlineThickness - 1 do
        surface.DrawOutlinedRect(i, i, width - i * 2, height - i * 2, 1)
    end

    if ( self.PaintAdditional ) then
        self:PaintAdditional(width, height)
    end
end

vgui.Register("bms.button.resume", PANEL, "ax.button.core")
