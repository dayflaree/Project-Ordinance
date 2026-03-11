--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Bodygroup Manager"
MODULE.description = "Allows players and administration to easily customize bodygroups."
MODULE.author = "Riggs"

ax.command:Add("CharEditBodygroup", {
    description = "Edit bodygroups of a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character, optional = true }
    },
    OnRun = function(def, client, target)
        if ( !target ) then target = client:GetCharacter() end

        net.Start("ax.bodygroup.view")
            net.WriteUInt(target.id, 32)
            net.WriteTable(target:GetData("bodygroups", {}))
        net.Send(client)
    end
})
