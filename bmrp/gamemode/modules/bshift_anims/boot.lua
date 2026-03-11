local MODULE = MODULE

MODULE.name = "Blue Shift Animations"
MODULE.description = "Implements Blue Shift style cinematic animations."
MODULE.author = "dayflare"

if (SERVER) then
    -- Network Strings
    util.AddNetworkString("lima_xte_doorknock")
    util.AddNetworkString("lima_xte_getup")
    util.AddNetworkString("lima_xte_weapon")
    util.AddNetworkString("lima_xte_weapon2")
    util.AddNetworkString("lima_xte_doanim")

    -- Received from Client to set weapon on entity
    net.Receive("lima_xte_weapon2", function(len, client)
        local ent = net.ReadEntity()
        local wep = net.ReadString()
        if (IsValid(ent)) then
            ent:SetNW2String("wep", wep)
        end
    end)

    -- Command Receivers (from concmds mostly, but good to have)
    net.Receive("lima_xte_getup", function(len, client)
        local p = net.ReadEntity()
        local type = net.ReadString()
        if (IsValid(p) and p == client) then
            local tele = ents.Create("xen_teleport_intro")
            if (IsValid(tele)) then
                tele:SetPos(client:GetPos())
                tele:SetOwner(client)
                tele:Spawn()
                tele:Activate()
                tele.AnimType = "fall" .. type
                tele:StartIntro(client)
            end
        end
    end)

    net.Receive("lima_xte_doanim", function(len, client)
        local p = net.ReadEntity()
        local type = net.ReadString()
        if (IsValid(p) and p == client) then
            local tele = ents.Create("xen_teleport_intro")
            if (IsValid(tele)) then
                tele:SetPos(client:GetPos())
                tele:SetOwner(client)
                tele:Spawn()
                tele:Activate()
                tele.AnimType = type
                tele:StartIntro(client)
            end
        end
    end)

    net.Receive("lima_xte_doorknock", function(len, client)
        local p = net.ReadEntity()
        local type = net.ReadString()
        if (IsValid(p) and p == client) then
            local tele = ents.Create("xen_teleport_intro")
            if (IsValid(tele)) then
                tele:SetPos(client:GetPos())
                tele:SetOwner(client)
                tele:Spawn()
                tele:Activate()
                tele.AnimType = "knock" .. type
                tele:StartIntro(client)
            end
        end
    end)


    -- Prevent weapon pickup during animation
    function MODULE:PlayerCanPickupWeapon(client, weapon)
        if (IsValid(client:GetNW2Entity("xen_teleport_effect"))) then
            local eff = client:GetNW2Entity("xen_teleport_effect")
            if (eff.AnimType != "teleport" and eff.AnimType != "fall_spawn" and eff.AnimType != "wakeup_weapon") then return false end
            if (weapon:GetParent() == eff) then return false end
        end
    end

    -- Custom hook triggered by PrePlayerPunch or net receivers
    function MODULE:PlayerKnock(client, ent, type)
        if (!ax.util:IsValidPlayer(client)) then return end

        local tele = ents.Create("xen_teleport_intro")
        if (IsValid(tele)) then
            tele:SetPos(client:GetPos())
            tele:SetOwner(client)
            tele:Spawn()
            tele:Activate()
            tele.AnimType = "knock" .. (type or "1")
            tele:StartIntro(client)
        end
    end
end

