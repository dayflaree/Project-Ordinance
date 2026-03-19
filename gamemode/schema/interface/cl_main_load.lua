--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

function PANEL:Init()
    hook.Run("PreMainMenuLoadCreated", self)

    local parent = self:GetParent()

    self:SetYOffset(ax.util:ScreenScaleH(64))
    self:SetHeightOffset(-ax.util:ScreenScaleH(128))

    self.characterList = self:Add("ax.transition")
    self.characterList:StartAtBottom()

    self.characters = self.characterList:Add("ax.scroller.horizontal")
    self.characters:Dock(TOP)
    self.characters:SetTall(ax.util:ScreenScaleH(220))
    self.characters:DockMargin(ax.util:ScreenScale(48), ax.util:ScreenScaleH(40), ax.util:ScreenScale(48), 0)
    self.characters:InvalidateParent(true)

    self.characters.btnLeft:SetAlpha(0)
    self.characters.btnRight:SetAlpha(0)
    self.characters.Paint = nil

    self.deletePanel = self:Add("ax.transition")
    self.deletePanel:StartAtRight()

    self.deleteContainer = self.deletePanel:Add("EditablePanel")
    self.deleteContainer:Dock(FILL)
    self.deleteContainer:InvalidateParent(true)

    hook.Run("PostMainMenuLoadCreated", self)
end

function PANEL:CreateNavigation() end

function PANEL:ResetHoverStates()
    for _, btn in pairs(self.characterButtons or {}) do
        if ( IsValid(btn) ) then
            btn:Stop()
            btn.inertia = 0
            if ( IsValid(btn.loadBtn) ) then
                btn.loadBtn:Stop()
                btn.loadBtn:SetVisible(false)
                btn.loadBtn:SetAlpha(0)

                btn.loadBtn:SetWasHovered(false)
                btn.loadBtn.lastFillHeightTarget = btn.loadBtn:GetFillHeightIdle()
                btn.loadBtn:SetFillHeightMotion(btn.loadBtn:GetFillHeightIdle())
                btn.loadBtn.lastTextColorTarget = btn.loadBtn.textColor
                btn.loadBtn.textColorMotion = btn.loadBtn.textColor
                btn.loadBtn:SetTextColorInternal(btn.loadBtn.textColor)
            end
            if ( IsValid(btn.deleteBtn) ) then
                btn.deleteBtn:Stop()
                btn.deleteBtn:SetVisible(false)
                btn.deleteBtn:SetAlpha(0)

                btn.deleteBtn:SetWasHovered(false)
                btn.deleteBtn.lastFillHeightTarget = btn.deleteBtn:GetFillHeightIdle()
                btn.deleteBtn:SetFillHeightMotion(btn.deleteBtn:GetFillHeightIdle())
                btn.deleteBtn.lastTextColorTarget = btn.deleteBtn.textColor
                btn.deleteBtn.textColorMotion = btn.deleteBtn.textColor
                btn.deleteBtn:SetTextColorInternal(btn.deleteBtn.textColor)
            end
        end
    end
    self.activeHovered = nil
end

function PANEL:OnHidden()
    self:ResetHoverStates()
end

function PANEL:OnSlideStart()
    if ( !IsValid(self.characters) ) then return end
    if ( !IsValid(self.deleteContainer) ) then return end

    self:ResetHoverStates()
    self.characterList:SlideToFront()
    self:PopulateCharacterList()
end

