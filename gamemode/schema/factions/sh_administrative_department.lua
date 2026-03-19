/*
    © 2025 Project Ordinance. 
    
    Unauthorized sharing, redistribution, or modification is strictly prohibited. 
    Violation of these terms will not be tolerated and may invoke consequences 
    beyond your comprehension.
    
    Seek permission from the author at riggs9162@gmx.de before proceeding—
    failure to comply could lead to dire repercussions.
    
    Proceed at your own risk.
*/

FACTION.name = "Administrative Department"
FACTION.description = "The Administrative Department is the governing body of Black Mesa, responsible for overseeing the facility's day-to-day operations."
FACTION.color = Color(150, 200, 200, 255)
FACTION.isDefault = true

FACTION.models = {
    "models/riggs9162/bms/characters/admin_male.mdl",
    "models/riggs9162/bms/characters/admin_male02.mdl",
    "models/riggs9162/bms/characters/admin_female.mdl"
}

FACTION.image = ax.util:GetMaterial("riggs9162/bms/ui/backgrounds/administrative_department.png", "smooth mips")
FACTION.sortOrder = 4
FACTION.viewResearchTree = true
FACTION.assignResearch = true

FACTION_ADMINISTRATION = FACTION.index
