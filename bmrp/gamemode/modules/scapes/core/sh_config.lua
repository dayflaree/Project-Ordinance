--[[
    Project Ordinance
    Copyright (c) 2025-2026 Project Ordinance Contributors

    This file is part of Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add("audio.scapes.enabled", ax.type.bool, true, {
    category = "map",
    subCategory = "scapes",
    description = "Enable the Scapes ambience system.",
})

ax.config:Add("audio.scapes.pause_legacy_music", ax.type.bool, true, {
    category = "map",
    subCategory = "scapes",
    description = "Fallback behavior for pausing legacy ambient music when a scape does not override it.",
})

ax.config:Add("audio.scapes.dsp_enabled", ax.type.bool, true, {
    category = "map",
    subCategory = "scapes",
    description = "Enable DSP preset application for active Scapes sessions.",
})

ax.config:Add("audio.scapes.dsp_default", ax.type.number, 1, {
    category = "map",
    subCategory = "scapes",
    description = "Default DSP preset restored when a Scapes session ends.",
    min = 0,
    max = 255,
    decimals = 0,
})

ax.config:Add("audio.scapes.dsp_default_fast_reset", ax.type.bool, false, {
    category = "map",
    subCategory = "scapes",
    description = "Use fast reset behavior when restoring default DSP after Scapes deactivation.",
})

ax.config:Add("audio.scapes.occlusion_enabled", ax.type.bool, true, {
    category = "map",
    subCategory = "scapes",
    description = "Enable wall-thickness based volume attenuation for positional Scapes sounds.",
})

ax.config:Add("audio.scapes.occlusion_thickness_scale", ax.type.number, 96, {
    category = "map",
    subCategory = "scapes",
    description = "Approximate wall thickness in Hammer units required to reach maximum Scapes occlusion loss.",
    min = 16,
    max = 512,
    decimals = 0,
})

ax.config:Add("audio.scapes.occlusion_max_volume_loss", ax.type.number, 0.92, {
    category = "map",
    subCategory = "scapes",
    description = "Maximum volume reduction applied by Scapes wall occlusion.",
    min = 0,
    max = 1,
    decimals = 2,
})

ax.config:Add("audio.scapes.use_priority", ax.type.bool, false, {
    category = "map",
    subCategory = "scapes",
    description = "Enable priority checks when activating scapes. When disabled, newest activation always replaces the current one.",
})

ax.config:Add("audio.scapes.schedule_window", ax.type.number, 20, {
    category = "map",
    subCategory = "scapes",
    description = "How many seconds ahead the server schedules random events.",
    min = 4,
    max = 120,
    decimals = 0,
})

ax.config:Add("audio.scapes.schedule_refill_interval", ax.type.number, 4, {
    category = "map",
    subCategory = "scapes",
    description = "How often the server checks whether schedule data should be refilled.",
    min = 0.1,
    max = 30,
    decimals = 1,
})

ax.config:Add("audio.scapes.schedule_refill_threshold", ax.type.number, 8, {
    category = "map",
    subCategory = "scapes",
    description = "When remaining scheduled time falls below this threshold, more events are generated.",
    min = 1,
    max = 60,
    decimals = 0,
})

ax.config:Add("audio.scapes.batch_events", ax.type.number, 48, {
    category = "map",
    subCategory = "scapes",
    description = "Maximum number of random events sent in one incremental schedule payload.",
    min = 8,
    max = 256,
    decimals = 0,
})

ax.config:Add("audio.scapes.net_lead_time", ax.type.number, 0.25, {
    category = "map",
    subCategory = "scapes",
    description = "Lead time in seconds added before server-authored events are due on clients.",
    min = 0.05,
    max = 3,
    decimals = 2,
})

ax.config:Add("audio.scapes.auto_trigger_from_map", ax.type.bool, true, {
    category = "map",
    subCategory = "scapes",
    description = "Automatically trigger scapes from original env_soundscape locations parsed via NikNaks.",
})

ax.config:Add("audio.scapes.auto_trigger_interval", ax.type.number, 0.75, {
    category = "map",
    subCategory = "scapes",
    description = "How often the server reevaluates player position for map soundscape auto-triggering.",
    min = 0.1,
    max = 10,
    decimals = 2,
})

ax.config:Add("audio.scapes.auto_trigger_hysteresis", ax.type.number, 0.08, {
    category = "map",
    subCategory = "scapes",
    description = "Stickiness threshold to avoid rapid switching between overlapping soundscape radii.",
    min = 0,
    max = 1,
    decimals = 2,
})

ax.config:Add("audio.scapes.auto_trigger_sticky_fallback", ax.type.bool, true, {
    category = "map",
    subCategory = "scapes",
    description = "Keep the last auto-triggered scape active after leaving all parsed soundscape radii.",
})

ax.config:Add("audio.scapes.auto_trigger_exit_delay", ax.type.number, 1.0, {
    category = "map",
    subCategory = "scapes",
    description = "Delay before deactivating an auto-triggered scape after leaving all soundscape radii.",
    min = 0,
    max = 10,
    decimals = 2,
})

ax.config:Add("audio.scapes.auto_trigger_debug", ax.type.bool, false, {
    category = "map",
    subCategory = "scapes",
    description = "Log map soundscape parser and auto-trigger diagnostics to the server console.",
})

ax.config:Add("audio.scapes.debug_logging", ax.type.bool, false, {
    category = "map",
    subCategory = "scapes",
    description = "Enable verbose Scapes runtime debug logging on the server.",
})

ax.config:Add("audio.scapes.debug_overlay", ax.type.bool, false, {
    category = "map",
    subCategory = "scapes",
    description = "Draw Scapes runtime debug overlays on the server.",
})

ax.config:Add("audio.scapes.debug_overlay_duration", ax.type.number, 0.2, {
    category = "map",
    subCategory = "scapes",
    description = "Server debug overlay lifetime for Scapes diagnostics.",
    min = 0.01,
    max = 5,
    decimals = 2,
})

ax.config:Add("audio.scapes.default_fade_in", ax.type.number, 1, {
    category = "map",
    subCategory = "scapes",
    description = "Default fade-in for scapes that do not explicitly define one.",
    min = 0,
    max = 30,
    decimals = 2,
})

ax.config:Add("audio.scapes.default_fade_out", ax.type.number, 1, {
    category = "map",
    subCategory = "scapes",
    description = "Default fade-out for scapes that do not explicitly define one.",
    min = 0,
    max = 30,
    decimals = 2,
})
