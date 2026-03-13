local MODULE = MODULE

MODULE.name = "ARC9 Support"
MODULE.description = "Adds support for ARC9 attachments and weapons in an immersive way."
MODULE.author = "bruck"
MODULE.specialThanks = "Adik, Hayter, FoxxoTrystan; a lot of my work wouldn't have been possible without the ability to reference theirs :); Darsu, for helping me debug some base-specific issues."
MODULE.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]

if ( !tobool(ARC9) ) then return end

function MODULE:OnLoaded()
    if ( SERVER ) then
        -- config options
        GetConVar("arc9_hud_force_disable"):SetBool(ax.config:Get("arc9.weapons.hud", true))
        GetConVar("arc9_free_atts"):SetBool(ax.config:Get("arc9.attachments.free", false))
        GetConVar("arc9_mod_penetration"):SetBool(ax.config:Get("arc9.bullets.penetration", true))
        GetConVar("arc9_ricochet"):SetBool(ax.config:Get("arc9.bullets.ricochet", true))
        GetConVar("arc9_bullet_physics"):SetBool(ax.config:Get("arc9.bullets.physical", true))

        -- this disables ammo duping, do not change
        GetConVar("arc9_mult_defaultammo"):SetInt(0)

        GetConVar("arc9_atts_nocustomize"):SetInt(0)

        -- optional convars. feel free to delete or change as you please
        GetConVar("arc9_autosave"):SetInt(0)
        GetConVar("arc9_center_bipod"):SetInt(0)
        GetConVar("arc9_center_jam"):SetInt(0)
        GetConVar("arc9_center_reload_enable"):SetInt(0)
        GetConVar("arc9_center_firemode"):SetInt(0)
        GetConVar("arc9_center_overheat"):SetInt(0)

        -- april fools debugging was fun
        GetConVar("arc9_cruelty_reload"):SetInt(0)
    end
end
