
local MODULE = MODULE

-- override the base arc9 base with the needed functions, since you cant really hook into it that easily
-- because of how i have to do this, any updates to these functions will largely break this plugin. there's not much i can do about that.
function MODULE:OnSchemaLoaded()
    local SWEP = weapons.GetStored("arc9_base")

    -- shared sh_attach.lua overrides
    do
        function SWEP:Attach(addr, att, silent, ignoreCount)
            local slottbl = self:LocateSlotFromAddress(addr)
            if !slottbl then -- to not error and reset menu
                self.BottomBarAddress = nil
                self.BottomBarMode = 0
                self:CreateHUD_Bottom()
                return false
            end

            if (slottbl.Installed == att) then return false end

            if !self:CanAttach(addr, att, nil, ignoreCount) then
                return false
            end

            -- if the attachment item has a needed tool, check if the player has it
            local itemClass = ax.arc9:GetItemForAttachment(att)
            local item = itemClass and ax.item.stored[itemClass]
            local client = LocalPlayer() or self:GetOwner()
            if client and item and !item:HasTool(client) then
                local toolItem = item.tool and ax.item.stored[item.tool]
                if toolItem then
                    client:Notify("You do not have the " .. toolItem.name .. " tool needed to add this attachment!")
                    return false
                else
                    client:Notify("You do not have the " .. item.tool .. " tool needed to add this attachment!")
                    return false
                end
            end

            local atttbl = ARC9.GetAttTable(att) or {}
            self:DetachAllFromSubSlot(addr, true)

            slottbl.Installed = att
            slottbl.ToggleNum = 1

            if !silent then
                self:PlayTranslatedSound({
                    name = "install",
                    sound = atttbl.InstallSound or slottbl.InstallSound or "arc9/newui/ui_part_install.ogg"
                })
            end

            self:PruneAttachments()
            self:PostModify()

            if ( CLIENT ) then
                self:UpdateItemPreset()
            end

            return true
        end
        function SWEP:Detach(addr, silent)

            local slottbl = self:LocateSlotFromAddress(addr)
            if !slottbl or !slottbl.Installed then return false end
            if !self:CanDetach(addr, slottbl.Installed) then return false end
            local atttbl = ARC9.GetAttTable(slottbl.Installed) or {}

            -- if the attachment item has a needed tool, check if the player has it
            local itemClass = ax.arc9:GetItemForAttachment(slottbl.Installed)
            local item = itemClass and ax.item.stored[itemClass]
            local client = LocalPlayer() or self:GetOwner()
            if client and item and !item:HasTool(client) then
                local toolItem = item.tool and ax.item.stored[item.tool]
                if toolItem then
                    client:Notify("You do not have the " .. toolItem.name .. " tool needed to remove this attachment!")
                    return false
                else
                    client:Notify("You do not have the " .. item.tool .. " tool needed to remove this attachment!")
                    return false
                end
            end

            slottbl.Installed = nil

            if !silent then
                self:PlayTranslatedSound({
                    name = "uninstall",
                    sound = atttbl.UninstallSound or slottbl.UninstallSound or "arc9/newui/ui_part_uninstall.ogg"
                })
            end

            self:PruneAttachments()
            self:PostModify()

            if ( CLIENT ) then
                self:UpdateItemPreset()
            end

            return true
        end

        -- removes invalid attachments, but still returns the attachment, weirdly. unsure if this will cause issues
        function SWEP:PruneAttachments()
            for _, slot in ipairs(self:GetSubSlotList()) do
                -- if !slot.Installed then continue end

                if !ARC9.Attachments[slot.Installed] then
                    slot.Installed = nil
                    continue
                end

                local atttbl = ARC9.GetAttTable(slot.Installed)

                if !atttbl or self:SlotInvalid(slot) then
                    --ARC9:PlayerGiveAtt(self:GetOwner(), slot.Installed, 1)
                    slot.Installed = false
                    slot.SubAttachments = nil
                end

                if slot.MergeSlotAddresses then
                    for _, msa in ipairs(slot.MergeSlotAddresses) do
                        local mslottbl = self:LocateSlotFromAddress(msa)

                        if !mslottbl then continue end

                        if mslottbl.Installed then
                            --ARC9:PlayerGiveAtt(self:GetOwner(), slot.Installed, 1)
                            slot.Installed = false
                            slot.SubAttachments = nil
                        end
                    end
                end
            end
        end


        function SWEP:ToggleCustomize(on, benchBypass)
            if on == self:GetCustomize() then return end
            if self.NotAWeapon then return end

            -- if we should be using weapon benches, the player should only be able to close it
            if on and ax.config:Get("arc9.weapons.benches", true) and !benchBypass then return end

            self:SetCustomize(on)

            self:SetShouldHoldType()

            self:SetInSights(false)

            if !on and self:HasAnimation("postcustomize") then
                self:CancelReload()
                self:PlayAnimation("postcustomize", 1, true)
            end
        end

        function SWEP:PostModify(toggleonly)
            self:InvalidateCache()
            self.ScrollLevels = {} -- moved from invalidcache

            if !toggleonly then
                self:CancelReload()
                -- self:PruneAttachments()
                self:SetNthReload(0)
            end

            local client = self:GetOwner()
            local validplayerowner = ax.util:IsValidPlayer(client)

            local base = baseclass.Get(self:GetClass())

            if ARC9:UseTrueNames() then
                self.PrintName = base.TrueName
                self.PrintName = self:GetValue("TrueName")
            else
                self.PrintName = base.PrintName
                self.PrintName = self:GetValue("PrintName")
            end

            if !self.PrintName then
                self.PrintName = base.PrintName
                self.PrintName = self:GetValue("PrintName")
            end

            self.Description = base.Description

            self.PrintName = self:RunHook("HookP_NameChange", self.PrintName)
            self.Description = self:RunHook("HookP_DescriptionChange", self.Description)

            if ( CLIENT ) then
                -- self:PruneAttachments()
                self:SendWeapon()
                self:KillModel()
                self:SetupModel(true)
                self:SetupModel(false)
                if !toggleonly then
                    self:SavePreset()
                end
                self:BuildMultiSight()
                self.InvalidateSelectIcon = true
            else
                if validplayerowner then
                    if self:GetValue("ToggleOnF") and client:FlashlightIsOn() then
                        client:Flashlight(false)
                    end

                    -- darsu called this a 'mess' when i asked him how to override ammo to use item data, lol

                    -- timer.Simple(0, function() -- PostModify gets called after each att attached
                    --     if self.LastAmmo != self:GetValue("Ammo") or self.LastClipSize != self:GetValue("ClipSize") then
                    --         if self.AlreadyGaveAmmo then
                    --             self:Unload()
                    --             self:SetRequestReload(true)
                    --         else
                    --             self:SetClip1(self:GetProcessedValue("ClipSize"))
                    --             self.AlreadyGaveAmmo = true
                    --         end
                    --     end

                    --     self.LastAmmo = self:GetValue("Ammo")
                    --     self.LastClipSize = self:GetValue("ClipSize")
                    -- end)


                    if self:GetValue("UBGL") then
                        if !self.AlreadyGaveUBGLAmmo then
                            self:SetClip2(self:GetMaxClip2())
                            self.AlreadyGaveUBGLAmmo = true
                        end

                        if self.LastUBGLAmmo and (self.LastUBGLAmmo != self:GetValue("UBGLAmmo") or self.LastUBGLClipSize != self:GetValue("UBGLClipSize")) then
                            client:GiveAmmo(self:Clip2(), self.LastUBGLAmmo)
                            self:SetClip2(0)
                            self:SetRequestReload(true)
                        end

                        self.LastUBGLAmmo = self:GetValue("UBGLAmmo")
                        self.LastUBGLClipSize = self:GetValue("UBGLClipSize")

                        local capacity = self:GetCapacity(true)
                        if capacity > 0 and self:Clip2() > capacity then
                            client:GiveAmmo(self:Clip2() - capacity, self.LastUBGLAmmo)
                            self:SetClip2(capacity)
                        end
                    end

                    local capacity = self:GetCapacity(false)
                    if capacity > 0 and self:Clip1() > capacity then
                        client:GiveAmmo(self:Clip1() - capacity, self.LastAmmo)
                        self:SetClip1(capacity)
                    end

                    if self:GetProcessedValue("BottomlessClip", true) then
                        self:RestoreClip()
                    end
                end
            end

            if self:GetUBGL() and !self:GetProcessedValue("UBGL") then
                self:ToggleUBGL(false)
            end

            if game.SinglePlayer() and validplayerowner then
                self:CallOnClient("RecalculateIKGunMotionOffset")
            end

            self:SetupAnimProxy()

            self:SetBaseSettings()

            if self:GetAnimLockTime() <= CurTime() then
                self:Idle()
            end
        end
    end

    -- clientside additions and overrides
    if ( CLIENT ) then
        function SWEP:UpdateItemPreset()
            net.Start("axARC9UpdatePreset")
                net.WriteUInt(LocalPlayer():GetCharacter():GetID(), 32)
                net.WriteUInt(self:EntIndex(), 32)
                net.WriteString(self:GeneratePresetExportCode())
            net.SendToServer()
        end

        function SWEP:LoadPreset(filename)
            if GetConVar("arc9_atts_nocustomize"):GetBool() then return end
            if LocalPlayer() != self:GetOwner() then return end

            filename = filename or "autosave"

            if filename == "autosave" and !GetConVar("arc9_autosave"):GetBool() then return end

            filename = ARC9.PresetPath .. self:GetPresetBase() .. "/" .. filename .. ".txt"

            if !file.Exists(filename, "DATA") then return end

            local f = file.Open(filename, "r", "DATA")
            if !f then return end

            local str = f:Read()

            if str[1] == "{" then
                self:LoadPresetFromTable(util.JSONToTable(str))
            elseif string.sub(str, 1, 5) == "name=" then
                -- first line is name second line is data
                local strs = string.Split(str, "\n")
                self:LoadPresetFromTable(self:ImportPresetCode(strs[2]))
            else
                self:LoadPresetFromTable(self:ImportPresetCode(str))
            end

            if self.CustomizeHUD and self.CustomizeHUD.lowerpanel then
                timer.Simple(0, function()
                    if !IsValid(self) then return end
                    self:CreateHUD_Bottom()
                end)
            end

            f:Close()

            self:UpdateItemPreset()
        end
    end
