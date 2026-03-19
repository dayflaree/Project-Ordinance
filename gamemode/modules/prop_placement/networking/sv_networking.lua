local MODULE = MODULE

local fundingModule
local function getFundingModule()
    if (fundingModule and fundingModule.funding) then return fundingModule end
    fundingModule = ax.module and ax.module:Get("funding")
    if (fundingModule and fundingModule.funding) then
        return fundingModule
    end
end

local function withdraw(amount, info)
    local mod = getFundingModule()
    if (not mod or not mod.funding) then return false end
    local current = tonumber(mod.funding:GetGlobal() or 0) or 0
    local cost = math.max(0, math.floor(amount))
    if (cost <= 0 or cost > current) then return false end
    mod.funding:SetGlobal(current - cost)
    mod.funding:PushHistoryPoint(mod.funding:GetGlobal())
    if (info and mod.funding.AddEvent) then
        mod.funding:AddEvent(info.type or "expense", info.title or "Expense", info.body or "", info.meta or { amount = cost })
    end
    if (mod.BroadcastUpdate) then
        mod:BroadcastUpdate()
    end
    return true
end

local function spawnProp(ply, model)
    local trace = util.TraceHull({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * 100,
        mins = Vector(-8, -8, -8),
        maxs = Vector(8, 8, 8),
        filter = ply
    })
    local pos = trace.HitPos + trace.HitNormal * 5
    local ang = Angle(0, ply:EyeAngles().y, 0)

    local ent = ents.Create("prop_physics")
    if (not IsValid(ent)) then return end

    ent:SetModel(model)
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    ent:SetCreator(ply)
    ent:SetPhysicsAttacker(ply)
    return ent
end

ax.net:Hook("prop_placement.purchase", function(ply, itemId)
    if (not IsValid(ply)) then return end
    if (not MODULE.catalog or not MODULE.catalog.FindItem) then return end

    local item = MODULE.catalog:FindItem(itemId)
    if (not item) then
        ply:Notify("Unknown catalogue entry.")
        return
    end

    local price = math.max(0, tonumber(item.price) or 0)
    if (price <= 0) then return end

    local summary = string.format("%s purchased %s for $%s.", ply:Name(), item.name, string.Comma(price))
    local meta = {
        type = "expense",
        title = "Prop Purchase",
        body = summary,
        meta = {
            amount = price,
            player = ply:SteamID64(),
            character = ply.GetCharacterID and ply:GetCharacterID() or nil,
            item = item.id,
            model = item.model
        }
    }

    if (not withdraw(price, meta)) then
        ply:Notify("Insufficient facility funds.")
        return
    end

    local ent = spawnProp(ply, item.model)
    if (not IsValid(ent)) then
        ply:Notify("Unable to spawn prop.")
        return
    end

    ply:Notify(string.format("Placed %s for $%s.", item.name, string.Comma(price)))
end)