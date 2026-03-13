--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Add a client customization option for Scapes playback.
-- @tparam table definition Option definition table.
local function AddScapesOption(definition)
    local data = {
        category = "audio",
        subCategory = "scapes",
        description = definition.description,
        bNoNetworking = true,
    }

    if ( definition.min != nil ) then
        data.min = definition.min
    end

    if ( definition.max != nil ) then
        data.max = definition.max
    end

    if ( definition.decimals != nil ) then
        data.decimals = definition.decimals
    end

    ax.option:Add(definition.key, definition.type, definition.default, data)
end

local OPTIONS = {
    {
        key = "scapes.enabled",
        type = ax.type.bool,
        default = true,
        description = "option.scapes.enabled.help",
    },
    {
        key = "scapes.master_volume",
        type = ax.type.number,
        default = 1,
        min = 0,
        max = 1,
        decimals = 2,
        description = "option.scapes.master_volume.help",
    },
    {
        key = "scapes.loop_volume",
        type = ax.type.number,
        default = 1,
        min = 0,
        max = 1,
        decimals = 2,
        description = "option.scapes.loop_volume.help",
    },
    {
        key = "scapes.random_volume",
        type = ax.type.number,
        default = 1,
        min = 0,
        max = 1,
        decimals = 2,
        description = "option.scapes.random_volume.help",
    },
    {
        key = "scapes.stinger_volume",
        type = ax.type.number,
        default = 1,
        min = 0,
        max = 1,
        decimals = 2,
        description = "option.scapes.stinger_volume.help",
    },
    {
        key = "scapes.ambient_volume",
        type = ax.type.number,
        default = 1,
        min = 0,
        max = 1,
        decimals = 2,
        description = "option.scapes.ambient_volume.help",
    },
    {
        key = "scapes.positional_volume",
        type = ax.type.number,
        default = 1,
        min = 0,
        max = 1,
        decimals = 2,
        description = "option.scapes.positional_volume.help",
    },
    {
        key = "scapes.loop_drift_scale",
        type = ax.type.number,
        default = 1,
        min = 0,
        max = 2,
        decimals = 2,
        description = "option.scapes.loop_drift_scale.help",
    },
    {
        key = "scapes.pause_legacy_music",
        type = ax.type.bool,
        default = true,
        description = "option.scapes.pause_legacy_music.help",
    },
    {
        key = "scapes.occlusion_enabled",
        type = ax.type.bool,
        default = true,
        description = "option.scapes.occlusion_enabled.help",
    },
    {
        key = "scapes.occlusion_strength",
        type = ax.type.number,
        default = 1,
        min = 0,
        max = 2,
        decimals = 2,
        description = "option.scapes.occlusion_strength.help",
    },
    {
        key = "scapes.debug_overlay",
        type = ax.type.bool,
        default = false,
        description = "option.scapes.debug_overlay.help",
    },
    {
        key = "scapes.debug_events",
        type = ax.type.number,
        default = 5,
        min = 1,
        max = 20,
        decimals = 0,
        description = "option.scapes.debug_events.help",
    },
}

for i = 1, #OPTIONS do
    AddScapesOption(OPTIONS[i])
end
