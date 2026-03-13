--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

net.Receive("ax.bodygroup.view", function()
    local target = ax.character:Get(net.ReadUInt(32))
    if ( !target ) then return end

    local bodygroupManager = vgui.Create("ax.bodygroup.view")
    bodygroupManager:Populate(target, net.ReadTable())
end)