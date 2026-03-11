-- Bitflags for StepContext.flags
RUNNING   = 1
CROUCHING = 2
LADDER    = 4
SUBMERGED = 8
ALT_WALK  = 16

-- Hook order (documentation, not enforced here):
-- 1) ParallaxFootsteps_SelectFamily(ctx, plan)
-- 2) ParallaxFootsteps_BaseLayer(ctx, plan)
-- 3) ParallaxFootsteps_Modifiers(ctx, plan)
-- 4) ParallaxFootsteps_RoleOverride(ctx, plan)  -- faction/class Footstep(ctx, plan) is called here
-- 5) ParallaxFootsteps_Finalize(ctx, plan)

-- StepContext/StepPlan shapes are documented for addon authors:

--[[
StepContext (immutable):
{
    ver=1, time=CurTime(), side=false, flags=<bitfield>,
    actor={
        eid=<int>, ref=<Player>, faction=<id?>, class=<id?>, model=<string>,
        tags={<string>...}?, weight=<0..1>
    },
    kin={ speed=<number>, ladder=<bool>, water=<0..3>, stamina=<number?> },
    contact={ pos=<Vector>, normal=<Vector>, surfaceIndex=<int?>, surfaceName=<string?> },
    env={ indoor=<bool?>, area=<string?> }
}

StepPlan (mutable):
{
    ver=1, cancel=false, handled=false,
    bus={ volume=1.0, pitch=100, pitchJitter=2, chan=CHAN_STATIC },
    family={ key="default_boots", seed=<int> },
    layers={
        { name="foot", alias=<string>|nil, file=<string>|nil, vol=<0..1>, pitch=<50..150>, delay=<seconds>, pos=<Vector>, tags={<string>...}? },
        -- more layers: gear, cloth, armor, env...
    },
    fx={ hpf?, lpf?, reverb?, eq? },
    dbg={<string>...}?
}
]]
