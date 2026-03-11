local function BuildOutageEerieStingers()
    local sounds = {}
    local files = file.Find("sound/riggs9162/bms/scapes/eerie/stingers/*.ogg", "GAME")
    table.sort(files)

    for i = 1, #files do
        sounds[#sounds + 1] = "riggs9162/bms/scapes/eerie/stingers/" .. files[i]
    end

    if ( !sounds[1] ) then
        sounds[1] = "riggs9162/bms/scapes/eerie/stingers/-01.ogg"
        print("Warning: No stinger files found for outage eerie scape, using fallback sound.")
    end

    return sounds
end

ax.scapes:Register("facility.power.outage.eerie", function(builder)
    builder:SetMixTag("facility")
    builder:SetPriority(40)
    builder:SetFade(1.0, 1.0)
    builder:SetPauseLegacyAmbient(false)
    builder:SetMixerProfile("power_outage")

    builder:AddLoop("outage_eerie_ambience", {
        sounds = "riggs9162/bms/scapes/room/lowdrone.ogg",
        volume = 0.1,
        pitch = 100.0,
        spatial = { mode = "ambient", soundLevel = 75 },
        preload = true,
    })

    builder:AddRandom("outage_eerie_stingers", {
        sounds = BuildOutageEerieStingers(),
        volume = {0.45, 0.85},
        pitch = {92, 108},
        interval = {7, 16},
        spatial = {
            mode = "relative",
            radius = {192, 768},
            hemisphere = true,
            soundLevel = 90,
        },
        limit = {
            instance = 1,
            blockDistance = 512,
        },
        burst = {
            chance = 0.08,
            count = {2, 2},
            spacing = {0.18, 0.4},
        },
        preload = true,
    })
end)
