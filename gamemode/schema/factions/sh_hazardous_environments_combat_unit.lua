/*
    © 2025 Project Ordinance.

    Unauthorized sharing, redistribution, or modification is strictly prohibited.
    Violation of these terms will not be tolerated and may invoke consequences
    beyond your comprehension.

    Seek permission from the author at riggs9162@gmx.de before proceeding—
    failure to comply could lead to dire repercussions.

    Proceed at your own risk.
*/

FACTION.name = "Hazardous Environment Combat Unit"
FACTION.description = "The Hazardous Environment Combat Unit (HECU) is a specialized detachment of the United States Marine Corps."
FACTION.color = Color(60, 100, 70)
FACTION.isDefault = false

FACTION.models = {
    "models/riggs9162/bms/characters/marine.mdl",
    "models/riggs9162/bms/characters/marine_02.mdl"
}

FACTION.image = ax.util:GetMaterial("riggs9162/bms/ui/backgrounds/hazardous_environments_combat_unit.png", "smooth mips")
FACTION.sortOrder = 5
FACTION.noFunding = true

FACTION_HECU = FACTION.index
