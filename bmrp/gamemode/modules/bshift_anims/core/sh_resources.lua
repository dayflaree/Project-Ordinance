--[[
    BShift Animations Module - Resources
    Registers sounds, particles, and convars for cinematic animations.
]]

game.AddParticles("particles/xenportal.pcf")
PrecacheParticleSystem("xen_portal_med")

local function AddSd(name, tbl, tbl2)
    sound.Add({
        name = name,
        level = tbl.l,
        pitch = tbl.p,
        channel = tbl.c,
        volume = tbl.v,
        sound = tbl2
    })
    util.PrecacheSound(name)
end

AddSd("Xen_intro_teleport", {l=80,p={95,105},v=0.9,c=CHAN_STATIC}, {
    "^tele/portal_in_01.wav", "^tele/portal_in_02.wav", "^tele/portal_in_03.wav"
})

AddSd("Interaction.BlackoutExit", {l=80,p=100,v=0.9,c=CHAN_STATIC}, {
    "bs_ia_blackoutexit.wav"
})

AddSd("BSKnockKnock_Metal", {l=70,p={95,105},v=0.8,c=CHAN_STATIC}, {
    "tele/pd_intro_doorknock.wav"
})

AddSd("BSKnockKnock_Metal_Hard", {l=75,p={95,105},v=0.9,c=CHAN_STATIC}, {
    "tele/pd_intro_doorknock_hard.wav"
})

AddSd("BSKnockKnock", {l=75,p={95,105},v=0.5,c=CHAN_STATIC}, {
    "tele/door_hit1.wav"
})

AddSd("BSKnockKnock_Squish", {l=75,p={95,105},v=0.9,c=CHAN_STATIC}, {
    "tele/flesh_squishy_impact_hard1.wav", "tele/flesh_squishy_impact_hard2.wav"
})

AddSd("BSKnockKnock_Concrete", {l=75,p={95,105},v=0.9,c=CHAN_STATIC}, {
    "tele/concrete_impact_hard1.wav", "tele/concrete_impact_hard2.wav"
})

AddSd("BSKnockKnock_Flesh", {l=75,p={95,105},v=0.9,c=CHAN_STATIC}, {
    "tele/flesh_impact_hard1.wav", "tele/flesh_impact_hard2.wav"
})

AddSd("BSKnockKnock_Glass", {l=75,p={95,105},v=0.9,c=CHAN_STATIC}, {
    "tele/glass_sheet_impact_hard1.wav", "tele/glass_sheet_impact_hard2.wav", "tele/glass_sheet_impact_hard3.wav"
})

AddSd("BS_Crash_Cloth1", {l=75,p={95,105},v=0.8,c=CHAN_STATIC}, {
    "sprintin6.wav"
}) 

AddSd("BS_Crash_Cloth2", {l=75,p={95,105},v=0.9,c=CHAN_STATIC}, {
    "sprintin7.wav"
}) 

AddSd("BS_Crash_Cloth3", {l=75,p={95,105},v=0.9,c=CHAN_STATIC}, {
    "sprintout2.wav"
}) 

AddSd("BS_Crash_Cloth4", {l=75,p={95,105},v=0.9,c=CHAN_STATIC}, {
    "sprintout3.wav"
}) 

AddSd("BS_Crash_BOEx", {l=75,p={95,105},v=0.8,c=CHAN_STATIC}, {
    "bs_ia_blackoutexit.wav"
}) 

AddSd("BS_Cloth", {l=65,p=100,v=1.2,c=CHAN_STATIC}, {
    "bs_ia_xenintro_part3.wav"
})

AddSd("BS_Cloth2", {l=65,p=100,v=1.2,c=CHAN_WEAPON}, {
    "sprintin6.wav"
})

AddSd("BS_BodyImpact", {l=75,p={95,105},v=0.9,c=CHAN_STATIC}, {
    "tele/body_medium_impact_hard4.wav", "tele/body_medium_impact_hard5.wav"
}) 

AddSd("BS_Step", {l=70,p={95,105},v=0.9,c=CHAN_AUTO}, {
    "concrete_step1.wav", "concrete_step2.wav", "concrete_step3.wav"
}) 

AddSd("tele.xen_crowbar_pickup_foley1", {l=75,p={95,105},v=0.7,c=CHAN_STATIC}, {
    "tele/xen_crowbar_pickup_foley1.wav"
}) 

AddSd("tele.xen_crowbar_pickup_foley2", {l=75,p={95,105},v=0.7,c=CHAN_STATIC}, {
    "tele/xen_crowbar_pickup_foley2.wav"
}) 

AddSd("tele.xen_crowbar_pickup", {l=75,p={95,105},v=0.7,c=CHAN_STATIC}, {
    "tele/xen_crowbar_pickup.wav"
}) 

-- Global Convars
local AddConvars = {
    ["lima_xte_spawn"] = 1,
    ["lima_xte_fall"] = 0,
    ["lima_xte_large_damage"] = 0,
    ["lima_xte_explosion"] = 1,
    ["lima_xte_blunt"] = 1,
    ["lima_xte_drop_weapons"] = 1,
    ["lima_xte_disable_effects"] = 0,
    ["lima_xte_different_spawn"] = 1,
    ["lima_xte_godmode"] = 0,
    ["lima_xte_speed_multiplier"] = 1,
    ["lima_xte_shock"] = 5,
    ["lima_xte_headshot"] = 6,
    ["lima_xte_notarget"] = 0,
    ["lima_xte_force_chands"] = 0,
    ["lima_xte_different_screffects"] = 0,
}

for k, v in pairs(AddConvars) do
    CreateConVar(k, v, {FCVAR_REPLICATED, FCVAR_ARCHIVE}) 
end

-- Precaching
if (SERVER) then
    util.PrecacheModel("models/tele/firstperson_standup.mdl")
    util.PrecacheModel("models/tele/bs_interaction_hands2.mdl")
    util.PrecacheModel("models/tele/interaction_hands2.mdl")
    util.PrecacheModel("models/tele/blackout.mdl")
    print("[BSHIFT] sh_resources.lua loaded successfully (SERVER)")
else
    print("[BSHIFT] sh_resources.lua loaded successfully (CLIENT)")
end
