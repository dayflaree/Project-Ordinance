ITEM.name = "Base Keycard"
ITEM.description = "A base clearance keycard item. This item is not meant to be spawned directly."
ITEM.model = Model("models/props_lab/clipboard.mdl")
ITEM.category = "Keycards"
ITEM.weight = 0.05
ITEM.price = 0

ITEM.shouldStack = false
ITEM.maxStack = 1

ITEM.isKeycard = true
ITEM.clearanceLevel = CLEARANCE_LEVEL_1

function ITEM:GetClearanceLevel()
    return ax.clearance:Normalize(self.clearanceLevel, 0)
end

function ITEM:IsBroken()
    return self:GetData("broken", self:GetData("isBroken", false)) == true
end
