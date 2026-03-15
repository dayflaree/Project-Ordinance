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

local function SetupMainUnderlineButton(button)
    if ( !IsValid(button) ) then
        return
    end

    button:SetFillColor(color_white)
    button:SetFillHeightHover(0.10)
    button:SetFillHeightMotion(0)
    button:SetToggled(false)
    button.GetToggled = function()
        return false
    end

    button.mainUnderlineActive = false

    local originalIsHovered = button.IsHovered
    button.IsHovered = function(this)
        if ( this.mainUnderlineActive ) then
            return true
        end

        return originalIsHovered(this)
    end
end

local PANEL = {}

local function AnimateBackButtonIn(parent, backButton)
    if ( !IsValid(parent) or !IsValid(backButton) ) then
        return
    end

    local wrap = parent.optionsBackWrap
    if ( !IsValid(wrap) ) then
        return
    end

    backButton:Stop()
    wrap:Stop()
    wrap:SetVisible(true)
    backButton:SetVisible(true)
    backButton:SetEnabled(true)
    backButton:SetToggled(false)

    local baseX = wrap._axBaseX or wrap:GetX()
    local baseY = wrap._axBaseY or wrap:GetY()
    wrap._axBaseX = baseX
    wrap._axBaseY = baseY

    local offset = ax.util:ScreenScaleH(12)
    wrap:SetPos(baseX, baseY + offset)
    backButton:SetAlpha(0)
    wrap:MoveTo(baseX, baseY, 0.2, 0, -1)
    backButton:AlphaTo(255, 0.2, 0)
end

local function AnimateBackButtonOut(parent, backButton)
    if ( !IsValid(parent) or !IsValid(backButton) ) then
        return
    end

    local wrap = parent.optionsBackWrap
    if ( !IsValid(wrap) ) then
        return
    end

    backButton:Stop()
    wrap:Stop()
    backButton:SetEnabled(false)
    backButton:SetToggled(false)

    local baseX = wrap._axBaseX or wrap:GetX()
    local baseY = wrap._axBaseY or wrap:GetY()
    wrap._axBaseX = baseX
    wrap._axBaseY = baseY

    local offset = ax.util:ScreenScaleH(12)
    wrap:MoveTo(baseX, baseY + offset, 0.2, 0, -1, function()
        if ( IsValid(parent) and IsValid(backButton) and IsValid(wrap) and parent.activePanel != parent.options ) then
            backButton:SetVisible(false)
            wrap:SetVisible(false)
            wrap:SetPos(baseX, baseY)
        end
    end)
    backButton:AlphaTo(0, 0.2, 0)
