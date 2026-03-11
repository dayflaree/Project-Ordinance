local rng = math.Rand
local clamp = math.Clamp
local band = bit.band

-- Per-player runtime state: next time/side/skip/jump/land
local function ensureState(client)
    if ( !client.NextStepTime ) then
        client.NextStepTime = 0
        client.NextStepSide = false
        client.StepSkip = 0
        client.WasOnGround = true
        client.LastJumpTime = 0
        client.LastLandTime = 0
    end
end

-- Min step speed baseline
local function getMinStepSpeed(client)
    local walk = client.GetWalkSpeed and client:GetWalkSpeed() or 120
    local crouchMul = client.GetCrouchedWalkSpeed and client:GetCrouchedWalkSpeed() or 0.25
    local scale = ax.config:Get("footstepMinSpeedScale", 1.0)

    return walk * crouchMul * scale
end

-- Interval calculation (shared fallback)
local function getNextStepTime(client, vel)
    if ( client:GetMoveType() == MOVETYPE_LADDER ) then
        return ax.config:Get("footstepLadderInterval", 0.45)
    end

    local val
    if ( client:WaterLevel() >= 1 ) then
        val = ax.config:Get("footstepWaterInterval", 0.60)
    else
        -- Slow walk: increase spacing; fast run: decrease spacing
        local walkI = ax.config:Get("footstepWalkingInterval", 0.55)
        local runI = ax.config:Get("footstepRunningInterval", 0.20)
        val = math.max(math.Remap(vel, client:GetWalkSpeed(), client:GetRunSpeed(), walkI, runI), 0.1)

        -- Alt-walk tiny slowdown for cadence smoothing
        if ( client:KeyDown(IN_WALK) and vel < 90 ) then
            val = 0.5 / math.max(vel / 90, 0.01)
        end
    end

    if ( client:Crouching() ) then
        val = val + 0.10
    end

    -- External multiplier, if any
    local mult = hook.Run("ParallaxFootsteps_NextTimeModifier", client)
    if ( mult ) then val = val * mult end

    return val
end

-- Build StepContext (immutable)
local HULL_OFFSET = Vector(0, 0, 16)
local function buildContext(client, side)
    local flags = 0
    if ( client:IsSprinting() ) then flags = flags + RUNNING end
    if ( client:Crouching() ) then flags = flags + CROUCHING end
    if ( client:GetMoveType() == MOVETYPE_LADDER ) then flags = flags + LADDER end
    if ( client:WaterLevel() >= 1 ) then flags = flags + SUBMERGED end
    if ( client:KeyDown(IN_WALK) ) then flags = flags + ALT_WALK end

    local mins, maxs = client:GetHull()
    local tr = util.TraceHull({
        start = client:GetPos(),
        endpos = client:GetPos() - HULL_OFFSET,
        filter = client,
        mins = mins,
        maxs = maxs,
        collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
    })

    local surfIdx = tr.SurfaceProps
    local surfName = surfIdx and util.GetSurfacePropName and util.GetSurfacePropName(surfIdx) or nil

    local stamina = client.GetStamina and client:GetStamina() or nil

    local ctx = {
        ver = 1,
        time = CurTime(),
        side = side,
        flags = flags,
        actor = {
            eid = client:EntIndex(),
            ref = client,
            faction = nil,
            class = nil,
            model = client:GetModel(),
            tags = nil,
            weight = client:GetNWFloat("ax_armorWeight", 0)
        },
        kin = {
            speed = client:GetVelocity():Length(),
            ladder = client:GetMoveType() == MOVETYPE_LADDER,
            water = client:WaterLevel(),
            stamina = stamina
        },
        contact = {
            pos = client:GetPos(),
            normal = Vector(0, 0, 1),
            surfaceIndex = surfIdx,
            surfaceName = surfName
        },
        env = {
            indoor = nil,
            area = nil
        }
    }

    local character = client:GetCharacter()
    if ( character ) then
        ctx.actor.faction = character:GetFaction()
        ctx.actor.class = character:GetClass()
    end

    return ctx
end

