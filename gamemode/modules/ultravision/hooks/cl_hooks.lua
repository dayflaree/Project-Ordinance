--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function HandleThink()
    if ( !ax.ultravision ) then return end

    -- Reapply short-lived DynamicLight while server state says ultravision is active.
    ax.ultravision:UpdateDynamicLight()
end

local function HandleInitPostEntity()
    if ( !ax.ultravision ) then return end

    ax.ultravision:SetActive(false)
end

hook.Add("PostRender", "ax.ultravision.DynamicLight", HandleThink)
hook.Add("InitPostEntity", "ax.ultravision.InitPostEntity", HandleInitPostEntity)
