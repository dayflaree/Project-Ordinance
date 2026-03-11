--[[
    BShift Animations Module - Client Core
    Handles screenspace effects, concommands, and UI.
]]

if (SERVER) then return end

-- Concommands for manual triggers
concommand.Add("lima_xte_doorknock", function(a, b, c, argStr)
    local ply = LocalPlayer()
    if (VManip and VManip:IsActive()) then return end
    if (argStr == "") then return end
    if (IsValid(ply:GetNW2Entity("xen_teleport_effect"))) then return end
    if (!ply:IsOnGround()) then return end

    net.Start("lima_xte_doorknock")
        net.WriteEntity(ply)
        net.WriteString(argStr)
    net.SendToServer()
end)

concommand.Add("lima_xte_getup", function(a, b, c, argStr)
    local ply = LocalPlayer()
    if (VManip and VManip:IsActive()) then return end
    if (IsValid(ply:GetNW2Entity("xen_teleport_effect"))) then return end
    if (!ply:IsOnGround()) then return end

    net.Start("lima_xte_getup")
        net.WriteEntity(ply)
        net.WriteString(argStr)
    net.SendToServer()
end)

concommand.Add("lima_xte_doanim", function(a, b, c, argStr)
    local ply = LocalPlayer()
    if (VManip and VManip:IsActive()) then return end
    if (IsValid(ply:GetNW2Entity("xen_teleport_effect"))) then return end
    if (!ply:IsOnGround()) then return end

    net.Start("lima_xte_doanim")
        net.WriteEntity(ply)
        net.WriteString(argStr)
    net.SendToServer()
end)

-- Weapon query from server
net.Receive("lima_xte_weapon", function() 
    local ent = net.ReadEntity()
    timer.Simple(0, function()
        net.Start("lima_xte_weapon2")
            net.WriteEntity(ent)
            net.WriteString(GetConVar("lima_xte_weapon"):GetString() or "weapon_crowbar")
        net.SendToServer()
    end)
end)

-- Effects
hook.Add("RenderScreenspaceEffects", "BShift_BloomEffect", function()
    local ply = LocalPlayer()
    local effect = ply:GetNW2Entity("xen_teleport_effect")
    if (IsValid(effect) and effect:GetNW2Float("Bloom", 0) > 0) then
        local num = effect:GetNW2Float("Bloom", 0)
        DrawBloom(0.2, 0.5 * num, 9, 9, 1, 1, 1, 1, 1)
        DrawMotionBlur(0.4, 0.1 * num, 0.06)
    end
end)
