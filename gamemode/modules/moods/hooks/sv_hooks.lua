--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--[[
    right_lid_raiser
    left_lid_raiser
    right_lid_tightener
    left_lid_tightener
    right_lid_droop
    left_lid_droop
    right_lid_closer
    left_lid_closer
    half_closed
    blink
    right_inner_raiser
    left_inner_raiser
    right_outer_raiser
    left_outer_raiser
    right_lowerer
    left_lowerer
    right_cheek_raiser
    left_cheek_raiser
    wrinkler
    dilator
    right_upper_raiser
    left_upper_raiser
    right_corner_puller
    left_corner_puller
    right_corner_depressor
    left_corner_depressor
    chin_raiser
    right_part
    left_part
    right_puckerer
    left_puckerer
    right_funneler
    left_funneler
    right_stretcher
    left_stretcher
    bite
    presser
    tightener
    jaw_clencher
    jaw_drop
    right_mouth_drop
    left_mouth_drop
    smile
    lower_lip
    head_rightleft
    head_updown
    head_tilt
    eyes_updown
    eyes_rightleft
    body_rightleft
    chest_rightleft
    head_forwardback
    gesture_updown
    gesture_rightleft
]]

util.AddNetworkString( "minerva.player.mood.updateflexes")

function MODULE:OnPlayerMoodChanged( client, moodID, moodPrev )
    for i = 1, client:GetFlexNum() - 1 do
        client:SetFlexWeight( i - 1, 0 )
    end

    local flexTable = self.Flexes[moodID]
    if ( flexTable ) then
        for k, v in pairs( flexTable ) do
            local flexID = client:GetFlexIDByName( k )
            if ( flexID and flexID >= 0 ) then
                client:SetFlexWeight( flexID, v )
            end
        end
    end
end
