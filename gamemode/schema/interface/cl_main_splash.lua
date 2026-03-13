--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

BMS_SPLASH_LOGO = ax.util:GetMaterial("riggs9162/bms/ui/logo-new.png", "smooth mips")

local function GetRatioSize(originalW, originalH, maxW, maxH)
    local ratio = math.min(maxW / originalW, maxH / originalH)
    return originalW * ratio, originalH * ratio
end

local function GetLastPlayedCharacter()
    local clientTable = ax.client:GetTable()
    if ( !istable(clientTable) or !istable(clientTable.axCharacters) ) then
        return nil, 0
    end

    local newestCharacter = nil
    local newestTime = -1

    for _, character in pairs(clientTable.axCharacters) do
        if ( !istable(character) ) then continue end

        local lastPlayed = 0
        if ( isfunction(character.GetLastPlayed) ) then
            lastPlayed = tonumber(character:GetLastPlayed()) or 0
        end

        if ( lastPlayed > newestTime ) then
            newestCharacter = character
            newestTime = lastPlayed
        end
    end

    return newestCharacter, math.max(newestTime, 0)
end

local function FormatLastPlayed(timestamp)
    if ( !isnumber(timestamp) or timestamp <= 0 ) then
        return "Never played"
    end

    return os.date("%A, %B %d %Y %H:%M:%S", timestamp)
end

local PANEL = {}

function PANEL:Init()
    hook.Run("PreMainMenuSplashCreated", self)

    self:SetYOffset(ax.util:ScreenScaleH(24))
    self:SetHeightOffset(-ax.util:ScreenScaleH(48))

    self.logoSizeW, self.logoSizeH = GetRatioSize(BMS_SPLASH_LOGO:Width(), BMS_SPLASH_LOGO:Height(), ax.util:ScreenScale(520), ax.util:ScreenScaleH(78))
    self.lastPlayedCharacter = nil

    self.logo = self:Add("EditablePanel")
    self.logo.Paint = function(this, width, height)
        ax.render.DrawMaterial(0, 0, 0, width, height, color_white, BMS_SPLASH_LOGO)
    end

    self.name = self:Add("ax.text")
    self.name:SetFont("ax.huge")
    self.name:SetTextColor(color_white)
    self.name:SetText("NO CHARACTER FOUND", true)

    self.lastPlayed = self:Add("ax.text")
    self.lastPlayed:SetFont("ax.regular")
    self.lastPlayed:SetTextColor(Color(225, 225, 225, 220))
    self.lastPlayed:SetText("Create a character to begin.", true)

    self.resume = self:Add("bms.button.resume")
    self.resume:SetFont("ax.regular.bold")
    self.resume:SetText("CONTINUE", true)
    self.resume:SetVisible(false)
    self.resume:SetEnabled(false)
    self.resume:SetMouseInputEnabled(false)
    self.resume.DoClick = function()
        self:ResumeLastPlayedCharacter()
    end

    hook.Add("OnCharactersRestored", self, function()
        if ( IsValid(self) ) then
            self:RefreshLastPlayedCharacter()
        end
    end)

    hook.Add("PlayerCreatedCharacter", self, function()
        if ( IsValid(self) ) then
            self:RefreshLastPlayedCharacter()
        end
    end)

    hook.Add("PlayerDeletedCharacter", self, function()
        if ( IsValid(self) ) then
            self:RefreshLastPlayedCharacter()
        end
    end)

    self:RefreshLastPlayedCharacter()

    hook.Run("PostMainMenuSplashCreated", self)
end

function PANEL:OnRemove()
    hook.Remove("OnCharactersRestored", self)
    hook.Remove("PlayerCreatedCharacter", self)
    hook.Remove("PlayerDeletedCharacter", self)
end

function PANEL:OnSlideStart()
    self:RefreshLastPlayedCharacter()
end

function PANEL:ResumeLastPlayedCharacter()
    if ( !istable(self.lastPlayedCharacter) ) then return end
    if ( !isnumber(self.lastPlayedCharacter.id) ) then return end

    if ( ax.client:GetCharacter() ) then
        ax.gui.main:Remove()
        return
    end

    ax.net:Start("character.load", self.lastPlayedCharacter.id)
end

function PANEL:RefreshLastPlayedCharacter()
    local character, lastPlayed = GetLastPlayedCharacter()
    self.lastPlayedCharacter = character

    if ( !istable(character) ) then
        self.name:SetFont("ax.huge")
        self.name:SetText("NO CHARACTER FOUND", true)
        self.lastPlayed:SetText("Create a character to begin.", true)
        self.resume:SetVisible(false)
        self.resume:SetEnabled(false)
        self.resume:SetMouseInputEnabled(false)
        self:InvalidateLayout(true)
        return
    end

    local name = "UNKNOWN CHARACTER"
    if ( isfunction(character.GetName) ) then
        name = character:GetName() or name
    elseif ( isstring(character.name) ) then
        name = character.name
    end

    name = utf8.upper(name)
    local nameLength = utf8.len(name) or #name
    self.name:SetFont(nameLength > 20 and "ax.massive" or "ax.huge")
    self.name:SetText(name, true)
    self.lastPlayed:SetText(FormatLastPlayed(lastPlayed), true)

    self.resume:SetVisible(true)
    self.resume:SetEnabled(true)
    self.resume:SetMouseInputEnabled(true)

    self:InvalidateLayout(true)
end

function PANEL:PerformLayout(width, height)
    local x = ax.util:ScreenScale(32)
    local y = ax.util:ScreenScaleH(196)

    self.logo:SetPos(x, y)
    self.logo:SetSize(self.logoSizeW, self.logoSizeH)

    y = y + self.logoSizeH + ax.util:ScreenScaleH(16)

    self.name:SizeToContents()
    self.name:SetPos(x, y)

    y = y + self.name:GetTall() - ax.util:ScreenScaleH(2)

    self.lastPlayed:SizeToContents()
    self.lastPlayed:SetPos(x, y)

    if ( self.resume:IsVisible() ) then
        self.resume:SizeToContents()
        self.resume:SetTall(math.max(self.resume:GetTall(), ax.util:ScreenScaleH(24)))
        self.resume:SetWide(math.max(self.resume:GetWide(), ax.util:ScreenScale(48)))
        self.resume:SetPos(x, y + self.lastPlayed:GetTall() + ax.util:ScreenScaleH(8))
    end
end

hook.Add("ShouldCreateLoadButton", "ax.main.splash", function()
    local clientTable = ax.client:GetTable()
    return clientTable.axCharacters and clientTable.axCharacters[1] != nil
end)

function PANEL:Paint(width, height)
end

vgui.Register("ax.main.splash", PANEL, "ax.transition")
