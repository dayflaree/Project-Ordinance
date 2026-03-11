util.AddNetworkString("vrnvgnetequip")
util.AddNetworkString("vrnvgnetflip")
util.AddNetworkString("vrnvgnetbreak")
util.AddNetworkString("vrnvgnetflashlight")
util.AddNetworkString("vrnvgnetbreakeasymode")
util.AddNetworkString("vrnvgnetloadhands")
util.AddNetworkString("vrnvgwarzone")
file.CreateDir("nvgs")
local drainrate = CreateConVar("vrnvg_drainrate", 0.70, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The battery drain rate for the NVGs.", 0, 10)
local rechargerate = CreateConVar("vrnvg_rechargerate", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The battery recharge rate for the NVGs.", 0, 10)
local blockchance = CreateConVar("vrnvg_blockchance", 25, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The chance of the NVGs taking a bullet for you.", 0, 100)
util.PrecacheModel("models/ventrische/c_quadnod2.mdl")
net.Receive("vrnvgnetflashlight", function(len, ply)
    local bool = net.ReadBool()
    if bool then
        ply:AllowFlashlight(false)
    else
        ply:AllowFlashlight(true)
    end
end)

concommand.Add("vrnvgequip", function(ply)
    --[[
    local gun = ply:GetActiveWeapon()
    if IsValid(ply) and ply:Alive() then
        if IsValid(gun) and not ply.vrnvgbroken and not ply.vrnvgflipped then
            ply:SetSuppressPickupNotices(true)
            local vrnvgs = ply:Give("vrnvgs")
            if not IsValid(vrnvgs) then vrnvgs = ply:GetWeapon("vrnvgs") end
            if IsValid(vrnvgs) then
                vrnvgs.slamholdtype = true
                ply:SelectWeapon("vrnvgs")
            else
                print("NVGs: potentially broken by another mod, look for a weapon pickup related addon in your addons and disable it.")
            end

            ply:SetSuppressPickupNotices(false)
        end
    end
    ]]
end)

concommand.Add("vrnvgflip", function(ply)
    local gun = ply:GetActiveWeapon()
    if IsValid(ply) and ply:Alive() then
        if IsValid(gun) and ply.vrnvgequipped and not ply.vrnvgbroken then
            ply:SetSuppressPickupNotices(true)
            local vrnvgs = ply:Give("vrnvgs")
            if not IsValid(vrnvgs) then vrnvgs = ply:GetWeapon("vrnvgs") end
            if IsValid(vrnvgs) then
                vrnvgs.cameraholdtype = true
                ply:SelectWeapon("vrnvgs")
            else
                print("NVGs: potentially broken by another mod, look for a weapon pickup related addon in your addons and disable it.")
            end

            ply:SetSuppressPickupNotices(false)
        elseif IsValid(gun) and ply.vrnvgbroken then
            ply:SetSuppressPickupNotices(true)
            local vrnvgs = ply:Give("vrnvgs")
            if not IsValid(vrnvgs) then vrnvgs = ply:GetWeapon("vrnvgs") end
            if IsValid(vrnvgs) then
                vrnvgs.brokentoss = true
                ply:SelectWeapon("vrnvgs")
            else
                print("NVGs: potentially broken by another mod, look for a weapon pickup related addon in your addons and disable it.")
            end

            ply:SetSuppressPickupNotices(false)
            timer.Simple(4.5, function()
                if ply:Alive() then
                    local brokennvgs = ents.Create("prop_physics")
                    brokennvgs:SetModel("models/ventrische/w_quadnods.mdl")
                    brokennvgs:SetPos(ply:GetPos() + Vector(0, 0, 20))
                    brokennvgs:SetCollisionGroup(COLLISION_GROUP_WEAPON)
                    brokennvgs:Spawn()
                    local phys = brokennvgs:GetPhysicsObject()
                    if IsValid(phys) then phys:SetVelocity(ply:EyeAngles():Forward() * 200 - ply:EyeAngles():Right() * 100) end
                    timer.Simple(15, function() if IsValid(brokennvgs) then brokennvgs:Remove() end end)
                end
            end)
        end
    end
end)

hook.Add("ScalePlayerDamage", "vrnvg_brokentosser", function(ply, hitgroup, dmginfo)
    local chance = math.random(0, 100)
    local attacker = dmginfo:GetAttacker()
    if IsValid(ply) and IsValid(attacker) then
        if not ax.util:IsValidPlayer(attacker) and ply.vrnvgflipped and chance < blockchance:GetFloat() or ax.util:IsValidPlayer(attacker) and hitgroup == HITGROUP_HEAD and ply.vrnvgflipped and chance < blockchance:GetFloat() then
            if dmginfo:IsExplosionDamage() or dmginfo:IsBulletDamage() then
                if not ply.vrnvgbroken then
                    ply.vrnvgbroken = true
                    net.Start("vrnvgnetbreakeasymode")
                    net.WriteBool(true)
                    net.Send(ply)
                    dmginfo:ScaleDamage(0)
                    ply:ViewPunch(Angle(-8, 0, 0))
                    return true
                end
            end
        end
    end
end)

hook.Add("PlayerDeath", "vrnvg_playerdeath", function(victim, inflictor, attacker)
    if IsValid(victim) then
        if victim.vrnvgequipped or victim.vrnvgbroken then
            victim.vrnvgflipped = false
            victim.vrnvgequipped = false
            victim.vrnvgbroken = false
        end
    end
end)

hook.Add("Think", "vrnvg_playerthink", function()
    for k, v in ipairs(player.GetAll()) do
        --old weapon grabbing
        local wep = v:GetActiveWeapon()
        if IsValid(v) and v:Alive() and IsValid(wep) then if wep:GetClass() != "vrnvgs" then v.vrnvglast = wep end end
        --battery
        if IsValid(v) and v:Alive() then
            if v.vrnvgequipped and not v.vrnvgflipped and v.vowarzoneenabled then
                net.Start("vrnvgwarzone")
                net.Send(v)
            end

            if not v.nvgbattery then v.nvgbattery = 80 end
            if v.vrnvgequipped then
                v:SetNW2Int("vrnvgbattery", v.nvgbattery)
                v:SetNW2Bool("vrnvgequipped", true)
                if v.vrnvgflipped then
                    v:SetNW2Bool("vrnvgflipped", true)
                    v.nvgbattery = math.Approach(v.nvgbattery, 0, FrameTime() * drainrate:GetFloat())
                else
                    v:SetNW2Bool("vrnvgflipped", false)
                    v.nvgbattery = math.Approach(v.nvgbattery, 80, FrameTime() * 4 * rechargerate:GetFloat())
                end
            else
                v:SetNW2Bool("vrnvgequipped", false)
            end
        end
    end
end)

local function vrnvg_spawnloadhands(ply) --fuckin rp modes
    net.Start("vrnvgnetloadhands")
    net.Send(ply)
end

hook.Add("PlayerSpawn", "vrnvg_spawnloadhands", vrnvg_spawnloadhands)
