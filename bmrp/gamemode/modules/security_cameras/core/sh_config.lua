ax.config:Add("security.cameras.monochrome", ax.type.bool, false, {
    category = "interface",
    subCategory = "security cameras",
    description = "Render security camera feeds in black and white."
})

ax.config:Add("security.cameras.interact_distance", ax.type.number, 128, {
    category = "interface",
    subCategory = "security cameras",
    description = "Maximum distance (in units) to interact with a security station."
})
