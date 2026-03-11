
-- personally i think autogeneration is inefficient and can create spotty results under the best of conditions
ax.config:Add("arc9.attachments.generate", ax.type.bool, false, {
    description = "Whether or not ARC9 attachments will have items created automatically. This can take a while with a lot of packs.",
    category = "arc9",
    OnChanged = function(oldValue, newValue)
        if ( newValue and !ax.arc9.attachmentsGenerated ) then
            ax.arc9:GenerateAttachments()
            RunConsoleCommand("spawnmenu_reload") -- in case any item spawnmenu tabs are installed
        end
    end
})

ax.config:Add("arc9.weapons.generate", ax.type.bool, false, {
    description = "Whether or not ARC9 weapons will have items created automatically. This can take a while with a lot of packs.",
    category = "arc9",
    OnChanged = function(oldValue, newValue)
        if ( newValue and !ax.arc9.weaponsGenerated ) then
            ax.arc9:GenerateWeapons()
            RunConsoleCommand("spawnmenu_reload")
        end
    end
})

ax.config:Add("arc9.attachments.free", ax.type.bool, false, {
    description = "Whether or not the ARC9 attachments are free to use, and do not require inventory items.",
    category = "arc9",
    OnChanged = function(oldValue, newValue)
        if ( SERVER ) then
            GetConVar("arc9_free_atts"):SetBool(newValue)
        end
    end
})

ax.config:Add("arc9.weapons.hud", ax.type.bool, true, {
    description = "Whether or not the ARC9 ammo and weapon HUD should show for players with ARC9 weapons.",
    category = "arc9",
    OnChanged = function(oldValue, newValue)
        if ( SERVER ) then
            GetConVar("arc9_hud_force_disable"):SetBool(newValue)
        end
    end
})

ax.config:Add("arc9.weapons.benches", ax.type.bool, true, {
    description = "Whether or not players must use an ARC9 Support Weapon Bench to customize their weapons.",
    category = "arc9",
    OnChanged = function(oldValue, newValue)
        if ( SERVER ) then
            GetConVar("arc9_enable_weapon_benches"):SetBool(newValue)
        end
    end
})

ax.config:Add("arc9.bullets.penetration", ax.type.bool, true, {
    description = "Whether or not ARC9 bullets can pierce world brushes and other objects.",
    category = "arc9",
    OnChanged = function(oldValue, newValue)
        if ( SERVER ) then
            GetConVar("arc9_mod_penetration"):SetBool(newValue)
        end
    end
})

ax.config:Add("arc9.bullets.ricochet", ax.type.bool, true, {
    description = "Whether or not ARC9 bullets can ricochet off of hard surfaces and potentially hit entities in the area.",
    category = "arc9",
    OnChanged = function(oldValue, newValue)
        if ( SERVER ) then
            GetConVar("arc9_ricochet"):SetBool(newValue)
        end
    end
})

ax.config:Add("arc9.bullets.physical", ax.type.bool, true, {
    description = "Whether or not ARC9 bullets are subject to physics, such as travel time and bullet drop.",
    category = "arc9",
    OnChanged = function(oldValue, newValue)
        if ( SERVER ) then
            GetConVar("arc9_bullet_physics"):SetBool(newValue)
        end
    end
})

ax.config:Add("arc9.always.raised", ax.type.bool, false, {
    description = "Whether or not ARC9 weapons can be raised and lowered. ARC9 isn't design to use holstering, so if TPIK is on you may want to have this enabled.",
    category = "arc9",
    OnChanged = function(oldValue, newValue)
        ax.arc9:SetAlwaysRaised()

        -- automatically raises any held ARC9 weapons if set to true
        if ( SERVER and newValue ) then
            for _, v in player.Iterator() do
                local weapon = v:GetActiveWeapon()
                if ( weapons.IsBasedOn(weapon:GetClass(), "arc9_base") and !v:IsWeaponRaised() ) then
                    v:SetWeaponRaised(true, weapon)
                end
            end
        end
    end
})

if ( CLIENT ) then
    ax.option:Add("arc9.weapons.benches.tooltip", ax.type.bool, false, {
        category = "arc9",
    })
end
