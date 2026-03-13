--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

BMS_NAV_COLOR = Color(228, 113, 37)
BMS_NAV_COLOR_BOTTOM = Color(0, 0, 0, 100)
BMS_NAV_LOGO = ax.util:GetMaterial("riggs9162/bms/ui/project-ordinance.png", "smooth mips")
BMS_MAIN_GRADIENT_COLOR = Color(228, 113, 37, 25)
BMS_MAIN_OVERLAY_COLOR = Color(90, 90, 90, 120)
BMS_MAIN_LOGO_MARK = ax.util:GetMaterial("riggs9162/bms/ui/logo-mark.png", "smooth mips")
BMS_DISCORD_ICON = ax.util:GetMaterial("riggs9162/bms/ui/discord-white.png", "smooth mips")

local function GetRatioSize(originalW, originalH, maxW, maxH)
    local ratio = math.min(maxW / originalW, maxH / originalH)
    return originalW * ratio, originalH * ratio
end

local PANEL = {}

function PANEL:Init()
    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
    end

    ax.gui.main = self

    self.startTime = SysTime()

    hook.Run("PreMainMenuCreated", self)

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()

    self.nav = self:Add("EditablePanel")
    self.nav:Dock(TOP)
    self.nav:DockPadding(ax.util:ScreenScale(32), 0, 0, 0)
    self.nav:SetTall(ax.util:ScreenScaleH(24))
    self.nav.Paint = function(this, width, height)
        local triangleWidth = height * 1.75
        local triangle = {
            { x = 0, y = 0 },
            { x = width / 2, y = 0 },
            { x = width / 2 + triangleWidth, y = 0 },
            { x = width / 2, y = height },
            { x = 0, y = height },
        }

        surface.SetDrawColor(BMS_NAV_COLOR)
        draw.NoTexture()
        surface.DrawPoly(triangle)

        local logoSize = height * 0.75
        local logoPos = (height - logoSize) / 2
        ax.render.DrawMaterial(0, logoPos + ax.util:ScreenScale(8), logoPos, logoSize, logoSize, color_white, BMS_NAV_LOGO)
    end

    self.navBottom = self:Add("EditablePanel")
    self.navBottom:Dock(BOTTOM)
    self.navBottom:DockPadding(ax.util:ScreenScale(16), 0, 0, 0)
    self.navBottom:SetTall(ax.util:ScreenScaleH(24))
    self.navBottom.Paint = function(this, width, height)
        ax.render.Draw(0, 0, 0, width, height, BMS_NAV_COLOR_BOTTOM)
    end

    self.splash = self:Add("ax.main.splash")
    self.splash:StartAtBottom()

    self.create = self:Add("ax.main.create")
    self.create:StartAtBottom()

    self.load = self:Add("ax.main.load")
    self.load:StartAtBottom()

    self.options = self:Add("ax.main.options")
    self.options:StartAtBottom()

    self.splash:StartAtTop()
    self.splash:SlideToFront()

    -- Allow for buttons to be created by other scripts
    local buttons = {}
    hook.Run("CreateMainMenuButtons", self, buttons)

    for _, button in ipairs(buttons) do
        self.nav:AddItem(button)
    end

    -- Now create our own buttons
    -- Play button (only show if we have a character)
    local allowPlay = hook.Run("ShouldCreatePlayButton", self)
    if ( ax.client.axCharacter and allowPlay != false ) then
        local playButton = self.nav:Add("bms.button")
        playButton:Dock(LEFT)
        playButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
        playButton:SetText("mainmenu.play")
        playButton:SetTextColor(color_white)
        playButton.DoClick = function()
            ax.client:EmitSound("ax.gui.menu.close")
            self:Remove()
        end
    end

    -- Create character button
    local allowCreate = hook.Run("ShouldCreateCreateButton", self)
    if ( allowCreate != false ) then
        local createButton = self.nav:Add("bms.button")
        createButton:Dock(LEFT)
        createButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
        createButton:SetText("mainmenu.create")
        createButton:SetTextColor(color_white)
        createButton.DoClick = function()
            self.splash:SlideDown()
            self.create:SlideToFront()
        end

        self.create.OnHidden = function()
            createButton:SetToggled(false)
        end
    end

    -- Load character button
    local allowLoad = hook.Run("ShouldCreateLoadButton", self)
    if ( allowLoad != false ) then
        local loadButton = self.nav:Add("bms.button")
        loadButton:Dock(LEFT)
        loadButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
        loadButton:SetText("mainmenu.load")
        loadButton:SetTextColor(color_white)
        loadButton.DoClick = function()
            self.splash:SlideDown()
            self.load:SlideToFront()
        end

        self.load.OnHidden = function()
            loadButton:SetToggled(false)
        end
    end

    -- Options button
    local allowOptions = hook.Run("ShouldCreateOptionsButton", self)
    if ( allowOptions != false ) then
        local optionsButton = self.nav:Add("bms.button")
        optionsButton:Dock(LEFT)
        optionsButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
        optionsButton:SetText("mainmenu.options")
        optionsButton:SetTextColor(color_white)
        optionsButton.DoClick = function()
            if ( self.options:IsVisible() ) then
                self.options:SlideDown()
                self.splash:SlideToFront()
                return
            end

            self.splash:SlideDown()
            self.options:SlideToFront()
        end

        self.options.OnHidden = function()
            optionsButton:SetToggled(false)
        end

        local workshopButton = self.nav:Add("bms.button")
        workshopButton:Dock(LEFT)
        workshopButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
        workshopButton:SetText("STEAM WORKSHOP")
        workshopButton:SetTextColor(color_white)
        workshopButton.DoClick = function()
            gui.OpenURL("https://steamcommunity.com/workshop/filedetails/?id=3684369184")

            timer.Simple(0, function()
                if ( IsValid(workshopButton) ) then
                    workshopButton:SetToggled(false)
                end
            end)
        end
    end

    -- Back button
    local backButton = self.navBottom:Add("bms.button")
    backButton:Dock(LEFT)
    backButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
    backButton:SetText("BACK")
    backButton:SetFillColor(BMS_BUTTON_HOVER_COLOR)
    backButton:SetFillHeightHover(1)
    backButton.DoClick = function()
        if ( self.create:IsVisible() ) then
            self.create:SlideDown()
        end

        if ( self.load:IsVisible() ) then
            self.load:SlideDown()
        end

        if ( self.options:IsVisible() ) then
            self.options:SlideDown()
        end

        self.splash:SlideToFront()
    end

    -- Disconnect button
    local allowDisconnect = hook.Run("ShouldCreateDisconnectButton", self)
    if ( allowDisconnect != false ) then
        local disconnectButton = self.navBottom:Add("bms.button")
        disconnectButton:Dock(LEFT)
        disconnectButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
        disconnectButton:SetText("mainmenu.disconnect")
        disconnectButton:SetFillColor(BMS_BUTTON_HOVER_COLOR)
        disconnectButton:SetFillHeightHover(1)
        disconnectButton.DoClick = function()
            Derma_Query("Are you sure you want to disconnect?", "Disconnect",
                "Yes", function()
                    RunConsoleCommand("disconnect")
                end,
                "No", function()
                    disconnectButton:SetToggled(false)
                end
            )
        end
    end

    -- Discord button
    local discordButton = self.navBottom:Add("bms.button")
    discordButton:Dock(RIGHT)
    discordButton:DockMargin(ax.util:ScreenScale(4), 0, ax.util:ScreenScale(4), 0)
    discordButton:SetText("")
    discordButton:SetWide(ax.util:ScreenScale(64))
    discordButton:SetFillColor(BMS_BUTTON_HOVER_COLOR)
    discordButton:SetFillHeightHover(1)
    discordButton.PaintAdditional = function(this, width, height)
        local iconW, iconH = GetRatioSize(BMS_DISCORD_ICON:Width(), BMS_DISCORD_ICON:Height(), width * 0.82, height * 0.82)
        local iconX = math.floor((width - iconW) * 0.5)
        local iconY = math.floor((height - iconH) * 0.5)
        ax.render.DrawMaterial(0, iconX, iconY, iconW, iconH, color_white, BMS_DISCORD_ICON)
    end
    discordButton.DoClick = function()
        gui.OpenURL("https://discord.gg/McHbSUAdUg")
    end

    hook.Run("PostMainMenuCreated", self)
end

function PANEL:Paint(width, height)
    ax.render.Draw(0, 0, 0, width, height, BMS_MAIN_OVERLAY_COLOR)

    ax.util:DrawGradient(0, "left", 0, 0, width, height, BMS_MAIN_GRADIENT_COLOR)

    local logoSizeW, logoSizeH = GetRatioSize(750, 738, ax.util:ScreenScale(256), ax.util:ScreenScaleH(256))
    ax.render.DrawMaterial(0, width - logoSizeW, height - logoSizeH, logoSizeW, logoSizeH, color_white, BMS_MAIN_LOGO_MARK)
end

vgui.Register("ax.main", PANEL, "EditablePanel")

if ( IsValid(ax.gui.main) ) then
    ax.gui.main:Remove()

    timer.Simple(0, function()
        vgui.Create("ax.main")
    end)
end

concommand.Add("ax_menu", function()
    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
        return
    end

    vgui.Create("ax.main")
end)

