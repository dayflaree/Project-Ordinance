local POWER_OUTAGE_SEARCH_RADIUS = 1024
local POWER_OUTAGE_SEARCH_RADIUS_SQR = POWER_OUTAGE_SEARCH_RADIUS * POWER_OUTAGE_SEARCH_RADIUS

local POWER_OUTAGE_SECTOR_KEYS = {
    "anomalous_materials",
    "logistics_facilities",
    "dorms",
    "security_facilities"
}

local sectorNameCache = setmetatable({}, {__mode = "k"})

local function ResolvePowerSectorName(ent)
    local cached = sectorNameCache[ent]
    if ( cached != nil ) then
        return cached != false and cached or nil
    end

    local rawName = ent:GetNWString("BMRF_Name", "")

    if ( !isstring(rawName) or rawName == "" ) then
        sectorNameCache[ent] = false
        return nil
    end

    local lowered = string.lower(rawName)
    for i = 1, #POWER_OUTAGE_SECTOR_KEYS do
        local sector = POWER_OUTAGE_SECTOR_KEYS[i]
        if ( string.find(lowered, sector, 1, true) ) then
            sectorNameCache[ent] = sector
            return sector
        end
    end

    sectorNameCache[ent] = false
    return nil
end

function SCHEMA:HasNearbyPowerOutage(pos)
    if ( !isvector(pos) ) then return false, nil end

    local nearby = ents.FindInSphere(pos, POWER_OUTAGE_SEARCH_RADIUS)
    local closestOutageSector
    local closestOutageDistSqr = math.huge
    local closestSector
    local closestSectorDistSqr = math.huge

    for i = 1, #nearby do
        local ent = nearby[i]
        if ( !IsValid(ent) or ent:GetClass() != "prop_dynamic" ) then continue end

        local distSqr = pos:DistToSqr(ent:GetPos())
        if ( distSqr > POWER_OUTAGE_SEARCH_RADIUS_SQR ) then continue end

        local sector = ResolvePowerSectorName(ent)
        if ( !sector ) then continue end

        if ( distSqr < closestSectorDistSqr ) then
            closestSectorDistSqr = distSqr
            closestSector = sector
        end

        if ( !GetGlobalBool("BMRF_PowerOn_" .. sector, true) and distSqr < closestOutageDistSqr ) then
            closestOutageDistSqr = distSqr
            closestOutageSector = sector
        end
    end

    if ( closestOutageSector ) then
        return true, closestOutageSector
    end

    return false, closestSector
end
