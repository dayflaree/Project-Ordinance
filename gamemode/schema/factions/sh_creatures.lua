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
FACTION.description = "A diverse collective of living beings, the Creatures are best understood by looking at their three distinct groups. First are the Xenian forms, organisms from a distant realm whose unusual biology continues to pique scientific interest. Next are the Race-X entities, mysterious in origin with traits that defy easy explanation. Finally, the Terrestrial Adapted consist of native Earth species that have evolved remarkable adaptations under extraordinary conditions. Together, these groups form a community that challenges our understanding of life and evolution."
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
