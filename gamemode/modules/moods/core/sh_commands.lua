--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

ax.command:Add("ChangeMood" , {
    description = "Change your character's mood.",
    arguments = {
        {
            type = ax.type.string,
            description = "The mood to set your character to. 1 = Neutral, 2 = Happy, 3 = Sad, 4 = Angry, 5 = Scared, 6 = Confused."
        }
    },
    OnRun = function(def, client, mood)
        local character = client:GetCharacter()
        if ( !character ) then return end

        local moodID = MODULE:GetMoodID(mood)
        if ( !moodID ) then
            client:Notify("Invalid mood ID!")
            return
        end

        local moodName = MODULE.Moods[moodID]

        local moodPrev = character:GetData("mood", MOOD_NEUTRAL)
        if ( moodPrev == moodID ) then
            client:Notify("Your character is already in the " .. moodName .. " mood.")
            return
        end

        character:SetData("mood", moodID)
        client:Notify("Your character's mood has been set to " .. moodName .. ".")

        hook.Run("OnPlayerMoodChanged", client, moodID, moodPrev)
    end
})
