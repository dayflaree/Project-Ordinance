ITEM.name = "ARC9 Attachment"
ITEM.description = "ARC9 attachment base."
ITEM.category = "ARC9 Attachments"
ITEM.model = "models/items/arc9/att_cardboard_box.mdl"
ITEM.width = 1
ITEM.height = 1

ITEM.isARC9Attachment = true
ITEM.att = "undefined"              -- id of the attachment this item is linked to
ITEM.tool = nil                     -- item unique id of the tool needed to use the attachment on a weapon

function ITEM:GetAttachment()
    if self.att then
        local atttbl = ARC9.GetAttTable(self.att)
        if atttbl then
            if atttbl.InvAtt then
                return atttbl.InvAtt, atttbl
            else
                return self.att, atttbl
            end
        end
    end

    return "undefined", nil
end

function ITEM:HasTool(client)
    if self.tool == nil then return true end
    if ax.config:Get("arc9.attachments.free", false) then return true end

    local inventory = client:GetCharacter():GetInventory()
    if !inventory then return false end

    -- Check if inventory has the tool item
    for itemID, itemObj in pairs(inventory.items or {}) do
        if itemObj.class == self.tool then
            return true
        end
    end

    return false
end