if (CLIENT) then
    CreateClientConVar("lima_xte_weapon", "weapon_crowbar", true, false, "Weapon to give on spawn animation")

    net.Receive("lima_xte_weapon", function()
        local ent = net.ReadEntity()
        timer.Simple(0.1, function()
            net.Start("lima_xte_weapon2")
            net.WriteEntity(ent)
            -- Default to weapon_crowbar if convar is missing
            local wep = GetConVar("lima_xte_weapon"):GetString()
            if (wep == "") then wep = "weapon_crowbar" end
            net.WriteString(wep)
            net.SendToServer()
        end)
    end)

    -- Language Strings
    language.Add("lima_xte", "BM FP Animations")
    language.Add("lima_xte_spawn", "Enable Spawn Animation?")
    language.Add("lima_xte_fall", "Enable Fall Animation?")
    language.Add("lima_xte_explosion", "Enable Explosion Animation?")
    language.Add("lima_xte_blunt", "Enable High Blunt Damage Animation?")
    language.Add("lima_xte_drop_weapons", "Enable Weapon Dropping?")
    language.Add("lima_xte_disable_effects", "Disable Spawn Effects?")
    language.Add("lima_xte_different_spawn", "Spawn Animation Type")
    language.Add("lima_xte_different_spawn_desc", "0 - Wake Up with weapon, 1 - Teleport, 2 - Wake Up")
    language.Add("lima_xte_godmode", "Enable Invincibility?")
    language.Add("lima_xte_speed_multiplier", "Animation Speed Multiplier")
    language.Add("lima_xte_shock", "Shock Animation Chance")
    language.Add("lima_xte_headshot", "Headshot Animation Chance")
    language.Add("lima_xte_chance_desc", "1/x. 0 - Disable")
    language.Add("lima_xte_weapon", "Spawn Weapon")
    language.Add("lima_xte_weapon_desc", "Which weapon will be given at spawn if you have first spawn animation type enabled. If empty - no weapons will be given")
    language.Add("lima_xte_notarget", "Enable No Target?")
    language.Add("lima_xte_large_damage", "Enable Fall Animation On Large Damage?")
    language.Add("lima_xte_different_screffects", "Enable Diffrent Fall Effects?")
    language.Add("lima_xte_force_chands", "Force C_Hands?")

    -- Options Menu
    hook.Add("PopulateToolMenu", "Lima_XTE", function()
        spawnmenu.AddToolMenuOption("Options", "Black Mesa", "lima_xte", "Animations", "", "", function(Panel)
            Panel:ClearControls()
            Panel:TextEntry("#lima_xte_weapon", "lima_xte_weapon")
            Panel:ControlHelp("#lima_xte_weapon_desc")

            if (!game.SinglePlayer() and !ax.client:IsAdmin() and !ax.client:IsSuperAdmin()) then
                Panel:Help("You must be an admin to change these settings.")
                return
            end

            Panel:AddControl("Checkbox", {Label = "#lima_xte_force_chands", Command = "lima_xte_force_chands"})
            Panel:AddControl("Checkbox", {Label = "#lima_xte_spawn", Command = "lima_xte_spawn"})
            Panel:AddControl("Checkbox", {Label = "#lima_xte_fall", Command = "lima_xte_fall"})
            Panel:AddControl("Checkbox", {Label = "#lima_xte_different_screffects", Command = "lima_xte_different_screffects"})
            Panel:AddControl("Checkbox", {Label = "#lima_xte_large_damage", Command = "lima_xte_large_damage"})
            Panel:AddControl("Checkbox", {Label = "#lima_xte_explosion", Command = "lima_xte_explosion"})
            Panel:AddControl("Checkbox", {Label = "#lima_xte_blunt", Command = "lima_xte_blunt"})
            Panel:AddControl("Slider", {Label = "#lima_xte_shock", min = 0, max = 10, Command = "lima_xte_shock"})
            Panel:AddControl("Slider", {Label = "#lima_xte_headshot", min = 0, max = 10, Command = "lima_xte_headshot"})
            Panel:ControlHelp("#lima_xte_chance_desc")
            Panel:AddControl("Checkbox", {Label = "#lima_xte_drop_weapons", Command = "lima_xte_drop_weapons"})
            Panel:AddControl("Checkbox", {Label = "#lima_xte_disable_effects", Command = "lima_xte_disable_effects"})
            Panel:AddControl("Slider", {Label = "#lima_xte_different_spawn", min = 0, max = 2, Command = "lima_xte_different_spawn"})
            Panel:ControlHelp("#lima_xte_different_spawn_desc")
            Panel:AddControl("Checkbox", {Label = "#lima_xte_godmode", Command = "lima_xte_godmode"})
            Panel:AddControl("Checkbox", {Label = "#lima_xte_notarget", Command = "lima_xte_notarget"})
            Panel:NumSlider("#lima_xte_speed_multiplier", "lima_xte_speed_multiplier", 0, 5, 2)
        end)
    end)

    -- Client implementation of commands
    concommand.Add("lima_xte_doorknock", function(client, cmd, args, argStr)
        if (VManip and VManip:IsActive()) then return end
        if (argStr == "") then
            client:ChatPrint("You Have To Put A Number Dude")
            return
        elseif (argStr != "1" and argStr != "2" and argStr != "3") then
            client:ChatPrint("Wrong Arguments Dude")
            return
        end
        if IsValid(client:GetNW2Entity("xen_teleport_effect")) then return end
        if !client:IsOnGround() then return end
        net.Start("lima_xte_doorknock")
        net.WriteEntity(client)
        net.WriteString(argStr)
        net.SendToServer()
    end)

    concommand.Add("lima_xte_getup", function(client, cmd, args, argStr)
        if (VManip and VManip:IsActive()) then return end
        if (argStr != "" and argStr != "1" and argStr != "2" and argStr != "3") then
            client:ChatPrint("Wrong Arguments Dude")
            return
        end
        if IsValid(client:GetNW2Entity("xen_teleport_effect")) then return end
        if !client:IsOnGround() then return end
        net.Start("lima_xte_getup")
        net.WriteEntity(client)
        net.WriteString(argStr)
        net.SendToServer()
    end)

    concommand.Add("lima_xte_doanim", function(client, cmd, args, argStr)
        if (VManip and VManip:IsActive()) then return end
        if IsValid(client:GetNW2Entity("xen_teleport_effect")) then return end
        if !client:IsOnGround() then return end
        net.Start("lima_xte_doanim")
        net.WriteEntity(client)
        net.WriteString(argStr)
        net.SendToServer()
    end)
end

-- Intercept default punch to trigger door knocking
function MODULE:PrePlayerPunch(client, trace)
    if (!ax.util:IsValidPlayer(client) or !trace or !IsValid(trace.Entity)) then return end

    if (ax.util:FindString(trace.Entity:GetClass(), "door")) then
        local weapon = client:GetActiveWeapon()
        if (IsValid(weapon) and weapon:GetClass() == "ax_hands") then
            if (SERVER) then
                hook.Run("PlayerKnock", client, trace.Entity, "1")
            end

            return false
        end
    end
end
