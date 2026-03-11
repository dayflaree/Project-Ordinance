--[[
    Project Ordinance
    Copyright (c) 2026 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

util.AddNetworkString("ax.bodygroup.apply")
util.AddNetworkString("ax.bodygroup.view")

net.Receive("ax.bodygroup.apply", function(len, client)
    if ( !client:IsAdmin() ) then return end

    local target = ax.character:Get(net.ReadUInt(32))
    if ( !target ) then return end

    local groups = net.ReadTable()
    if ( !istable(groups) ) then return end

    local targetPlayer = target:GetOwner()
    if ( ax.util:IsValidPlayer(targetPlayer) ) then
        for k, v in pairs(groups) do
            local id = targetPlayer:FindBodygroupByName(k)
            if ( id and id >= 0 ) then
                targetPlayer:SetBodygroup(id, v)
            end
        end
    end

    target:SetData("bodygroups", groups)
    target:Save()

    if ( client:GetCharacter():GetID() == target:GetID() ) then
        client:Notify("You have changed your bodygroups.")
    else
        client:Notify("You have changed " .. target:GetName() .. "'s bodygroups.")
    end
end)
