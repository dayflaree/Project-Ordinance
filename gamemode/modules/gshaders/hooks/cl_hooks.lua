--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Check if gshaders addon is available before loading module functionality
local gshaderLib = GetConVar("r_shaderlib")
if ( !gshaderLib ) then
    ax.util:PrintDebug("GShaders addon not detected, skipping shader hooks")
    return
end

local MODULE = MODULE

local function GetSafeConVar(name)
    local cvar = GetConVar(name)
    if ( !cvar ) then
        ax.util:PrintWarning("Shader convar '" .. name .. "' not found")
    end

    return cvar
end

local function SafeSetConVar(cvar, value)
    if ( !cvar or value == nil ) then
        return
    end

    if ( isbool(value) ) then
        cvar:SetInt(value and 1 or 0)
        return
    end

    if ( isnumber(value) ) then
        cvar:SetFloat(value)
        return
    end
end

local shaderBindings = {
    shaderCSM = { cvar = GetSafeConVar("r_csm"), isToggle = true },
    shaderFXAA = { cvar = GetSafeConVar("r_fxaa"), isToggle = true },
    shaderPhysicallyBasedBloom = { cvar = GetSafeConVar("pp_pbb"), isToggle = true },
    shaderSMAA = { cvar = GetSafeConVar("r_smaa"), isToggle = true },
    shaderSSAO = { cvar = GetSafeConVar("pp_ssao_plus"), isToggle = true },
    shaderSSR = { cvar = GetSafeConVar("r_ssr"), isToggle = true },
    shaderMotionBlur = { cvar = GetSafeConVar("r_motionblur"), isToggle = true },
    shaderSharpness = { cvar = GetSafeConVar("r_sharpness"), isToggle = true },
    shaderDDOF = { cvar = GetSafeConVar("r_ddof_gshader"), isToggle = true },
    shaderVolumetricLight = { cvar = GetSafeConVar("r_volumetric_light"), isToggle = true },

    shaderSSRStencil = { cvar = GetSafeConVar("r_ssr_stencil") },
    shaderSSRNoMask = { cvar = GetSafeConVar("r_ssr_nomaks") },
    shaderSSRDebug = { cvar = GetSafeConVar("r_ssr_debug") },
    shaderSSRQuality = { cvar = GetSafeConVar("r_ssr_quality") },
    shaderSSRIntensity = { cvar = GetSafeConVar("r_ssr_intensity") },
    shaderSSRStencilIntensity = { cvar = GetSafeConVar("r_ssr_stencil_intensity") },
    shaderSSRLuma = { cvar = GetSafeConVar("r_ssr_luma") },
    shaderSSRDistance = { cvar = GetSafeConVar("r_ssr_distance") },
    shaderSSRLength = { cvar = GetSafeConVar("r_ssr_length") },
    shaderSSRContrast = { cvar = GetSafeConVar("r_ssr_contrast") },
    shaderSSRSaturationR = { cvar = GetSafeConVar("r_ssr_saturation_r") },
    shaderSSRSaturationG = { cvar = GetSafeConVar("r_ssr_saturation_g") },
    shaderSSRSaturationB = { cvar = GetSafeConVar("r_ssr_saturation_b") },
    shaderSSRTintR = { cvar = GetSafeConVar("r_ssr_tint_r") },
    shaderSSRTintG = { cvar = GetSafeConVar("r_ssr_tint_g") },
    shaderSSRTintB = { cvar = GetSafeConVar("r_ssr_tint_b") }
}

local function VerifyShaderLib()
    for optionKey, binding in pairs(shaderBindings) do
        if ( !binding.isToggle ) then
            continue
        end

        local value = ax.option:Get(optionKey)
        if ( value != nil and binding.cvar and value ) then
            return true
        end
    end

    return false
end

function MODULE:OnOptionChanged(key)
    local binding = shaderBindings[key]
    if ( !binding or !binding.cvar ) then
        return
    end

    local shouldEnable = VerifyShaderLib()
    SafeSetConVar(gshaderLib, shouldEnable and 1 or 0)

    local value = ax.option:Get(key)
    SafeSetConVar(binding.cvar, value)
end

function MODULE:OnOptionsLoaded()
    local shouldEnable = VerifyShaderLib()
    SafeSetConVar(gshaderLib, shouldEnable and 1 or 0)

    for optionKey, binding in pairs(shaderBindings) do
        local value = ax.option:Get(optionKey)
        if ( value != nil ) then
            SafeSetConVar(binding.cvar, value)
        end
    end
end
