/*
    © 2025 Project Ordinance. 
    
    Unauthorized sharing, redistribution, or modification is strictly prohibited. 
    Violation of these terms will not be tolerated and may invoke consequences 
    beyond your comprehension.
    
    Seek permission from the author at riggs9162@gmx.de before proceeding—
    failure to comply could lead to dire repercussions.
    
    Proceed at your own risk.
*/

FACTION.name = "Research & Development"
FACTION.description = "The Science Team is a diverse collective of innovators pushing the boundaries of knowledge in research fields as varied as particle physics, xenobiology, and space travel. United by a relentless pursuit of discovery, these scientists work tirelessly in high-stakes laboratories and hazardous environments alike, devising breakthrough technologies and conducting experiments that challenge conventional wisdom. With each member contributing a unique perspective and a commitment to safety during complex operations, the team embodies Black Mesa's spirit of scientific excellence and resilience in the face of extraordinary challenges."
FACTION.color = Color(80, 80, 80, 255)
FACTION.isDefault = true

FACTION.models = {
    "models/riggs9162/bms/characters/scientist.mdl",
    "models/riggs9162/bms/characters/scientist_02.mdl",
    "models/riggs9162/bms/characters/scientist_03.mdl",
    "models/riggs9162/bms/characters/scientist_04.mdl",
    "models/riggs9162/bms/characters/scientist_cl.mdl",
    "models/riggs9162/bms/characters/scientist_cl_02.mdl",
    "models/riggs9162/bms/characters/scientist_cl_03.mdl",
    "models/riggs9162/bms/characters/scientist_cl_04.mdl",
    "models/riggs9162/bms/characters/scientist_fat.mdl",
    "models/riggs9162/bms/characters/scientist_female.mdl"
}

FACTION.image = ax.util:GetMaterial("riggs9162/bms/ui/backgrounds/research_and_development.png", "smooth mips")
FACTION.sortOrder = 2
FACTION.viewResearchTree = true

FACTION_SCIENCE = FACTION.index
