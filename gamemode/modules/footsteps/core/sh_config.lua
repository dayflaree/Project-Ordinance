-- volumes/pitches
ax.config:Add("footstepVolumeMultiplier", ax.type.number, 1.0, {min = 0, max = 2, decimals = 2, category = "audio", subCategory = "footsteps", description = "Global volume scalar for footsteps."})
ax.config:Add("footstepPitchMin", ax.type.number, 95, {min = 50, max = 150, decimals = 0, category = "audio", subCategory = "footsteps", description = "Minimum footstep pitch."})
ax.config:Add("footstepPitchMax", ax.type.number, 105, {min = 50, max = 150, decimals = 0, category = "audio", subCategory = "footsteps", description = "Maximum footstep pitch."})

-- cadence
ax.config:Add("footstepWalkingInterval", ax.type.number, 0.55, {min = 0.1, max = 2, decimals = 2, category = "audio", subCategory = "footsteps", description = "Baseline walking step interval."})
ax.config:Add("footstepRunningInterval", ax.type.number, 0.3, {min = 0.05, max = 2, decimals = 2, category = "audio", subCategory = "footsteps", description = "Baseline running step interval."})
ax.config:Add("footstepLadderInterval", ax.type.number, 0.45, {min = 0.1, max = 2, decimals = 2, category = "audio", subCategory = "footsteps", description = "Ladder step interval."})
ax.config:Add("footstepWaterInterval", ax.type.number, 0.60, {min = 0.2, max = 2, decimals = 2, category = "audio", subCategory = "footsteps", description = "Water step interval."})

-- behavior
ax.config:Add("silentCrouching", ax.type.bool, false, {category = "audio", subCategory = "footsteps", description = "Crouching is silent."})
ax.config:Add("silentWalking", ax.type.bool, false, {category = "audio", subCategory = "footsteps", description = "Alt-walk is silent."})
ax.config:Add("footstepSecondaryEnable", ax.type.bool, true, {category = "audio", subCategory = "footsteps", description = "Enable secondary overlay layers."})
ax.config:Add("footstepSecondaryVolumeScale", ax.type.number, 0.25, {min = 0, max = 1, decimals = 2, category = "audio", subCategory = "footsteps", description = "Volume for secondary layers."})
ax.config:Add("footstepMinSpeedScale", ax.type.number, 1.0, {min = 0.2, max = 1.0, decimals = 2, category = "audio", subCategory = "footsteps", description = "Multiplier for min speed threshold."})
