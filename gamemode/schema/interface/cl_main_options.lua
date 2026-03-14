--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

local OPTIONS_BG_COLOR = Color(24, 24, 24, 200)
local OPTIONS_HEADER_BG = Color(24, 24, 24, 200)
local OPTIONS_FOOTER_BG = Color(24, 24, 24, 200)
local OPTIONS_ACCENT = Color(228, 113, 37)
local OPTIONS_TEXT = Color(235, 240, 245)
local OPTIONS_SCROLLBAR_TRACK = Color(255, 255, 255, 28)
local OPTIONS_SCROLLBAR_GRIP = Color(228, 113, 37, 220)
local OPTIONS_WARNING_ICON = ax.util:GetMaterial("riggs9162/bms/ui/warning.png", "smooth mips")

local function StyleOptionsScroller(scroller)
    if ( !IsValid(scroller) or !scroller.GetVBar ) then
        return
    end

    local vbar = scroller:GetVBar()
    if ( !IsValid(vbar) ) then
        return
    end

    vbar:SetWide(ax.util:ScreenScale(6))
    vbar:Dock(RIGHT)

    if ( IsValid(vbar.btnUp) ) then
        vbar.btnUp:SetTall(0)
        vbar.btnUp:SetVisible(false)
    end

    if ( IsValid(vbar.btnDown) ) then
        vbar.btnDown:SetTall(0)
        vbar.btnDown:SetVisible(false)
    end

    if ( IsValid(vbar.btnGrip) ) then
        vbar.btnGrip.Paint = function(_, width, height)
            ax.render.Draw(4, 0, 0, width, height, OPTIONS_SCROLLBAR_GRIP)
        end
    end

    vbar.Paint = function(_, width, height)
        ax.render.Draw(4, 0, 0, width, height, OPTIONS_SCROLLBAR_TRACK)
    end
end

function PANEL:SetSectionTitle(text)
    local titleText = text and text != "" and utf8.upper(text) or "OPTIONS"
    self.title:SetText(titleText)
    self.title:SizeToContentsX()
end

function PANEL:SetHintText(text)
    local hintText = text and text != "" and text or (self.defaultHintText or "Select a setting to view its description.")
    if ( IsValid(self.hint) ) then
        self.hint:SetText(hintText)
    end
end

