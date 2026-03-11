-- Track power state per sector based on light_prop_* entities
-- Power is ON by default, and goes OFF if more than 50% of lights are disabled

local knownSectors = {}

-- Light prop skin definitions: which skin value means the light is ON
-- Key = light prop type (extracted from name), Value = skin value when ON
local lightPropSkinConfig = {
    ["sconce03"] = 1, -- Normal: Skin 1 = ON, Skin 0 = OFF
    ["ceiling01b"] = 0, -- Inverted: Skin 0 = ON, Skin 1 = OFF
    ["strip01b"] = 1, -- Normal: Skin 1 = ON, Skin 0 = OFF
    ["strip03"] = 1, -- Normal: Skin 1 = ON, Skin 0 = OFF
    ["lowbay01"] = 1, -- Normal: Skin 1 = ON, Skin 0 = OFF
    ["lowprofile01"] = 1, -- Normal: Skin 1 = ON, Skin 0 = OFF
    ["wall04"] = 1, -- Normal: Skin 1 = ON, Skin 0 = OFF
    ["lab"] = 0, -- Inverted: Skin 0 = ON, Skin 1 = OFF
}

local defaultLightOnSkin = 1 -- Default: Skin 1 = ON for unknown light types

local function GetLightTypeFromName(lightName)
    if ( !isstring(lightName) or lightName == "" ) then return nil end

    -- Extract light type from name like "light_prop_sconce03-sector" or "light_prop_strip01b"
    local lightType = lightName:match("light_prop_([^%-]+)")
    return lightType
end

local function IsLightOn(entity, lightType)
    if ( !IsValid(entity) ) then return false end

    local currentSkin = entity:GetSkin()
    local onSkin = lightPropSkinConfig[lightType] or defaultLightOnSkin

    return currentSkin == onSkin
end

local function GetLightSectorFromName(lightName)
    if ( !isstring(lightName) or lightName == "" ) then return nil end

    local sectorDelimiterIndex = lightName:find("-", 1, true)
    if ( !sectorDelimiterIndex ) then return nil end

    local sectorName = lightName:sub(sectorDelimiterIndex + 1)
    if ( sectorName == "" ) then return nil end

    return sectorName
end

local nextTracker = 0
hook.Add("Think", "BMRF.Power.Tracker", function()
    if ( CurTime() < nextTracker ) then return end
    nextTracker = CurTime() + 0.5

    if ( CLIENT ) then return end

    local lightProps = ents.FindByName("light_prop_*")
    local sectorStats = {}

    for k, v in ipairs(lightProps) do
        if ( !IsValid(v) ) then continue end

        local lightName = v:GetName()
        local lightType = GetLightTypeFromName(lightName)
        local sectorName = GetLightSectorFromName(lightName)

        v:SetNWString("BMRF_LightName", lightName)

        if ( !sectorName ) then continue end

        v:SetNWString("BMRF_LightSector", sectorName)

        if ( !sectorStats[sectorName] ) then
            sectorStats[sectorName] = {
                totalProps = 0,
                offProps = 0,
            }
        end

        sectorStats[sectorName].totalProps = sectorStats[sectorName].totalProps + 1

        -- Check if light is OFF using the proper skin configuration
        if ( !IsLightOn(v, lightType) ) then
            sectorStats[sectorName].offProps = sectorStats[sectorName].offProps + 1
        end
    end

    local bAnySectorPowerOff = false
    local activeSectors = {}

    for sectorName, stats in pairs(sectorStats) do
        activeSectors[sectorName] = true

        -- Power is OFF if more than 50% of lights are disabled
        local bPowerOn = true
        if ( stats.totalProps > 0 ) then
            bPowerOn = (stats.offProps / stats.totalProps) < 0.5
        end

        SetGlobalBool("BMRF_PowerOn_" .. sectorName, bPowerOn)

        if ( !bPowerOn ) then
            bAnySectorPowerOff = true
        end
    end

    -- Set power OFF for sectors that no longer have any light props
    for sectorName in pairs(knownSectors) do
        if ( !activeSectors[sectorName] ) then
            SetGlobalBool("BMRF_PowerOn_" .. sectorName, true) -- Default to ON when no lights exist
        end
    end

    knownSectors = activeSectors

    -- Keep aggregate global for compatibility with anything else that still checks this
    -- True if all sectors have power, false if any sector is without power
    SetGlobalBool("BMRF_PowerOn", !bAnySectorPowerOff)
end)

-- HUD Paint to display power status per sector
hook.Add("HUDPaint", "BMRF.Power.HUD", function()
    if ( SERVER ) then return end

    local client = LocalPlayer()
    if ( !IsValid(client) ) then return end

    -- Gather all known sectors from light props
    local sectors = {}
    for k, v in ipairs(ents.GetAll()) do
        if ( !IsValid(v) ) then continue end

        local sectorName = v:GetNWString("BMRF_LightSector", "")
        if ( sectorName != "" ) then
            sectors[sectorName] = true
        end
    end

    -- Display power status for each sector
    local yPos = ScrH() / 4
    draw.SimpleText("POWER STATUS", "DermaDefault", 300, yPos, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    yPos = yPos + 20

    for sectorName, _ in pairs(sectors) do
        local bPowerOn = GetGlobalBool("BMRF_PowerOn_" .. sectorName, true)
        local colorStatus = bPowerOn and Color(50, 255, 50, 255) or Color(255, 50, 50, 255)
        local statusText = bPowerOn and "ON" or "OFF"

        draw.SimpleText(string.format("%s: %s", sectorName, statusText), "DermaDefault", 310, yPos, colorStatus, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        yPos = yPos + 15
    end
end)
