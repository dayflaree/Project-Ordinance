-- Shared funding API skeleton
local MODULE = MODULE

MODULE.funding = MODULE.funding or {}
MODULE.funding.schemaVersion = 1

-- Internal store (server-authoritative). Clients receive snapshots via net.
-- Extended to support a realistic dashboard: ordered allocations, reports,
-- grants, and time-series history for the trend graph.
local START_FALLBACK = 275000000
MODULE.funding.data = MODULE.funding.data or {
    global = ax.config:Get("funding.start_global", START_FALLBACK),
    -- Ordered allocations shown in the UI. We keep stable string IDs so we
    -- don't depend on runtime numeric enum values.
    -- id: unique stable key, label: human name, amount: current funds
    allocations = {
        { id = "admin",     label = "Administrative Budget",   amount = 0 },
        { id = "logistics", label = "Logistics Operations",    amount = 0 },
        { id = "security",  label = "Security Division",       amount = 0 },
        { id = "rnd",       label = "Research & Development", amount = 0 },
        { id = "survey",    label = "Survey Team",            amount = 0 },
        { id = "bio",       label = "Biological Sciences",    amount = 0 },
        { id = "service",   label = "Service Department",      amount = 0 },
    },
    -- Intelligence feed
    reports = {
        facility = {}, -- { {title, body, date, severity} }
        world = {}     -- ^ same
    },
    -- Up to 3 active grants
    grants = {
        -- { id, title, objective, amount, deadline, progress, completed, claimed }
    },
    -- Time-series values for right-side trend (latest last)
    history = { ax.config:Get("funding.start_global", START_FALLBACK) },
    -- Per-allocation time-series (id -> {values})
    allocationHistory = {},
    -- Structured event feed (audit trail)
    events = {}, -- { {type, title, body, ts, meta={}} }
    -- Alert rule placeholders (to be evaluated server-side later)
    alertRules = { -- simple shape: { id -> { threshold, severity } }
        -- e.g., security_low = { target = "security", lt = 10, severity = "warning" }
    },
    -- Forecast placeholders (read-only projections)
    forecast = {
        global = {},       -- array of numbers (future points)
        allocations = {}   -- id -> { future points }
    },
    -- Action shells (permission-checked operations; no logic yet)
    actions = {
        -- { id = "request_transfer", label = "Request Transfer", roles = {"ADMIN"}, enabled = false }
    },
    -- Legacy fields maintained for compatibility (not rendered directly)
    factions = {},   -- [factionID] = amount
    sub = {}         -- [factionID] = { [divisionID] = amount }
}

-- Deterministic operations cost model (non-payroll)
-- Monthly costs in USD and time scaling to real seconds
MODULE.funding.ops = MODULE.funding.ops or {
    monthlyUSDByCategory = {
        utilities = 62000000,       -- power, HVAC, water
        infrastructure = 34000000,  -- maintenance, repairs
        medical_ops = 18000000,     -- medbay, supplies
        supplies_logistics = 26000000,
        security_ops = 22000000,    -- non-payroll
        rnd_ops = 38000000,         -- consumables, runtime
        compliance_safety = 8000000,
    },
    monthSeconds = 432000,         -- lore scale: 1 month = 5 real days
    tickSeconds = 5                -- must match server timer interval
}

function MODULE.funding:GetMonthlyOpsTotal()
    local t = 0
    local m = self.ops and self.ops.monthlyUSDByCategory or {}
    for _, v in pairs(m) do t = t + (tonumber(v) or 0) end
    return t
end

function MODULE.funding:ComputeOpsTickCost()
    -- Deprecated: left for compatibility with old hooks
    local monthly = self:GetMonthlyOpsTotal()
    local monthSec = (self.ops and self.ops.monthSeconds) or 3600
    local tickSec = (self.ops and self.ops.tickSeconds) or 5
    if monthSec <= 0 or tickSec <= 0 then return 0 end
    local perSecond = monthly / monthSec
    return perSecond * tickSec
end

-- Accessors (shared-safe; on client this reflects last known snapshot)
function MODULE.funding:GetGlobal()
    return (self.data and self.data.global) or 0
end

