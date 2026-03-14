local SCHEMA = SCHEMA

local songs = {
    ["rp_black_mesa_facility"] = {
        "riggs9162/bms/music/black mesa source/gamestartup 1.ogg",
        "riggs9162/bms/music/black mesa source/gamestartup 2.ogg"
    },
    ["rp_survey_facility"] = {
        "riggs9162/bms/music/black mesa xen/vista.ogg",
    },
}

function SCHEMA:GetMapSceneMusicPath(client, defaultPath, currentPath)
    local map = game.GetMap()
    local mapSongs = songs[map]

    return {
        paths = mapSongs
    }
end

local color = {}
color["$pp_colour_addr"] = 0.01
color["$pp_colour_addg"] = 0.005
color["$pp_colour_addb"] = -0.002

color["$pp_colour_brightness"] = 0.01
color["$pp_colour_contrast"] = 1.08
color["$pp_colour_colour"] = 1.12

color["$pp_colour_mulr"] = 0.00
color["$pp_colour_mulg"] = 0.00
color["$pp_colour_mulb"] = 0.00

function SCHEMA:RenderScreenspaceEffects()
    local trace = {}
    trace.start = EyePos()
    trace.endpos = trace.start + (EyeAngles():Forward() * 16)
    trace.filter = ax.client
    local tr = util.TraceLine(trace)

    local brightness = render.GetLightColor(tr.HitPos):Length() / 8

    local envFactor = math.Clamp(brightness / 4, 0, 1)

    -- color modify slightly tuned by environment brightness
    local col = table.Copy(color)
    col["$pp_colour_colour"] = col["$pp_colour_colour"] * Lerp(envFactor, 0.9, 1.15)
    col["$pp_colour_brightness"] = col["$pp_colour_brightness"] * Lerp(envFactor, 0.95, 1.05)

    local colorCorrection = ax.config:Get("effects.color.correction", true)
    if ( colorCorrection ) then
        DrawColorModify(col)
    end

    -- bloom that scales a bit with brightness
    local bloomMul = Lerp(envFactor, 0.85, 1.35)
    local bloomSize = Lerp(envFactor, 0.95, 1.1)

    local bloom = ax.config:Get("effects.bloom", true)
    if ( bloom ) then
        DrawBloom(0.75 * bloomMul, 1.5 * bloomMul, 4 * bloomSize, 4 * bloomSize, 2, 1, 1, 1, 1)
    end

    -- toy-town / posterize effect slightly stronger in brighter areas
    local toytown = ax.config:Get("effects.toytown", true)
    if ( toytown ) then
        local toyStrength = Lerp(envFactor, 0.95, 1.15)
        DrawToyTown(2 * toyStrength, ScrH() / 4)
    end

    -- sunbeams scale with brightness
    local sunbeams = ax.config:Get("effects.sunbeams", true)
    if ( sunbeams ) then
        local sunStrength = Lerp(envFactor, 0.9, 1.4)
        DrawSunbeams(0.1 * sunStrength, 0.013, 0.14, 0.2, 0.6 * sunStrength)
    end
end

function SCHEMA:ShouldDrawVersionWatermark()
    return false
end

function SCHEMA:ShouldDrawHealthHUD()
    return false
end

function SCHEMA:ShouldDrawArmorHUD()
    return false
end

local spinIcon = ax.util:GetMaterial("riggs9162/bms/ui/project-ordinance.png", "smooth mips")
local spinSpeed = 2
local iconSize = 64
local startTime = SysTime()
local function DrawWatermark()
    local scrW, scrH = ScrW(), ScrH()
    local t = (SysTime() - startTime) * spinSpeed
    local scale = math.abs(math.cos(t))
    local xScale = Lerp(scale, 0, 1)

    local width = iconSize * xScale
    local height = iconSize
    local x = scrW * 0.05 - width / 2
    local y = scrH * 0.95 - height / 2

    ax.render.DrawMaterial(0, x, y, width, height, ColorAlpha(color_white, 255 / 3), spinIcon)

    x = scrW * 0.05 + iconSize / 2
    y = scrH * 0.95 - height / 2

    local versionData = ax.version
    local text = "Alpha " .. os.date("%Y-%m-%d")
    if ( versionData.version ) then
        text = "Version " .. versionData.version
    end

    draw.SimpleText("Project Ordinance", "ax.regular.bold.italic", x + 8, y + 32, ColorAlpha(color_white, 255 / 6), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    draw.SimpleText(text, "ax.small.bold.italic", x, y + 32, ColorAlpha(color_white, 255 / 6), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function SCHEMA:PostRenderCurvy(width, height, client)
    DrawWatermark()
end

function SCHEMA:PlayerPostThink(client)
    local isNearTram = false
    for _, ent in ipairs(ents.FindInSphere(client:GetPos(), 256)) do
        if ( IsValid(ent) and ent:GetClass() == "prop_dynamic" and string.find(ent:GetModel(), "tram") ) then
            isNearTram = true
            break
        end
    end

    if ( !isNearTram ) then
        return
    end

    local dist = 256
    local traces = {
        {start = Vector(0, 0, 0), endpos = Vector(0, 0, dist)},
        {start = Vector(0, 0, 0), endpos = Vector(0, 0, -dist)},
        {start = Vector(0, 0, 0), endpos = Vector(dist, 0, 0)},
        {start = Vector(0, 0, 0), endpos = Vector(-dist, 0, 0)},
        {start = Vector(0, 0, 0), endpos = Vector(0, dist, 0)},
        {start = Vector(0, 0, 0), endpos = Vector(0, -dist, 0)}
    }

    local tracesHitTram = 0
    for _, trace in ipairs(traces) do
        local tr = util.TraceLine({
            start = client:EyePos() + trace.start,
            endpos = client:EyePos() + trace.endpos,
            filter = client
        })

        if ( IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_dynamic" and string.find(tr.Entity:GetModel(), "tram") ) then
            tracesHitTram = tracesHitTram + 1
            debugoverlay.Line(tr.StartPos, tr.HitPos, 0.1, Color(0, 255, 0), false)
        else
            debugoverlay.Line(tr.StartPos, tr.HitPos, 0.1, Color(255, 0, 0), false)
        end
    end

    -- if most of the traces hit the tram, we can assume the player is inside it and set the DSP accordingly
    if ( tracesHitTram >= #traces / 1.5 ) then
        client:SetDSP(2)
    else
        -- default back to scape dsp, but guard against nil/invalid preset
        local dspPreset = client.GetActiveScapeDSPPreset and client:GetActiveScapeDSPPreset() or nil
        if ( !isnumber(dspPreset) ) then
            dspPreset = 0
        end

        client:SetDSP(dspPreset)
    end
end

-- PlayerFootstep hook removed - handled by footsteps module
-- to prevent double-footstep issues
