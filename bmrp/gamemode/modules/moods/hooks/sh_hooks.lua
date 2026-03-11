--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Animations = {
    [MOOD_PANIC] = {
        [ACT_MP_RUN]            = "run_all_panicked",
        [ACT_MP_CROUCHWALK]     = "walk_panicked_all",
    },
}

MODULE.NonAffectedFactions = {
    --[FACTION_VORTIGAUNT] = true,
    --[FACTION_TF] = true
}

function MODULE:ShouldMoodsAffect(client, originalAct, currentAct)
    return !self.NonAffectedFactions[client:Team()]
end

function MODULE:SetupMove(client, moveData, userCmd)
    local character = client:GetCharacter()
    if ( !character ) then return end

    local mood = character:GetData("mood", MOOD_NEUTRAL)
    if ( mood == MOOD_NEUTRAL ) then return end

    if ( mood == MOOD_PANIC ) then
        -- Give 10% speed boost during panic mood
        moveData:SetMaxClientSpeed(moveData:GetMaxClientSpeed() * 1.1)
    end
end

function MODULE:OverrideActivity(client, originalAct, currentAct, ctx)
    local character = client:GetCharacter()
    if ( !character ) then return end

    local mood = character:GetData("mood", MOOD_NEUTRAL)
    if ( mood == MOOD_NEUTRAL ) then return end

    if ( hook.Run("ShouldMoodsAffect", client, originalAct) == false ) then return end

    local moodTable = self.Animations[mood]
    if ( !moodTable ) then return end

    if ( moodTable[originalAct] ) then
        return moodTable[originalAct]
    end
end