function PANEL:PopulateCharacterList()
    self.characters:Clear()
    local clientTable = ax.client:GetTable()
    if ( !istable(clientTable.axCharacters) ) then clientTable.axCharacters = {} end
    if ( clientTable.axCharacters[1] == nil ) then return end

    local buttonWidth = ax.util:ScreenScale(150)
    self.characterButtons = {}

    for k, v in pairs(clientTable.axCharacters or {}) do
        local name = v:GetName():upper()
        local lastPlayed = os.date("%a %b %d %H:%M:%S %Y", v:GetLastPlayed())
        local faction = v:GetFactionData()
        local banner = hook.Run("GetCharacterBanner", v.id) or (faction and faction.image) or "parallax/banners/unknown.png"
        if ( isstring(banner) ) then
            banner = ax.util:GetMaterial(banner)
        end

        local card = self.characters:Add("EditablePanel")
        card:SetWide(buttonWidth)
        card:Dock(LEFT)
        card:DockMargin(ax.util:ScreenScale(12), 0, ax.util:ScreenScale(12), 0)
        card.inertia = 0
        table.insert(self.characterButtons, card)

        local loadBtn = card:Add("bms.button.resume")
        card.loadBtn = loadBtn
        loadBtn:SetText("LOAD")
        loadBtn:SetWide(ax.util:ScreenScale(52))
        loadBtn:SetTall(ax.util:ScreenScaleH(24))
        loadBtn:SetFont("ax.regular.bold")
        loadBtn:SetOutlineThickness(4)
        loadBtn:SetAlpha(0)
        loadBtn:SetVisible(false)
        loadBtn.DoClick = function()
            if ( (ax.gui.main.lastButtonClickTime or 0) + 0.3 > SysTime() ) then return end
            ax.gui.main.lastButtonClickTime = SysTime()

            ax.net:Start("character.load", v.id)
        end

        local deleteBtn = card:Add("bms.button.resume")
        card.deleteBtn = deleteBtn
        deleteBtn:SetText("DELETE")
        deleteBtn:SetWide(ax.util:ScreenScale(52))
        deleteBtn:SetTall(ax.util:ScreenScaleH(24))
        deleteBtn:SetFont("ax.regular.bold")
        deleteBtn:SetOutlineThickness(4)
        deleteBtn:SetAlpha(0)
        deleteBtn:SetVisible(false)
        deleteBtn.DoClick = function()
            if ( (ax.gui.main.lastButtonClickTime or 0) + 0.3 > SysTime() ) then return end
            ax.gui.main.lastButtonClickTime = SysTime()

            self:PopulateDeletePanel(v)
        end

        card.OnCursorEntered = function(this)
            for _, btn in ipairs(self.characterButtons or {}) do
                if ( IsValid(btn) and btn != this ) then
                    btn:Motion(0.1, { Target = { inertia = 0 }, Easing = "Linear" })
                    btn.inertia = 0
                    if ( IsValid(btn.loadBtn) ) then btn.loadBtn:SetVisible(false); btn.loadBtn:SetAlpha(0) end
                    if ( IsValid(btn.deleteBtn) ) then btn.deleteBtn:SetVisible(false); btn.deleteBtn:SetAlpha(0) end
                end
            end

            self.activeHovered = this
            loadBtn:SetVisible(true)
            deleteBtn:SetVisible(true)
            this:Motion(0.2, {
                Target = { inertia = 1 },
                Easing = "OutQuint"
            })
        end

        card.OnCursorExited = function(this)
            timer.Simple(0, function()
                if ( !IsValid(this) or this:IsHovered() or (IsValid(loadBtn) and loadBtn:IsHovered()) or (IsValid(deleteBtn) and deleteBtn:IsHovered()) ) then return end
                
                if ( self.activeHovered == this ) then
                    self.activeHovered = nil
                end

                this:Motion(0.2, {
                    Target = { inertia = 0 },
                    Easing = "OutQuint"
                }, function()
                    if ( IsValid(loadBtn) and this.inertia == 0 ) then
                        loadBtn:SetVisible(false)
                    end
                    if ( IsValid(deleteBtn) and this.inertia == 0 ) then
                        deleteBtn:SetVisible(false)
                    end
                end)
            end)
        end

        card.PerformLayout = function(this, w, h)
            local sidePadding = ax.util:ScreenScale(6)
            loadBtn:SetPos(sidePadding, h - loadBtn:GetTall() - sidePadding)
            deleteBtn:SetPos(w - deleteBtn:GetWide() - sidePadding, h - deleteBtn:GetTall() - sidePadding)
        end

        card.Paint = function(this, width, height)
            local glass = ax.theme:GetGlass()
            local inertia = this.inertia or 0
            local orange = BMS_NAV_COLOR or Color(228, 113, 37)

            if ( self.activeHovered != this ) then
                inertia = 0
            end

            loadBtn:SetAlpha(255 * inertia)
            deleteBtn:SetAlpha(255 * inertia)

            local imageHeight = math.Round(width * (9 / 16))
            ax.render.DrawMaterial(0, 0, 0, width, imageHeight, color_white, banner)

            if ( inertia > 0 ) then
                surface.SetDrawColor(0, 0, 0, 180 * inertia)
                surface.DrawRect(0, imageHeight, width, height - imageHeight)

                surface.SetDrawColor(orange.r, orange.g, orange.b, 255 * inertia)
                surface.DrawOutlinedRect(0, 0, width, height, 1)
                
                surface.DrawLine(0, 0, width, 0)
                surface.DrawLine(0, 0, 0, imageHeight)
                surface.DrawLine(width - 1, 0, width - 1, imageHeight)
            end

            local textColor = inertia > 0.5 and glass.textHover or glass.text
            local titleFont = "ax.large.bold"
            local subtitleFont = "ax.regular"
            local sidePadding = ax.util:ScreenScale(6)

            local titleY = imageHeight + ax.util:ScreenScaleH(8)
            draw.SimpleText(name, titleFont, sidePadding, titleY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            titleY = titleY + ax.util:GetTextHeight(titleFont)

            local subtitleY = titleY + ax.util:ScreenScaleH(2)
            local subtitleColor = ColorAlpha(textColor, 160 + (95 * inertia))
            local descriptionWrapped = ax.util:GetWrappedText(lastPlayed, subtitleFont, width - sidePadding * 2)

            for d = 1, #descriptionWrapped do
                draw.SimpleText(descriptionWrapped[d], subtitleFont, sidePadding, subtitleY, subtitleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                subtitleY = subtitleY + ax.util:GetTextHeight(subtitleFont)
            end
        end

        self.characters:AddPanel(card)
    end
end

function PANEL:PopulateDeletePanel(character)
    self.characterList:SlideLeft()
    self.deletePanel:SlideToFront()
    self.deleteContainer:Clear()

    local title = self.deleteContainer:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(ax.util:ScreenScale(48), ax.util:ScreenScaleH(40), 0, 0)
    title:SetFont("ax.huge.bold")
    title:SetText("ARE YOU SURE YOU WANT TO DELETE")

    local name = self.deleteContainer:Add("ax.text")
    name:Dock(TOP)
    name:DockMargin(ax.util:ScreenScale(72), 0, 0, ax.util:ScreenScaleH(20))
    name:SetFont("ax.huge.bold")
    name:SetText(character:GetName():upper())
    name:SetTextColor(team.GetColor(character:GetFaction()) or color_white)

    local mark = name:Add("ax.text")
    mark:Dock(LEFT)
    mark:DockMargin(name:GetWide(), 0, 0, 0)
    mark:SetFont("ax.huge.bold")
    mark:SetText("?")

    local model = self.deleteContainer:Add("DModelPanel")
    model:SetModel(character:GetModel() or "models/player/kleiner.mdl")
    model:SetFOV(15)
    model:SetSize(self.deleteContainer:GetWide() / 3, self.deleteContainer:GetTall())
    model:Center()
    model:SetMouseInputEnabled(false)
    model.LayoutEntity = function(this, ent)
        ent:SetAngles(Angle(0, RealTime() * 10 % 360, 0))
        ent:SetPos(-Vector(128, 128, 32))
        ent:SetEyeTarget(ent:GetPos() * ent:GetAngles():Forward())
        ent:SetIK(false)

        this:RunAnimation()
    end

    local confirmBtn = self.deleteContainer:Add("bms.button.resume")
    confirmBtn:SetText("CONFIRM")
    confirmBtn:SetWide(ax.util:ScreenScale(64))
    confirmBtn:SetTall(ax.util:ScreenScaleH(28))
    confirmBtn:SetFont("ax.large.bold")
    confirmBtn:SetOutlineThickness(4)
    confirmBtn:SetPos(ax.util:ScreenScale(72), ax.util:ScreenScaleH(150)) -- Positioned under the name
    confirmBtn.DoClick = function()
        if ( (ax.gui.main.lastButtonClickTime or 0) + 0.3 > SysTime() ) then return end
        ax.gui.main.lastButtonClickTime = SysTime()

        ax.net:Start("character.delete", character.id)

        self:PopulateCharacterList()
        self.characterList:SlideToFront()
        self.deletePanel:SlideRight()
    end
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.main.load", PANEL, "ax.transition")
