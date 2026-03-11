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
FACTION.description = "The Administrative Department is the governing body of Black Mesa, responsible for overseeing the facility's day-to-day operations. Comprised of a diverse array of scientists, security personnel, and other specialists, this group is tasked with ensuring that the facility runs smoothly and efficiently. The Administrative Department is also responsible for managing the facility's research projects, allocating resources, and maintaining communication with the outside world. Although the Administrative Department is often seen as the public face of Black Mesa, its members are also responsible for handling sensitive information and making difficult decisions that affect the entire facility."
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
