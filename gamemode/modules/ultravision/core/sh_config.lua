--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add("ultravision.enabled", ax.type.bool, true, {
    category = "modules",
    subCategory = "ultravision",
    description = "config.ultravision.enabled.help"
})

ax.config:Add("ultravision.radius", ax.type.number, 220, {
    category = "modules",
    subCategory = "ultravision",
    description = "config.ultravision.radius.help",
    min = 64,
    max = 1024,
    decimals = 0
})

ax.config:Add("ultravision.brightness", ax.type.number, 0.6, {
    category = "modules",
    subCategory = "ultravision",
    description = "config.ultravision.brightness.help",
    min = 0.05,
    max = 3,
    decimals = 2
})

ax.config:Add("ultravision.decay", ax.type.number, 120, {
    category = "modules",
    subCategory = "ultravision",
    description = "config.ultravision.decay.help",
    min = 10,
    max = 3000,
    decimals = 0
})

ax.config:Add("ultravision.dietime", ax.type.number, 0.12, {
    category = "modules",
    subCategory = "ultravision",
    description = "config.ultravision.dietime.help",
    min = 0.05,
    max = 1,
    decimals = 2
})

ax.config:Add("ultravision.minInterval", ax.type.number, 0.05, {
    category = "modules",
    subCategory = "ultravision",
    description = "config.ultravision.minInterval.help",
    min = 0.01,
    max = 0.5,
    decimals = 2
})
