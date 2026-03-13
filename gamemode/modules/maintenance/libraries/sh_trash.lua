--[[
    Project Ordinance
    Copyright (c) 2025 Project Ordinance Contributors

    This file is part of the Project Ordinance and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

require("niknaks")

local mapObject = NikNaks.CurrentMap
local nodes = mapObject:FindByClass("info_node")

ax.hook:Register("TRASH")

TRASH.settings = {
    trashSearchRange = 140,
    binSearchRange = 140,
    binMaxStoredWeight = 30,
    bagMaxStoredWeight = 10,
    binLookDistance = 196
}

TRASH.BIN_CLASSES = {
    ax_trash_bin = true,
    ax_trash_bin_wall = true
}

TRASH.worldModels = {
    cardboard = {
        "models/props_junk/garbage_cardboard001a.mdl",
        "models/props_junk/garbage_cardboard002a.mdl"
    },
    composite = {
        "models/props_junk/garbage_bag001a.mdl",
        "models/props_junk/garbage_metalcan001a.mdl",
        "models/props_junk/garbage_metalcan002a.mdl",
        "models/props_junk/garbage_milkcarton001a.mdl",
        "models/props_junk/garbage_milkcarton002a.mdl",
        "models/props_junk/garbage_plasticbottle001a.mdl",
        "models/props_junk/garbage_plasticbottle003a.mdl",
        "models/props_junk/garbage_takeoutcarton001a.mdl"
    }
}

TRASH.collectibleClasses = {
    cardboard = {
        "trash_piece_newspaper_bundle",
        "trash_piece_takeout_carton",
        "trash_piece_cardboard_box",
        "trash_piece_worn_shoe"
    },
    composite = {
        "trash_piece_plastic_bottle",
        "trash_piece_metal_can",
        "trash_piece_milk_carton",
        "trash_piece_coffee_mug",
        "trash_piece_glass_bottle",
        "trash_piece_food_scraps"
    }
}

TRASH.pickupSounds = {
    cardboard = {
        "physics/cardboard/cardboard_box_break1.wav",
        "physics/cardboard/cardboard_box_break2.wav",
        "physics/cardboard/cardboard_box_break3.wav",
        "physics/cardboard/cardboard_box_impact_bullet2.wav",
        "physics/cardboard/cardboard_box_shake1.wav",
        "physics/cardboard/cardboard_box_shake2.wav",
        "physics/cardboard/cardboard_box_shake3.wav"
    },
    composite = {
        "physics/plastic/plastic_barrel_break1.wav",
        "physics/plastic/plastic_barrel_break2.wav"
    }
}

function TRASH:GetTrashSearchRange()
    return self.settings.trashSearchRange
end

function TRASH:GetBinSearchRange()
    return self.settings.binSearchRange
end

function TRASH:GetBinMaxStoredWeight()
    return tonumber(self.settings.binMaxStoredWeight) or 30
end

function TRASH:GetBagMaxStoredWeight()
    return tonumber(self.settings.bagMaxStoredWeight) or 10
end

function TRASH:GetBinLookDistance()
    return tonumber(self.settings.binLookDistance) or 196
end

function TRASH:IsBinClass(className)
    return self.BIN_CLASSES[className] == true
end

function TRASH:IsBinEntity(entity)
    return IsValid(entity) and self:IsBinClass(entity:GetClass())
end

function TRASH:FindNearbyBin(origin, distance)
    local originPos
    if ( IsValid(origin) ) then
        originPos = origin:GetPos()
    elseif ( isvector(origin) ) then
        originPos = origin
    end

    if ( !isvector(originPos) ) then return nil end

    local searchDistance = tonumber(distance) or self:GetBinSearchRange()
    local nearby = ents.FindInSphere(originPos, searchDistance)
    local nearestEntity, nearestDistance

    for i = 1, #nearby do
        local entity = nearby[i]
        if ( !self:IsBinEntity(entity) ) then
            continue
        end

        local currentDistance = originPos:DistToSqr(entity:GetPos())
        if ( !nearestDistance or currentDistance < nearestDistance ) then
            nearestDistance = currentDistance
            nearestEntity = entity
        end
    end

    return nearestEntity
end

function TRASH:GetLookedAtBin(client, maxDistance)
    if ( !ax.util:IsValidPlayer(client) ) then
        return nil
    end

    local trace = client:GetEyeTrace()
    if ( !istable(trace) ) then
        return nil
    end

    local entity = trace.Entity
    if ( !self:IsBinEntity(entity) ) then
        return nil
    end

    local limit = tonumber(maxDistance) or self:GetBinLookDistance()
    if ( client:GetPos():DistToSqr(entity:GetPos()) > limit ^ 2 ) then
        return nil
    end

    return entity
end

function TRASH:FindNearbyLooseTrash(origin, distance)
    local originPos
    if ( IsValid(origin) ) then
        originPos = origin:GetPos()
    elseif ( isvector(origin) ) then
        originPos = origin
    end

    if ( !isvector(originPos) ) then return nil end

    local searchDistance = tonumber(distance) or self:GetTrashSearchRange()
    local nearby = ents.FindInSphere(originPos, searchDistance)
    local nearestEntity, nearestDistance

    for i = 1, #nearby do
        local entity = nearby[i]
        if ( !IsValid(entity) or entity:GetClass() != "ax_trash" ) then
            continue
        end

        local collector = entity:GetRelay("trash.collector", nil)
        if ( IsValid(collector) ) then
            continue
        end

        local currentDistance = originPos:DistToSqr(entity:GetPos())
        if ( !nearestDistance or currentDistance < nearestDistance ) then
            nearestDistance = currentDistance
            nearestEntity = entity
        end
    end

    return nearestEntity
end

function TRASH:GetTypeFromModel(model)
    model = string.lower(model or "")

    for trashType, modelList in pairs(self.worldModels) do
        for i = 1, #modelList do
            if ( string.lower(modelList[i]) == model ) then
                return trashType
            end
        end
    end

    return "composite"
end

function TRASH:GetPickupSound(trashType)
    local soundList = self.pickupSounds[trashType] or self.pickupSounds.composite
    return soundList[math.random(#soundList)]
end

function TRASH:GetRandomCollectibleClass(trashType)
    local classList = self.collectibleClasses[trashType] or self.collectibleClasses.composite
    if ( !istable(classList) or #classList <= 0 ) then
        return nil
    end

    local attempts = #classList
    for i = 1, attempts do
        local className = classList[math.random(#classList)]
        if ( ax.item and ax.item.stored and istable(ax.item.stored[className]) ) then
            return className
        end
    end

    return classList[1]
end

function TRASH:GatherLocations()
    local locations = {}
    for i = 1, #nodes do
        local node = nodes[i]
        locations[#locations + 1] = node.origin
    end

    local approved = {}
    for _, loc in ipairs(locations) do
        if ( table.HasValue(approved, loc) ) then continue end
        if ( math.random(1, 5) != 1 ) then continue end

        local tooClose = false
        for _, client in player.Iterator() do
            if ( client:GetPos():DistToSqr(loc) < 384 ^ 2 ) then
                tooClose = true
                break
            end
        end

        if ( tooClose ) then continue end

        local tooCloseToTrash = false
        for _, ent in ipairs(ents.FindByClass("ax_trash")) do
            if ( ent:GetPos():DistToSqr(loc) < 384 ^ 2 ) then
                tooCloseToTrash = true
                break
            end
        end

        if ( tooCloseToTrash ) then continue end

        local tooFar = true
        for _, client in player.Iterator() do
            if ( client:GetPos():DistToSqr(loc) < 2048 ^ 2 ) then
                tooFar = false
                break
            end
        end

        if ( tooFar ) then continue end

        approved[#approved + 1] = loc
    end

    return approved
end

function TRASH:PlayerCanManageTrash(client)
    if ( !ax.util:IsValidPlayer(client) ) then return false end

    local character = client:GetCharacter()
    if ( !istable(character) ) then return false end

    local class = character:GetClass()
    if ( !isnumber(class) or class <= 0 ) then return false end

    return ax.class:HasAny(class, {
        CLASS_SERVICE_1_SERVICE_STAFF,
        CLASS_SERVICE_2_CUSTODIAN,
        CLASS_SERVICE_9_SERVICE_SUPERVISOR,
        CLASS_SERVICE_10_DEPARTMENT_DIRECTOR
    })
end

local nextThink = 0
local nextParticle = 0
function TRASH:Think()
    if ( SERVER and CurTime() > nextThink ) then
        nextThink = CurTime() + 5

        local locations = self:GatherLocations()
        for index, pos in ipairs(locations) do
            if ( math.random(1, 10) == 1 ) then
                timer.Simple(index, function()
                    local max = player.GetCount() * 4
                    local total = #ents.FindByClass("ax_trash")
                    if ( total >= max ) then return end

                    self:SpawnTrash(pos)
                end)
            end
        end

        for _, client in player.Iterator() do
            self:MakePlayerReact(client)
        end
    elseif ( CLIENT and CurTime() > nextParticle ) then
        nextParticle = CurTime() + math.Rand(0.5, 1.5)

        local emitter = ParticleEmitter(ax.client:GetPos())
        local locations = ents.FindByClass("ax_trash")
        for _, ent in ipairs(locations) do
            local tr = util.TraceLine({
                start = EyePos(),
                endpos = ent:GetPos(),
                filter = ax.client
            })

            if ( tr.Hit and tr.Entity != ent ) then continue end

            local part = emitter:Add("particle/particle_smokegrenade.vmt", ent:GetPos() + Vector(0, 0, 8))
            if ( part ) then
                part:SetDieTime(5)
                part:SetColor(200, 255, 200)
                part:SetStartAlpha(50)
                part:SetEndAlpha(0)
                part:SetStartSize(0)
                part:SetEndSize(128)
                part:SetCollide(false)
                part:SetGravity(Vector(0, 0, 8))
                part:SetVelocity(VectorRand() * 5)
            end
        end

        emitter:Finish()
    end
end

local reactions = {
    idle = {
        "A damp, moldy scent seeps out from somewhere close by.",
        "A foul stench hangs in the air like a dirty curtain.",
        "A harsh, acidic stink makes your eyes water for a brief moment.",
        "A sour, chemical tang burns the inside of your nose.",
        "Something oily and burnt lingers in the air, sticking to the back of your throat.",
        "The air smells rotten and decayed, like something died and was forgotten.",
        "The air tastes stale, thick with dust and the reek of neglected trash.",
        "The stink of old food and warm garbage makes your stomach twist.",
        "You catch a whiff of something unpleasant nearby...",
        "You catch hints of rotting meat buried under layers of other smells.",
        "You feel nauseous as a rancid smell creeps into your lungs.",
        "You hear the faint buzz of flies before the smell even hits you.",
        "You swear the smell alone could be classified as a workplace hazard.",
        "You wrinkle your nose at a disgusting odor clinging to the corridor.",
        "Your instincts scream at you to step away from whatever is causing that stench."
    },
    move = {
        "As you move by, a wave of rotten air rolls over you.",
        "Each step stirs up another layer of stale, sour air.",
        "Moving on doesn\'t help much; the stench still lingers behind you.",
        "The stink briefly grows stronger as you move past the source.",
        "You angle your body away, trying not to walk directly through the foul haze.",
        "You hurry along, resisting the urge to check if something is stuck to your boots.",
        "You pass by and feel the smell following you like a shadow.",
        "You quicken your pace to escape the awful stench clinging to the hallway.",
        "You subconsciously hold your breath as you walk through the contaminated air.",
        "Your footsteps kick up dust and the faint odor of long-forgotten trash."
    }
}

local reactionSounds = {
    male = {
        "riggs9162/bms/character/male/vomit_1.ogg",
        "riggs9162/bms/character/male/vomit_2.ogg",
        "riggs9162/bms/character/male/vomit_3.ogg",
        "riggs9162/bms/character/male/vomit_4.ogg",
        "riggs9162/bms/character/male/vomit_5.ogg",
        "riggs9162/bms/character/male/vomit_6.ogg",
        "riggs9162/bms/character/male/vomit_7.ogg"
    },
    female = {
        "riggs9162/bms/character/female/vomit_1.ogg",
        "riggs9162/bms/character/female/vomit_2.ogg",
        "riggs9162/bms/character/female/vomit_3.ogg",
        "riggs9162/bms/character/female/vomit_4.ogg",
        "riggs9162/bms/character/female/vomit_5.ogg",
        "riggs9162/bms/character/female/vomit_6.ogg",
        "riggs9162/bms/character/female/vomit_7.ogg"
    }
}

function TRASH:MakePlayerReact(client)
    if ( !ax.util:IsValidPlayer(client) or !client:Alive() or client:GetMoveType() == MOVETYPE_NOCLIP ) then return end

    local trashEntities = ents.FindByClass("ax_trash")
    local foundTrash = false
    for _, ent in ipairs(trashEntities) do
        local tr = util.TraceLine({
            start = client:EyePos(),
            endpos = ent:GetPos(),
            filter = client
        })

        debugoverlay.Sphere(ent:GetPos(), 256, 5, Color(200, 255, 200, 100))

        if ( client:GetPos():DistToSqr(ent:GetPos()) < 256 ^ 2 and ( !tr.Hit or tr.Entity == ent ) ) then
            foundTrash = true
            break
        end
    end

    if ( !foundTrash ) then return end

    if ( client.axNextTrashReact and CurTime() < client.axNextTrashReact ) then return end
    client.axNextTrashReact = CurTime() + math.Rand(15, 30)

    local reactionType = "idle"
    if ( client:GetVelocity():Length2D() > 10 ) then
        reactionType = "move"
    end

    local reactionList = reactions[reactionType]
    if ( reactionList ) then
        local reaction = reactionList[math.random(#reactionList)]
        local color = ax.config:Get("chat.it.color", Color(255, 255, 175))
        client:ChatPrint(color, "** " .. ax.chat:Format(reaction))
    end

    local gender = client:IsFemale() and "female" or "male"
    local soundList = reactionSounds[gender]
    if ( soundList ) then
        local soundPath = soundList[math.random(#soundList)]
        client:EmitSound(soundPath, 60, 100)
    end

    client:ScreenFade(SCREENFADE.IN, Color(200, 255, 200, 50), 5, 0)
end

function TRASH:SpawnTrash(pos)
    local tmp = ents.Create("ax_trash")
    if ( !IsValid(tmp) ) then return end

    local trashType = ( math.random(1, 2) == 1 ) and "cardboard" or "composite"
    local modelList = self.worldModels[trashType] or self.worldModels.composite
    local model = modelList[math.random(#modelList)]

    if ( !util.IsValidModel(model) ) then
        model = "models/props_junk/garbage_bag001a.mdl"
    end

    tmp:SetModel(model)
    tmp:SetRelay("trash.type", trashType)

    local ang = Angle(0, math.random(0, 360), 0)
    tmp:SetAngles(ang)
    tmp:Spawn()
    tmp:SetNoDraw(true)
    tmp:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

    local phys = tmp:GetPhysicsObject()
    if ( IsValid(phys) ) then
        phys:EnableMotion(false)
    end

    local hullMins, hullMaxs = tmp:GetCollisionBounds()
    SafeRemoveEntity(tmp)

    local tr = util.TraceHull({
        start = pos,
        endpos = pos,
        mins = hullMins,
        maxs = hullMaxs,
        mask = MASK_SOLID_BRUSHONLY
    })

    if ( tr.Hit ) then return end

    tr = util.TraceLine({
        start = pos + Vector(0, 0, 128),
        endpos = pos - Vector(0, 0, 128),
        mask = MASK_SOLID_BRUSHONLY
    })

    debugoverlay.Axis(pos, tr.HitNormal:Angle(), 32, 10, true)

    local ent = ents.Create("ax_trash")
    ent:SetPos(tr.HitPos + tr.HitNormal * 4)
    ent:SetAngles(tr.HitNormal:Angle() + Angle(90, 0, 0))
    ent:SetModel(model)
    ent:SetRelay("trash.type", trashType)
    ent:Spawn()
    ent:PhysicsInit(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetSolid(SOLID_VPHYSICS)

    local physicsObject = ent:GetPhysicsObject()
    if ( IsValid(physicsObject) ) then
        physicsObject:EnableMotion(false)
    end

    debugoverlay.Box(ent:GetPos(), ent:OBBMins(), ent:OBBMaxs(), 5, Color(0, 255, 0, 100))
    return ent
end

function TRASH:GetEntityDisplayText(entity)
    local class = entity:GetClass()
    if ( class == "ax_trash" ) then
        local trashType = entity:GetRelay("trash.type", "composite")
        if ( trashType == "cardboard" ) then
            return "Cardboard Trash"
        else
            return "Mixed Trash"
        end
    elseif ( self:IsBinEntity(entity) ) then
        return "Trash Bin"
    elseif ( class == "ax_trash_cremator" ) then
        return "Trash Cremator"
    end
end

function TRASH:HUDPaintTargetIDExtra(entity, x, y, alpha)
    -- Draw descriptions for trash entities and bins
    local class = entity:GetClass()
    local desc
    if ( class == "ax_trash" ) then
        local trashType = entity:GetRelay("trash.type", "composite")
        if ( trashType == "cardboard" ) then
            desc = "A pile of discarded cardboard and paper waste."
        else
            desc = "A heap of mixed trash, emitting a foul stench."
        end
    elseif ( self:IsBinEntity(entity) ) then
        desc = "A receptacle for disposing of trash. It looks like it can hold a decent amount of waste before it needs to be emptied."
    elseif ( class == "ax_trash_cremator" ) then
        desc = "A large industrial machine used to incinerate collected trash. It has a chute for depositing waste and a hatch for removing ashes."
    end

    if ( desc ) then
        local wrapped = ax.util:GetWrappedText(desc, "ax.small", ax.util:ScreenScale(128))
        for i, line in ipairs(wrapped) do
            draw.SimpleText(line, "ax.small", x + 1, y + ax.util:ScreenScaleH(6) * i + 1, Color(0, 0, 0, alpha / 4), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(line, "ax.small", x, y + ax.util:ScreenScaleH(6) * i, Color(255, 255, 255, alpha / 2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if ( self:IsBinEntity(entity) ) then
            local storedWeight = entity:GetStoredWeight()
            local maxWeight = entity:GetMaxStoredWeight()
            local weightText = string.format("Stored Weight: %.1f / %.1f kg", storedWeight, maxWeight)
            draw.SimpleText(weightText, "ax.tiny.italic", x + 1, y + ax.util:ScreenScaleH(6) * (#wrapped + 1) + 1, Color(0, 0, 0, alpha / 4), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(weightText, "ax.tiny.italic", x, y + ax.util:ScreenScaleH(6) * (#wrapped + 1), Color(255, 255, 255, alpha / 2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

function TRASH:SetupMove(client, mv, cmd)
    local sequence = client:GetRelay("sequence.identifier", "")
    if ( ax.util:FindString(sequence, "d1_town05_daniels_kneel") ) then
        mv:SetButtons(bit.bor(mv:GetButtons(), IN_DUCK))
    end
end

concommand.Add("ax_trash_spawn", function(client)
    if ( !ax.util:IsValidPlayer(client) or !client:IsAdmin() ) then return end

    local pos = client:GetEyeTrace().HitPos
    TRASH:SpawnTrash(pos)
end)
