--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Server blacklist storage
weapon_reverb.serverBlacklist = {}

-- Initialize server blacklist file
if not file.Read("weapon_reverb_sv_blacklist.json") or #file.Read("weapon_reverb_sv_blacklist.json") == 0 then
    print("[Weapon Reverb] Created server blacklist file.")
    file.Write("weapon_reverb_sv_blacklist.json", util.TableToJSON({}))
else
    print("[Weapon Reverb] Loaded server blacklist file.")
    weapon_reverb.serverBlacklist = util.JSONToTable(file.Read("weapon_reverb_sv_blacklist.json"))
end

-- Register network strings
util.AddNetworkString("weapon_reverb_network_fire")
util.AddNetworkString("weapon_reverb_network_sound")
util.AddNetworkString("weapon_reverb_sync_blacklist")

-- Change blacklist helper function
local function changeBlacklist(action, weaponClass)
    local JSONData = file.Read("weapon_reverb_sv_blacklist.json")
    local converted = util.JSONToTable(JSONData) or {}

    if action == "remove" then
        print("[Weapon Reverb] Removed " .. weaponClass .. " from server blacklist.")
        converted[weaponClass] = nil
    end

    if action == "add" then
        print("[Weapon Reverb] Added " .. weaponClass .. " to server blacklist.")
        converted[weaponClass] = true
    end

    if action == "clear" then
        print("[Weapon Reverb] Server blacklist cleared.")
        converted = {}
    end

    weapon_reverb.serverBlacklist = converted
    file.Write("weapon_reverb_sv_blacklist.json", util.TableToJSON(weapon_reverb.serverBlacklist))

    -- Sync to all clients
    net.Start("weapon_reverb_sync_blacklist")
        net.WriteTable(weapon_reverb.serverBlacklist)
    net.Broadcast()
end

-- Server console commands for blacklist management
concommand.Add("sv_weapon_reverb_blacklist_remove", function(client, cmd, args)
    if not args[1] then
        print("[Weapon Reverb] Missing weapon class.")
        return
    end
    changeBlacklist("remove", args[1])
end, nil, "Remove a weapon class from the server blacklist.")

concommand.Add("sv_weapon_reverb_blacklist_add", function(client, cmd, args)
    if not args[1] then
        print("[Weapon Reverb] Missing weapon class.")
        return
    end
    changeBlacklist("add", args[1])
end, nil, "Add a weapon class to the server blacklist.")

concommand.Add("sv_weapon_reverb_blacklist_clear", function(client, cmd, args)
    changeBlacklist("clear", nil)
end, nil, "Clear the server blacklist.")

-- Sync blacklist to newly joined players
hook.Add("PlayerSpawn", "WeaponReverb_SyncBlacklist", function(client)
    net.Start("weapon_reverb_sync_blacklist")
        net.WriteTable(weapon_reverb.serverBlacklist)
    net.Send(client)
end)

-- Write vector to network (uncompressed)
local function writeVectorUncompressed(vector)
    net.WriteFloat(vector.x)
    net.WriteFloat(vector.y)
    net.WriteFloat(vector.z)
end

-- Network gunshot event to clients
local function networkGunshotEvent(data)
    net.Start("weapon_reverb_network_fire", false)
        writeVectorUncompressed(data.Src)
        writeVectorUncompressed(data.Dir)
        writeVectorUncompressed(data.Vel)
        writeVectorUncompressed(data.Spread)
        net.WriteString(data.Ammotype)
        net.WriteBool(data.isSuppressed)
        net.WriteEntity(data.Entity)
        net.WriteBool(data.Explosion)

    -- Send to all clients or PAS (Potentially Audible Set) based on config
    if ax.config:Get("weaponReverbNetworkSounds", false) then
        net.SendPAS(data.Src)
    else
        net.Broadcast()
    end
end

-- Explosion detection hooks
hook.Add("OnEntityCreated", "WeaponReverb_ExplosionCreate", function(ent)
    timer.Simple(0, function()
        if IsValid(ent) and ent:GetClass() == "env_explosion" then
            local data = {
                Src = ent:GetPos(),
                Dir = vector_origin,
                Vel = vector_origin,
                Spread = vector_origin,
                Ammotype = "explosions",
                isSuppressed = false,
                Entity = ent,
                Weapon = ent,
                Explosion = true
            }
            networkGunshotEvent(data)
        end
    end)
end)

hook.Add("EntityRemoved", "WeaponReverb_ExplosionRemove", function(ent)
    if IsValid(ent) and (ent:GetClass() == "grenade_ar2" or ent:GetClass() == "npc_grenade_frag" or ent:GetClass() == "env_explosion") then
        local data = {
            Src = ent:GetPos(),
            Dir = vector_origin,
            Vel = vector_origin,
            Spread = vector_origin,
            Ammotype = "explosions",
            isSuppressed = false,
            Entity = ent,
            Weapon = ent,
            Explosion = true
        }
        networkGunshotEvent(data)
    end
end)

