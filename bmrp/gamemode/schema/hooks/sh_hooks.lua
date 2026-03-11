
function SCHEMA:EntityEmitSound(data)
    local ent = data.Entity
    if ( !IsValid(ent) ) then return end

    if ( ent:IsNPC() ) then
        data.SoundLevel = data.SoundLevel - 15

        return true
    end
end

function SCHEMA:InitPostEntity()
    local playermodels = {}

    for _, v in ipairs(file.Find("models/riggs9162/bms/characters/*.mdl", "GAME")) do
        table.insert(playermodels, "models/riggs9162/bms/characters/" .. v)
    end

    for _, v in ipairs(playermodels) do
        ax.animations:SetModelClass(v, "player")
        util.PrecacheModel(v)
    end

    -- Remove all soundscape entities
    for _, v in ipairs(ents.FindByClass("*soundscape*")) do
        print("Removing soundscape entity", v)
        SafeRemoveEntity(v)
    end
end

local entities = {
    ["prop_ragdoll"] = 300,
}

local entityCollisions = {
    ["prop_ragdoll"] = COLLISION_GROUP_WORLD
}

function SCHEMA:OnEntityCreated(ent)
    timer.Simple(0, function()
        if ( !IsValid(ent) ) then return end

        local class = ent:GetClass()
        local time = entities[class]
        if ( time ) then
            SafeRemoveEntityDelayed(ent, time)
        end

        if ( entityCollisions[class] ) then
            ent:SetCollisionGroup(entityCollisions[class])
        end
    end)
end

local OUTAGE_SCAPE_ID = "facility.power.outage.eerie"

--- Override auto-triggered map scapes while near an unpowered sector.
-- When power is restored, returning `nil` allows normal scape selection to resume.
-- @tparam Player client Target player.
-- @tparam Vector position Player position.
-- @tparam table state Player scape auto-trigger state.
-- @treturn string|nil scapeId Override scape id.
-- @treturn table|nil ctx Optional activation context.
function SCHEMA:ScapesGetAutoTriggerOverride(client, position, state)
    if ( !SERVER ) then return end
    if ( !ax.util:IsValidPlayer(client) or !isvector(position) ) then return end
    if ( !isfunction(self.HasNearbyPowerOutage) ) then return end

    local hasOutage, sector = self:HasNearbyPowerOutage(position)
    if ( hasOutage == true ) then
        return OUTAGE_SCAPE_ID, {
            seed = string.format("power_outage.%s.%s", tostring(sector or "unknown"), game.GetMap()),
            priority = 40,
            force = true,
        }
    end
end