-- Build StepPlan (mutable)
local function newPlan(ctx)
    return {
        ver = 1,
        cancel = false,
        handled = false,
        bus = {
            volume = ax.config:Get("footstepVolumeMultiplier", 1.0),
            pitch = 100,
            pitchJitter = 2,
            chan = CHAN_STATIC
        },
        family = { key = "default", seed = ctx.actor.eid + (ctx.side and 1 or 0) },
        layers = {},
        fx = {},
        dbg = nil
    }
end

-- Material-based sound selection
local ladderSurface = ax.util:GetSurfaceDataViaName("ladder")
local wadeSurface = ax.util:GetSurfaceDataViaName("wade")

-- Helper functions to access material data - uses globally stored ax.footsteps
local function getStepSound(surfaceName)
    if (!ax.footsteps or !ax.footsteps.GetStepSound) then
        return nil
    end
    return ax.footsteps:GetStepSound(surfaceName)
end

local function getJumpSound(surfaceName)
    if (!ax.footsteps or !ax.footsteps.GetJumpSound) then
        return nil
    end
    return ax.footsteps:GetJumpSound(surfaceName)
end

local function getLandSound(surfaceName)
    if (!ax.footsteps or !ax.footsteps.GetLandSound) then
        return nil
    end
    return ax.footsteps:GetLandSound(surfaceName)
end

local function getReverbSound(surfaceName)
    if (!ax.footsteps or !ax.footsteps.GetReverbSound) then
        return nil
    end
    return ax.footsteps:GetReverbSound(surfaceName)
end

local function pickDefaultAlias(ctx)
    if ( band(ctx.flags, LADDER) != 0 ) then
        return ctx.side and (ladderSurface and ladderSurface.stepRightSound or "Default.StepRight")
                        or (ladderSurface and ladderSurface.stepLeftSound  or "Default.StepLeft")
    end

    if ( band(ctx.flags, SUBMERGED) != 0 ) then
        return ctx.side and (wadeSurface and wadeSurface.stepRightSound or "Water.StepRight")
                        or (wadeSurface and wadeSurface.stepLeftSound  or "Water.StepLeft")
    end

    -- Use material-based footsteps
    local surfName = ctx.contact.surfaceName
    local stepSound = getStepSound(surfName)

    if ( stepSound ) then
        return stepSound
    end

    -- Fallback: Use concrete as default instead of GMod default sounds
    -- This prevents playing Default.StepLeft/Right which aren't blocked
    local concreteSound = getStepSound("concrete")
    if ( concreteSound ) then
        return concreteSound
    end

    -- Final fallback - should never happen if sounds are loaded
    return nil
end