-- Main EntityFireBullets hook
hook.Add("EntityFireBullets", "WeaponReverb_EntityFireBullets", function(attacker, data)
    -- Skip special cases
    if data.Spread.z == 0.125 then return end -- Blood decal workaround
    if data.AmmoType == "grenadeFragments" then return end -- RFS support
    if data.Distance < 200 then return end -- Melee weapons

    local entity = NULL
    local weapon = NULL
    local weaponIsWeird = false
    local isSuppressed = false
    local ammotype = "none"

    -- Determine entity and weapon
    if ax.util:IsValidPlayer(attacker) or attacker:IsNPC() then
        entity = attacker
        weapon = entity:GetActiveWeapon()
    else
        weapon = attacker
        entity = weapon:GetOwner()
        if entity == NULL then
            entity = attacker
            weaponIsWeird = true
        end
    end

    -- Get weapon and ammo information
    if not weaponIsWeird and IsValid(weapon) and entity.GetShootPos then
        local weaponClass = weapon:GetClass()
        local entityShootPos = entity:GetShootPos()

        -- Skip special weapons
        if weaponClass == "mg_arrow" then return end
        if weaponClass == "mg_sniper_bullet" and data.Spread == Vector(0, 0, 0) then return end
        if weaponClass == "mg_slug" and data.Spread == Vector(0, 0, 0) then return end

        -- ArcCW grenade launchers and physics bullets
        if string.StartWith(weaponClass, "arccw_") then
            if data.Distance == 20000 then return end -- Grenade launchers
            if GetConVar("arccw_bullet_enable"):GetInt() == 1 and data.Spread == vector_origin then
                return -- Physics bullets
            end
        end

        -- ARC9 physics bullets
        if string.StartWith(weaponClass, "arc9_") then
            if GetConVar("arc9_bullet_physics"):GetInt() == 1 and data.Spread == vector_origin then
                return
            end
        end

        -- TacRP physics bullets
        if string.StartWith(weaponClass, "tacrp_") and not entity:IsNPC() then
            local hitscan = true

            if TacRP.ConVars["physbullet"]:GetBool() then
                local weaponMuzzle = weapon:GetMuzzleOrigin()
                local dir = weapon:GetShootDir()
                local dist = math.max(weapon:GetValue("MuzzleVelocity"), 15000) * engine.TickInterval() * game.GetTimeScale() * 2

                local inst_tr = util.TraceLine({
                    start = weaponMuzzle,
                    endpos = weaponMuzzle + dir:Forward() * dist,
                    mask = MASK_SHOT,
                    filter = {weapon:GetOwner(), weapon:GetOwner():GetVehicle(), weapon}
                })

                if inst_tr.Hit and not inst_tr.HitSky then
                    hitscan = true
                else
                    hitscan = false
                end
            end

            if not hitscan and data.Spread == vector_origin then
                return
            end
        end

        -- FEAR bullet time
        if game.GetTimeScale() < 1 and data.Spread == vector_origin and data.Tracer == 0 then return end

        -- Prevent double-detection per tick
        if entity.dwr_shotThisTick == nil then
            entity.dwr_shotThisTick = false
        end

        if entity.dwr_shotThisTick then return end
        entity.dwr_shotThisTick = true
        timer.Simple(engine.TickInterval() * 2, function()
            if IsValid(entity) then
                entity.dwr_shotThisTick = false
            end
        end)

        -- Get ammo type
        if #data.AmmoType > 2 then
            ammotype = data.AmmoType
        elseif weapon.Primary then
            ammotype = weapon.Primary.Ammo
        end

        isSuppressed = weapon_reverb:IsSuppressed(weapon, weaponClass)
    end

    -- Network the gunshot
    local dwr_data = {
        Src = data.Src,
        Dir = data.Dir,
        Vel = Vector(0, 0, 0),
        Spread = data.Spread,
        Ammotype = ammotype,
        isSuppressed = isSuppressed,
        Entity = entity,
        Weapon = weapon,
        Explosion = false
    }

    networkGunshotEvent(dwr_data)
end)

-- EntityEmitSound hook for server-sound networking
hook.Add("EntityEmitSound", "WeaponReverb_EntityEmitSound", function(data)
    if not ax.config:Get("weaponReverbNetworkSounds", false) then return end
    if not string.StartsWith(data.OriginalSoundName, "Weapon") then return end
    if string.find(data.SoundName, "rpg") then return end

    local src = data.Entity:GetPos()
    if ax.util:IsValidPlayer(data.Entity) or data.Entity:IsNPC() then src = data.Entity:GetShootPos() end
    data.Pos = src

    net.Start("weapon_reverb_network_sound")
        net.WriteTable(data)
    net.Broadcast()

    data.Volume = 0
    return true
end)
