--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Supported ammo types
weapon_reverb.supportedAmmoTypes = {'357', 'ar2', 'buckshot', 'pistol', 'smg1'}

-- Weapon blacklist storage (client-side)
weapon_reverb.blacklist = {}

-- Server blacklist (synced from server)
weapon_reverb.serverBlacklist = {}

-- Initialize blacklist file
if not file.Read("weapon_reverb_blacklist.json") or #file.Read("weapon_reverb_blacklist.json") == 0 then
    file.Write("weapon_reverb_blacklist.json", util.TableToJSON({}))
else
    weapon_reverb.blacklist = util.JSONToTable(file.Read("weapon_reverb_blacklist.json"))
end

-- Check if weapon is suppressed (supports multiple weapon bases)
function weapon_reverb:IsSuppressed(weapon, weaponClass)
    weaponClass = weaponClass or weapon:GetClass()

    -- ArcCW
    if string.StartWith(weaponClass, "arccw_") then
        if weapon.GetBuff_Override and weapon:GetBuff_Override("Silencer") then
            return true
        end
    end

    -- ARC9
    if string.StartWith(weaponClass, "arc9_") then
        if isfunction(weapon.GetProcessedValue) and weapon:GetProcessedValue("Silencer") then
            return true
        end
    end

    -- TFA (True Firearms Advanced)
    if string.StartWith(weaponClass, "tfa_") then
        if weapon:GetSilenced() then
            return true
        end
    end

    -- MW2019 (Modern Warfare 2019 SWEPs)
    if string.StartWith(weaponClass, "mg_") then
        if weapon.GetAllAttachmentsInUse then
            for slot, attachment in pairs(weapon:GetAllAttachmentsInUse()) do
                if attachment.ClassName and (string.find(attachment.ClassName, "silence") or string.find(attachment.ClassName, "suppress")) then
                    return true
                end
            end
        end
    end

    -- CW2.0 (Customizable Weaponry 2.0)
    if string.StartWith(weaponClass, "cw_") then
        if weapon.ActiveAttachments then
            for k, v in pairs(weapon.ActiveAttachments) do
                if v == false then continue end
                local att = CustomizableWeaponry.registeredAttachmentsSKey[k]
                if att and att.isSuppressor then
                    return true
                end
            end
        end
    end

    return false
end

-- Format ammo type to supported format
function weapon_reverb:FormatAmmoType(ammotype)
    ammotype = string.lower(ammotype or "")

    if table.HasValue(self.supportedAmmoTypes, ammotype) then
        return ammotype
    elseif ammotype == "explosions" then
        return "explosions"
    else
        return "other"
    end
end

-- Get custom properties from weapon entity
function weapon_reverb:GetWeaponProperties(weapon)
    return {
        reverbDisable = weapon.dwr_reverbDisable or false,
        cracksDisable = weapon.dwr_cracksDisable or false,
        customVolume = weapon.dwr_customVolume or 1,
        customAmmoType = weapon.dwr_customAmmoType,
        customIsSuppressed = weapon.dwr_customIsSuppressed
    }
end

-- Check if weapon should be processed
function weapon_reverb:ShouldProcessWeapon(weapon)
    if not IsValid(weapon) then
        return false, "Weapon invalid"
    end

    local weaponClass = weapon:GetClass()

    -- Check blacklists
    if self.blacklist[weaponClass] or self.serverBlacklist[weaponClass] then
        return false, "Weapon blacklisted"
    end

    -- Special case weapons
    if weaponClass == "mg_arrow" then
        return false, "Crossbow excluded"
    end

    return true, nil
end