function PANEL:Init()
    hook.Run("PreMainMenuOptionsCreated", self)

    self:SetYOffset(ax.util:ScreenScaleH(48))
    self:SetHeightOffset(-ax.util:ScreenScaleH(80))

    self:DockPadding(ax.util:ScreenScale(18), ax.util:ScreenScaleH(18), ax.util:ScreenScale(18), ax.util:ScreenScaleH(18))

    self.wrapper = self:Add("EditablePanel")
    self.wrapper:Dock(FILL)
    self.wrapper.Paint = function(_, width, height)
        ax.render.Draw(0, 0, 0, width, height, OPTIONS_BG_COLOR)
    end

    self.header = self.wrapper:Add("EditablePanel")
    self.header:Dock(TOP)
    self.header:SetTall(ax.util:ScreenScaleH(44))
    self.header:DockPadding(ax.util:ScreenScale(24), 0, ax.util:ScreenScale(24), 0)
    self.header.Paint = function(_, width, height)
        ax.render.Draw(0, 0, 0, width, height, OPTIONS_HEADER_BG)
    end

    self.title = self.header:Add("DLabel")
    self.title:Dock(LEFT)
    self.title:SetFont("ax.huge.bold")
    self.title:SetText("OPTIONS")
    self.title:SetTextColor(OPTIONS_ACCENT)
    self.title:SizeToContentsX()
    self.title:SetContentAlignment(4)

    self.warningWrap = self.header:Add("EditablePanel")
    self.warningWrap:Dock(FILL)
    self.warningWrap:DockMargin(ax.util:ScreenScale(8), 0, 0, 0)
    self.warningWrap:SetTall(self.header:GetTall())
    self.warningWrap.Paint = nil

    self.warningIcon = self.warningWrap:Add("DImage")
    self.warningIcon:Dock(RIGHT)

    local iconHeight = math.max(1, self.header:GetTall() - ax.util:ScreenScaleH(24))
    local iconRatio = 1
    if ( OPTIONS_WARNING_ICON ) then
        iconRatio = OPTIONS_WARNING_ICON:Width() / math.max(1, OPTIONS_WARNING_ICON:Height())
    end

    local iconWidth = math.max(1, math.Round(iconHeight * iconRatio))
    local iconPadding = math.max(0, math.Round((self.header:GetTall() - iconHeight) * 0.5))

    self.warningIcon:DockMargin(ax.util:ScreenScale(6), iconPadding, 0, iconPadding)
    self.warningIcon:SetSize(iconWidth, iconHeight)
    self.warningIcon:SetMaterial(OPTIONS_WARNING_ICON)
    self.warningIcon:SetImageColor(OPTIONS_TEXT)

    self.warning = self.warningWrap:Add("DLabel")
    self.warning:Dock(FILL)
    self.warning:SetFont("ax.medium.bold")
    self.warning:SetText("Some parameters could severely impact performance.")
    self.warning:SetTextColor(OPTIONS_TEXT)
    self.warning:SetContentAlignment(6)

    self.footer = self.wrapper:Add("EditablePanel")
    self.footer:Dock(BOTTOM)
    self.footer:SetTall(ax.util:ScreenScaleH(58))
    self.footer:DockPadding(ax.util:ScreenScale(18), ax.util:ScreenScaleH(8), ax.util:ScreenScale(18), ax.util:ScreenScaleH(8))
    self.footer.Paint = function(_, width, height)
        ax.render.Draw(0, 0, 0, width, height, OPTIONS_FOOTER_BG)
    end

    self.hint = self.footer:Add("DLabel")
    self.hint:Dock(FILL)
    self.hint:SetFont("ax.medium.bold")
    self.hint:SetTextColor(OPTIONS_TEXT)
    self.hint:SetContentAlignment(4)
    self.defaultHintText = "Select a setting to view its description."
    self:SetHintText(self.defaultHintText)

    ax.gui.optionsHint = self.hint
    ax.gui.optionsDefaultHintText = self.defaultHintText

    self.body = self.wrapper:Add("EditablePanel")
    self.body:Dock(FILL)
    self.body:DockMargin(0, ax.util:ScreenScaleH(2), 0, ax.util:ScreenScaleH(2))
    self.body.Paint = nil

    self.settings = self.body:Add("ax.store")
    self.settings:Dock(FILL)
    self.settings:DockMargin(ax.util:ScreenScale(18), ax.util:ScreenScaleH(18), ax.util:ScreenScale(18), ax.util:ScreenScaleH(18))
    self.settings:SetType("option")

    timer.Simple(0, function()
        if ( !IsValid(self) or !IsValid(self.settings) ) then
            return
        end

        if ( IsValid(self.settings.categories) ) then
            self.settings.categories:SetVisible(false)
        end

        if ( IsValid(self.settings.container) ) then
            self.settings.container:DockMargin(0, 0, 0, 0)
        end

        for _, page in ipairs(self.settings:GetPages()) do
            if ( IsValid(page) ) then
                page:SetXOffset(0)
                page:SetWidthOffset(0)
            end
        end

        self.settings:InvalidateLayout(true)
        self.settings:PerformLayout()

        if ( IsValid(self.settings.container) ) then
            self.settings.container:InvalidateLayout(true)
            self.settings.container:PerformLayout()
        end

        local categoryButtons = self.settings.categoryButtons
        if ( istable(categoryButtons) ) then
            local firstButton = nil

            for _, button in SortedPairs(categoryButtons) do
                if ( IsValid(button) and IsValid(button.tab) and isnumber(button.tab.index) ) then
                    firstButton = button

                    local originalDoClick = button.DoClick
                    button.DoClick = function(this, ...)
                        if ( isfunction(originalDoClick) ) then
                            originalDoClick(this, ...)
                        end

                        if ( IsValid(self) and isfunction(self.SetSectionTitle) ) then
                            self:SetSectionTitle(this:GetText())
                        end

                        if ( IsValid(this.tab) and IsValid(self.settings) ) then
                            local page = self.settings:GetPage(this.tab.index)
                            if ( IsValid(page) ) then
                                local scroller = page:GetChildren()[1]
                                if ( IsValid(scroller) ) then
                                    StyleOptionsScroller(scroller)
                                end
                            end
                        end
                    end
                end
            end

            if ( IsValid(firstButton) ) then
                firstButton:DoClick()
            end
        end
    end)

    hook.Run("PostMainMenuOptionsCreated", self)
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.main.options", PANEL, "ax.transition")