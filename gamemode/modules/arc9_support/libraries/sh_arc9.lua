ax.arc9 = {}
ax.arc9.attachments = {}
ax.arc9.grenades = {}
ax.arc9.freeAttachments = {}

if ( SERVER ) then
    -- set up a weapon's attachments on equip, based on it's default value or data
    function ax.arc9:InitWeapon(client, weapon, item)
        if !ax.util:IsValidPlayer(client) or !IsValid(weapon) or !item then return end
        ax.arc9.SendPreset(client, weapon, item:GetPreset(), true)
    end

    -- replacement for ARC9.SendPreset()
    function ax.arc9.SendPreset(client, weapon, preset, setAmmo)
        if !ax.util:IsValidPlayer(client) or !IsValid(weapon) then
            return
        end

        if !isstring(preset) then -- no preset found, so we just need to set the ammo
            if weapon.axItem and weapon.axItem.isGrenade then
                weapon:SetClip1(1)
            elseif weapon.axItem then
                weapon:SetClip1(weapon.axItem:GetData("ammo", 0))
            end

            return
        end

        if IsValid(weapon) then
            if !ax.config:Get("arc9.attachments.free", false) or !GetConVar("arc9_free_atts"):GetBool() then
                local atts = ARC9.GetAttsFromPreset("[ax]" .. preset) -- expects a preset name to be trimmed, so just give it a fake one
                if !atts then return end

                ax.arc9:GiveAttsFromList(client, atts)
            end

            -- clear all original attachments so they dont get added as items/AttInv entries when we apply the preset
            weapon.Attachments = baseclass.Get(weapon:GetClass()).Attachments
            for slot, slottbl in ipairs(weapon.Attachments) do
                slottbl.Installed = nil
                slottbl.SubAttachments = nil
            end

            weapon:SetNoPresets(true)

            -- on proper servers, we need to wait until the weapon is valid on the client. this is also how its done in the base, surprisingly. i kinda hate it
            timer.Simple(0.1, function()
                net.Start("axARC9SendPreset")
                    net.WriteEntity(weapon)
                    net.WriteString(preset)
                net.Send(client)

                weapon:PostModify()

                if setAmmo then
                    if weapon.axItem and weapon.axItem.isGrenade then
                        weapon:SetClip1(1)
                    elseif weapon.axItem then
                        weapon:SetClip1(weapon.axItem:GetData("ammo", 0))
                    end
                end
            end)
        end
    end

    -- replacement for ARC9.GiveAttsFromList() that will never give the player items, only add to their AttInv
    function ax.arc9:GiveAttsFromList(client, tbl)
        local take = false

        for i, k in pairs(tbl) do
            ARC9:PlayerGiveAtt(client, k, 1, true)
            take = true
        end

        if take then ARC9:PlayerSendAttInv(client) end
    end
end

-- generates attachment items automatically
function ax.arc9:GenerateAttachments()
    if ax.arc9.attachmentsGenerated then return end

    for attID, attTable in pairs(ARC9.Attachments) do
        if !ax.arc9:IsFreeAttachment(attID) and !attTable.AdminOnly and !ARC9.Blacklist[attID] then
            if !ax.arc9.attachments[attID] and !(attTable.InvAtt and ax.arc9.attachments[attTable.InvAtt]) then
                -- Create attachment item using Parallax pattern
                local baseItem = ax.item.stored["arc9_attachments"]
                ITEM = setmetatable({ class = attID, base = "arc9_attachments" }, {
                    __index = function(t, k)
                        -- First check the item itself
                        local val = rawget(t, k)
                        if ( val != nil ) then return val end

                        -- Then check the base item
                        if ( baseItem and baseItem[k] != nil ) then return baseItem[k] end

                        -- Finally check the item meta
                        return ax.item.meta[k]
                    end
                })

                ITEM.name = attTable.PrintName
                ITEM.category = "Attachments"
                ITEM.description = attTable.Description or "An attachment, used to modify weapons."
                ITEM.isGenerated = true

                if attTable.DropMagazineModel then
                    ITEM.model = attTable.DropMagazineModel
                else
                    ITEM.model = "models/items/arc9/att_cardboard_box.mdl"
                end

                if attTable.InvAtt then
                    ITEM.att = attTable.InvAtt
                else
                    ITEM.att = attID
                end

                ax.arc9.attachments[ITEM.att] = attID
                ax.item.stored[attID] = ITEM
                ITEM = nil
            end
        else
            ax.util:PrintDebug("Skipping free or admin-only attachment: " .. attID)
        end
    end

    ax.arc9.attachmentsGenerated = true
end

