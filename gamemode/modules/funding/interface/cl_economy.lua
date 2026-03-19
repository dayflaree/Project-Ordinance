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

    -- KPI row (3 tiles): Budget, Active Grants, Alerts
    local kpiRow = vgui.Create("EditablePanel", self.left)
    kpiRow:Dock(TOP)
    kpiRow:SetTall(72)
    kpiRow:DockMargin(0, 0, 0, 8)
    kpiRow.PerformLayout = function(s, w, h)
        local pad = 8
        local colW = math.floor((w - pad * 2) / 3)
        if (s.tiles) then
            for i = 1, 3 do
                local x = (i-1) * (colW + pad)
                s.tiles[i]:SetPos(x, 0)
                s.tiles[i]:SetSize(colW, h)
            end
        end
    end
    kpiRow.tiles = {}
    local function makeTile(label, getter)
        local p = vgui.Create("EditablePanel", kpiRow)
        p.Paint = function(s, w, h)
            surface.SetDrawColor(30, 30, 30, 235)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(60, 60, 60, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(label, "DermaDefault", 10, 10, GREY)
            local val = getter and getter(self) or "—"
            draw.SimpleText(val, "DermaLarge", 10, h-12, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        end
        return p
    end
    kpiRow.tiles[1] = makeTile("Budget", function(s) return s:GetGlobalAmountText() end)
    kpiRow.tiles[2] = makeTile("Active Grants", function(s) return tostring(s._kpi_grants or 0) end)
    kpiRow.tiles[3] = makeTile("Alerts", function(s) return tostring(s._kpi_alerts or 0) end)

    -- Section header for faction funding
    local allocHeader = vgui.Create("EditablePanel", self.left)
    allocHeader:Dock(TOP)
    allocHeader:SetTall(24)
    allocHeader:DockMargin(0, 0, 0, 4)
    allocHeader.Paint = function(s, w, h)
        draw.SimpleText("Faction Funding", "DermaDefaultBold", 2, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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
    self._kpi = kpiRow
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

        -- decide which history to show (hovered allocation or global)
        local hoverID = self._hoverAlloc
        local pts
        if (hoverID and self.historyByAllocation and istable(self.historyByAllocation[hoverID]) and #self.historyByAllocation[hoverID] >= 2) then
            pts = self.historyByAllocation[hoverID]
        else
            pts = self.historyGlobal or self.history or {}
        end

        -- plot history
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

        local title = "Funding Trend"
        if (hoverID and self._allocLabels and self._allocLabels[hoverID]) then
            title = title .. " — " .. (self._allocLabels[hoverID] or hoverID)
        else
            title = title .. " — Global"
        end
        draw.SimpleText(title, "DermaDefault", 50, 12, color_white)
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

    -- Facility section header
    local facHeader = vgui.Create("EditablePanel", inner)
    facHeader:Dock(TOP)
    facHeader:SetTall(22)
    facHeader:DockMargin(0, 0, 0, 4)
    facHeader.Paint = function(s, w, h)
        draw.SimpleText("Facility Reports", "DermaDefaultBold", 0, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.facilityList = vgui.Create("EditablePanel", inner)
    self.facilityList:Dock(TOP)
    self.facilityList:DockMargin(0, 0, 0, 10)
    self.facilityList.PerformLayout = function(s, w, h)
        local y = 0
        for _, row in ipairs(s.rows or {}) do
            row:SetPos(0, y)
            row:SetSize(w, 64)
            y = y + 64 + 6
        end
        s:SetTall(math.max(24, y))
    end

    -- World section header
    local worldHeader = vgui.Create("EditablePanel", inner)
    worldHeader:Dock(TOP)
    worldHeader:SetTall(22)
    worldHeader:DockMargin(0, 4, 0, 4)
    worldHeader.Paint = function(s, w, h)
        draw.SimpleText("World Report", "DermaDefaultBold", 0, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.worldList = vgui.Create("EditablePanel", inner)
    self.worldList:Dock(TOP)
    self.worldList.PerformLayout = function(s, w, h)
        local y = 0
        for _, row in ipairs(s.rows or {}) do
            row:SetPos(0, y)
            row:SetSize(w, 64)
            y = y + 64 + 6
        end
        s:SetTall(math.max(24, y))
    end

    -- Events (audit) header
    local evtHeader = vgui.Create("EditablePanel", inner)
    evtHeader:Dock(TOP)
    evtHeader:SetTall(22)
    evtHeader:DockMargin(0, 4, 0, 4)
    evtHeader.Paint = function(s, w, h)
        draw.SimpleText("Audit Events", "DermaDefaultBold", 0, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.eventsList = vgui.Create("EditablePanel", inner)
    self.eventsList:Dock(TOP)
    self.eventsList.PerformLayout = function(s, w, h)
        local y = 0
        for _, row in ipairs(s.rows or {}) do
            row:SetPos(0, y)
            row:SetSize(w, 48)
            y = y + 48 + 4
        end
        s:SetTall(math.max(24, y))
    end

    -- Actions header
    local actHeader = vgui.Create("EditablePanel", inner)
    actHeader:Dock(TOP)
    actHeader:SetTall(22)
    actHeader:DockMargin(0, 4, 0, 4)
    actHeader.Paint = function(s, w, h)
        draw.SimpleText("Actions", "DermaDefaultBold", 0, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.actionsList = vgui.Create("EditablePanel", inner)
    self.actionsList:Dock(TOP)
    self.actionsList.PerformLayout = function(s, w, h)
        local y = 0
        for _, row in ipairs(s.rows or {}) do
            row:SetPos(0, y)
            row:SetSize(w, 36)
            y = y + 36 + 4
        end
        s:SetTall(math.max(24, y))
    end

    self.graph = top
    self.reportsPanel = bottom
end

function PANEL:GetGlobalAmountText()
    if (self._globalAmount ~= nil) then
        return string.format("$%s", string.Comma(math.floor(self._globalAmount)))
    end
    return "$0"
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
    -- store histories: global + per-allocation for hover graphing
    self.historyGlobal = snap.history or self.historyGlobal or { self._globalAmount or 0 }
    self.historyByAllocation = snap.allocationHistory or self.historyByAllocation or {}
    self:RefreshAllocations(snap.allocations or {})
    self:RefreshEvents(snap.events or {})
    self:RefreshActions(snap.actions or {})
    local reports = snap.reports or { facility = {}, world = {} }
    self:RefreshReports(reports)
    local grants = snap.grants or {}
    self:RefreshGrants(grants)
    -- Update KPI counters
    self._kpi_grants = 0
    for i = 1, #grants do if not grants[i].claimed then self._kpi_grants = self._kpi_grants + 1 end end
    local alerts = 0
    local function countAlerts(list)
        for _, r in ipairs(list or {}) do
            if (r.severity == "warning" or r.severity == "danger") then alerts = alerts + 1 end
        end
    end
    countAlerts(reports.facility)
    countAlerts(reports.world)
    self._kpi_alerts = alerts
    if (IsValid(self._kpi)) then self._kpi:InvalidateLayout(true) end
end

function PANEL:RefreshAllocations(list)
    local parent = self.allocList
    parent.rows = parent.rows or {}
    for _, pnl in ipairs(parent.rows) do if IsValid(pnl) then pnl:Remove() end end
    parent.rows = {}
    self._allocLabels = {}

    local total = math.max(1, tonumber(self._globalAmount or 0))

    local function makeRow(row)
        local p = vgui.Create("EditablePanel", parent)
        p._allocID = row.id
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
        -- hover behavior: set current hovered allocation for the graph
        p.OnCursorEntered = function()
            self._hoverAlloc = p._allocID
            if (IsValid(self.graph)) then self.graph:InvalidateLayout(true) end
        end
        p.OnCursorExited = function()
            if (self._hoverAlloc == p._allocID) then
                self._hoverAlloc = nil
                if (IsValid(self.graph)) then self.graph:InvalidateLayout(true) end
            end
        end
        return p
    end

    for _, row in ipairs(list) do
        if (row.id) then self._allocLabels[row.id] = row.label or row.id end
        local p = makeRow(row)
        table.insert(parent.rows, p)
    end

    if (#parent.rows == 0) then
        local empty = vgui.Create("EditablePanel", parent)
        empty.Paint = function(s, w, h)
            surface.SetDrawColor(30, 30, 30, 230)
            surface.DrawRect(0, 0, w, 46)
            surface.SetDrawColor(50, 50, 50, 255)
            surface.DrawOutlinedRect(0, 0, w, 46, 1)
            draw.SimpleText("No allocations received yet", "DermaDefault", 12, 23, GREY, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        table.insert(parent.rows, empty)
    end

    parent:InvalidateLayout(true)
end

function PANEL:RefreshReports(reports)
    reports = reports or { facility = {}, world = {} }

    local function badgeColor(sev)
        if (sev == "warning") then return Color(255, 190, 32) end
        if (sev == "danger") then return Color(220, 70, 70) end
        return ORANGE
    end

    local function makeRows(parent, list, kindLabel)
        for _, pnl in ipairs(parent.rows or {}) do if IsValid(pnl) then pnl:Remove() end end
        parent.rows = {}
        if (not list or #list == 0) then
            local empty = vgui.Create("EditablePanel", parent)
            empty.Paint = function(s, w, h)
                draw.SimpleText("No " .. string.lower(kindLabel) .. " available", "DermaDefault", 6, 6, GREY)
            end
            table.insert(parent.rows, empty)
            parent:InvalidateLayout(true)
            return
        end

        table.sort(list, function(a, b) return (a.date or 0) > (b.date or 0) end)
        for _, r in ipairs(list) do
            local p = vgui.Create("EditablePanel", parent)
            p.Paint = function(s, w, h)
                surface.SetDrawColor(30, 30, 30, 230)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(50, 50, 50, 255)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText(kindLabel .. " • " .. os.date("%Y-%m-%d %H:%M", r.date or os.time()), "DermaDefault", 12, 8, GREY)
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

    makeRows(self.facilityList, reports.facility or {}, "Facility")
    makeRows(self.worldList, reports.world or {}, "World")
end

function PANEL:RefreshEvents(events)
    local parent = self.eventsList
    if (not IsValid(parent)) then return end
    for _, pnl in ipairs(parent.rows or {}) do if IsValid(pnl) then pnl:Remove() end end
    parent.rows = {}

    if (not events or #events == 0) then
        local empty = vgui.Create("EditablePanel", parent)
        empty.Paint = function(s, w, h)
            draw.SimpleText("No events yet", "DermaDefault", 6, 6, GREY)
        end
        table.insert(parent.rows, empty)
        parent:InvalidateLayout(true)
        return
    end

    for _, e in ipairs(events) do
        local p = vgui.Create("EditablePanel", parent)
        p.Paint = function(s, w, h)
            surface.SetDrawColor(30, 30, 30, 230)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(50, 50, 50, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            local ts = os.date("%Y-%m-%d %H:%M", e.ts or os.time())
            draw.SimpleText(string.upper(e.type or "INFO") .. " • " .. ts, "DermaDefault", 12, 6, GREY)
            draw.SimpleText(e.title or "", "DermaDefaultBold", 12, 24, color_white)
        end
        table.insert(parent.rows, p)
    end
    parent:InvalidateLayout(true)
end

function PANEL:RefreshActions(actions)
    local parent = self.actionsList
    if (not IsValid(parent)) then return end
    for _, pnl in ipairs(parent.rows or {}) do if IsValid(pnl) then pnl:Remove() end end
    parent.rows = {}

    if (not actions or #actions == 0) then
        local empty = vgui.Create("EditablePanel", parent)
        empty.Paint = function(s, w, h)
            draw.SimpleText("No actions available", "DermaDefault", 6, 6, GREY)
        end
        table.insert(parent.rows, empty)
        parent:InvalidateLayout(true)
        return
    end

    for _, a in ipairs(actions) do
        local p = vgui.Create("EditablePanel", parent)
        p.Paint = function(s, w, h)
            surface.SetDrawColor(35, 35, 35, 230)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(60, 60, 60, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            local label = a.label or a.id or "Action"
            local state = (a.enabled == true) and "ENABLED" or "DISABLED"
            draw.SimpleText(label .. " (" .. state .. ")", "DermaDefault", 12, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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