-- end

-- function MODULE:OnConfigsLoaded()
    -- generation kinda sucks because of arc9's largely arbitrary nature, dont really recommend it
    if ( ax.config:Get("arc9.weapons.generate", false) ) then
        ax.arc9:GenerateWeapons()
    end

    if ( ax.config:Get("arc9.attachments.generate", false) ) then
        ax.arc9:GenerateAttachments()
    end

    -- go through the list again to cover manually created items. sorta inefficient, but necessary
    for k, v in pairs(ax.item.stored) do
        if ( v.isARC9Attachment and !v.isGenerated ) then
            ax.arc9.attachments[v:GetAttachment()] = k
        elseif ( v.isARC9Weapon and v.isGrenade and !v.isGenerated ) then
            ax.arc9.grenades[v.class] = true
        end
    end

    ax.arc9:SetAlwaysRaised()
end

function MODULE:NearWeaponBench(client)
    for _, bench in ipairs(ents.FindByClass("ax_arc9_weapon_bench")) do
        if ( client:GetPos():DistToSqr(bench:GetPos()) < 100 ^ 2 ) then
            return true
        end
    end
end

function MODULE:IsCustomizing(client, weapon)
    if ( weapons.IsBasedOn(weapon:GetClass(), "arc9_base") ) then
        return weapon:GetCustomize()
    end