--- Calculates realistic weapon weight based on SWEP properties
-- This function uses a multi-factor algorithm to determine weapon weight:
--
-- 1. Base Weight: Determined by weapon category (pistol, rifle, LMG, etc.)
-- 2. Ammo Type Modifier: Larger calibers increase weight (9mm < 5.56 < 7.62 < .50 BMG)
-- 3. Barrel Length: Longer barrels add weight proportionally
-- 4. Ergonomics: Lower ergonomics indicate heavier/bulkier weapons
-- 5. Slot Constraints: Ensures pistols stay light and heavy weapons stay heavy
--
-- Real-world weight references:
-- - Glock 17: 0.9 kg (empty), ~1.1 kg (loaded)
-- - MP5: 2.5 kg (empty), ~3.0 kg (loaded)
-- - M4A1: 2.9 kg (empty), ~3.5 kg (loaded)
-- - AK-47: 3.5 kg (empty), ~4.3 kg (loaded)
-- - M249 SAW: 7.5 kg (empty), ~10 kg (loaded)
--
-- @realm shared
-- @param swep table The weapon table from weapons.GetList()
-- @param weaponCategory string The detected weapon category
-- @return number The calculated weight in kilograms
function ax.arc9:CalculateWeaponWeight(swep, weaponCategory)
    -- Base weights by category (in kg, based on real-world averages)
    local baseWeights = {
        ["Throwable"] = 0.4,
        ["Melee"] = 1.2,
        ["Secondary"] = 1.0,
        ["Primary"] = 3.5,
        ["Shotgun"] = 3.8,
        ["SMG"] = 2.8,
        ["Sniper"] = 5.0,
        ["LMG"] = 7.5,
        ["DMR"] = 4.5,
        ["Default"] = 3.0
    }

    -- Ammo type weight modifiers (larger calibers = heavier weapons)
    local ammoWeightMods = {
        ["pistol"] = 0.85,    -- 9mm, .45 ACP
        ["357"] = 1.05,        -- .357 Magnum, larger pistol calibers
        ["smg1"] = 0.95,       -- 4.6x30mm, 5.7x28mm
        ["ar2"] = 1.0,         -- 5.56x45mm NATO (baseline)
        ["buckshot"] = 1.15,   -- 12 gauge shotgun shells
        ["AirboatGun"] = 1.25, -- Larger rifle calibers (7.62x51mm, .308)
        ["SniperRound"] = 1.3, -- .338 Lapua, .50 BMG
        ["slam"] = 0.5         -- Explosives
    }

    -- Start with base weight from category
    local weight = baseWeights[weaponCategory] or baseWeights["Default"]

    -- Apply ammo type modifier
    if swep.Ammo and ammoWeightMods[swep.Ammo] then
        weight = weight * ammoWeightMods[swep.Ammo]
    end

    -- Barrel length adjustment (normalized to typical ranges)
    -- Pistols: 3-6 inches, Rifles: 10-20 inches, Snipers: 20-30 inches
    if swep.BarrelLength and isnumber(swep.BarrelLength) then
        local barrelFactor = math.Clamp(swep.BarrelLength / 50, 0.7, 1.4)
        weight = weight * barrelFactor
    end

    -- Ergonomics adjustment (inverse relationship)
    -- EFT Ergo ranges: 25 (heavy/bulky) to 95 (lightweight/maneuverable)
    if swep.EFTErgo and isnumber(swep.EFTErgo) then
        local ergoFactor = 1.0 + ((65 - swep.EFTErgo) / 100) -- ergo 65 is neutral
        ergoFactor = math.Clamp(ergoFactor, 0.75, 1.35)
        weight = weight * ergoFactor
    end

    -- Slot-based adjustment (backup if category detection fails)
    if swep.Slot then
        if swep.Slot == 1 then -- Pistol slot
            weight = math.min(weight, 2.5)
        elseif swep.Slot == 3 then -- Heavy weapon slot
            weight = math.max(weight, 5.0)
        end
    end

    -- Round to 1 decimal place for cleaner values
    return math.Round(weight, 1)
end

