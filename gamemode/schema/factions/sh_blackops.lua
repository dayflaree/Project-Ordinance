/*
    © 2025 Project Ordinance.

    Unauthorized sharing, redistribution, or modification is strictly prohibited.
    Violation of these terms will not be tolerated and may invoke consequences
    beyond your comprehension.

    Seek permission from the author at riggs9162@gmx.de before proceeding—
    failure to comply could lead to dire repercussions.

    Proceed at your own risk.
*/

FACTION.name = "Black Operations"
FACTION.description = "Black Operations is a covert paramilitary force operating under the jurisdiction of the Federal Government of the United States. Unlike traditional military branches, BlackOps units act on classified directives with complete operational secrecy, often without formal oversight or public acknowledgement. Their role within Black Mesa includes the elimination of compromised personnel, suppression of sensitive information, and extraction of critical research materials. Highly trained in infiltration, sabotage, and silent takedowns, BlackOps operatives are deployed only when deniability is paramount. Their presence signals that the situation has escalated beyond recovery — their objective is resolution, not containment."
FACTION.color = Color(30, 30, 30)
FACTION.isDefault = false

FACTION.models = {
    "models/riggs9162/bms/characters/blackops/black_operator.mdl",
    "models/riggs9162/bms/characters/blackops/black_operator_2.mdl",
    "models/riggs9162/bms/characters/blackops/black_operator_bandana.mdl",
    "models/riggs9162/bms/characters/blackops/black_operator_beanie.mdl",
    "models/riggs9162/bms/characters/blackops/black_operator_cap.mdl",
    "models/riggs9162/bms/characters/blackops/black_operator_cap_2.mdl",
    "models/riggs9162/bms/characters/blackops/black_operator_hood_2.mdl",
    "models/riggs9162/bms/characters/blackops/black_operator_mask.mdl",
    "models/riggs9162/bms/characters/blackops/black_operator_tshirt.mdl",
    "models/riggs9162/bms/characters/blackops/marine_tanker_black.mdl"
}


FACTION.image = ax.util:GetMaterial("riggs9162/bmrp/ui/backgrounds/black_operations.png", "smooth mips")
FACTION.sortOrder = 6
FACTION.noFunding = true

FACTION_BLACKOPS = FACTION.index
