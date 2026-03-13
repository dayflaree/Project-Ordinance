--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Ambient Music"
MODULE.description = "Plays ambient music in the background."
MODULE.author = "Riggs"

ax.option:Add("ambient.music", ax.type.bool, true, {
    category = "audio",
    subCategory = "ambient",
    description = "Enable or disable ambient background music.",
    bNoNetworking = true
})

ax.option:Add("ambient.music.volume", ax.type.number, 0.25, {
    category = "audio",
    subCategory = "ambient",
    description = "The volume of ambient background music.",
    min = 0,
    max = 1,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("ambient.music.history", ax.type.number, 4, {
    category = "audio",
    subCategory = "ambient",
    description = "How many previous songs to avoid repeating.",
    min = 1,
    max = 20,
    bNoNetworking = true
})

ax.option:Add("ambient.music.hold", ax.type.number, 10, {
    category = "audio",
    subCategory = "ambient",
    description = "Seconds the HUD 'Now Playing' holds before fading.",
    min = 1,
    max = 60,
    bNoNetworking = true
})

ax.localization:Register("en", {
    ["category.audio"] = "Audio",
    ["subcategory.ambient"] = "Ambient",
    ["option.ambient.music"] = "Ambient Music",
    ["option.ambient.music.volume"] = "Volume",
    ["option.ambient.music.history"] = "History Size",
    ["option.ambient.music.hold"] = "\"Now Playing\" Hold Time"
})

if ( SERVER ) then return end

local songPools = {} -- Dynamic table to store pools and songs
local mapPools = {} -- Map name -> pool name mapping
local currentSong
local currentPoolName
local lastPlayed = {}
local nextSong = 0
local fadingSound = nil

-- Function to register a new pool
function MODULE:RegisterPool(poolName)
    songPools[poolName] = {}
end

-- Function to add a song to a pool
function MODULE:AddSongToPool(poolName, songPath, songName, chance)
    if ( !songPools[poolName] ) then
        self:RegisterPool(poolName)
    end

    -- Treat chance as a percentage (0-100). Clamp and normalize.
    local pct = math.floor(tonumber(chance) or 1)
    if ( pct < 0 ) then pct = 0 end
    if ( pct > 100 ) then pct = 100 end

    songPools[poolName][#songPools[poolName] + 1] = {path = songPath, name = songName, chance = pct}
end

-- Function to map a pool to a map name
function MODULE:AddPoolToMap(poolName, mapName)
    if ( !isstring(poolName) or poolName == "" ) then return end
    if ( !isstring(mapName) or mapName == "" ) then return end

    if ( !songPools[poolName] ) then
        self:RegisterPool(poolName)
    end

    mapPools[mapName] = poolName
end

-- Function to pick a pool based on the current map
function MODULE:PickPoolName()
    local map = game.GetMap()
    local poolName = mapPools[map] or map

    local overridePoolName = hook.Run("AmbientMusicPickPoolOverride", poolName)
    if ( isstring(overridePoolName) and songPools[overridePoolName] ) then
        poolName = overridePoolName
    end

    if ( songPools[poolName] ) then
        return poolName
    end

    return "default"
end

function MODULE:PickPool()
    return songPools[self:PickPoolName()] or {}
end

-- Function to pick a random song based on chance
function MODULE:PickRandomSong(poolName)
    local resolvedPoolName = poolName or self:PickPoolName()
    local pool = songPools[resolvedPoolName] or songPools["default"] or {}
    if ( pool[1] == nil ) then return nil, resolvedPoolName end

    -- Build candidate list excluding recently played entries
    local candidates = {}
    for i = 1, #pool do
        local song = pool[i]
        local recently = false
        for l = 1, #lastPlayed do
            if ( lastPlayed[l] == song.path ) then
                recently = true
                break
            end
        end

        if ( !recently ) then
            candidates[#candidates + 1] = song
        end
    end

    -- If everything was excluded, allow all entries
    if ( #candidates == 0 ) then
        candidates = pool
    end

    -- Shuffle candidates to avoid list-order bias (Fisher-Yates)
    for i = #candidates, 2, -1 do
        local j = math.random(1, i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    -- Score each candidate with random(1..100) + chance, pick the highest score.
    local topScore = -math.huge
    local topCandidates = {}

    for i = 1, #candidates do
        local song = candidates[i]
        local pct = math.max(0, math.min(100, tonumber(song.chance) or 1))
        local roll = math.random(1, 100)
        local score = roll + pct

        if ( score > topScore ) then
            topScore = score
            topCandidates = { song }
        elseif ( score == topScore ) then
            topCandidates[#topCandidates + 1] = song
        end
    end

    -- Return a random song among the highest-scoring candidates
    return topCandidates[math.random(#topCandidates)], resolvedPoolName
end

-- Function to reset the last played songs
function MODULE:ResetLastPlayed()
    lastPlayed = {}
end

-- Function to clear the current song
function MODULE:ClearCurrentSong(fadeTime)
    if ( fadeTime == nil ) then fadeTime = 1 end
    if ( !currentSong ) then return end

    -- Clean up any existing fade timer first to prevent timer accumulation
    if ( timer.Exists("ax_ambient_fade") ) then
        timer.Remove("ax_ambient_fade")
        ax.util:PrintDebug("Removed existing fade timer")
    end

    local s = currentSong

    -- Clear current song immediately to prevent re-entrance
    currentSong = nil
    currentPoolName = nil
    fadingOut = true
    fadingSound = s

    if ( fadeTime <= 0 ) then
        -- Immediate stop
        if ( IsValid(s) ) then
            s:Stop()
        end
        fadingOut = false
        fadingSound = nil
        nextSong = CurTime() + 5
        return
    end

    -- Helper function to stop and cleanup
    local function stopAndCleanup()
        if ( IsValid(s) ) then
            s:Stop()
        end

        -- Only clear fading state if this sound is still the one being faded
        if ( fadingSound == s ) then
            fadingOut = false
            fadingSound = nil
        end

        -- Ensure timer is removed after completion
        if ( timer.Exists("ax_ambient_fade") ) then
            timer.Remove("ax_ambient_fade")
        end
    end

    if ( !IsValid(s) or s:GetState() != GMOD_CHANNEL_PLAYING ) then
        -- Sound isn't playing, just clear it after fade time
        timer.Simple(fadeTime, stopAndCleanup)
        nextSong = CurTime() + fadeTime + 1
        return
    end

    -- Implement smooth fade using timer
    local startVolume = s:GetVolume()
    local fadeInterval = 0.05 -- 20 FPS
    local totalSteps = math.ceil(fadeTime / fadeInterval)
    local currentStep = 0

    timer.Create("ax_ambient_fade", fadeInterval, totalSteps, function() -- Use exact step count
        if ( !IsValid(s) or fadingSound != s ) then
            timer.Remove("ax_ambient_fade")
            return
        end

        currentStep = currentStep + 1
        local progress = currentStep / totalSteps
        local newVolume = startVolume * (1 - progress)

        s:SetVolume(math.max(0, newVolume))

        ax.util:PrintDebug("Fading ambient music: step " .. currentStep .. "/" .. totalSteps .. " (" .. string.format("%.2f", progress * 100) .. "%), volume: " .. string.format("%.2f", newVolume))

        -- Check if fade is complete (this should happen automatically when timer expires)
        if ( currentStep >= totalSteps or newVolume <= 0 ) then
            stopAndCleanup()
        end
    end)

    nextSong = CurTime() + fadeTime + 1
end

local nowPlaying = ""
local nowPlayingAlpha = 0
local nowPlayingStart = 0
local nowPlayingFadeOut = false
function MODULE:PlayRandomSong(poolName)
    if ( nextSong > CurTime() ) then return end

    self:ClearCurrentSong()

    local historySize = math.max(1, math.floor(ax.option:Get("ambient.music.history") or 4))
    if ( lastPlayed[historySize + 1] != nil ) then
        table.remove(lastPlayed, 1)
    end

    local song, resolvedPoolName = self:PickRandomSong(poolName)
    if ( !song or !file.Exists("sound/" .. song.path, "GAME") ) then
        ax.util:PrintWarning("[AMBIENT] The song '" .. (song and song.path or "nil") .. "' does not exist! Skipping.")
        currentPoolName = nil
        nextSong = CurTime() + 1
        return
    end

    lastPlayed[#lastPlayed + 1] = song.path

    sound.PlayFile("sound/" .. song.path, "noplay", function(soundObj, errorID, errorName)
        if ( IsValid(soundObj) ) then
            currentSong = soundObj
            currentPoolName = resolvedPoolName
            soundObj:SetVolume(ax.option:Get("ambient.music.volume"))
            soundObj:Play()

            -- Get actual duration from sound.PlayFile callback, fallback to 1 if unavailable
            local dur = soundObj:GetLength() or 1
            if ( dur <= 0 ) then dur = 1 end
            nextSong = CurTime() + dur + 1

            nowPlaying = "Now Playing: " .. (song.name or "Unknown Title")
            nowPlayingStart = CurTime()
            nowPlayingAlpha = 0
            nowPlayingFadeOut = false
        else
            ax.util:PrintWarning("Failed to load sound: " .. song.path .. " (Error: " .. (errorName or "Unknown") .. ")")
            currentPoolName = nil
            nextSong = CurTime() + 1
        end
    end)
end

local nextThink = 0
local THINK_INTERVAL = 2 -- Increased from 1 to 2 seconds to reduce CPU load
function MODULE:Think()
    if ( nextThink > CurTime() ) then return end
    nextThink = CurTime() + THINK_INTERVAL

    if ( !ax.option:Get("ambient.music") or hook.Run("AmbientMusicShouldPause") ) then
        self:ClearCurrentSong(5)
        return
    end

    local desiredPoolName = self:PickPoolName()
    if (
        IsValid(currentSong)
        and currentSong:GetState() == GMOD_CHANNEL_PLAYING
        and currentPoolName != desiredPoolName
    ) then
        self:ClearCurrentSong(2)
        nextSong = 0
        self:PlayRandomSong(desiredPoolName)
        return
    end

    self:PlayRandomSong(desiredPoolName)

    if ( IsValid(currentSong) and currentSong:GetState() == GMOD_CHANNEL_PLAYING ) then
        local targetVolume = ax.option:Get("ambient.music.volume")
        if ( currentSong:GetVolume() != targetVolume ) then
            currentSong:SetVolume(targetVolume)
        end
    end
end

function MODULE:OnReloaded()
    -- Clean up any existing timers
    if ( timer.Exists("ax_ambient_fade") ) then
        timer.Remove("ax_ambient_fade")
    end

    self:ResetLastPlayed()
    self:ClearCurrentSong()
end

function MODULE:HUDPaint()
    if ( nowPlaying == "" ) then return end

    local elapsed = CurTime() - nowPlayingStart

    if ( !nowPlayingFadeOut ) then
        if ( elapsed < 1 ) then
            nowPlayingAlpha = Lerp(elapsed / 1, 0, 255)
        else
            nowPlayingAlpha = 255
            if ( elapsed > 10 ) then
                nowPlayingFadeOut = true
                nowPlayingStart = CurTime()
            end
        end
    else
        local fadeElapsed = CurTime() - nowPlayingStart
        nowPlayingAlpha = Lerp(fadeElapsed / 2, 255, 0)
        if ( nowPlayingAlpha <= 0 ) then
            nowPlaying = ""
            nowPlayingAlpha = 0
            return
        end
    end

    draw.SimpleText(nowPlaying, "ax.regular.bold.italic", 24, 16, Color(255, 255, 255, nowPlayingAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function MODULE:AmbientMusicShouldPause()
    local client = ax.client

    if ( IsValid(ax.gui.main) and ax.gui.main:IsVisible() ) then
        return true
    end

    if ( ax.mapscene:ShouldRenderMapScene(client) ) then
        return true
    end

    -- If we are near a radio, return true
    local radios = ents.FindByClass("ax_radio_*")
    for _, radio in ipairs(radios) do
        if ( IsValid(radio) and radio:GetEnabled() ) then
            local distSqr = client:GetPos():DistToSqr(radio:GetPos())
            if ( distSqr <= 256 * 256 ) then
                return true
            end
        end
    end
end

-- Precache all songs on initialization
function MODULE:Initialize()
    for poolName, songs in pairs(songPools) do
        for _, song in ipairs(songs) do
            util.PrecacheSound(song.path)
        end
    end
end

concommand.Add("ax_ambient_music_play", function(client, cmd, args)
    if ( !ax.option:Get("ambient.music") ) then
        ax.util:PrintWarning("Ambient music is disabled!")
        return
    end

    -- Parse optional delay argument (seconds)
    local delay = tonumber(args[1]) or 0
    if ( delay < 0 ) then delay = 0 end

    MODULE:ResetLastPlayed()

    -- Stop current immediately (no fade)
    MODULE:ClearCurrentSong(0)

    -- Cancel any previously scheduled play to prevent timer accumulation
    local timerName = "ax_ambient_music_play_delay"
    if ( timer.Exists(timerName) ) then
        timer.Remove(timerName)
        ax.util:PrintDebug("Removed existing play delay timer")
    end

    if ( delay <= 0 ) then
        nextSong = 0
        MODULE:PlayRandomSong()
    else
        -- Schedule the next song after `delay` seconds and set nextSong accordingly
        nextSong = CurTime() + delay
        timer.Create(timerName, delay, 1, function()
            if ( !ax.option:Get("ambient.music") ) then return end
            nextSong = 0
            MODULE:PlayRandomSong()

            -- Clean up the timer after it fires
            if ( timer.Exists(timerName) ) then
                timer.Remove(timerName)
            end
        end)
    end
end)

MODULE:RegisterPool("default")
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 01.ogg", "Black Mesa: Blue Shift - Ambient 1", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 02.ogg", "Black Mesa: Blue Shift - Ambient 2", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 03.ogg", "Black Mesa: Blue Shift - Ambient 3", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 04.ogg", "Black Mesa: Blue Shift - Ambient 4", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 05.ogg", "Black Mesa: Blue Shift - Ambient 5", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 06.ogg", "Black Mesa: Blue Shift - Ambient 6", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 07.ogg", "Black Mesa: Blue Shift - Ambient 7", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 08.ogg", "Black Mesa: Blue Shift - Ambient 8", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 09.ogg", "Black Mesa: Blue Shift - Ambient 9", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 10.ogg", "Black Mesa: Blue Shift - Ambient 10", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/ambient 11.ogg", "Black Mesa: Blue Shift - Ambient 11", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/inbound 1.ogg", "Black Mesa: Blue Shift - Inbound 1", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/inbound 2.ogg", "Black Mesa: Blue Shift - Inbound 2", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa blue shift/inbound 3.ogg", "Black Mesa: Blue Shift - Inbound 3", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/ambience 2.ogg", "Black Mesa - Ambience 2", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/ambience 3.ogg", "Black Mesa - Ambience 3", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/apprehension 2 (mix).ogg", "Black Mesa - Apprehension 2 (Mix)", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/blast pit part 1.ogg", "Black Mesa - Blast Pit Part 1", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/blast pit part 2 (mix).ogg", "Black Mesa - Blast Pit Part 2 (Mix)", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/blast pit part 2.ogg", "Black Mesa - Blast Pit Part 2", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/gamestartup 1.ogg", "Black Mesa - Gamestartup 1", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/gamestartup 2.ogg", "Black Mesa - Gamestartup 2", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/inbound a.ogg", "Black Mesa - Inbound A", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/inbound b.ogg", "Black Mesa - Inbound B", 100)
MODULE:AddSongToPool("default", "riggs9162/bms/music/black mesa source/inbound c.ogg", "Black Mesa - Inbound C", 100)

MODULE:RegisterPool("eerie")
MODULE:AddSongToPool("eerie", "riggs9162/bms/music/scp containment breach/the dread.ogg", "SCP Containment Breach - The Dread", 100)
MODULE:AddSongToPool("eerie", "riggs9162/bms/music/scp containment breach/heavy containment.ogg", "SCP Containment Breach - Heavy Containment", 100)
MODULE:AddSongToPool("eerie", "riggs9162/bms/music/scp containment breach/entrance zone.ogg", "SCP Containment Breach - Entrance Zone", 100)

MODULE:RegisterPool("military")
MODULE:AddSongToPool("military", "riggs9162/bms/music/black mesa hecu/fog of war.ogg", "Black Mesa HECU - Fog of War", 1)
MODULE:AddSongToPool("military", "riggs9162/bms/music/black mesa hecu/hazardous combat.ogg", "Black Mesa HECU - Hazardous Combat", 1)
MODULE:AddSongToPool("military", "riggs9162/bms/music/opposing force/fright.ogg", "Opposing Force - Fright", 1)
MODULE:AddSongToPool("military", "riggs9162/bms/music/opposing force/lost in thought.ogg", "Opposing Force - Lost in Thought", 1)
MODULE:AddSongToPool("military", "riggs9162/bms/music/opposing force/orbit.ogg", "Opposing Force - Orbit", 1)
MODULE:AddSongToPool("military", "riggs9162/bms/music/opposing force/run.ogg", "Opposing Force - Run", 1)
MODULE:AddSongToPool("military", "riggs9162/bms/music/opposing force/trample.ogg", "Opposing Force - Trample", 1)
MODULE:AddSongToPool("military", "riggs9162/bms/music/opposing force/tunnel.ogg", "Opposing Force - Tunnel", 1)

MODULE:RegisterPool("borderworld")
MODULE:AddSongToPool("borderworld", "riggs9162/bms/music/black mesa blue shift/ambient xen swamp.ogg", "Black Mesa: Blue Shift - Ambient Xen Swamp", 1)
MODULE:AddSongToPool("borderworld", "riggs9162/bms/music/black mesa blue shift/ambient xen vista.ogg", "Black Mesa: Blue Shift - Ambient Xen Vista", 1)
MODULE:AddSongToPool("borderworld", "riggs9162/bms/music/black mesa xen/respite.ogg", "Black Mesa - Respite", 1)
MODULE:AddSongToPool("borderworld", "riggs9162/bms/music/black mesa xen/theme.ogg", "Black Mesa - Theme", 1)
MODULE:AddSongToPool("borderworld", "riggs9162/bms/music/black mesa xen/vista.ogg", "Black Mesa - Vista", 1)
MODULE:AddSongToPool("borderworld", "riggs9162/bms/music/black mesa xen/vistasting.ogg", "Black Mesa - Vistasting", 1)

MODULE:AddPoolToMap("borderworld", "rp_survey_facility")

hook.Add("AmbientMusicPickPoolOverride", "ax_ambient_power_loss", function(poolName)
    local hasOutage = SCHEMA:HasNearbyPowerOutage(ax.client:GetPos())
    if ( hasOutage ) then
        return "eerie"
    end
end)
