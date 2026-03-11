--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Soda Machine"
ENT.Category = "Parallax"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
    for i = 1, 8 do
        self:NetworkVar("Entity", "Button" .. i, "Button" .. i)
    end
end
