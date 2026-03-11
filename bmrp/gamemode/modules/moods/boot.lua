--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Moods"
MODULE.description = "Adds moods that change the character's animations based on their current state."
MODULE.author = "BLOODYCOP" -- I forgot about this crap...

MODULE.Moods = {
    "Neutral",
    "Happy",
    "Confident",
    "Energized",
    "Focused",
    "Fine",
    "Angry",
    "Bored",
    "Dazed",
    "Tense",
    "Uncomfortable",
    "Sad",
    "Panic"
}

-- Create enumerations:
-- MOOD_NEUTRAL, MOOD_HAPPY, MOOD_SAD, MOOD_ANGRY, MOOD_SCARED, MOOD_CONFUSED
for k, v in pairs( MODULE.Moods ) do
    _G[ "MOOD_" .. string.upper( v ) ] = k
end

MODULE.Flexes = {
    [ MOOD_HAPPY ] = {
        ["left_corner_puller"] = 1.0,
        ["right_corner_puller"] = 1.0,
        ["right_upper_raiser"] = 1.0,
        ["left_upper_raiser"] = 1.0,
        ["smile"] = 1.0,
    },
}

function MODULE:GetMoodID( input )
    for i = 1, #self.Moods do
        if ( ax.util:FindString( self.Moods[i], input ) ) then
            return i
        end
    end

    return nil
end
