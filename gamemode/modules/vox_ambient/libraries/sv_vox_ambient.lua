--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

require("niknaks")

local mapObject = NikNaks.CurrentMap
local speakers1 = mapObject:FindStaticByModel("models/props_generic/loudspeaker.mdl")
local speakers2 = mapObject:FindStaticByModel("models/props_generic/loudspeaker001.mdl")

function MODULE:OnSchemaLoaded()
    self.speakers = {}

    local function add(speaker)
        table.insert(self.speakers, {
            object = speaker,
            uniqueID = util.CRC(tostring(speaker.Origin) .. "_" .. tostring(speaker.Angles))
        })
    end

    for _, speaker in ipairs(speakers1) do
        add(speaker)
    end

    for _, speaker in ipairs(speakers2) do
        add(speaker)
    end
end

local voxList = {
    {"riggs9162/bms/vox/facility/c1a0_01.ogg", "<i>[Intercom] Security Officer Sezen, Please Report to-- Office Complex, Level Six, Conference Room--B.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_02.ogg", "<i>[Intercom] Doctor McVinnie, Doctor Ryman, and Doctor Briggeman.  Please Report to-- Materials Complex.  For... Audit Review. Scheduled in--fifteen minutes.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_03.ogg", "<i>[Intercom] R.Maclean Reports Sector C Material Rail System Is Now...Operational.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_04.ogg", "<i>[Intercom] Agent Chinner, Report to--Topside Tactical Operations Center.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_05.ogg", "<i>[Intercom] Agent Allen, Report to-- Administration...Sub-level--Two.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_06.ogg", "<i>[Intercom] Doctor Wilson, Please Call-- ObservationTank-- One.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_07.ogg", "<i>[Intercom] Doctor Robertson, Please Report To-- Lambda Reactor Complex.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_08.ogg", "<i>[Intercom] Doctor Ayres, Please Call-- 7-2-9.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_09.ogg", "<i>[Intercom] Sergeant Fleistad, Report To-- Topside. Checkpoint--Bravo.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_10.ogg", "<i>[Intercom] Coded Message For-- Captain Claesson. Command and Communications Center.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_11.ogg", "<i>[Intercom] J_Headon, Science Personnel. Report To-- Anomalous Materials Test Lab.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_12.ogg", "<i>[Intercom] Doctor Freeman, Report to-- Anomalous Materials Test Lab. Immediately.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_13.ogg", "<i>[Intercom] Doctor Nielsen Reports-- Superconducting Interchange is-- Activated.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_14.ogg", "<i>[Intercom] Doctor Peloski, Report to--Supercooled Laser Lab. Please.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_15.ogg", "<i>[Intercom] Sergeant Boetsma, Report to--Topside Motorpool... Immediately.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_16.ogg", "<i>[Intercom] Lieutenant Montero To-- Sub Level--Three.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_17.ogg", "<i>[Intercom] Agent Teunissen, Report to--Topside Tactical Operations Center.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_18.ogg", "<i>[Intercom] Security Officer Sisk Reports--Medical Emergency In--Administration Center.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_19.ogg", "<i>[Intercom] Security Officer Tart, Please Report To-- Office Complex. Level 6. Conference Room--B.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_20.ogg", "<i>[Intercom] Doctor Tripolt, Doctor Dravean, and Doctor Engels... Please Report To-- Lambda Reactor Complex. For-- Audit Review. Scheduled In-- 15 minutes.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_21.ogg", "<i>[Intercom] D Keptres Reports-- Sector C Material Rail System... Is Now-- Operational.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_22.ogg", "<i>[Intercom] Doctor Ben Truman, Please Place Secure Line Call--To-- Line 7-1-5.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_23.ogg", "<i>[Intercom] Doctor Stone, Doctor Mertens, and Doctor Junek. Please Report to-- Processing Plant. For- Unscheduled Emergency Shut down Procedural Test Review.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_24.ogg", "<i>[Intercom] Security Officer Alexander, Please Report To-- Office Complex. For-- Personnel Profile Upgrade.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_25.ogg", "<i>[Intercom] Corporal Dominski, Please Report To-- Topside Security Office.  Emergency Grade Level-- 2.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_26.ogg", "<i>[Intercom] Sergeant Dahlgren,  Report to-- Topside. Checkpoint-- Bravo.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_27.ogg", "<i>[Intercom] Agent d'Avalos, Report to-- Topside Hazard Course Operations Center.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_28.ogg", "<i>[Intercom] Agent Dale, Report to-- Administration. Sub Level-- Eight.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_29.ogg", "<i>[Intercom] Doctor Horn, Please Call-- Residue Observation Tank-- Four.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_30.ogg", "<i>[Intercom] Doctor Narchi, Please Report To-- Lambda Reactor Complex.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_31.ogg", "<i>[Intercom] Doctor Escobedo, Please Call-- 3-2-6.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_32.ogg", "<i>[Intercom] Sergeant Gillen, Report To-- Topside. Checkpoint-- Alpha.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_33.ogg", "<i>[Intercom] Coded Message For-- Captain Morel. Command And Communications Center.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_34.ogg", "<i>[Intercom] D. Keyworth, Science_Personnel.  Report to-- Lambda Materials Storage Area.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_35.ogg", "<i>[Intercom] Doctor Vavilov, Report To-- Anomalous Materials Test Lab. Immediately.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_36.ogg", "<i>[Intercom] Doctor Kane Reports-- Superconducting Outerchange is--Activated.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_37.ogg", "<i>[Intercom] Doctor Wells, Report To-- Supercooled Laser Lab. Please.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_38.ogg", "<i>[Intercom] Sergeant Jarreau, Report To-- Topside Motorpool. Immediately.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_39.ogg", "<i>[Intercom] Lieutenant Henkel-- To-- Sub Level--Three.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_40.ogg", "<i>[Intercom] Agent Foreman, Report To--Topside Tactical Operations Center.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_41.ogg", "<i>[Intercom] Security Officer Schwenk Reports-- Medical-Emergency In-- Administration Center.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_42.ogg", "<i>[Intercom] Sergeant Fanaris, Personal Call On-- Line 2.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_43.ogg", "<i>[Intercom] Tech Sergeant Sezen, Please Call-- 0-1-0.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_44.ogg", "<i>[Intercom] Maitenance Member Kemp, Please Contact--  Human Resources. Line 4.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_45.ogg", "<i>[Intercom] Corporal Lucas, Please Report To-- Topside. Checkpoint--Alpha. Immediately.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_46.ogg", "<i>[Intercom] Security Officer Mirfin,  Please Report To--Office Complex.  Level--6 Conference Room--A.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_47.ogg", "<i>[Intercom] J. Radak, Network Team. Please Call-- 4-7-0.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_48.ogg", "<i>[Intercom] Coded Message For-- Captain Tsarouhas. Command and Communications Center.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_49.ogg", "<i>[Intercom] Coded Message For-- Sergeant Soleto. Command and Communications Center.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_50.ogg", "<i>[Intercom] Lieutenant Rose, Please Report To-- Hydro Dam Login Office.</i>"},
    {"riggs9162/bms/vox/facility/c1a0_51.ogg", "<i>[Intercom] Doctor Hillard Reports-- Residue Processing Plant Is--Operating-- at-- Optimal Performance.</i>"}
}

function MODULE:EmitAmbientVox()
    local randomID = math.random(#voxList)
    local randomVox = voxList[randomID]
    local sound = randomVox[1]
    local duration = SoundDuration(sound)
    for _, speakerData in ipairs(self.speakers) do
        local position = speakerData.object:GetPos()
        if ( hook.Run("HasNearbyPowerOutage", position) ) then continue end

        debugoverlay.Sphere(position, 1024, 4, Color(255, 0, 0, 0), true)
        debugoverlay.Text(position, sound, 4)

        EmitSound(sound, position, 0, CHAN_AUTO, 0.5, 75, 0, 100)
    end

    return duration
end

local nextAmbientVox = 0
function MODULE:Think()
    if ( nextAmbientVox > CurTime() ) then return end
    nextAmbientVox = CurTime() + self:EmitAmbientVox() + math.Rand(60, 120)
end
