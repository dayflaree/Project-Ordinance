local MODULE = MODULE

function MODULE:RequestCatalog()
    local payload = {}
    payload.categories = {}
    for _, category in ipairs(self.catalog:GetCategories()) do
        table.insert(payload.categories, {
            id = category.id,
            name = category.name,
            items = category.items
        })
    end
    return payload
end

function MODULE:SendPurchaseRequest(itemId)
    if (not itemId or itemId == "") then return end
    ax.net:Start("prop_placement.purchase", itemId)
end