-- generates weapon items automatically
function ax.arc9:GenerateWeapons()
    if ax.arc9.weaponsGenerated then print("ARC9 weapons have already been generated!") return end

    for _, v in ipairs(weapons.GetList()) do
        if v.PrintName and weapons.IsBasedOn(v.ClassName, "arc9_base") and !string.find(v.ClassName, "base") then
            -- Create weapon item using Parallax pattern
            local baseItem = ax.item.stored["arc9_weapons"]
            ITEM = setmetatable({ class = v.ClassName, base = "arc9_weapons" }, {
                __index = function(t, k)
                    -- First check the item itself
                    local val = rawget(t, k)
                    if ( val != nil ) then return val end

                    -- Then check the base item
                    if ( baseItem and baseItem[k] != nil ) then return baseItem[k] end

                    -- Finally check the item meta
                    return ax.item.meta[k]
                end
            })

            ITEM.name = v.PrintName
            ITEM.category = "Weapons"
            ITEM.description = v.Description or nil
            ITEM.class = v.ClassName
            ITEM.isGenerated = true

            local class
            if v.Class then
                class = v.Class:lower():gsub("%s+", "")
            end

            local detectedCategory = "Default" -- Track category for weight calculation

            -- i tried my best to update these for consistency, but most of ARC9's definitions are arbitrary. this WILL produce bad results somewhere.
            if v.Throwable or (class and string.find(class, "grenade") and !string.find(class, "launch")) then
                ITEM.weaponCategory = "Throwable"
                detectedCategory = "Throwable"
                ITEM.width = 1
                ITEM.height = 1
                ITEM.isGrenade = true
                ITEM.model = v.WorldModel or "models/weapons/w_eq_fraggrenade.mdl"

                ax.arc9.grenades[v.ClassName] = true
            elseif (v.NotAWeapon) then
                ITEM.width = 1
                ITEM.height = 1
                ITEM.model = v.WorldModel or "models/weapons/w_defuser.mdl"
                detectedCategory = "Throwable"
            elseif v.PrimaryBash or v.HoldType == "melee" or v.HoldType == "melee2" or v.HoldType == "knife" or v.HoldType == "fist" or (class and string.find(class, "melee")) then
                ITEM.weaponCategory = "Melee"
                detectedCategory = "Melee"
                ITEM.width = 1
                ITEM.height = 2
                ITEM.model = v.WorldModel or "models/weapons/w_knife_ct.mdl"
            elseif v.HoldType == "pistol" or v.HoldType == "revolver" or (class and (string.find(class, "pistol") or string.find(class, "revolver"))) then
                ITEM.weaponCategory = "Secondary"
                detectedCategory = "Secondary"
                ITEM.width = 2
                ITEM.height = 2
                if class and string.find(class, "revolver") then
                    ITEM.model = v.WorldModel or "models/weapons/w_357.mdl"
                else
                    ITEM.model = v.WorldModel or "models/weapons/w_pist_elite_single.mdl"
                end
            else
                ITEM.weaponCategory = "Primary"
                detectedCategory = "Primary"
                ITEM.model = v.WorldModel or "models/weapons/w_rif_m4a1.mdl" -- most weapons use an invisible css world model with bonemerged attachments, so this probably wont look right
                ITEM.width = 3
                ITEM.height = 2

                -- this is largely cosmetic but i think it helps
                if class then
                    if string.find(class, "shotgun") then
                        ITEM.model = v.WorldModel or "models/weapons/w_shot_m3super90.mdl"
                        detectedCategory = "Shotgun"
                        ITEM.width = 3
                        ITEM.height = 2
                    elseif string.find(class, "sniper") or string.find(class, "marksman") then
                        ITEM.model = v.WorldModel or "models/weapons/w_snip_scout.mdl"
                        detectedCategory = string.find(class, "marksman") and "DMR" or "Sniper"
                        ITEM.width = 4
                        ITEM.height = 2
                    elseif string.find(class, "smg") or string.find(class, "submachine") then
                        ITEM.model = v.WorldModel or "models/weapons/w_smg_ump45.mdl"
                        detectedCategory = "SMG"
                        ITEM.width = 3
                        ITEM.height = 2
                    elseif string.find(class, "lmg") or string.find(class, "machinegun") or string.find(class, "hmg") then
                        ITEM.model = v.WorldModel or "models/weapons/w_mach_m249para.mdl"
                        detectedCategory = "LMG"
                        ITEM.width = 4
                        ITEM.height = 2
                    end
                end
            end

            -- Calculate weight based on SWEP properties
            -- Weight formula considers: category base, ammo type, barrel length, and ergonomics
            ITEM.weight = ax.arc9:CalculateWeaponWeight(v, detectedCategory)

            ax.util:PrintDebug(string.format(
                "Generated weapon: %s | Category: %s | Weight: %.1f kg | Ergo: %s | Barrel: %s",
                v.ClassName,
                detectedCategory,
                ITEM.weight,
                tostring(v.EFTErgo or "N/A"),
                tostring(v.BarrelLength or "N/A")
            ))

            ax.item.stored[v.ClassName] = ITEM
            ITEM = nil
        end
    end

    ax.arc9.weaponsGenerated = true
end

function ax.arc9:SetAlwaysRaised()
    local raised = ax.config:Get("arc9.always.raised", false)

    if raised then
        for _, v in ipairs(weapons.GetList()) do
            local class = v.ClassName
            if weapons.IsBasedOn(class, "arc9_base") and !string.find(class, "base") and !AX_ALWAYS_RAISED[class] then
                AX_ALWAYS_RAISED[class] = true
            end
        end
    else
        for _, v in ipairs(weapons.GetList()) do
            local class = v.ClassName
            if weapons.IsBasedOn(class, "arc9_base") and !string.find(class, "base") and AX_ALWAYS_RAISED[class] then
                AX_ALWAYS_RAISED[class] = nil
            end
        end
    end
end

-- returns the item id for the passed attachment id
function ax.arc9:GetItemForAttachment(att)
    return ax.arc9.attachments[att]
end

function ax.arc9:IsFreeAttachment(att)
    local atttbl = ARC9.GetAttTable(att)
    return ax.arc9.freeAttachments[att] or (atttbl and atttbl.Free)
end

function ax.arc9:MakeFreeAttachment(att)
    ax.arc9.freeAttachments[att] = true
end