-- Play jump sound when player presses jump key
hook.Add("OnKeyPress", "Footsteps_OnJump", function(client, key)
    if ( client != LocalPlayer() ) then return end
    if ( key != IN_JUMP ) then return end

    -- Only play if on ground (prevent double-jump sounds)
    if ( !client:IsFlagSet(FL_ONGROUND) ) then return end

    -- Prevent spam
    if ( CurTime() - (client.LastJumpTime or 0) < 0.2 ) then return end

    local surfIdx = util.TraceLine({
        start = client:GetPos(),
        endpos = client:GetPos() - Vector(0, 0, 16),
        filter = client
    }).SurfaceProps

    local surfName = surfIdx and util.GetSurfacePropName(surfIdx) or nil
    local jumpSound = getJumpSound(surfName)

    if ( jumpSound ) then
        if ( istable(jumpSound) ) then
            jumpSound = jumpSound[math.random(#jumpSound)]
        end
        client:EmitSound(jumpSound, 75, 100, 1, CHAN_BODY)
        client.LastJumpTime = CurTime()
    end
end)

-- Landing detection - client-side using state tracking
local wasOnGround = false

hook.Add("Think", "Footsteps_Landing", function()
    local client = LocalPlayer()
    if ( !ax.util:IsValidPlayer(client) or client:IsDormant() ) then return end
    if ( client:GetMoveType() != MOVETYPE_WALK ) then return end

    -- Initialize LastLandTime if not set
    if ( client.LastLandTime == nil ) then
        client.LastLandTime = 0
    end

    local isOnGround = client:IsFlagSet(FL_ONGROUND)

    -- Landing: was in air, now on ground
    if ( !wasOnGround and isOnGround ) then
        ax.util:PrintDebug("[FOOTSTEPS] Landing detected!")

        -- Prevent spam
        if ( CurTime() - client.LastLandTime > 0.2 ) then
            local surfIdx = util.TraceLine({
                start = client:GetPos(),
                endpos = client:GetPos() - Vector(0, 0, 16),
                filter = client
            }).SurfaceProps

            local surfName = surfIdx and util.GetSurfacePropName(surfIdx) or nil
            local landSound = getLandSound(surfName)

            ax.util:PrintDebug("[FOOTSTEPS] Surface:", surfName or "unknown", "Sound:", tostring(landSound))

            if ( landSound ) then
                if ( istable(landSound) ) then
                    landSound = landSound[math.random(#landSound)]
                end
                ax.util:PrintDebug("[FOOTSTEPS] Playing:", landSound)
                client:EmitSound(landSound, 75, 100,1, CHAN_BODY)
                client.LastLandTime = CurTime()
            else
                ax.util:PrintWarning("[FOOTSTEPS] No landing sound found!")
            end
        else
            ax.util:PrintDebug("[FOOTSTEPS] Landing blocked by spam protection")
        end
    end

    wasOnGround = isOnGround
end)

-- Emit the plan
local function playPlan(ctx, plan)
    if ( plan.cancel ) then return end
    if ( #plan.layers == 0 ) then return end

    local volMult = clamp(plan.bus.volume or 1, 0, 2)
    local basePitch = clamp(plan.bus.pitch or 100, 50, 150)
    local jitter = plan.bus.pitchJitter or 0

    for i = 1, #plan.layers do
        local layer = plan.layers[i]
        if ( layer and (layer.alias or layer.file) ) then
            local pitch = clamp(basePitch + rng(-jitter, jitter), 50, 150)
            local vol = clamp((layer.vol or 0.2) * volMult, 0, 1)
            local pos = layer.pos or ctx.contact.pos
            local snd = layer.alias or layer.file
            local lvl = layer.level or 70

            if ( istable(snd) ) then
                snd = snd[math.random(#snd)]
            end

            if ( layer.delay and layer.delay > 0 ) then
                timer.Simple(layer.delay, function()
                    if ( !ax.util:IsValidPlayer(ctx.actor.ref) ) then return end

                    EmitSound(snd, pos, ctx.actor.eid, plan.bus.chan or CHAN_STATIC, vol, lvl, nil, pitch)
                end)
            else
                EmitSound(snd, pos, ctx.actor.eid, plan.bus.chan or CHAN_STATIC, vol, lvl, nil, pitch)
            end
        end
    end
end

-- Cancel model-baked HL2 footstep spam
local steps = {".stepleft", ".stepright"}
function MODULE:EntityEmitSound(info)
    if ( !ax.util:IsValidPlayer(info.Entity) ) then return end

    local name = info.OriginalSoundName
    if ( name:find(steps[1]) or name:find(steps[2]) ) then return false end
end

-- Core think loop: schedule footsteps and build/execute plans
hook.Add("Think", "Footsteps_Think", function()
    local timeNow = CurTime()

    for _, client in player.Iterator() do
        if ( !ax.util:IsValidPlayer(client) or client:IsDormant() ) then continue end

        ensureState(client)

        if ( client.NextStepTime > timeNow ) then continue end
        if ( client:GetMoveType() == MOVETYPE_NOCLIP ) then continue end
        if ( client:GetMoveType() != MOVETYPE_LADDER and !client:IsFlagSet(FL_ONGROUND) ) then continue end
        if ( ax.config:Get("silentCrouching", false) and client:Crouching() ) then continue end
        if ( ax.config:Get("silentWalking", false) and client:KeyDown(IN_WALK) ) then continue end

        -- Water cadence skipping (reduce spam)
        if ( client:WaterLevel() >= 1 ) then
            if ( client.StepSkip == 2 ) then
                client.StepSkip = 0
            else
                client.StepSkip = client.StepSkip + 1
                client.NextStepTime = timeNow + ax.config:Get("footstepWaterInterval", 0.60)
                continue
            end
        end

        local speed = client:GetVelocity():Length()
        if ( speed < getMinStepSpeed(client) ) then
            continue
        end

        local side = client.NextStepSide

        -- Build context and initial plan
        local ctx = buildContext(client, side)
        local plan = newPlan(ctx)

        -- 1) SelectFamily
        hook.Run("ParallaxFootsteps_SelectFamily", ctx, plan)

        -- 2) BaseLayer (default)
        local snd = pickDefaultAlias(ctx)
        local vol = band(ctx.flags, RUNNING) != 0 and 0.5 or 0.20
        if ( band(ctx.flags, CROUCHING) != 0 ) then vol = vol * 0.5 end

        plan.layers[#plan.layers + 1] = {
            name = "foot",
            alias = snd,
            vol = vol,
            pitch = plan.bus.pitch,
            delay = 0,
            pos = ctx.contact.pos
        }

        hook.Run("ParallaxFootsteps_BaseLayer", ctx, plan)

        -- Add reverb layer if enabled
        if ( ax.config:Get("footstepReverbEnable", true) ) then
            local surfName = ctx.contact.surfaceName
            local reverbSound = getReverbSound(surfName)

            if ( reverbSound ) then
                local reverbVol = ax.config:Get("footstepReverbVolume", 0.25)
                local baseVol = band(ctx.flags, RUNNING) != 0 and 0.5 or 0.20

                -- Reverb volume - use config value directly, scale slightly with base volume
                reverbVol = clamp(reverbVol * 0.8, 0, 1)

                if ( band(ctx.flags, CROUCHING) != 0 ) then
                    reverbVol = reverbVol * 0.5
                end

                plan.layers[#plan.layers + 1] = {
                    name = "reverb",
                    alias = reverbSound,
                    vol = reverbVol,
                    pitch = plan.bus.pitch,
                    delay = ax.config:Get("footstepReverbDelay", 0.0),
                    pos = ctx.contact.pos
                }
            end
        end

        -- 3) Modifiers (volume/pitch/overlays)
        hook.Run("ParallaxFootsteps_Modifiers", ctx, plan)

        -- 4) RoleOverride
        -- Faction/class adapters if available
        local character = client:GetCharacter()
        if ( character ) then
            local factionData = character:GetFactionData()
            if ( factionData ) then
                if ( factionData.footstepProfile ) then
                    plan.family.key = factionData.footstepProfile
                end

                if ( factionData.Footstep and isfunction(factionData.Footstep) ) then
                    local r = factionData:Footstep(ctx, plan)
                    if ( r == false ) then plan.cancel = true end
                    if ( r == true ) then plan.handled = true end
                end

                if ( factionData.layers ) then
                    for i = 1, #factionData.layers do
                        local layer = factionData.layers[i]
                        if ( layer ) then
                            plan.layers[#plan.layers + 1] = table.Copy(layer)
                        end
                    end
                end
            end

            local classData = character:GetClassData()
            if ( classData ) then
                if ( classData.footstepProfile ) then
                    plan.family.key = classData.footstepProfile
                end

                if ( classData.Footstep and isfunction(classData.Footstep) ) then
                    local r = classData:Footstep(ctx, plan)
                    if ( r == false ) then plan.cancel = true end
                    if ( r == true ) then plan.handled = true end
                end

                if ( classData.layers ) then
                    for i = 1, #classData.layers do
                        local layer = classData.layers[i]
                        if ( layer ) then
                            plan.layers[#plan.layers + 1] = table.Copy(layer)
                        end
                    end
                end
            end
        end

        hook.Run("ParallaxFootsteps_RoleOverride", ctx, plan)

        -- 5) Finalize
        hook.Run("ParallaxFootsteps_Finalize", ctx, plan)

        for i = 1, #plan.layers do
            local layer = plan.layers[i]
            if ( layer ) then
                layer.vol = clamp(layer.vol or 0.2, 0, 1)
                layer.pitch = clamp(layer.pitch or plan.bus.pitch or 100, 50, 150)
                layer.delay = math.max(layer.delay or 0, 0)
                layer.pos = layer.pos or ctx.contact.pos
            end
        end

        table.sort(plan.layers, function(a, b) return (a.delay or 0) < (b.delay or 0) end)

        -- Execute
        if ( !plan.cancel ) then
            playPlan(ctx, plan)
        end

        -- schedule next step
        client.NextStepTime = timeNow + getNextStepTime(client, speed)
        client.NextStepSide = !side
    end
end)