end

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

    self.mainNavButtons = {}

    function self:SetMainNavActive(activeButton)
        for _, navButton in ipairs(self.mainNavButtons) do
            if ( IsValid(navButton) ) then
                navButton.mainUnderlineActive = (navButton == activeButton)
            end
        end
    end

    self.optionsSubnav = self:Add("EditablePanel")
    self.optionsSubnav:Dock(TOP)
    self.optionsSubnav:DockPadding(ax.util:ScreenScale(32), 0, ax.util:ScreenScale(32), ax.util:ScreenScaleH(2))
    self.optionsSubnav:SetTall(ax.util:ScreenScaleH(24))
    self.optionsSubnavTargetHeight = self.optionsSubnav:GetTall()
    self.optionsSubnav:SetVisible(false)
    self.optionsSubnav.Paint = function(this, width, height)
        ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 140))
    end

    self.optionsSubnavLoading = self.optionsSubnav:Add("DLabel")
    self.optionsSubnavLoading:Dock(FILL)
    self.optionsSubnavLoading:SetFont("ax.medium.bold")
    self.optionsSubnavLoading:SetText("Loading categories...")
    self.optionsSubnavLoading:SetTextColor(color_white)
    self.optionsSubnavLoading:SetContentAlignment(5)
    self.optionsSubnavLoading:SetZPos(1)

    self.optionsSubnavInner = self.optionsSubnav:Add("EditablePanel")
    self.optionsSubnavInner:Dock(FILL)
    self.optionsSubnavInner:SetZPos(2)
    self.optionsSubnavInner.Paint = nil

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

    self.activePanel = self.splash
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
        SetupMainUnderlineButton(playButton)
        table.insert(self.mainNavButtons, playButton)
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
        SetupMainUnderlineButton(createButton)
        table.insert(self.mainNavButtons, createButton)
        createButton.DoClick = function()
            self.splash:SlideDown()
            self.create:SlideToFront()
            self:SetMainNavActive(createButton)
        end

        self.create.OnHidden = function()
            createButton.mainUnderlineActive = false
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
        SetupMainUnderlineButton(loadButton)
        table.insert(self.mainNavButtons, loadButton)
        loadButton.DoClick = function()
            self.splash:SlideDown()
            self.load:SlideToFront()
            self:SetMainNavActive(loadButton)
        end

        self.load.OnHidden = function()
            loadButton.mainUnderlineActive = false
        end
    end

    -- Options button
    local allowOptions = hook.Run("ShouldCreateOptionsButton", self)
    if ( allowOptions != false ) then
        self.optionsButton = self.nav:Add("bms.button")
        self.optionsButton:Dock(LEFT)
        self.optionsButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
        self.optionsButton:SetText("mainmenu.options")
        self.optionsButton:SetTextColor(color_white)
        SetupMainUnderlineButton(self.optionsButton)
        table.insert(self.mainNavButtons, self.optionsButton)
        self.optionsButton.DoClick = function()
            if ( self.activePanel == self.options ) then
                self.options:SlideDown()
                self.splash:SlideToFront()
                self.activePanel = self.splash
                self:SetMainNavActive(nil)

                if ( IsValid(self.optionsSubnav) ) then
                    local targetHeight = self.optionsSubnavTargetHeight or self.optionsSubnav:GetTall()

                    self.optionsSubnav:SizeTo(self.optionsSubnav:GetWide(), 0, 0.2, 0, -1, function()
                        if ( IsValid(self.optionsSubnav) ) then
                            self.optionsSubnav:SetVisible(false)
                        end
                    end)
                end

                if ( IsValid(self.optionsBackButton) ) then
                    timer.Remove("ax_options_back_hide_" .. tostring(self))
                    AnimateBackButtonOut(self, self.optionsBackButton)
                end

                return
            end

            if ( self.activePanel and self.activePanel != self.splash and self.activePanel != self.options ) then
                self.activePanel:SlideDown()
            end

            self.splash:SlideDown()
            self.options:SlideToFront()
            self.activePanel = self.options
            self:SetMainNavActive(self.optionsButton)

            if ( IsValid(self.optionsSubnav) ) then
                local targetHeight = self.optionsSubnavTargetHeight or self.optionsSubnav:GetTall()
                self.optionsSubnav:SetVisible(true)
                self.optionsSubnav:SetZPos(100)
                self.optionsSubnav:MoveToFront()
                self.optionsSubnav:SetTall(0)
                self.optionsSubnav:SizeTo(self.optionsSubnav:GetWide(), targetHeight, 0.2, 0, -1)
            end

            if ( isfunction(self.BuildOptionsSubnav) ) then
                timer.Simple(0, function()
                    if ( IsValid(self) ) then
                        self:BuildOptionsSubnav()
                    end
                end)

                timer.Create("ax_options_subnav_retry_" .. tostring(self), 0.1, 10, function()
                    if ( !IsValid(self) ) then
                        return
                    end

                    if ( self:BuildOptionsSubnav() > 0 ) then
                        timer.Remove("ax_options_subnav_retry_" .. tostring(self))
                    end
                end)
            end

            if ( IsValid(self.optionsBackButton) ) then
                timer.Remove("ax_options_back_hide_" .. tostring(self))
                self.optionsBackButton:SetText("BACK")
                AnimateBackButtonIn(self, self.optionsBackButton)
            end
        end

        function self:UpdateOptionsSubnavActive(categoryID)
            if ( !istable(self.optionsSubnavButtons) ) then
                return
            end

            self.optionsSubnavActive = nil

            for id, button in pairs(self.optionsSubnavButtons) do
                if ( IsValid(button) ) then
                    local active = (id == categoryID)
                    button.bmsSubnavActive = active
                    button.underlineMotion = 0

                    if ( active ) then
                        self.optionsSubnavActive = button
                        button.selectMotion = 0
                        button:SetTextColorInternal(color_white)
                    else
                        button:SetTextColorInternal(color_white)
                    end

                    local target = active and 1 or 0
                    button:Motion(button:GetAnimationDuration(), {
                        Target = {
                            selectMotion = target
                        },
                        Easing = button.easing
                    })

                    button:InvalidateLayout(true)
                    button:InvalidateParent(true)
                end
            end
        end

        function self:BuildOptionsSubnav()
            if ( !IsValid(self.optionsSubnavInner) ) then
                return 0
            end

            self.optionsSubnavInner:Clear()
            self.optionsSubnavButtons = {}

            local categoryButtons = nil
            if ( IsValid(self.options) and IsValid(self.options.settings) ) then
                categoryButtons = self.options.settings.categoryButtons
            end

            local created = 0
            if ( istable(categoryButtons) ) then
                for categoryID, sourceButton in SortedPairs(categoryButtons) do
                    if ( IsValid(sourceButton) ) then
                        local categoryButton = self.optionsSubnavInner:Add("bms.button")
                        categoryButton:Dock(LEFT)
                        categoryButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
                        categoryButton:SetText(sourceButton:GetText() or string.upper(tostring(categoryID)))
                        categoryButton:SetTextColor(color_white)
                        categoryButton:SetFillColor(BMS_BUTTON_HOVER_COLOR)
                        categoryButton:SetFillHeightHover(0)
                        categoryButton:SetFillHeightMotion(0)
                        categoryButton:SetToggled(false)
                        categoryButton.GetToggled = function()
                            return false
                        end
                        categoryButton:SetTextColorToggled(color_white)
                        categoryButton:SetTall(self.optionsSubnavInner:GetTall())
                        categoryButton.underlineMotion = 0
                        categoryButton.selectMotion = 0

                        categoryButton.OnThink = function(this)
                            local hoverUnderline = this:IsHovered() and !this.bmsSubnavActive
                            local underlineTarget = hoverUnderline and 1 or 0
                            local step = FrameTime() / math.max(this:GetAnimationDuration(), 0.001)

                            this.underlineMotion = math.Approach(this.underlineMotion or 0, underlineTarget, step)

                            if ( this.bmsSubnavActive ) then
                                this:SetTextColorInternal(color_white)
                            elseif ( this:IsHovered() ) then
                                this:SetTextColorInternal(BMS_BUTTON_HOVER_COLOR)
                            else
                                this:SetTextColorInternal(color_white)
                            end
                        end

                        categoryButton.PaintAdditional = function(this, width, height)
                            local selectAmount = math.Clamp(this.selectMotion or 0, 0, 1)
                            if ( selectAmount > 0 ) then
                                local fillHeight = math.max(1, math.Round(height * selectAmount))

                                surface.SetDrawColor(BMS_BUTTON_HOVER_COLOR)
                                surface.DrawRect(0, height - fillHeight, width, fillHeight)
                            end

                            if ( !this.bmsSubnavActive ) then
                                local amount = math.Clamp(this.underlineMotion or 0, 0, 1)
                                if ( amount > 0 ) then
                                    local lineHeight = math.max(1, math.Round(height * 0.1 * amount))

                                    surface.SetDrawColor(BMS_BUTTON_HOVER_COLOR)
                                    surface.DrawRect(0, height - lineHeight, width, lineHeight)
                                end
                            end
                        end

                        categoryButton.DoClick = function()
                            if ( IsValid(self.options) and isfunction(self.options.SetSectionTitle) ) then
                                self.options:SetSectionTitle(categoryButton:GetText())
                            end

                            if ( isfunction(self.UpdateOptionsSubnavActive) ) then
                                self:UpdateOptionsSubnavActive(categoryID)
                            end

                            if ( IsValid(sourceButton) and isfunction(sourceButton.DoClick) ) then
                                sourceButton:DoClick()
                                return
                            end

                            if ( IsValid(self.options) and self.options.SelectCategory ) then
                                self.options:SelectCategory(categoryID)
                            end
                        end

                        self.optionsSubnavButtons[categoryID] = categoryButton
                        created = created + 1
                    end
                end
            end

            local selectedCategoryID = ax.gui.storeLastOption
            if ( !selectedCategoryID or !self.optionsSubnavButtons[selectedCategoryID] ) then
                for id, _ in SortedPairs(self.optionsSubnavButtons) do
                    selectedCategoryID = id
                    break
                end
            end

            if ( selectedCategoryID and self.optionsSubnavButtons[selectedCategoryID] ) then
                if ( !ax.gui.optionsFirstCategoryInitialized ) then
                    ax.gui.optionsFirstCategoryInitialized = true
                    ax.gui.storeLastOption = selectedCategoryID
                    self.optionsSubnavButtons[selectedCategoryID]:DoClick()
                elseif ( isfunction(self.UpdateOptionsSubnavActive) ) then
                    self:UpdateOptionsSubnavActive(selectedCategoryID)

                    if ( IsValid(self.options) and isfunction(self.options.SetSectionTitle) ) then
                        self.options:SetSectionTitle(self.optionsSubnavButtons[selectedCategoryID]:GetText())
                    end
                end
            end

            if ( IsValid(self.optionsSubnavLoading) ) then
                self.optionsSubnavLoading:SetVisible(created == 0)
            end

            return created
        end

        local workshopButton = self.nav:Add("bms.button")
        workshopButton:Dock(LEFT)
        workshopButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
        workshopButton:SetText("STEAM WORKSHOP")
        workshopButton:SetTextColor(color_white)
        SetupMainUnderlineButton(workshopButton)
        table.insert(self.mainNavButtons, workshopButton)
        workshopButton.DoClick = function()
            local timerID = "ax_workshop_button_state_" .. tostring(self)

            if ( IsValid(self) ) then
                self:SetMainNavActive(workshopButton)
            end

            gui.OpenURL("https://steamcommunity.com/workshop/filedetails/?id=3684369184")

            timer.Remove(timerID)
            timer.Create(timerID, 0.05, 0, function()
                if ( !IsValid(self) or !IsValid(workshopButton) ) then
                    timer.Remove(timerID)
                    return
                end

                if ( !gui.IsGameUIVisible() ) then
                    workshopButton.mainUnderlineActive = false
                    timer.Remove(timerID)
                end
            end)
        end
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
            if ( IsValid(self.disconnectConfirmFrame) ) then
                self.disconnectConfirmFrame:Remove()
            end

            local frame = vgui.Create("DFrame")
            self.disconnectConfirmFrame = frame

            frame:SetTitle("")
            frame:ShowCloseButton(false)
            frame:SetDraggable(false)
            frame:SetDeleteOnClose(true)
            frame:SetSize(ax.util:ScreenScale(300), ax.util:ScreenScaleH(120))
            frame:Center()
            frame:MakePopup()

            local headerTall = ax.util:ScreenScaleH(24)
            local bodyColor = Color(14, 18, 24, 220)
            local headerColor = Color(195, 102, 36, 245)
            local borderColor = Color(195, 102, 36, 180)

            frame.Paint = function(this, width, height)
                ax.render.Draw(0, 0, 0, width, height, bodyColor)
                ax.render.Draw(0, 0, 0, width, headerTall, headerColor)

                surface.SetDrawColor(borderColor)
                surface.DrawOutlinedRect(0, 0, width, height, 1)
            end

            local title = frame:Add("DLabel")
            title:SetFont("ax.large.bold")
            title:SetText("DISCONNECT")
            title:SetTextColor(color_white)
            title:SetContentAlignment(4)
            title:Dock(TOP)
            title:DockMargin(ax.util:ScreenScale(10), 0, 0, 0)
            title:SetTall(headerTall)

            local message = frame:Add("DLabel")
            message:SetFont("ax.medium")
            message:SetText("Are you sure you want to disconnect?")
            message:SetTextColor(color_white)
            message:SetContentAlignment(4)
            message:Dock(TOP)
            message:DockMargin(ax.util:ScreenScale(12), ax.util:ScreenScaleH(8), ax.util:ScreenScale(12), 0)
            message:SetTall(ax.util:ScreenScaleH(18))

            local buttonRow = frame:Add("EditablePanel")
            buttonRow:Dock(BOTTOM)
            buttonRow:DockMargin(ax.util:ScreenScale(10), ax.util:ScreenScaleH(10), ax.util:ScreenScale(10), ax.util:ScreenScaleH(10))
            buttonRow:SetTall(ax.util:ScreenScaleH(24))
            buttonRow.Paint = nil

            local noButton = buttonRow:Add("bms.button")
            noButton:Dock(RIGHT)
            noButton:SetWide(ax.util:ScreenScale(72))
            noButton:SetText("NO")
            noButton:SetFillColor(color_white)
            noButton:SetFillHeightHover(0)
            noButton:SetFillHeightMotion(0)
            noButton.PaintAdditional = function(this, width, height)
                if ( this:IsHovered() ) then
                    surface.SetDrawColor(BMS_BUTTON_HOVER_COLOR)
                else
                    surface.SetDrawColor(color_white)
                end

                surface.DrawOutlinedRect(0, 0, width, height, 2)
            end
            noButton.DoClick = function()
                if ( IsValid(frame) ) then
                    frame:Close()
                end

                disconnectButton:SetToggled(false)
            end

            local yesButton = buttonRow:Add("bms.button")
            yesButton:Dock(RIGHT)
            yesButton:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
            yesButton:SetWide(ax.util:ScreenScale(72))
            yesButton:SetText("YES")
            yesButton:SetFillColor(color_white)
            yesButton:SetFillHeightHover(0)
            yesButton:SetFillHeightMotion(0)
            yesButton.PaintAdditional = function(this, width, height)
                if ( this:IsHovered() ) then
                    surface.SetDrawColor(BMS_BUTTON_HOVER_COLOR)
                else
                    surface.SetDrawColor(color_white)
                end

                surface.DrawOutlinedRect(0, 0, width, height, 2)
            end
            yesButton.DoClick = function()
                if ( IsValid(frame) ) then
                    frame:Close()
                end

                RunConsoleCommand("disconnect")
            end

            frame.OnClose = function()
                if ( IsValid(self) and self.disconnectConfirmFrame == frame ) then
                    self.disconnectConfirmFrame = nil
                end

                disconnectButton:SetToggled(false)
            end
        end

        self.optionsBackWrap = self.navBottom:Add("EditablePanel")
        self.optionsBackWrap:SetTall(self.navBottom:GetTall())
        self.optionsBackWrap:SetVisible(false)
        self.optionsBackWrap.Paint = nil

        local backButton = self.optionsBackWrap:Add("bms.button")
        backButton:Dock(FILL)
        backButton:SetText("BACK")
        backButton:SetFillColor(BMS_BUTTON_HOVER_COLOR)
        backButton:SetFillHeightHover(1)
        backButton:SetToggled(false)
        backButton:SetAlpha(255)
        backButton:SetEnabled(false)
        backButton:SetVisible(false)

        local backTextW = select(1, backButton:GetContentSize())
        local backPadding = ax.util:ScreenScale(18)
        local backWidth = math.max(ax.util:ScreenScale(52), backTextW + backPadding)
        self.optionsBackWrap:SetWide(backWidth)

        local disconnectWidth = disconnectButton:GetWide()
        if ( disconnectWidth <= 0 ) then
            disconnectButton:SizeToContentsX()
            disconnectWidth = disconnectButton:GetWide()
        end

        local leftPadding = ax.util:ScreenScale(16)
        local spacing = ax.util:ScreenScale(4)
        self.optionsBackWrap:SetPos(leftPadding + disconnectWidth + spacing, 0)
        self.optionsBackWrap._axBaseX = self.optionsBackWrap:GetX()
        self.optionsBackWrap._axBaseY = self.optionsBackWrap:GetY()

        backButton.DoClick = function()
            if ( self.activePanel == self.options ) then
                self.options:SlideDown()
                self.splash:SlideToFront()
                self.activePanel = self.splash
                self:SetMainNavActive(nil)

                AnimateBackButtonOut(self, backButton)
            end
        end

        self.optionsBackButton = backButton
    end

    self.options.OnHidden = function()
        if ( IsValid(self.optionsButton) ) then
            self.optionsButton.mainUnderlineActive = false
        end

        if ( IsValid(self.optionsSubnav) ) then
            self.optionsSubnav:SizeTo(self.optionsSubnav:GetWide(), 0, 0.2, 0, -1, function()
                if ( IsValid(self.optionsSubnav) ) then
                    self.optionsSubnav:SetVisible(false)
                end
            end)
        end
    end

    self.OnRemove = function()
        timer.Remove("ax_options_back_hide_" .. tostring(self))
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