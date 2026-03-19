/*
    © 2025 Project Ordinance. 
    
    Unauthorized sharing, redistribution, or modification is strictly prohibited. 
    Violation of these terms will not be tolerated and may invoke consequences 
    beyond your comprehension.
    
    Seek permission from the author at riggs9162@gmx.de before proceeding—
    failure to comply could lead to dire repercussions.
    
    Proceed at your own risk.
*/

FACTION.name = "Creature"
FACTION.description = "A diverse collective of living beings that occupy the borderworld known as Xen."
FACTION.color = Color(100, 50, 200)
FACTION.isDefault = false

FACTION.models = {
    "models/player/gasmask.mdl",
    "models/player/riot.mdl",
    "models/player/swat.mdl",
    "models/player/urban.mdl"
}

FACTION.image = ax.util:GetMaterial("riggs9162/bms/ui/backgrounds/creature.png", "smooth mips")
FACTION.sortOrder = 7
FACTION.noFunding = true

FACTION_CREATURE = FACTION.index
