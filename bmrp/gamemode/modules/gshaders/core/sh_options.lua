--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Check if gshaders addon is available before creating options
local gshaderLib = GetConVar("r_shaderlib")
if ( !gshaderLib ) then
    ax.util:PrintDebug("GShaders addon not detected, skipping shader options")
    return
end

local function AddShaderOption(definition)
    local convar = GetConVar(definition.convar)
    if ( !convar ) then
        ax.util:PrintWarning("Shader convar '" .. definition.convar .. "' not found, skipping option '" .. definition.option .. "'")
        return
    end

    local optionData = {
        category = "visual",
        subCategory = "shaders",
        description = definition.desc,
        bNoNetworking = true
    }

    if ( definition.min != nil ) then
        optionData.min = definition.min
    end

    if ( definition.max != nil ) then
        optionData.max = definition.max
    end

    if ( definition.decimals != nil ) then
        optionData.decimals = definition.decimals
    end

    ax.option:Add(definition.option, definition.type, definition.default, optionData)
    ax.util:PrintDebug("Created shader option: " .. definition.option .. " for convar: " .. definition.convar)
end

-- Keep this in sync with installed shaders from the shared addons/shaders workspace.
local shaderOptions = {
    -- General shader toggles
    { convar = "r_csm", option = "shaderCSM", desc = "shaderCSM.help", type = ax.type.bool, default = false },
    { convar = "r_fxaa", option = "shaderFXAA", desc = "shaderFXAA.help", type = ax.type.bool, default = false },
    { convar = "pp_pbb", option = "shaderPhysicallyBasedBloom", desc = "shaderPhysicallyBasedBloom.help", type = ax.type.bool, default = false },
    { convar = "r_smaa", option = "shaderSMAA", desc = "shaderSMAA.help", type = ax.type.bool, default = false },
    { convar = "pp_ssao_plus", option = "shaderSSAO", desc = "shaderSSAO.help", type = ax.type.bool, default = false },
    { convar = "r_ssr", option = "shaderSSR", desc = "shaderSSR.help", type = ax.type.bool, default = false },
    { convar = "r_motionblur", option = "shaderMotionBlur", desc = "shaderMotionBlur.help", type = ax.type.bool, default = false },
    { convar = "r_sharpness", option = "shaderSharpness", desc = "shaderSharpness.help", type = ax.type.bool, default = false },
    { convar = "r_ddof_gshader", option = "shaderDDOF", desc = "shaderDDOF.help", type = ax.type.bool, default = false },
    { convar = "r_volumetric_light", option = "shaderVolumetricLight", desc = "shaderVolumetricLight.help", type = ax.type.bool, default = false },

    -- SSR specific tuning
    { convar = "r_ssr_stencil", option = "shaderSSRStencil", desc = "shaderSSRStencil.help", type = ax.type.bool, default = true },
    { convar = "r_ssr_nomaks", option = "shaderSSRNoMask", desc = "shaderSSRNoMask.help", type = ax.type.bool, default = false },
    { convar = "r_ssr_debug", option = "shaderSSRDebug", desc = "shaderSSRDebug.help", type = ax.type.bool, default = false },

    { convar = "r_ssr_quality", option = "shaderSSRQuality", desc = "shaderSSRQuality.help", type = ax.type.number, default = 2, min = 1, max = 3, decimals = 0 },
    { convar = "r_ssr_intensity", option = "shaderSSRIntensity", desc = "shaderSSRIntensity.help", type = ax.type.number, default = 4, min = 0.25, max = 20, decimals = 2 },
    { convar = "r_ssr_stencil_intensity", option = "shaderSSRStencilIntensity", desc = "shaderSSRStencilIntensity.help", type = ax.type.number, default = 4, min = 0.25, max = 20, decimals = 2 },
    { convar = "r_ssr_luma", option = "shaderSSRLuma", desc = "shaderSSRLuma.help", type = ax.type.number, default = 1, min = 0, max = 20, decimals = 2 },
    { convar = "r_ssr_distance", option = "shaderSSRDistance", desc = "shaderSSRDistance.help", type = ax.type.number, default = 5000, min = 192, max = 20000, decimals = 0 },
    { convar = "r_ssr_length", option = "shaderSSRLength", desc = "shaderSSRLength.help", type = ax.type.number, default = 14, min = 1, max = 46, decimals = 0 },
    { convar = "r_ssr_contrast", option = "shaderSSRContrast", desc = "shaderSSRContrast.help", type = ax.type.number, default = 0, min = 0, max = 1, decimals = 2 },

    { convar = "r_ssr_saturation_r", option = "shaderSSRSaturationR", desc = "shaderSSRSaturationR.help", type = ax.type.number, default = 255, min = 0, max = 255, decimals = 0 },
    { convar = "r_ssr_saturation_g", option = "shaderSSRSaturationG", desc = "shaderSSRSaturationG.help", type = ax.type.number, default = 255, min = 0, max = 255, decimals = 0 },
    { convar = "r_ssr_saturation_b", option = "shaderSSRSaturationB", desc = "shaderSSRSaturationB.help", type = ax.type.number, default = 255, min = 0, max = 255, decimals = 0 },
    { convar = "r_ssr_tint_r", option = "shaderSSRTintR", desc = "shaderSSRTintR.help", type = ax.type.number, default = 128, min = 0, max = 255, decimals = 0 },
    { convar = "r_ssr_tint_g", option = "shaderSSRTintG", desc = "shaderSSRTintG.help", type = ax.type.number, default = 128, min = 0, max = 255, decimals = 0 },
    { convar = "r_ssr_tint_b", option = "shaderSSRTintB", desc = "shaderSSRTintB.help", type = ax.type.number, default = 128, min = 0, max = 255, decimals = 0 }
}

for _, definition in ipairs(shaderOptions) do
    AddShaderOption(definition)
end
