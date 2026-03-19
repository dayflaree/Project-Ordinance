local PANEL = {}

local BG = Color(247, 247, 247, 245)
local BORDER = Color(210, 210, 210)
local HEADER = Color(235, 235, 235)
local TEXT_DARK = Color(35, 35, 35)
local TEXT_MUTED = Color(90, 90, 90)

function PANEL:Init()
    self:SetSize(math.floor(ScrW() * 0.7), math.floor(ScrH() * 0.78))
    self:Center()
    self:SetKeyboardInputEnabled(true)
    self:SetMouseInputEnabled(true)
    self:MakePopup()

    self:SetTitle("", 0)

    self.header = self:Add("EditablePanel")
    self.header:Dock(TOP)
    self.header:SetTall(56)
    self.header.Paint = function(_, w, h)
        surface.SetDrawColor(HEADER)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(BORDER)
        surface.DrawLine(0, h - 1, w, h - 1)
    end

    self.titleLabel = self.header:Add("DLabel")
    self.titleLabel:SetFont("ax.large.bold")
    self.titleLabel:SetText("Prop Placement Catalogue")
    self.titleLabel:SetTextColor(TEXT_DARK)
    self.titleLabel:Dock(LEFT)
    self.titleLabel:DockMargin(16, 0, 0, 0)
    self.titleLabel:SetContentAlignment(4)

    self.budgetLabel = self.header:Add("DLabel")
    self.budgetLabel:SetFont("ax.medium")
    self.budgetLabel:SetTextColor(TEXT_MUTED)
    self.budgetLabel:SetContentAlignment(6)
    self.budgetLabel:SetText("Budget: Updating…")
    self.budgetLabel:Dock(RIGHT)
    self.budgetLabel:DockMargin(0, 0, 120, 0)

    self.closeBtn = self.header:Add("DButton")
    self.closeBtn:SetText("✕")
    self.closeBtn:SetFont("ax.medium.bold")
    self.closeBtn:SetTextColor(TEXT_DARK)
    self.closeBtn:Dock(RIGHT)
    self.closeBtn:SetWide(64)
    self.closeBtn.Paint = function(btn, w, h)
        local clr = btn:IsHovered() and Color(220, 220, 220) or Color(240, 240, 240)
        surface.SetDrawColor(clr)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(BORDER)
        surface.DrawLine(0, 0, 0, h)
    end
    self.closeBtn.DoClick = function()
        self:ClosePanel()
    end

    self.body = self:Add("EditablePanel")
    self.body:Dock(FILL)
    self.body.Paint = function(_, w, h)
        surface.SetDrawColor(BG)
        surface.DrawRect(0, 0, w, h)
    end

    self.sidebar = self.body:Add("DScrollPanel")
    self.sidebar:Dock(LEFT)
    self.sidebar:SetWide(math.max(220, math.floor(self:GetWide() * 0.2)))
    self.sidebar:DockMargin(16, 16, 16, 16)

    self.categoryList = self.sidebar:Add("DIconLayout")
    self.categoryList:Dock(TOP)
    self.categoryList:SetSpaceY(8)
    self.categoryList:SetSpaceX(0)

    self.contentScroll = self.body:Add("DScrollPanel")
    self.contentScroll:Dock(FILL)
    self.contentScroll:DockMargin(0, 16, 16, 16)

    self.itemsLayout = self.contentScroll:Add("DIconLayout")
    self.itemsLayout:Dock(TOP)
    self.itemsLayout:SetSpaceX(16)
    self.itemsLayout:SetSpaceY(16)

    self:RefreshBudget()
    self.nextBudgetPoll = 0
end

function PANEL:SetTitle(text)
    self._title = text
end

function PANEL:Think()
    if (self.nextBudgetPoll < CurTime()) then
        self:RefreshBudget()
        self.nextBudgetPoll = CurTime() + 1
    end
end

function PANEL:RefreshBudget()
    local budgetText = "Budget: Unknown"
    local funding = ax.module and ax.module:Get("funding")
    if (funding and funding.funding and funding.funding.GetGlobal) then
        local amount = tonumber(funding.funding:GetGlobal()) or 0
        budgetText = string.format("Budget: $%s", string.Comma(math.floor(amount)))
    end
    if (IsValid(self.budgetLabel)) then
        self.budgetLabel:SetText(budgetText)
    end
end

