--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local title

local PANEL = {}

function PANEL:Init()
    hook.Run("PreMainMenuCreateCreated", self)

    self:SetYOffset(ax.util:ScreenScaleH(64))
    self:SetHeightOffset(-ax.util:ScreenScaleH(128))

    self.payload = {}
    self.tabs = {}

    local vars = self:GetVars()
    for k, v in pairs(vars) do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end

        if ( isfunction(v.canPopulate) ) then
            local canPop, err = pcall(function()
                return v:canPopulate(self.payload, ax.client)
            end)

            if ( !canPop ) then
                ax.util:PrintWarning(("Failed to check canPopulate for character var '%s': %s"):format(tostring(k), tostring(err)))
                continue
            end

            if ( !err ) then
                continue
            end
        end

        if ( v.default != nil and self.payload[k] == nil ) then
            self.payload[k] = v.default
        end
    end

    self:StartAtBottom()
    self:ClearVars()

    hook.Run("PostMainMenuCreateCreated", self)
end

function PANEL:CreateNavigation() end

function PANEL:OnSlideStart()
    self:ClearVars()

    local function populate()
        if ( !IsValid(self) ) then return end

        -- Build only the first available category dynamically based on current payload.
        local categories = self:GetOrderedCategories()
        if ( #categories == 0 ) then
            -- Retry once after a short delay if it's empty, could be a race condition with data loading
            if ( !self._axPopulateRetry ) then
                self._axPopulateRetry = true
                timer.Simple(0.1, function()
                    if ( IsValid(self) ) then
                        populate()
                    end
                end)
            end
            return
        end

        local firstCategory = categories[1]
        local tab = self:CreateOrGetCategoryTab(firstCategory, 1)
        if ( IsValid(tab) ) then
            tab:SlideToFront(0)
            self.currentTab = tab
            -- CRITICAL: Clear before populating to prevent duplicates!
            self:ClearVars(firstCategory)
            self:PopulateVars(firstCategory)
        end
    end

    self._axPopulateRetry = false
    timer.Simple(0, populate)
end

function PANEL:ResetHoverStates()
    -- Deep reset for all faction cards to guarantee no sticky hover when we leave
    for _, tab in pairs(self.tabs) do
        if ( IsValid(tab) and IsValid(tab.container) and tab.container.factionButtons ) then
            for _, btn in ipairs(tab.container.factionButtons) do
                if ( IsValid(btn) ) then
                    btn:Stop()
                    btn.inertia = 0
                    if ( IsValid(btn.createBtn) ) then
                        btn.createBtn:Stop()
                        btn.createBtn:SetVisible(false)
                        btn.createBtn:SetAlpha(0)

                        -- Deep reset bms.button.resume specific variables
                        btn.createBtn:SetWasHovered(false)
                        btn.createBtn.lastFillHeightTarget = btn.createBtn:GetFillHeightIdle()
                        btn.createBtn:SetFillHeightMotion(btn.createBtn:GetFillHeightIdle())
                        btn.createBtn.lastTextColorTarget = btn.createBtn.textColor
                        btn.createBtn.textColorMotion = btn.createBtn.textColor
                        btn.createBtn:SetTextColorInternal(btn.createBtn.textColor)
                    end
                end
            end
            tab.container.activeHovered = nil
        end
    end
end

function PANEL:OnHidden()
    self:ResetHoverStates()
end

function PANEL:GetVars()
    local vars = table.Copy(ax.character.vars)
    local sortOrder = 0
    for k, v in pairs(vars) do
        v.category = v.category or "03_other"
        v.sortOrder = v.sortOrder or sortOrder
        sortOrder = sortOrder + 2
    end

    return vars
end

function PANEL:ValidateCategory(category)
    local vars = self:GetVars()

    for k, v in SortedPairsByMemberValue(vars, "sortOrder") do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end
        if ( (v.category or "03_other") != category ) then continue end

        if ( isfunction(v.canPopulate) ) then
            local ok, res = pcall(function()
                return v:canPopulate(self.payload, ax.client)
            end)

            if ( !ok or !res ) then continue end
        end

        local value = self.payload[k]
        if ( isfunction(v.validate) ) then
            local ok, isValid, reason = pcall(function()
                return v:validate(value, self.payload, ax.client)
            end)

            if ( !ok ) then
                return false, "An error occurred while validating this field"
            end

            if ( !isValid ) then
                return false, reason or "This field is invalid"
            end
        end
    end

    return true
end

function PANEL:NavigateToNextTab(currentTab)
    local categories = self:GetOrderedCategories()
    if ( #categories == 0 ) then return end

    local currentCategory = currentTab.category
    local currentIndex
    for i, name in ipairs(categories) do
        if ( name == currentCategory ) then
            currentIndex = i
            break
        end
    end

    if ( !currentIndex ) then return end

    local isValid, reason = self:ValidateCategory(currentCategory)
    if ( !isValid ) then
        ax.client:Notify(reason)
        return
    end

    if ( currentIndex == #categories ) then
        ax.net:Start("character.create", self.payload)
        return
    end

    local nextCategory = categories[currentIndex + 1]
    local nextTab = self:CreateOrGetCategoryTab(nextCategory, currentIndex + 1)
    if ( !IsValid(nextTab) ) then return end

    -- Force reset all button states before transitioning
    self:ResetHoverStates()

    currentTab:SlideLeft()
    nextTab:SlideToFront()
    self.currentTab = nextTab
    self:ClearVars(nextCategory)
    self:PopulateVars(nextCategory)
end

function PANEL:NavigateToPreviousTab(currentTab)
    local categories = self:GetOrderedCategories()
    if ( #categories == 0 ) then return end

    local currentCategory = currentTab.category
    local currentIndex
    for i, name in ipairs(categories) do
        if ( name == currentCategory ) then currentIndex = i break end
    end

    if ( !currentIndex ) then return end

    if ( currentIndex == 1 ) then
        return
    end

    local prevCategory = categories[currentIndex - 1]
    local prevTab = self:CreateOrGetCategoryTab(prevCategory, currentIndex - 1)
    if ( !IsValid(prevTab) ) then return end

    -- Force reset all button states before transitioning back
    self:ResetHoverStates()

    currentTab:SlideRight()
    prevTab:SlideToFront()
    self.currentTab = prevTab
    self:ClearVars(prevCategory)
    self:PopulateVars(prevCategory)
end

-- Returns a sorted list of category names that are currently eligible for population
function PANEL:GetOrderedCategories()
    local vars = self:GetVars()
    local categories = {}
    local categoryOrder = {}

    for k, v in SortedPairsByMemberValue(vars, "category") do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end

        local category = v.category or "03_other"

        local canUse = true
        if ( isfunction(v.canPopulate) ) then
            local ok, res = pcall(function()
                return v:canPopulate(self.payload, ax.client)
            end)

            if ( !ok or !res ) then
                if ( !ok ) then
                    ax.util:PrintWarning(("Failed to check canPopulate for character var '%s': %s"):format(tostring(k), tostring(res)))
                end
                canUse = false
            end
        end

        if ( canUse ) then
            categories[category] = true
            categoryOrder[category] = math.min(categoryOrder[category] or v.sortOrder, v.sortOrder)
        end
    end

    local catList = {}
    for name, _ in pairs(categories) do
        local baseOrder = categoryOrder[name] or 0
        local prefix = string.match(name, "^(%d+)[_%-]")
        local orderKey = baseOrder
        if ( prefix ) then
            orderKey = tonumber(prefix) * 100000 + baseOrder
        end
        table.insert(catList, { name = name, order = orderKey })
    end

    table.sort(catList, function(a, b)
        if ( a.order == b.order ) then return a.name < b.name end
        return a.order < b.order
    end)

    local ordered = {}
    for _, info in ipairs(catList) do table.insert(ordered, info.name) end

    -- Update indices on existing tabs for consistent navigation
    for i, name in ipairs(ordered) do
        local tab = self.tabs[name]
        if ( IsValid(tab) ) then tab.index = i end
    end

    return ordered
end

-- Creates a tab for a category if it does not yet exist (or returns existing one)
function PANEL:CreateOrGetCategoryTab(category, index)
    local tab = self.tabs[category]
    if ( IsValid(tab) ) then
        tab.index = index or tab.index or 1
        return tab
    end

    tab = self:CreatePage(category)
    tab.category = category
    tab.index = index or tab.index or 1
    tab:StartAtRight()
    
    -- Forcefully override CreateNavigation on the tab to prevent Parallax from adding its own buttons
    tab.CreateNavigation = function() end

    tab.container = tab:Add("EditablePanel")
    tab.container:Dock(FILL)
    tab.container:DockMargin(ax.util:ScreenScale(48), ax.util:ScreenScaleH(16), ax.util:ScreenScale(48), ax.util:ScreenScaleH(40))
    tab.container:InvalidateParent(true)

    self.tabs[category] = tab

    return tab
end

function PANEL:GetContainer(category)
    category = category or "03_other"

    local container = self.tabs[category]
    if ( !IsValid(container) ) then return end

    container = container.container
    if ( !IsValid(container) ) then return end

    return container
end

function PANEL:ClearVars(category)
    if ( !category ) then
        for k, v in pairs(self.tabs) do
            self:ClearVars(k)
        end

        return
    end

    local container = self:GetContainer(category)
    if ( !IsValid(container) ) then return end

    container:Clear()
end

function PANEL:PopulateVars(category)
    local vars = self:GetVars()

    category = category or "03_other"

    local container = self:GetContainer(category)
    if ( !IsValid(container) ) then return end

    for k, v in SortedPairsByMemberValue(vars, "sortOrder") do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end
        if ( (v.category or "03_other") != category ) then continue end

        if ( isfunction(v.canPopulate) ) then
            local canPop, err = pcall(function()
                return v:canPopulate(self.payload, ax.client)
            end)

            if ( !canPop ) then
                ax.util:PrintWarning(("Failed to check canPopulate for character var '%s': %s"):format(tostring(k), tostring(err)))
                continue
            end

            if ( !err ) then
                continue
            end
        end

        if ( isfunction(v.populate) ) then
            local ok, err = pcall(function()
                v:populate(container, self.payload)
            end)

            if ( !ok ) then
                ax.util:PrintWarning(("Failed to populate character var '%s': %s"):format(tostring(k), tostring(err)))
            end

            continue
        end

        if ( v.fieldType == ax.type.string ) then
            local option = container:Add("ax.text")
            option:SetFont("ax.large.bold")
            option:SetText(utf8.upper(ax.util:UniqueIDToName(k)))
            option:SetZPos(v.sortOrder - 1)
            option:Dock(TOP)

            local entry = container:Add("ax.text.entry")
            entry:SetPlaceholderText(v.default)
            entry:SetZPos(v.sortOrder)
            entry:Dock(TOP)
            entry:DockMargin(0, 0, 0, ax.util:ScreenScaleH(16))

            entry.OnValueChange = function(this)
                self.payload[k] = this:GetText()

                if ( self.OnPayloadChanged ) then
                    self:OnPayloadChanged(self.payload)
                end

                hook.Run("OnPayloadChanged", self.payload)
            end

            if ( isfunction(v.populatePost) ) then
                v:populatePost(container, self.payload, option, entry)
            end
        elseif ( v.fieldType == ax.type.number ) then
            local option = container:Add("ax.text")
            option:SetFont("ax.large.bold")
            option:SetText(utf8.upper(ax.util:UniqueIDToName(k)))
            option:SetZPos(v.sortOrder - 1)
            option:Dock(TOP)

            local slider = container:Add("DNumSlider")
            slider:SetDecimals(v.decimals or 0)
            slider:SetMin(v.min or 0)
            slider:SetMax(v.max or 100)
            slider:SetValue(v.default)
            slider:SetZPos(v.sortOrder)
            slider:Dock(TOP)
            slider:DockMargin(0, 0, 0, ax.util:ScreenScaleH(16))

            slider.OnValueChanged = function(this, value)
                self.payload[k] = value

                if ( self.OnPayloadChanged ) then
                    self:OnPayloadChanged(self.payload)
                end

                hook.Run("OnPayloadChanged", self.payload)
            end

            if ( isfunction(v.populatePost) ) then
                v:populatePost(container, self.payload, option, slider)
            end
        end
    end

    if ( self.OnPopulateVars ) then
        self:OnPopulateVars(container, category, self.payload)
    end

    hook.Run("OnCharacterPopulateVars", container, category, self.payload)
end

function PANEL:OnPopulateVars(container, category, payload)
    local targetCategory = category or "03_other"
    for k, v in pairs(self:GetVars()) do
        if ( v.field == "model" ) then
            targetCategory = v.category or "03_other"
            break
        end
    end

    if ( ax.util:FindString(category, targetCategory) ) then
        self.miscModel = container:Add("DModelPanel")
        self.miscModel:SetModel(payload.model or "models/player.mdl")
        self.miscModel:SetWide(0)
        self.miscModel:SetFOV(ax.util:ScreenScale(12))
        self.miscModel:Dock(LEFT)
        self.miscModel:DockMargin(0, 0, 0, 0)
        self.miscModel:SetZPos(-1)

        self.miscModel.LayoutEntity = function(this, entity)
            this:RunAnimation()
            entity:SetAngles(Angle(0, 90, 0))
        end

        local entity = self.miscModel:GetEntity()
        if ( IsValid(entity) ) then
            entity:SetSkin(payload.skin or 0)
        end
    end
end

function PANEL:OnPayloadChanged(payload)
    if ( IsValid(self.miscModel) ) then
        if ( payload.model and self.miscModel:GetModel() != payload.model ) then
            self.miscModel:SetModel(payload.model)
            if ( self.miscModel:GetWide() == 0 ) then
                self.miscModel:Motion(1, {
                    Target = {
                        width = self.miscModel:GetParent():GetWide() / 4,
                        rightPadding = ax.util:ScreenScale(32)
                    },
                    Easing = "OutQuad",
                    Think = function(this)
                        self.miscModel:SetWide(this.width)
                        self.miscModel:DockMargin(0, 0, this.rightPadding, 0)
                    end
                })
            end
        end

        self.miscModel:GetEntity():SetSkin(payload.skin or 0)
    end
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.main.create", PANEL, "ax.transition.pages")

-- Override faction selection UI for BMRP to match the requested design
local factionVar = ax.character.vars["faction"]
if ( factionVar ) then
    factionVar.populate = function(this, container, payload)
        local parent = container:GetParent()
        if ( !IsValid(parent) ) then
            ax.util:PrintWarning("Cannot populate faction selection: invalid parent container")
            return
        end
        
        local factionList = container:Add("ax.scroller.horizontal")
        factionList:Dock(TOP)
        factionList:SetTall(ax.util:ScreenScaleH(250))
        factionList:DockMargin(0, ax.util:ScreenScaleH(20), 0, 0)
        factionList:InvalidateParent(true)
        factionList.Paint = nil

        factionList.btnLeft:SetAlpha(0)
        factionList.btnRight:SetAlpha(0)

        local factions = table.Copy(ax.faction:GetAll())
        table.sort(factions, function(a, b)
            local aSort = a.sortOrder or 100
            local bSort = b.sortOrder or 100

            if ( aSort == bSort ) then
                return a.name < b.name
            end

            return aSort < bSort
        end)

        local buttonWidth = ax.util:ScreenScale(150)
        container.factionButtons = {}

        for i = 1, #factions do
            local v = factions[i]
            local can, reason = ax.faction:CanBecome(v.index, ax.client)
            if ( !can ) then
                continue
            end

            local name = (v.name and utf8.upper(v.name)) or "UNKNOWN FACTION"
            local description = v.description or "UNKNOWN FACTION DESCRIPTION"
            description = string.gsub(description, "%s+([%p])", "%1")
            
            local titleFont = "ax.large.bold"
            local subtitleFont = "ax.regular"
            
            local sidePadding = ax.util:ScreenScale(6)
            -- REMOVED utf8.upper to keep descriptions in normal casing
            local descriptionWrapped = ax.util:GetWrappedText(description, subtitleFont, buttonWidth - sidePadding * 2)

            local banner = v.image or hook.Run("GetFactionBanner", v.index) or "parallax/banners/unknown.png"
            if ( isstring(banner) ) then
                banner = ax.util:GetMaterial(banner)
            end

            local factionButton = factionList:Add("EditablePanel")
            factionButton:SetWide(buttonWidth)
            factionButton:Dock(LEFT)
            factionButton:DockMargin(ax.util:ScreenScale(12), 0, ax.util:ScreenScale(12), 0)
            factionButton.inertia = 0
            table.insert(container.factionButtons, factionButton)

            local createBtn = factionButton:Add("bms.button.resume")
            factionButton.createBtn = createBtn
            createBtn:SetText("CREATE")
            createBtn:SetWide(ax.util:ScreenScale(52))
            createBtn:SetTall(ax.util:ScreenScaleH(24))
            createBtn:SetFont("ax.regular.bold")
            createBtn:SetOutlineThickness(4)
            createBtn:SetAlpha(0)
            createBtn:SetVisible(false)
            createBtn.DoClick = function()
                if ( (ax.gui.main.lastButtonClickTime or 0) + 0.3 > SysTime() ) then return end
                ax.gui.main.lastButtonClickTime = SysTime()

                table.Empty(payload or {})
                payload.faction = v.index

                if ( ax.gui.main.create.OnPayloadChanged ) then
                    ax.gui.main.create:OnPayloadChanged(payload)
                end

                hook.Run("OnPayloadChanged", payload)

                ax.gui.main.create:NavigateToNextTab(parent)
            end

            factionButton.OnCursorEntered = function(this)
                -- Force all other buttons to reset their hover state immediately to prevent double-hover
                for _, btn in ipairs(container.factionButtons or {}) do
                    if ( IsValid(btn) and btn != this ) then
                        btn:Motion(0.1, { Target = { inertia = 0 }, Easing = "Linear" })
                        btn.inertia = 0
                        if ( IsValid(btn.createBtn) ) then 
                            btn.createBtn:SetVisible(false)
                            btn.createBtn:SetAlpha(0)
                        end
                    end
                end

                container.activeHovered = this
                createBtn:SetVisible(true)
                this:Motion(0.2, {
                    Target = { inertia = 1 },
                    Easing = "OutQuint"
                })
            end

            factionButton.OnCursorExited = function(this)
                timer.Simple(0, function()
                    if ( !IsValid(this) or this:IsHovered() or (IsValid(createBtn) and createBtn:IsHovered()) ) then return end
                    
                    if ( container.activeHovered == this ) then
                        container.activeHovered = nil
                    end

                    this:Motion(0.2, {
                        Target = { inertia = 0 },
                        Easing = "OutQuint"
                    }, function()
                        if ( IsValid(createBtn) and this.inertia == 0 ) then
                            createBtn:SetVisible(false)
                        end
                    end)
                end)
            end

            factionButton.PerformLayout = function(this, w, h)
                createBtn:SetPos(sidePadding, h - createBtn:GetTall() - sidePadding)
            end

            factionButton.Paint = function(this, width, height)
                local glass = ax.theme:GetGlass()
                local inertia = this.inertia or 0
                local orange = BMS_NAV_COLOR or Color(228, 113, 37)

                -- Ensure strictly one card shows hover effects at any given time
                if ( container.activeHovered != this ) then
                    inertia = 0
                end

                createBtn:SetAlpha(255 * inertia)

                -- Use a widescreen aspect ratio (16:9) for the banner image.
                local imageHeight = math.Round(width * (9 / 16))

                -- 1. Draw the faction banner (image)
                ax.render.DrawMaterial(0, 0, 0, width, imageHeight, color_white, banner)

                -- 2. Draw background and frames on hover
                if ( inertia > 0 ) then
                    -- Background ONLY for text area (below image)
                    surface.SetDrawColor(0, 0, 0, 180 * inertia)
                    surface.DrawRect(0, imageHeight, width, height - imageHeight)

                    -- Frame outline
                    surface.SetDrawColor(orange.r, orange.g, orange.b, 255 * inertia)
                    surface.DrawOutlinedRect(0, 0, width, height, 1)
                    
                    -- Image area outline (Top, Left, Right ONLY)
                    surface.DrawLine(0, 0, width, 0) -- Top
                    surface.DrawLine(0, 0, 0, imageHeight) -- Left
                    surface.DrawLine(width - 1, 0, width - 1, imageHeight) -- Right
                end

                local textColor = inertia > 0.5 and glass.textHover or glass.text
                
                -- Title: Detached from faction image with padding
                local titleY = imageHeight + ax.util:ScreenScaleH(8)
                
                local nameWrapped = ax.util:GetWrappedText(name, titleFont, width - sidePadding * 2)
                for _, line in ipairs(nameWrapped) do
                    draw.SimpleText(line, titleFont, sidePadding, titleY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    titleY = titleY + ax.util:GetTextHeight(titleFont)
                end

                -- Subtitle/Description: Also detached with padding
                local subtitleY = titleY + ax.util:ScreenScaleH(2)
                local subtitleColor = ColorAlpha(textColor, 160 + (95 * inertia))
                
                -- Ensure there's padding between description and the "CREATE" button
                for d = 1, #descriptionWrapped do
                    draw.SimpleText(descriptionWrapped[d], subtitleFont, sidePadding, subtitleY, subtitleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    subtitleY = subtitleY + ax.util:GetTextHeight(subtitleFont)
                end
            end

            factionList:AddPanel(factionButton)
        end
    end
end
