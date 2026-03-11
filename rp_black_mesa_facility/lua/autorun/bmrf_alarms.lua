-- Track if the alarm is active or not if more than 50% of the prop dynamic models are changed skins
-- Track it via names of alarm_prop_*

local knownSectors = {}

-- Sector-specific alarm configurations
local sectorAlarmConfigs = {
    ["logistics_facilities"] = {
        sound = "bshift/scripted_midgame/freightyard_blastdoor_alarm.wav",
        mode = "delayed", -- Sound plays continuously via CSoundPatch
        delay = 2,
        volume = 60,
        pitch = 100,
        soundLevel = 60,
    },
    ["security_facilities"] = {
        sound = "bshift/scripted_predisaster/pd_insecurity_alarm.wav",
        mode = "looped", -- Sound plays with delay between emits
        volume = 70,
        pitch = 100,
        soundLevel = 70,
    },
    ["dorms"] = {
        sound = "bshift/bs_emitters/bs_alarm_klaxon.wav",
        mode = "delayed",
        delay = 1.5,
        volume = 70,
        pitch = 100,
        soundLevel = 70,
    },
}

-- Default configuration for sectors not explicitly defined
local defaultAlarmConfig = {
    sound = "bshift/bs_emitters/bs_alarm_klaxon.wav",
    mode = "delayed",
    delay = 2,
    volume = 60,
    pitch = 100,
    soundLevel = 75,
}

-- Client-side sound tracking for looped mode
local activeSoundPatches = {} -- [sector] = { [entity] = CSoundPatch }
local sectorNextSound = {} -- [sector] = nextTime for delayed mode

local function GetAlarmSectorFromName(alarmName)
    if ( !isstring(alarmName) or alarmName == "" ) then return nil end

    local sectorDelimiterIndex = alarmName:find("-", 1, true)
    if ( !sectorDelimiterIndex ) then return nil end

    local sectorName = alarmName:sub(sectorDelimiterIndex + 1)
    if ( sectorName == "" ) then return nil end

    return sectorName
end

local function GetSectorConfig(sectorName)
    return sectorAlarmConfigs[sectorName] or defaultAlarmConfig
end

local nextThink = 0
hook.Add("Think", "BMRF.Alarm.Tracker.Debug", function()
    if ( CurTime() < nextThink ) then return end
    nextThink = CurTime() + 0.1

    if ( CLIENT ) then return end

    for k, v in ipairs(ents.FindByName("alarm_*")) do
        debugoverlay.Cross(v:GetPos(), 10, 0.1, Color(0, 255, 0, 0), false)
        debugoverlay.Text(v:GetPos(), v:GetName(), 0.1, true)
    end
end)

local nextTracker = 0
hook.Add("Think", "BMRF.Alarm.Tracker", function()
    if ( CurTime() < nextTracker ) then return end
    nextTracker = CurTime() + 0.5

    if ( CLIENT ) then return end

    local alarmProps = ents.FindByName("alarm_prop_*")
    local sectorStats = {}

    for k, v in ipairs(alarmProps) do
        if ( !IsValid(v) ) then continue end

        local alarmName = v:GetName()
        local sectorName = GetAlarmSectorFromName(alarmName)

        v:SetNWString("BMRF_Name", alarmName)

        if ( !sectorName ) then continue end

        v:SetNWString("BMRF_AlarmSector", sectorName)

        if ( !sectorStats[sectorName] ) then
            sectorStats[sectorName] = {
                totalProps = 0,
                activeProps = 0,
            }
        end

        sectorStats[sectorName].totalProps = sectorStats[sectorName].totalProps + 1

        if ( v:GetSkin() > 0 ) then
            sectorStats[sectorName].activeProps = sectorStats[sectorName].activeProps + 1
        end
    end

    local bAnySectorActive = false
    local activeSectors = {}

    for sectorName, stats in pairs(sectorStats) do
        activeSectors[sectorName] = true

        local bSectorActive = stats.totalProps > 0 and (stats.activeProps / stats.totalProps) >= 0.5
        SetGlobalBool("BMRF_AlarmActive_" .. sectorName, bSectorActive)

        if ( bSectorActive ) then
            bAnySectorActive = true
        end
    end

    for sectorName in pairs(knownSectors) do
        if ( !activeSectors[sectorName] ) then
            SetGlobalBool("BMRF_AlarmActive_" .. sectorName, false)
        end
    end

    knownSectors = activeSectors

    -- Keep aggregate global for compatibility with anything else that still checks this.
    SetGlobalBool("BMRF_AlarmActive", bAnySectorActive)
end)

