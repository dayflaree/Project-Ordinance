-- Economy main panel (left status cards, right live graph)
local PANEL = {}

local ORANGE = Color(237, 110, 39)
local ORANGE_DARK = Color(220, 100, 30)
local ORANGE_TEXT = Color(20, 20, 20)
local BG_DARK = Color(18, 18, 18, 230)
local GREY = Color(200, 200, 200)

function PANEL:Init()
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)

    self:Dock(FILL)

    self.left = vgui.Create("EditablePanel", self)
    self.left:Dock(LEFT)
    self.left:SetWide(math.floor(ScrW() * 0.45))
    self.left:DockMargin(8, 8, 8, 8)

    self.right = vgui.Create("EditablePanel", self)
    self.right:Dock(FILL)
    self.right:DockMargin(0, 8, 8, 8)

    -- Build left stack
    self:BuildLeft()

    -- Build right (graph + reports)
    self:BuildRight()

    self:InvalidateLayout(true)
end

function PANEL:BuildLeft()
    -- Top: Global Funding header
    local header = vgui.Create("EditablePanel", self.left)
    header:Dock(TOP)
    header:SetTall(110)
    header:DockMargin(0, 0, 0, 8)
    header.Paint = function(s, w, h)
        surface.SetDrawColor(ORANGE)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText("Global Facility Budget", "DermaDefault", 12, 10, ORANGE_TEXT)
        draw.SimpleText(self:GetGlobalAmountText() or "$0", "ax.giant.bold", w/2, h/2, ORANGE_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if (self._lastUpdated) then
            draw.SimpleText("Updated " .. os.date("!%H:%M:%S", self._lastUpdated) .. " UTC", "DermaDefault", w-12, h-8, ORANGE_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        end
    end

    -- Scroll list for allocations
    local scroll = vgui.Create("DScrollPanel", self.left)
    scroll:Dock(FILL)
    scroll:DockMargin(0, 0, 0, 8)

    self.allocList = vgui.Create("EditablePanel", scroll)
    self.allocList:Dock(TOP)
    self.allocList:DockMargin(0, 0, 0, 8)
    self.allocList.PerformLayout = function(s, w, h)
        local y = 0
        for _, row in ipairs(s.rows or {}) do
            row:SetPos(0, y)
            row:SetSize(w, 46)
            y = y + 46 + 6
        end
        s:SetTall(y)
    end

    -- Grants strip
    local grants = vgui.Create("EditablePanel", self.left)
    grants:Dock(BOTTOM)
    grants:SetTall(170)
    grants:DockMargin(0, 8, 0, 0)
    grants.PerformLayout = function(s, w, h)
        local pad = 8
        local colW = math.floor((w - pad*2) / 3)
        if (s.cards) then
            for i = 1, 3 do
                local x = (i-1) * (colW + pad)
                if (i == 3) then x = (colW + pad)*2 end
                s.cards[i]:SetPos(x, 0)
                s.cards[i]:SetSize(colW, h)
            end
        end
    end

    self._header = header
    self._allocScroll = scroll
    self._grants = grants
end

function PANEL:BuildRight()
    -- Split right into top graph and bottom reports feed
    local top = vgui.Create("EditablePanel", self.right)
    top:Dock(TOP)
    top:SetTall(math.max(220, math.floor(ScrH() * 0.35)))
    top:DockMargin(0, 0, 0, 8)

    top.Paint = function(s, w, h)
        surface.SetDrawColor(BG_DARK)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(ORANGE_DARK)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        -- axes
        surface.DrawLine(40, h-30, w-10, h-30)
        surface.DrawLine(40, 10, 40, h-30)

        -- plot history
        local pts = self.history or {}
        if (#pts >= 2) then
            surface.SetDrawColor(255, 160, 90)
            local maxv, minv = -1e9, 1e9
            for _, v in ipairs(pts) do maxv = math.max(maxv, v) minv = math.min(minv, v) end
            local span = math.max(1, maxv - minv)
            local rw, rh = (w - 50), (h - 40)
            for i = 2, #pts do
                local x1 = 40 + rw * ((i-2) / math.max(1, (#pts-1)))
                local x2 = 40 + rw * ((i-1) / math.max(1, (#pts-1)))
                local y1 = (h-30) - rh * ((pts[i-1] - minv) / span)
                local y2 = (h-30) - rh * ((pts[i] - minv) / span)
                surface.DrawLine(x1, y1, x2, y2)
            end
        end

        draw.SimpleText("Funding Trend", "DermaDefault", 50, 12, color_white)
    end

    local bottom = vgui.Create("EditablePanel", self.right)
    bottom:Dock(FILL)
    bottom.Paint = function(s, w, h)
        surface.SetDrawColor(BG_DARK)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(ORANGE_DARK)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local inner = vgui.Create("DScrollPanel", bottom)
    inner:Dock(FILL)
    inner:DockMargin(8, 8, 8, 8)

    self.reportList = vgui.Create("EditablePanel", inner)
    self.reportList:Dock(TOP)
    self.reportList.PerformLayout = function(s, w, h)
        local y = 0
        for _, row in ipairs(s.rows or {}) do
            row:SetPos(0, y)
            row:SetSize(w, 64)
            y = y + 64 + 6
        end
        s:SetTall(y)
    end

    self.graph = top
    self.reportsPanel = bottom
end

function PANEL:GetGlobalAmountText()
    if (self._globalAmount ~= nil) then
        return string.format("$%s", string.Comma(math.floor(self._globalAmount)))
    end
    return "$100"
end

function PANEL:SetGlobalAmount(num)
    self._globalAmount = tonumber(num) or 0
end

function PANEL:Think() end

-- Data setters from networking snapshot
function PANEL:SetData(snap)
    if (not istable(snap)) then return end
    self:SetGlobalAmount(tonumber(snap.global) or 0)
    self._lastUpdated = os.time()
    self.history = snap.history or self.history or { self._globalAmount or 0 }
    self:RefreshAllocations(snap.allocations or {})
    self:RefreshReports(snap.reports or { facility = {}, world = {} })
    self:RefreshGrants(snap.grants or {})
end

function PANEL:RefreshAllocations(list)
    local parent = self.allocList
    parent.rows = parent.rows or {}
    for _, pnl in ipairs(parent.rows) do if IsValid(pnl) then pnl:Remove() end end
    parent.rows = {}

    local total = math.max(1, tonumber(self._globalAmount or 0))

    local function makeRow(row)
        local p = vgui.Create("EditablePanel", parent)
        p.Paint = function(s, w, h)
            surface.SetDrawColor(35, 35, 35, 230)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(60, 60, 60, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            draw.SimpleText(row.label or row.id, "DermaDefaultBold", 12, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local amt = tonumber(row.amount) or 0
            draw.SimpleText("$" .. string.Comma(math.floor(amt)), "DermaDefaultBold", w-12, h/2, GREY, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

            local share = math.Clamp(amt / total, 0, 1)
            surface.SetDrawColor(ORANGE)
            surface.DrawRect(12, h-8, (w-24) * share, 4)
        end
        return p
    end

    for _, row in ipairs(list) do
        local p = makeRow(row)
        table.insert(parent.rows, p)
    end

    parent:InvalidateLayout(true)
end

function PANEL:RefreshReports(reports)
    local parent = self.reportList
    for _, pnl in ipairs(parent.rows or {}) do if IsValid(pnl) then pnl:Remove() end end
    parent.rows = {}

    local all = {}
    if (reports.facility) then for _, r in ipairs(reports.facility) do r._kind = "Facility" table.insert(all, r) end end
    if (reports.world) then for _, r in ipairs(reports.world) do r._kind = "World" table.insert(all, r) end end

    table.sort(all, function(a, b) return (a.date or 0) > (b.date or 0) end)

    local function badgeColor(sev)
        if (sev == "warning") then return Color(255, 190, 32) end
        if (sev == "danger") then return Color(220, 70, 70) end
        return ORANGE
    end

    for _, r in ipairs(all) do
        local p = vgui.Create("EditablePanel", parent)
        p.Paint = function(s, w, h)
            surface.SetDrawColor(30, 30, 30, 230)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(50, 50, 50, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText((r._kind or "Report") .. " • " .. os.date("%Y-%m-%d %H:%M", r.date or os.time()), "DermaDefault", 12, 8, GREY)
            draw.SimpleText(r.title or "Untitled", "DermaDefaultBold", 12, 26, color_white)
            draw.SimpleText(r.body or "", "DermaDefault", 12, 44, GREY)
            surface.SetDrawColor(badgeColor(r.severity))
            surface.DrawRect(w-80, 8, 68, 18)
            draw.SimpleText(string.upper(r.severity or "info"), "DermaDefault", w-46, 17, ORANGE_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        table.insert(parent.rows, p)
    end

    parent:InvalidateLayout(true)
end

function PANEL:RefreshGrants(grants)
    local holder = self._grants
    holder.cards = holder.cards or { vgui.Create("EditablePanel", holder), vgui.Create("EditablePanel", holder), vgui.Create("EditablePanel", holder) }

    local function paintCard(panel, grant)
        panel.Paint = function(s, w, h)
            surface.SetDrawColor(ORANGE)
            surface.DrawRect(0, 0, w, h)
            if (grant) then
                draw.SimpleText(grant.title or "Grant", "DermaDefaultBold", 12, 10, ORANGE_TEXT)
                local reward = tonumber(grant.amount or 0) or 0
                draw.SimpleText("Reward: $" .. string.Comma(math.floor(reward)), "DermaDefault", 12, 30, ORANGE_TEXT)
                if (grant.deadline) then
                    local remain = math.max(0, grant.deadline - os.time())
                    draw.SimpleText("Deadline: " .. os.date("%Y-%m-%d", grant.deadline) .. " (" .. string.NiceTime(remain) .. ")", "DermaDefault", 12, 46, ORANGE_TEXT)
                end
                draw.SimpleText(grant.objective or "Complete objectives to redeem.", "DermaDefault", 12, 62, ORANGE_TEXT)
                local state = grant.claimed and "CLAIMED" or (grant.completed and "READY" or "ACTIVE")
                draw.SimpleText(state, "DermaDefaultBold", w-12, h-12, ORANGE_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            else
                draw.SimpleText("No Grant", "DermaDefault", 12, 10, ORANGE_TEXT)
            end
        end
    end

    for i = 1, 3 do
        paintCard(holder.cards[i], grants[i])
    end

    holder:InvalidateLayout(true)
end

-- Main menu panel helpers expected by Parallax main view wrappers
function PANEL:SlideToFront()
    self:SetVisible(true)
    self:MakePopup()
end

function PANEL:SlideDown()
    self:SetVisible(false)
end

function PANEL:StartAtBottom()
    self:SetVisible(false)
end

vgui.Register("bmrp.economy", PANEL, "EditablePanel")
