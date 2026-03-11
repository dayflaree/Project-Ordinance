--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.localization:Register("en", {
    ["subcategory.ultravision"] = "Ultravision",

    ["config.ultravision.enabled"] = "Enabled",
    ["config.ultravision.enabled.help"] = "Enable or disable Ultravision entirely.",

    ["config.ultravision.radius"] = "Glow Radius",
    ["config.ultravision.radius.help"] = "Radius of the local guiding light while active.",

    ["config.ultravision.brightness"] = "Glow Brightness",
    ["config.ultravision.brightness.help"] = "Brightness of the local guiding light while active.",

    ["config.ultravision.decay"] = "Glow Decay",
    ["config.ultravision.decay.help"] = "How fast the dynamic light decays each refresh cycle.",

    ["config.ultravision.dietime"] = "Glow Dietime",
    ["config.ultravision.dietime.help"] = "Lifetime in seconds for each dynamic light refresh.",

    ["config.ultravision.minInterval"] = "Refresh Interval",
    ["config.ultravision.minInterval.help"] = "Minimum seconds between dynamic light refreshes."
})
