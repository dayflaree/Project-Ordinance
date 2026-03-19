ax.config:Add("funding.start_global", ax.type.number, 275000000, {
    description = "Initial global funding balance when no persisted data exists.",
    category = "economy",
    subCategory = "funding",
    min = 0,
    max = 1000000000,
    decimals = 0
})

local factionDefaults = {
    administrative_department = 75000000,
    research_and_development = 120000000,
    security_division = 40000000,
    service_personel = 15000000
}

for id, default in pairs(factionDefaults) do
    ax.config:Add("funding.start_faction." .. id, ax.type.number, default, {
        description = "Starter funding for faction '" .. id .. "' when no data exists.",
        category = "economy",
        subCategory = "funding",
        min = 0,
        max = 1000000000,
        decimals = 0
    })
end