end

function MODULE:StartCustomizing(client, weapon)
    if ( weapons.IsBasedOn(weapon:GetClass(), "arc9_base") and !weapon:GetCustomize() ) then
        weapon:ToggleCustomize(true, true)
        return true
    end
end

-- in addition to normal inv stuff, iterate through and check if the player has attachment items for the needed type
function ARC9:PlayerGetAtts(client, att)
    if ( !ax.util:IsValidPlayer(client) or !client:GetCharacter() ) then return 0 end

    if ( ax.arc9:IsFreeAttachment(att) or att == "" ) then return 999 end
    if ( ax.config:Get("arc9.attachments.free", false) ) then return 999 end

    local atttbl = ARC9.GetAttTable(att)
    if ( !atttbl ) then return 0 end

    if ( !client:IsAdmin() and atttbl.AdminOnly ) then
        return 0
    end

    if ( atttbl.InvAtt ) then att = atttbl.InvAtt end

    if ( !client.ARC9_AttInv ) then return 0 end

    local amount = client.ARC9_AttInv[att] or 0
    local inventory = client:GetCharacter():GetInventory()
    if inventory then
        for itemID, itemObj in pairs(inventory.items or {}) do
            if itemObj.base == "base_arc9_attachments" and itemObj:GetAttachment() == att then
                amount = amount + 1
            end
        end
    end

    return amount
