--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:Tick()
    if ( !self.hydration ) then return end

    local decay = ax.config:Get("plants.decay_rate", 0.0001)
    local frameDecay = decay * engine.TickInterval()

    for key, level in pairs(self.hydration) do
        -- Only decay if not already at 0
        if ( level > 0 ) then
            self.hydration[key] = math.max(0, level - frameDecay) 
        end
    end
end