-- Ensure structure + seed visible defaults (server only)
function MODULE.funding:EnsureStructureWithDefaults()
    self.data = self.data or {}
    if (SERVER) then
        local configured = ax.config:Get("funding.start_global", START_FALLBACK)
        if (not self.data.global or self.data.global <= 100) then
            self.data.global = configured
        end
    end
    -- allocations in required order and labels
    self.data.allocations = {
        { id = "admin",     label = "Administrative Funding",   amount = self:GetAllocationAmount("admin") },
        { id = "logistics", label = "Logistics Funding",        amount = self:GetAllocationAmount("logistics") },
        { id = "security",  label = "Security Division",        amount = self:GetAllocationAmount("security") },
        { id = "rnd",       label = "Research & Development",   amount = self:GetAllocationAmount("rnd") },
        { id = "survey",    label = "Survey Team",              amount = self:GetAllocationAmount("survey") },
        { id = "bio",       label = "Biological Sciences",      amount = self:GetAllocationAmount("bio") },
        { id = "service",   label = "Service Department",       amount = self:GetAllocationAmount("service") },
    }

    -- If everything is zero, seed simple visible amounts relative to global
    local allZero = true
    for _, r in ipairs(self.data.allocations) do if (tonumber(r.amount) or 0) > 0 then allZero = false break end end
    local g = tonumber(self.data.global or ax.config:Get("funding.start_global", START_FALLBACK)) or START_FALLBACK
    if allZero then
        local seed = {
            admin = math.floor(g * 0.28),
            logistics = math.floor(g * 0.14),
            security = math.floor(g * 0.18),
            rnd = math.floor(g * 0.24),
            survey = math.floor(g * 0.07),
            bio = math.floor(g * 0.06),
            service = math.max(0, g - (math.floor(g * 0.28)+math.floor(g*0.14)+math.floor(g*0.18)+math.floor(g*0.24)+math.floor(g*0.07)+math.floor(g*0.06)))
        }
        for _, r in ipairs(self.data.allocations) do r.amount = seed[r.id] or 0 end
    end

    -- Reports buckets
    self.data.reports = self.data.reports or { facility = {}, world = {} }
    -- Seed example report entries if empty for visibility
    if (#self.data.reports.facility == 0 and #self.data.reports.world == 0) then
        table.insert(self.data.reports.facility, 1, { title = "Quarterly Budget Rollup", body = "Administration posted the latest budget distribution across sectors.", date = os.time(), severity = "info" })
        table.insert(self.data.reports.world, 1, { title = "Federal Appropriations Bill", body = "Appropriations committee advanced funding bill; R&D incentives likely.", date = os.time(), severity = "warning" })
    end

    -- Grants list (max 3)
    self.data.grants = self.data.grants or {}
    if (#self.data.grants == 0) then
        self.data.grants = {
            { id = "g1", title = "DOE Safety Compliance Grant", objective = "Pass facility-wide safety audit.", amount = 25, deadline = os.time() + 7*24*3600, progress = 0.2, completed = false, claimed = false },
            { id = "g2", title = "NNSA Containment Upgrade", objective = "Install and certify new containment seals in R&D labs.", amount = 40, deadline = os.time() + 12*24*3600, progress = 0.0, completed = false, claimed = false },
        }
    end

    -- History points for trend
    self.data.history = self.data.history or { self:GetGlobal() }
    if (#self.data.history < 2) then
        table.insert(self.data.history, self:GetGlobal())
    end

    -- Per-allocation history containers
    self.data.allocationHistory = self.data.allocationHistory or {}
    for _, r in ipairs(self.data.allocations or {}) do
        self.data.allocationHistory[r.id] = self.data.allocationHistory[r.id] or { tonumber(r.amount) or 0 }
        if (#self.data.allocationHistory[r.id] < 2) then
            table.insert(self.data.allocationHistory[r.id], tonumber(r.amount) or 0)
        end
    end

    -- Ensure containers for scaffolding fields
    self.data.events = self.data.events or {}
    self.data.alertRules = self.data.alertRules or {}
    self.data.forecast = self.data.forecast or { global = {}, allocations = {} }
    self.data.actions = self.data.actions or {}
end

function MODULE.funding:SetGlobal(amount)
    self.data = self.data or {}
    self.data.global = tonumber(amount) or 0
end

function MODULE.funding:GetFaction(fid)
    self.data = self.data or {}
    local f = self.data.factions or {}
    return f[fid] or 0
end

function MODULE.funding:SetFaction(fid, amount)
    self.data = self.data or {}
    self.data.factions = self.data.factions or {}
    self.data.factions[fid] = tonumber(amount) or 0
end

function MODULE.funding:GetSubFaction(fid, did)
    self.data = self.data or {}
    local sub = self.data.sub or {}
    local map = sub[fid] or {}
    return map[did] or 0
end

function MODULE.funding:SetSubFaction(fid, did, amount)
    self.data = self.data or {}
    self.data.sub = self.data.sub or {}
    self.data.sub[fid] = self.data.sub[fid] or {}
    self.data.sub[fid][did] = tonumber(amount) or 0
end

-- Allocation helpers
function MODULE.funding:FindAllocation(id)
    self.data = self.data or {}
    local list = self.data.allocations or {}
    for i, row in ipairs(list) do
        if (row.id == id) then return row, i end
    end
end

function MODULE.funding:GetAllocationAmount(id)
    local row = self:FindAllocation(id)
    return row and (tonumber(row.amount) or 0) or 0
end

function MODULE.funding:SetAllocationAmount(id, amount)
    self.data = self.data or {}
    self.data.allocations = self.data.allocations or {}
    local row = self:FindAllocation(id)
    if (row) then
        row.amount = tonumber(amount) or 0
    else
        table.insert(self.data.allocations, { id = id, label = id, amount = tonumber(amount) or 0 })
    end
end

-- Reports helpers
function MODULE.funding:AddReport(kind, title, body, severity)
    self.data = self.data or {}
    self.data.reports = self.data.reports or { facility = {}, world = {} }
    local bucket = (kind == "world") and self.data.reports.world or self.data.reports.facility
    table.insert(bucket, 1, { title = title, body = body, date = os.time(), severity = severity or "info" })
end

-- Grants helpers
function MODULE.funding:SetGrants(list)
    -- list is array of grant objects (max 3)
    self.data = self.data or {}
    self.data.grants = {}
    for i = 1, math.min(3, #list) do
        self.data.grants[i] = list[i]
    end
end

function MODULE.funding:PushHistoryPoint(value)
    self.data = self.data or {}
    self.data.history = self.data.history or {}
    table.insert(self.data.history, tonumber(value) or 0)
    if (#self.data.history > 240) then -- cap ~24s at 10hz
        table.remove(self.data.history, 1)
    end
end

-- Push one point for each allocation into per-allocation histories
function MODULE.funding:PushAllocationHistoryPoints()
    self:EnsureStructureWithDefaults()
    local maxLen = 240
    for _, r in ipairs(self.data.allocations or {}) do
        local id = r.id
        self.data.allocationHistory[id] = self.data.allocationHistory[id] or {}
        table.insert(self.data.allocationHistory[id], tonumber(r.amount) or 0)
        if (#self.data.allocationHistory[id] > maxLen) then
            table.remove(self.data.allocationHistory[id], 1)
        end
    end
end

-- Helpers to serialise a compact snapshot
function MODULE.funding:BuildSnapshot()
    if (SERVER) then
        -- Ensure structure before sending to clients
        self:EnsureStructureWithDefaults()
    end
    return {
        schemaVersion = self.schemaVersion,
        global = self:GetGlobal(),
        allocations = self.data.allocations or {},
        reports = self.data.reports or { facility = {}, world = {} },
        grants = self.data.grants or {},
        history = self.data.history or {},
        allocationHistory = self.data.allocationHistory or {},
        events = self.data.events or {},
        alertRules = self.data.alertRules or {},
        forecast = self.data.forecast or { global = {}, allocations = {} },
        actions = self.data.actions or {},
        factions = self.data.factions or {},
        sub = self.data.sub or {}
    }
end

function MODULE.funding:ApplySnapshot(snap)
    if not istable(snap) then return end
    self.data = self.data or {}
    self.data.global = tonumber(snap.global) or self.data.global or 0
    self.data.allocations = istable(snap.allocations) and snap.allocations or (self.data.allocations or {})
    self.data.reports = istable(snap.reports) and snap.reports or (self.data.reports or { facility = {}, world = {} })
    self.data.grants = istable(snap.grants) and snap.grants or (self.data.grants or {})
    self.data.history = istable(snap.history) and snap.history or (self.data.history or {})
    self.data.allocationHistory = istable(snap.allocationHistory) and snap.allocationHistory or (self.data.allocationHistory or {})
    self.data.events = istable(snap.events) and snap.events or (self.data.events or {})
    self.data.alertRules = istable(snap.alertRules) and snap.alertRules or (self.data.alertRules or {})
    self.data.forecast = istable(snap.forecast) and snap.forecast or (self.data.forecast or { global = {}, allocations = {} })
    self.data.actions = istable(snap.actions) and snap.actions or (self.data.actions or {})
    -- legacy for compatibility
    self.data.factions = istable(snap.factions) and snap.factions or (self.data.factions or {})
    self.data.sub = istable(snap.sub) and snap.sub or (self.data.sub or {})
end

-- Event feed helpers (scaffolding)
function MODULE.funding:AddEvent(evType, title, body, meta)
    self:EnsureStructureWithDefaults()
    local e = { type = evType or "info", title = title or "", body = body or "", ts = os.time(), meta = meta or {} }
    table.insert(self.data.events, 1, e)
    -- cap feed size
    if (#self.data.events > 200) then table.remove(self.data.events) end
    return e
end

-- Alert framework scaffolding (no real evaluation yet)
function MODULE.funding:SetAlertRules(rules)
    self:EnsureStructureWithDefaults()
    if istable(rules) then self.data.alertRules = rules end
end

-- Forecast scaffolding
function MODULE.funding:SetForecast(forecast)
    self:EnsureStructureWithDefaults()
    if istable(forecast) then self.data.forecast = forecast end
end

-- Actions scaffolding
function MODULE.funding:SetActions(list)
    self:EnsureStructureWithDefaults()
    if istable(list) then self.data.actions = list end
end