function PANEL:SetCatalogData(categories)
    self.catalogData = categories or {}
    self:BuildCategoryButtons()
    if (#self.catalogData > 0) then
        self:SelectCategory(self.catalogData[1].id)
    else
        self.itemsLayout:Clear()
    end
end

function PANEL:BuildCategoryButtons()
    if (not IsValid(self.categoryList)) then return end
    self.categoryList:Clear()
    self.categoryButtons = {}

    for _, category in ipairs(self.catalogData or {}) do
        local button = self.categoryList:Add("DButton")
        button:SetTall(40)
        button:SetWide(self.sidebar:GetWide() - 20)
        button:SetText(category.name or category.id)
        button:SetFont("ax.medium")
        button:SetTextColor(TEXT_DARK)
        button.Paint = function(btn, w, h)
            local hovered = btn:IsHovered() or self.activeCategory == category.id
            surface.SetDrawColor(hovered and Color(230, 230, 230) or Color(244, 244, 244))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(BORDER)
            surface.DrawOutlinedRect(0, 0, w, h, hovered and 2 or 1)
        end
        button.DoClick = function()
            self:SelectCategory(category.id)
        end
        self.categoryButtons[category.id] = button
    end
end

function PANEL:SelectCategory(categoryId)
    if (self.activeCategory == categoryId) then return end
    self.activeCategory = categoryId
    self:PopulateItems(categoryId)
end

function PANEL:PopulateItems(categoryId)
    if (not IsValid(self.itemsLayout)) then return end
    self.itemsLayout:Clear()

    local category
    for _, data in ipairs(self.catalogData or {}) do
        if (data.id == categoryId) then
            category = data
            break
        end
    end
    if (not category) then return end

    local columns = math.max(2, math.floor((self:GetWide() - self.sidebar:GetWide() - 64) / 320))
    local cardWidth = math.floor((self:GetWide() - self.sidebar:GetWide() - 64 - (columns - 1) * 16) / columns)
    cardWidth = math.Clamp(cardWidth, 280, 360)

    for _, item in ipairs(category.items or {}) do
        local card = self.itemsLayout:Add("EditablePanel")
        card:SetSize(cardWidth, 260)
        card.Paint = function(_, w, h)
            surface.SetDrawColor(color_white)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(BORDER)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local preview = vgui.Create("DModelPanel", card)
        preview:SetPos(12, 12)
        preview:SetSize(cardWidth - 24, 150)
        preview:SetModel(item.model or "models/props_c17/oildrum001.mdl")
        preview:SetTooltip(item.name or item.id)
        preview.LayoutEntity = function() end
        preview:SetFOV(25)
        function preview:SetupModel()
            local ent = self:GetEntity()
            if (not IsValid(ent)) then return end
            local min, max = ent:GetModelBounds()
            local size = max - min
            local radius = size:Length() * 0.5
            local center = (min + max) * 0.5
            self:SetCamPos(center + Vector(radius, radius, radius))
            self:SetLookAt(center)
        end
        preview:SetupModel()

        local textPanel = card:Add("EditablePanel")
        textPanel:SetPos(12, 168)
        textPanel:SetSize(cardWidth - 24, 46)
        textPanel.Paint = nil

        textPanel.PaintOver = function(_, w, h)
            local rawName = item.name or "Prop"
            local name = rawName:sub(1, 32)
            draw.SimpleText(name, "ax.medium.bold", 0, 0, TEXT_DARK, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(string.format("$%s", string.Comma(math.floor(item.price or 0))), "ax.medium", w, h, TEXT_MUTED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        end

        local buyBtn = vgui.Create("DButton", card)
        buyBtn:SetText("Purchase")
        buyBtn:SetFont("ax.medium")
        buyBtn:SetTextColor(TEXT_DARK)
        buyBtn:SetTall(32)
        buyBtn:SetWide(cardWidth - 24)
        buyBtn:SetPos(12, card:GetTall() - 44)
        buyBtn.Paint = function(btn, w, h)
            local hovered = btn:IsHovered()
            surface.SetDrawColor(hovered and Color(225, 225, 225) or Color(238, 238, 238))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(BORDER)
            surface.DrawOutlinedRect(0, 0, w, h, hovered and 2 or 1)
        end
        buyBtn.DoClick = function()
            if (MODULE and MODULE.SendPurchaseRequest) then
                surface.PlaySound("buttons/button14.wav")
                MODULE:SendPurchaseRequest(item.id)
            end
        end
    end

    self.itemsLayout:Layout()
end

function PANEL:ClosePanel()
    self:Remove()
end

function PANEL:OnRemove()
    if (MODULE) then
        MODULE._propCatalog = nil
    end
end

derma.DefineControl("bmrp.prop_catalog", "Prop placement catalogue", PANEL, "EditablePanel")