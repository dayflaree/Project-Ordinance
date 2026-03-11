--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Track ammo for local player detection
local previousAmmo = 0
local previousWep = NULL

-- Load reverb files on initialization
hook.Add("InitPostEntity", "WeaponReverb_Precache", function()
    weapon_reverb.reverbFiles = {}

    -- Find all dwr sound files
    local function FindReverbFiles(dir)
        local files, dirs = file.Find(dir .. "/*", "GAME")

        for _, filename in ipairs(files) do
            if ( string.GetExtensionFromFilename(filename) == "wav" ) then
                table.insert(weapon_reverb.reverbFiles, dir .. "/" .. filename)
            end
        end

        for _, dirname in ipairs(dirs) do
            FindReverbFiles(dir .. "/" .. dirname)
        end
    end

    FindReverbFiles("sound/dwr")

    -- Precache all reverb sounds
    for _, snd in ipairs(weapon_reverb.reverbFiles) do
        util.PrecacheSound(snd)
    end

    print("[Weapon Reverb] Precached " .. #weapon_reverb.reverbFiles .. " reverb sounds.")
end)

-- Handle networked weapon fire from server
net.Receive("weapon_reverb_network_fire", function(len)
    local src = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
    local dir = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
    local vel = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
    local spread = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
    local ammotype = net.ReadString()
    local isSuppressed = net.ReadBool()
    local entity = net.ReadEntity()
    local explosion = net.ReadBool()

    local ignore = (entity == ax.client)
    local weapon = {}

    if IsValid(entity) and entity.GetActiveWeapon then
        weapon = entity:GetActiveWeapon()
        local shouldProcess, reason = weapon_reverb:ShouldProcessWeapon(weapon)
        if not shouldProcess then
            return
        end
    end

    if not game.SinglePlayer() and ignore then return end

    -- Play bullet crack if enabled
    if not ignore and not explosion then
        weapon_reverb:PlayBulletCrack(src, dir, vel, spread, ammotype, weapon)
    end

    -- Play reverb
    if explosion then
        weapon_reverb:PlayReverb(src, "explosions", false, weapon)
    else
        weapon_reverb:PlayReverb(src, ammotype, isSuppressed, weapon)
    end
end)

-- Network message for server-sent EntityEmitSound events
net.Receive("weapon_reverb_network_sound", function(len)
    local data = net.ReadTable()

    if not data or not data.Entity or data.Entity == NULL then return end

    data = weapon_reverb.ProcessSound(data, true)

    if not game.SinglePlayer() and data.Entity == ax.client then return end

    data.Entity:EmitSound(data.SoundName, data.SoundLevel, data.Pitch, data.Volume, CHAN_STATIC, data.Flags, data.DSP)
end)

-- Network message for server blacklist sync
net.Receive("weapon_reverb_sync_blacklist", function(len)
    weapon_reverb.serverBlacklist = net.ReadTable()
    print("[Weapon Reverb] Server blacklist synced: " .. table.Count(weapon_reverb.serverBlacklist) .. " entries.")
end)

-- Detect local player weapon firing (single player only)
if game.SinglePlayer() then
    local function onPrimaryAttack(attacker, weapon)
        local weaponClass = weapon:GetClass()
        local shouldProcess, reason = weapon_reverb:ShouldProcessWeapon(weapon)
        if not shouldProcess then return end

        local entityShootPos = attacker:GetShootPos()
        local isSuppressed = weapon_reverb:IsSuppressed(weapon, weaponClass)

        local ammotype_num = weapon:GetPrimaryAmmoType()
        local ammotype = "unknown"

        if ammotype_num ~= -1 then
            ammotype = game.GetAmmoName(ammotype_num)
        end

        if (ammotype == "unknown" or #ammotype < 2) and weapon.Primary then
            ammotype = weapon.Primary.Ammo
        end

        weapon_reverb:PlayReverb(entityShootPos, ammotype, isSuppressed, weapon)
    end

    hook.Add("Think", "WeaponReverb_DetectFire", function()
        local client = ax.client
        if not client:Alive() then return end

        local wep = client:GetActiveWeapon()
        if not wep or not wep.Clip1 then return end

        local currentAmmo = wep:Clip1()

        -- Detect when ammo decreases (weapon fired)
        if currentAmmo < previousAmmo and wep == previousWep then
            onPrimaryAttack(client, wep)
        end

        previousAmmo = currentAmmo
        previousWep = wep
    end)
end

-- Process all entity sounds if enabled
hook.Add("EntityEmitSound", "WeaponReverb_EntityEmitSound", function(data)
    if data.Pos == nil or not data.Pos then return end

    if ax.config:Get("weaponReverbProcessAll", false) then
        local isWeapon = string.StartsWith(data.OriginalSoundName, "Weapon")
        data = weapon_reverb.ProcessSound(data, isWeapon)
        return true
    end
end)
