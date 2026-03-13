/*
    © 2025 Project Ordinance.

    Unauthorized sharing, redistribution, or modification is strictly prohibited.
    Violation of these terms will not be tolerated and may invoke consequences
    beyond your comprehension.

    Seek permission from the author at riggs9162@gmx.de before proceeding—
    failure to comply could lead to dire repercussions.

    Proceed at your own risk.
*/

FACTION.name = "Security Division"
FACTION.description = "The Security Division is the vigilant backbone of Black Mesa, entrusted with safeguarding every corridor and sector of the facility. Operating on distinct colored shifts that designate responsibility for specific areas, these officers carry clearance levels averaging around Level 3 and stand as the final arbiters at controlled access points and security checkpoints. After reporting to their assigned facilities and settling into secure quarters, they don their standard blue uniforms complete with black ties, dark blue pants, assault boots, and protective gear, while being armed with a range of weaponry from reliable sidearms to heavier ordnance—ever prepared to enforce protocol and maintain order."
FACTION.color = Color(25, 25, 170, 255)
FACTION.isDefault = true

FACTION.models = {
    "models/riggs9162/bms/characters/guard.mdl",
    "models/riggs9162/bms/characters/guard_02.mdl",
    "models/riggs9162/bms/characters/guard_03.mdl",
    "models/riggs9162/bms/characters/guard_04.mdl",
    "models/riggs9162/bms/characters/guard_otis.mdl",
    "models/riggs9162/bms/characters/guard_female.mdl"
}

FACTION.image = ax.util:GetMaterial("riggs9162/bms/ui/backgrounds/legacy/security_division.png", "smooth mips")
FACTION.sortOrder = 3

function FACTION:ModifyPlayerStep(client, data)
    if ( data.ladder or data.submerged ) then return end

    data.extraSounds.snd = "riggs9162/bms/footsteps/foley/foley-" .. ax.util:ZeroNumber(math.random(16), 2) .. ".mp3"

    if ( data.running ) then
        data.extraSounds.volume = 0.25
    else
        data.extraSounds.volume = 0.125
    end

    return true
end

FACTION_SECURITY = FACTION.index