-- Play alarm sound to nearby alarm props if the alarm is active, only if we are near it too
hook.Add("Think", "BMRF.Alarm.Sound", function()
    if ( SERVER ) then return end

    local client = LocalPlayer()
    if ( !IsValid(client) ) then return end

    local clientPos = client:GetPos()
    local curTime = CurTime()
    local nearbyAlarms = ents.FindInSphere(clientPos, 512)

    -- Track which sectors and entities are currently valid for sound
    local activeSoundEntities = {} -- [sector] = { [entity] = true }

    -- Scan for valid alarm entities
    for k, v in ipairs(nearbyAlarms) do
        if ( !IsValid(v) ) then continue end

        local alarmName = v:GetNWString("BMRF_Name", "")
        if ( alarmName == "" or !alarmName:find("alarm_prop_", 1, true) ) then continue end

        local sectorName = v:GetNWString("BMRF_AlarmSector", "")
        if ( sectorName == "" ) then
            sectorName = GetAlarmSectorFromName(alarmName)
        end

        if ( sectorName == "" ) then continue end
        if ( !GetGlobalBool("BMRF_AlarmActive_" .. sectorName, false) ) then continue end

        -- This entity should be playing an alarm sound
        if ( !activeSoundEntities[sectorName] ) then
            activeSoundEntities[sectorName] = {}
        end
        activeSoundEntities[sectorName][v] = true
    end

    -- Process each sector
    for sectorName, entities in pairs(activeSoundEntities) do
        local config = GetSectorConfig(sectorName)

        if ( config.mode == "looped" ) then
            -- Looped mode: use CSoundPatch for continuous playback
            if ( !activeSoundPatches[sectorName] ) then
                activeSoundPatches[sectorName] = {}
            end

            -- Start sounds for new entities
            for ent, _ in pairs(entities) do
                if ( !activeSoundPatches[sectorName][ent] or !activeSoundPatches[sectorName][ent]:IsPlaying() ) then
                    local soundPatch = CreateSound(ent, config.sound)
                    if ( soundPatch ) then
                        soundPatch:SetSoundLevel(config.soundLevel)
                        soundPatch:Play()
                        activeSoundPatches[sectorName][ent] = soundPatch
                    end
                end

                -- Update volume based on distance
                local soundPatch = activeSoundPatches[sectorName][ent]
                if ( soundPatch ) then
                    local distance = clientPos:Distance(ent:GetPos())
                    local vol = math.Clamp(1 - (distance / 512), 0, 1)
                    soundPatch:ChangeVolume(vol * (config.volume / 100), 0)
                    soundPatch:ChangePitch(config.pitch, 0)
                end
            end

            -- Clean up sounds for entities that are no longer valid
            for ent, soundPatch in pairs(activeSoundPatches[sectorName]) do
                if ( !entities[ent] or !IsValid(ent) ) then
                    soundPatch:Stop()
                    activeSoundPatches[sectorName][ent] = nil
                end
            end
        elseif ( config.mode == "delayed" ) then
            -- Delayed mode: emit sounds with delay between plays
            local nextTime = sectorNextSound[sectorName] or 0

            if ( curTime >= nextTime ) then
                for ent, _ in pairs(entities) do
                    if ( IsValid(ent) ) then
                        local distance = clientPos:Distance(ent:GetPos())
                        local vol = math.Clamp(1 - (distance / 512), 0, 1)
                        ent:EmitSound(config.sound, config.volume, config.pitch, vol, CHAN_STATIC)
                    end
                end

                sectorNextSound[sectorName] = curTime + config.delay
            end
        end
    end

    -- Clean up looped sounds for inactive sectors
    for sectorName, patches in pairs(activeSoundPatches) do
        if ( !activeSoundEntities[sectorName] ) then
            for ent, soundPatch in pairs(patches) do
                if ( soundPatch ) then
                    soundPatch:Stop()
                end
            end
            activeSoundPatches[sectorName] = nil
        end
    end
end)

-- Cleanup function to stop all active sound patches
local function StopAllAlarmSounds()
    if ( CLIENT ) then
        for sectorName, patches in pairs(activeSoundPatches) do
            for ent, soundPatch in pairs(patches) do
                if ( soundPatch ) then
                    soundPatch:Stop()
                end
            end
        end
        activeSoundPatches = {}
        sectorNextSound = {}
    end
end

-- Stop sounds when the addon is reloaded
hook.Add("ShutDown", "BMRF.Alarm.Cleanup", StopAllAlarmSounds)

-- Stop sounds when the client disconnects
hook.Add("OnPlayerDisconnected", "BMRF.Alarm.ClientCleanup", function(ply)
    if ( CLIENT and ply == LocalPlayer() ) then
        StopAllAlarmSounds()
    end
end)

-- HUD Paint to display alarm status per sector
hook.Add("HUDPaint", "BMRF.Alarm.HUD", function()
    if ( SERVER ) then return end

    local client = LocalPlayer()
    if ( !IsValid(client) ) then return end

    -- Gather all known sectors from alarm props
    local sectors = {}
    for k, v in ipairs(ents.GetAll()) do
        if ( !IsValid(v) ) then continue end

        local sectorName = v:GetNWString("BMRF_AlarmSector", "")
        if ( sectorName != "" ) then
            sectors[sectorName] = true
        end
    end

    -- Display alarm status for each sector
    local yPos = ScrH() / 4
    draw.SimpleText("ALARM STATUS", "DermaDefault", 10, yPos, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    yPos = yPos + 20

    for sectorName, _ in pairs(sectors) do
        local bAlarmActive = GetGlobalBool("BMRF_AlarmActive_" .. sectorName, false)
        local colorStatus = bAlarmActive and Color(255, 50, 50, 255) or Color(50, 255, 50, 255)
        local statusText = bAlarmActive and "ACTIVE" or "INACTIVE"

        draw.SimpleText(string.format("%s: %s", sectorName, statusText), "DermaDefault", 20, yPos, colorStatus, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        yPos = yPos + 15
    end
end)