end

-- give the player the needed attachment item, or increment the AttInv if no item exists
function ARC9:PlayerGiveAtt(client, att, amt, noItem)

    if ( !ax.util:IsValidPlayer(client) or !client:GetCharacter() ) then return end
    if ( ax.arc9:IsFreeAttachment(att) or att == "" ) then return true end
    if ( ax.config:Get("arc9.attachments.free", false) ) then return true end

    amt = amt or 1

    if ( !client.ARC9_AttInv ) then
        client.ARC9_AttInv = {}
    end

    local atttbl = ARC9.GetAttTable(att)
    if ( !atttbl ) then return end
    if ( atttbl.AdminOnly and !(ax.util:IsValidPlayer(client) and client:IsAdmin()) ) then return false end
    if ( atttbl.InvAtt ) then att = atttbl.InvAtt end

    local itemClass = ax.arc9:GetItemForAttachment(att)
    if ( noItem or !itemClass ) then
        if ( GetConVar("arc9_atts_lock"):GetBool() ) then
            if ( client.ARC9_AttInv[att] == 1 ) then return end
            client.ARC9_AttInv[att] = 1
        else
            client.ARC9_AttInv[att] = (client.ARC9_AttInv[att] or 0) + amt
        end
    else
        if ( SERVER ) then
            local inventory = client:GetCharacter():GetInventory()
            if inventory then
                inventory:AddItem(itemClass, {}, function(success, item)
                    if !success then
                        -- Spawn at player position if inventory is full
                        ax.item:Spawn(itemClass, client:GetPos() + Vector(0, 0, 32), Angle(0, 0, 0))
                    end
                end)
            end
        end
    end
end

-- remove the attachment item from the player, or from the AttInv if no item exists
function ARC9:PlayerTakeAtt(client, att, amt, noItem)
    if ( GetConVar("arc9_atts_lock"):GetBool() ) then return end
    if ( !ax.util:IsValidPlayer(client) or !client:GetCharacter() ) then return end
    if ( ax.arc9:IsFreeAttachment(att) or att == "" ) then return true end
    if ( ax.config:Get("arc9.attachments.free", false) ) then return true end

    amt = amt or 1

    if ( !client.ARC9_AttInv ) then
        client.ARC9_AttInv = {}
    end

    local atttbl = ARC9.GetAttTable(att)
    if ( atttbl.InvAtt ) then att = atttbl.InvAtt end

    local itemClass = ax.arc9:GetItemForAttachment(att)
    local attItems = {}
    local inventory = client:GetCharacter():GetInventory()

    if inventory and itemClass then
        for itemID, itemObj in pairs(inventory.items or {}) do
            if itemObj.class == itemClass then
                table.insert(attItems, itemObj)
            end
        end
    end

    client.ARC9_AttInv[att] = client.ARC9_AttInv[att] or 0

    local total = client.ARC9_AttInv[att]
    if ( itemClass ) then
        total = total + #attItems
    end

    if ( total < amt ) then return false end

    if ( noItem or !itemClass or #attItems < 1 ) then
        client.ARC9_AttInv[att] = client.ARC9_AttInv[att] - amt

        if ( client.ARC9_AttInv[att] <= 0 ) then
            client.ARC9_AttInv[att] = nil
        end
    else
        local removed = 0
        while removed < amt do
            if ( client.ARC9_AttInv[att] > 0 ) then
                client.ARC9_AttInv[att] = client.ARC9_AttInv[att] - 1
                removed = removed + 1
            else
                local head = table.remove(attItems)
                if ( SERVER and head ) then
                    inventory:RemoveItem(head.id)
                end
                removed = removed + 1
            end
        end
    end

    return true
end

-- credit to FoxxoTrystan for this one, i just updated it to work with some generation options
hook.Add("EntityRemoved", "ARC9RemoveGrenade", function(entity)
    if ( ax.arc9.grenades[entity:GetClass()] ) then
        local client = entity:GetOwner()
        if ( ax.util:IsValidPlayer(client) and client:GetCharacter() ) then
            local ammoName = game.GetAmmoName(entity:GetPrimaryAmmoType())
            if ( isstring(ammoName) and client:GetAmmoCount(ammoName) < 1 and entity:Clip1() < 1 and entity.axItem and entity.axItem.Unequip ) then
                entity.axItem:Unequip(client, false, true)
            end
        end
    end
end)
