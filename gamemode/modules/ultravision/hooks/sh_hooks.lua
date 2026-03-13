--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function HandleConfigChanged(key, oldValue, value)
    if ( !ax.ultravision ) then return end

    ax.ultravision:OnConfigChanged(key, oldValue, value)
end

-- React to config toggles immediately (especially ultravision.enabled).
hook.Add("OnConfigChanged", "ax.ultravision.ConfigChanged", HandleConfigChanged)
