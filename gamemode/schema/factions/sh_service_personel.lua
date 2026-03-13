/*
    (c) 2025 Project Ordinance.

    Unauthorized sharing, redistribution, or modification is strictly prohibited.
    Violation of these terms will not be tolerated and may invoke consequences.

    Seek permission from the author at riggs9162@gmx.de before proceeding.
*/

FACTION.name = "Maintenance and Service Department"
FACTION.description = "The Maintenance and Service Department keeps Black Mesa operational through two coordinated divisions: Maintenance and Service. Maintenance handles sanitation, systems repair, and infrastructure restoration. Service handles medical response, logistics, and day-to-day support coverage across the site. Department leadership is handled by divisional supervisors and a department director."
FACTION.color = Color(200, 100, 100, 255)
FACTION.isDefault = true

FACTION.models = {
    "models/riggs9162/bms/characters/custodian.mdl",
    "models/riggs9162/bms/characters/custodian_female.mdl"
}

FACTION.image = ax.util:GetMaterial("riggs9162/bms/ui/backgrounds/service_personnel.png", "smooth mips")
FACTION.sortOrder = 1

FACTION_SERVICE = FACTION.index
