-- Shared funding API skeleton
local MODULE = MODULE

MODULE.funding = MODULE.funding or {}

-- Internal store (server-authoritative). Clients receive snapshots via net.
-- Extended to support a realistic dashboard: ordered allocations, reports,
-- grants, and time-series history for the trend graph.
MODULE.funding.data = MODULE.funding.data or {
    global = 100,
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
    history = { 100 },
    -- Legacy fields maintained for compatibility (not rendered directly)
    factions = {},   -- [factionID] = amount
    sub = {}         -- [factionID] = { [divisionID] = amount }
}

-- Accessors (shared-safe; on client this reflects last known snapshot)
function MODULE.funding:GetGlobal()
    return (self.data and self.data.global) or 0
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

-- Helpers to serialise a compact snapshot
function MODULE.funding:BuildSnapshot()
    return {
        global = self:GetGlobal(),
        allocations = self.data.allocations or {},
        reports = self.data.reports or { facility = {}, world = {} },
        grants = self.data.grants or {},
        history = self.data.history or {},
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
    -- legacy for compatibility
    self.data.factions = istable(snap.factions) and snap.factions or (self.data.factions or {})
    self.data.sub = istable(snap.sub) and snap.sub or (self.data.sub or {})
end
