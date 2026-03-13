AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Author = "Limakenori"
ENT.PrintName = "Intro Animation"
ENT.Spawnable = true
ENT.Category = "Black Mesa"
function ENT:GetPlayerColor()
return self:GetNW2Vector("PlayerColor") or Vector(255,255,255) end
if (CLIENT) then

	hook.Add( "RenderScreenspaceEffects", "BloomEffect", function()
local ply = LocalPlayer()
if IsValid(ply:GetNW2Entity("xen_teleport_effect")) &&  ply:GetNW2Entity("xen_teleport_effect"):GetNW2Float("Bloom",0) > 0 then
local num = ply:GetNW2Entity("xen_teleport_effect"):GetNW2Float("Bloom",0)
DrawBloom( 0.2, 0.5*num, 9, 9, 1, 1, 1, 1, 1 )
	DrawMotionBlur( 0.4, 0.1*num, 0.06 )
end
end )

	function ENT:Draw() 
	self:DrawModel()
	end
	
	hook.Add( "PrePlayerDraw" , "xen_teleport_effect" , function( ply )
	if IsValid(ply:GetNW2Entity("xen_teleport_effect")) && LocalPlayer() == ply then ply:DrawShadow( false ) return true end 
	end)

    -- Client-side Think removed (merged into shared Think)

    function ENT:OnRemove()
        if (self.ViewstackRegistered) then
            local id = "XenIntro_" .. self:EntIndex()
            ax.viewstack:UnregisterModifier(id)
        end
    end
	
	else
	
-- SERVER-side hooks are now handled in the module's boot.lua
-- This keeps the entity file focused on entity logic only

end

local modeltbl = { 
--lima_xte_doorknock 1
["blackout"] = {
{model="models/tele/blackout.mdl",attachment="vehicle_driver_eyes",anim="enter1",up=1,uselegs=false,
addtime=2.1666667461395,
dropweapon=true,
func=function(ply,self)
ply:ScreenFade(SCREENFADE.OUT,Color(0,0,0,255),(3/self.PBR),1)
timer.Simple((3/self.PBR),function() if IsValid(ply) && IsValid(self) then
ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),(3/self.PBR),0)
self:ResetSequenceInfo()
self:SetCycle(0)
self:ResetSequence("exit1")
end end)
end
},
},

["knockout"] = {
{model="models/tele/blackout.mdl",attachment="knockout_camera_parent",anim="knockout",up=1,uselegs=false,
addtime=2.4,
dropweapon=true,
func=function(ply,self)
ply:ScreenFade(SCREENFADE.OUT,Color(0,0,0,255),(1.5/self.PBR),1)
timer.Simple((2/self.PBR),function() if IsValid(ply) && IsValid(self) then
self:Remove()
local pos = self:GetPos()
timer.Simple(0.01,function() if IsValid(ply) then
local tele = ents.Create("xen_teleport_intro")
tele:SetPos(pos)
tele:SetOwner(ply)
tele:Spawn()
tele:Activate()
tele.AnimType = "fall"
tele:StartIntro(ply) 
end end)
end end)
end
},
},


["knock1"] = {
{
model="models/tele/bs_interaction_hands2.mdl",
anim="intro_doorknock",
uselegs=false,
}
},

["knock2"] = {
{
model="models/tele/bs_interaction_hands2.mdl",
anim="intro_doorknock_hard",
uselegs=false,
}},

["knock3"] = {
{
model="models/tele/bs_interaction_hands_knock_drugs.mdl",
anim="intro_doorknock_ondrugs",
uselegs=false,
}},

["fall_fast"] = {
--{model="models/tele/bs_interaction_hands2.mdl", anim="controllerjack_recover",sd="controllerjack_recover.wav",up=0.1,uselegs=true, func = function(ply,self) if IsValid(ply) then
--if GetConVar("lima_xte_different_screffects"):GetBool() == false then
-- ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),1.4,0) 
-- else
--  self:DoBloom(ply)
--end
 --end end},
{model="models/tele/bs_interaction_hands2.mdl",
anim="mantaride_crash",
up = 13.8,
pbr = 1.5,
dropweapon=true,
uselegs=true,
func = function(ply,self) if IsValid(ply) then
if GetConVar("lima_xte_different_screffects"):GetBool() == false then
 ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),2.5,0) 
  else
 self:DoBloom(ply)
end
 end end},
{model="models/tele/bs_interaction_hands2.mdl",
anim="mantaride_crash",
up = 13.8,
pbr = 1.5,
dropweapon=true,
uselegs=true,
func = function(ply,self) if IsValid(ply) then
if GetConVar("lima_xte_different_screffects"):GetBool() == false then
 ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),2.5,0) 
  else
 self:DoBloom(ply)
end
 end end},
{model="models/tele/bs_interaction_hands2.mdl",
anim="mantaride_crash",
up = 13.8,
pbr = 1.5,
dropweapon=true,
uselegs=true,
func = function(ply,self) if IsValid(ply) then
if GetConVar("lima_xte_different_screffects"):GetBool() == false then
 ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),2.5,0)
 else
 self:DoBloom(ply)
end
 end end}
},

["fall"] = {
{model="models/tele/interaction_hands2.mdl", anim="uc_wakeup",up=1.1,uselegs=true,dropweapon=true, sd="uc_wakeup.wav", func = function(ply,self) if IsValid(ply) then 
if GetConVar("lima_xte_different_screffects"):GetBool() == false then
ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),2,0) 
else
  self:DoBloom(ply)
end
end end},
{model="models/tele/interaction_hands2.mdl", anim="rp_wakeup",up=0.1,uselegs=true,dropweapon=true, sd="rp_wakeup.wav", func = function(ply,self) if IsValid(ply) then
if GetConVar("lima_xte_different_screffects"):GetBool() == false then
 ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),2,0) 
 else
  self:DoBloom(ply)
end
 end end},
{model="models/tele/bs_interaction_hands2.mdl", anim="blackout_exit1",dropweapon=true, sd="bs_ia_blackoutexit.wav",up=0.1,uselegs=true, func = function(ply,self) if IsValid(ply) then
if GetConVar("lima_xte_different_screffects"):GetBool() == false then
 ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),1.4,0) 
 else
  self:DoBloom(ply)
end
 end end}
},

["wakeup_weapon"] = {
{
model="models/tele/firstperson_standup.mdl",
anim="first_person_standup",
uselegs=false,
up=2,
func = function(ply,self)
ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),3,0) 
timer.Simple(0.01,function() if IsValid(self) && IsValid(ply) then
net.Start("lima_xte_weapon")
net.WriteEntity(self)
net.Send(ply)
timer.Simple(0.5,function() if IsValid(self) && isstring(self:GetNW2String("wep")) && self:GetNW2String("wep") != "" then
local crowbar = ents.Create(self:GetNW2String("wep"))
crowbar:SetPos(self:GetAttachment(self:LookupAttachment("crowbar")).Pos)
crowbar:SetParent(self)
crowbar:Fire("SetParentAttachment","crowbar")
crowbar:Spawn()
crowbar.CanBePicked = true
self:CallOnRemove( "OnRemoveAnimXTE"..self:EntIndex(), function(self,ply)
if IsValid(ply) then
ply:Give(self:GetNW2String("wep"))
end
end,
ply)
end end)
end end)
end
}
},

["fall_spawn"] = {
{model="models/tele/interaction_hands2.mdl", anim="uc_wakeup",up=1.1,uselegs=true, sd="uc_wakeup.wav", func = function(ply,self) if IsValid(ply) then ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),2,0) end end},
{model="models/tele/interaction_hands2.mdl", anim="rp_wakeup",up=0.1,uselegs=true, sd="rp_wakeup.wav", func = function(ply,self) if IsValid(ply) then ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),2,0) end end},
{model="models/tele/bs_interaction_hands2.mdl", anim="blackout_exit1",sd="bs_ia_blackoutexit.wav",up=0.1,uselegs=true, func = function(ply,self) if IsValid(ply) then ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),1.4,0) end end}
},

["fall1"] = {
{model="models/tele/interaction_hands2.mdl", anim="uc_wakeup",up=1.1,uselegs=true, sd="uc_wakeup.wav", func = function(ply,self) if IsValid(ply) then ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),2,0) end end},
},

["fall2"] = {
{model="models/tele/interaction_hands2.mdl", anim="rp_wakeup",up=0.1,uselegs=true, sd="rp_wakeup.wav", func = function(ply,self) if IsValid(ply) then ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),2,0) end end},
},

["fall3"] = {
{model="models/tele/bs_interaction_hands2.mdl", anim="blackout_exit1",sd="bs_ia_blackoutexit.wav",up=0.1,uselegs=true, func = function(ply,self) if IsValid(ply) then ply:ScreenFade(SCREENFADE.IN,Color(0,0,0,255),1.4,0) end end}
},

["teleport"] = {
{model="models/tele/interaction_hands2.mdl", anim="endgame_intro",up=2,uselegs=true},
{model="models/tele/interaction_hands2.mdl", anim="gonarch_intro",sd="gonarch_intro.wav",up=1.1,uselegs=true},
{model="models/tele/interaction_hands2.mdl", anim="gonarch_intro",sd="gonarch_intro.wav",up=1.1,uselegs=true},
}

}

ENT.AutomaticFrameAdvance = true

function ENT:DoBloom(ply)
self:SetNW2Float("Bloom",8)
timer.Create("XTE_ScreenEffect"..ply:EntIndex(), 0.01*(3/self.PBR), 160, function() if !IsValid(self) then return end
self:SetNW2Float("Bloom",math.Clamp(self:GetNW2Float("Bloom",0) - 0.05,0,8)) end) 

end

function ENT:HandleAnimEvent(event, a, b, c, options)
    if ( !SERVER ) then
        return
    end

    if ( event == 12 ) then
        self:EmitSound(options)
        return
    end

    if ( event == 25 ) then
        local tr = util.TraceLine({
            start = self:WorldSpaceCenter(),
            endpos = self:WorldSpaceCenter() + self:GetForward() * 50,
            filter = { self, self:GetOwner() }
        })
        local mat = tr.MatType
        local sd = (mat == MAT_METAL && ((options == "BS_Intro_DoorknockHard" && "BSKnockKnock_Metal_Hard") or "BSKnockKnock_Metal") )
            or (mat == MAT_CONCRETE && "BSKnockKnock_Concrete")
            or (mat == MAT_DIRT && "BSKnockKnock_Concrete")
            or (mat == MAT_METAL && "BSKnockKnock_Metal")
            or (mat == MAT_BLOODYFLESH && "BSKnockKnock_Squish")
            or (mat == MAT_ANTLION && "BSKnockKnock_Flesh")
            or (mat == MAT_FLESH && "MAT_ALIENFLESH")
            or (mat == MAT_GLASS && "BSKnockKnock_Glass")
            or "BSKnockKnock"

        if ( tr.Hit ) then
            self:EmitSound(sd)
            if ( IsValid(tr.Entity) ) then
                local dmginfo = DamageInfo()
                dmginfo:SetInflictor(self:GetOwner())
                dmginfo:SetAttacker(self:GetOwner())
                dmginfo:SetDamage(5)
                dmginfo:SetDamageType(DMG_CLUB)
                dmginfo:SetDamagePosition(self:GetPos())
                tr.Entity:TakeDamageInfo(dmginfo)
            end
        end
    end
end

function ENT:Initialize()
util.PrecacheModel( "models/tele/bs_interaction_hands2.mdl" )
util.PrecacheModel("models/tele/interaction_hands2.mdl" )
util.PrecacheModel( "models/tele/blackout.mdl" )
    self:DrawShadow(false)
	
    if SERVER then
        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		self:AddSolidFlags( FSOLID_NOT_STANDABLE )
		self:SetSolid(SOLID_NONE)
    end
end


function ENT:StartIntro(ply)
if IsValid(ply:GetNW2Entity("xen_teleport_effect")) && ply:GetNW2Entity("xen_teleport_effect") != self then ply:GetNW2Entity("xen_teleport_effect"):Remove() end
self.Started = true

-- Safety check for invalid animation types
if (!self.AnimType or !modeltbl[self.AnimType]) then
    print("[BSHIFT] Error: Invalid AnimType '" .. tostring(self.AnimType) .. "' in StartIntro")
    self:Remove()
    return
end

local seq = table.Random(modeltbl[self.AnimType])
self:SetNW2Vector("PlayerColor",ply:GetPlayerColor())
self:SetModel(seq.model)
	if GetConVar("lima_xte_notarget"):GetBool() == true then -- skill issue x2
	ply:AddFlags(FL_NOTARGET)
	end
	if GetConVar("lima_xte_force_chands"):GetBool() == true then
	seq.uselegs = false
	end
self:SetNW2Bool("HasLegs",seq.uselegs)

if seq.dropweapon then
if GetConVar("lima_xte_drop_weapons"):GetBool() == true then
if IsValid(ply:GetActiveWeapon()) && ply:GetActiveWeapon():GetModel() != "" && isstring(ply:GetActiveWeapon():GetModel()) then
local wepdrop = ply:GetActiveWeapon()
ply:DropWeapon( wepdrop )
if IsValid(wepdrop:GetPhysicsObject()) then wepdrop:GetPhysicsObject():SetVelocity(ply:GetForward()*20 + Vector(math.random(-100,100),math.random(-100,100),math.random(60,110))) end
end end
end

if seq.sd then
self:EmitSound(seq.sd)
end


ply:SetNW2Entity("xen_teleport_effect",self)
self:SetPos(self:GetPos() + Vector(0,0,seq.up))
ply:SetPos(self:GetPos() + self:GetForward()*-10)
self:SetAngles(Angle(0,ply:GetAngles().y,0))
self.PBR = seq.pbr or 1
	self.PBR = self.PBR*GetConVar("lima_xte_speed_multiplier"):GetFloat()
if seq.func then 
seq.func(ply,self)
end

self.MyWeapon = ply:GetActiveWeapon()
self:ResetSequenceInfo()
        self:SetCycle(0)
        self:ResetSequence(seq.anim)
	seq.addtime = seq.addtime or 0
	timer.Simple( (self:SequenceDuration(self:LookupSequence(seq.anim))/self.PBR) + (seq.addtime/self.PBR),function() if IsValid(self) then self:Remove() end end)
self.MyPly = ply
ply:SetMoveType(MOVETYPE_NONE)
ply:Freeze(true)
-- self:SetNoDraw(true)
local helmet = ents.Create("xen_teleport_intro_bonemerge")
helmet:SetPos(self:GetPos())
if !self:GetNW2Bool("HasLegs") && IsValid(ply:GetHands()) then
helmet:SetModel(ply:GetHands():GetModel()) 
helmet:SetSkin(ply:GetHands():GetSkin())
if ply:GetHands():GetNumBodyGroups() != nil && isnumber(ply:GetHands():GetNumBodyGroups()) then local i = 0
while i < ply:GetHands():GetNumBodyGroups() do
helmet:SetBodygroup( i, ply:GetHands():GetBodygroup( i ) ) i = i + 1
		end end
else
helmet:SetModel(ply:GetModel()) 
helmet:SetSkin(ply:GetSkin())
if ply:GetNumBodyGroups() != nil && isnumber(ply:GetNumBodyGroups()) then local i = 0
while i < ply:GetNumBodyGroups() do
helmet:SetBodygroup( i, ply:GetBodygroup( i ) ) i = i + 1
		end end
end
helmet:SetOwner(self)
 helmet:SetParent(self)
	helmet:AddEffects(EF_BONEMERGE)
	helmet:SetSolid(SOLID_NONE)
	helmet:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	helmet:Spawn()
	/*
	local enta = ents.Create("prop_physics")
			enta:SetModel("models/headcrabclassic.mdl")
			enta:SetRenderMode(1)
			enta:SetColor(Color(255, 255, 255, 0))
			enta:DrawShadow(false)
			enta:SetParent(self)
		local att = seq.attachment or (self:LookupAttachment("camera_parent") > 0 && "camera_parent") or (self:LookupAttachment("vehicle_driver_eyes") > 0 && "vehicle_driver_eyes") or (self:LookupAttachment("knockout_camera_parent") > 0 && "knockout_camera_parent") or "ViewmodelEyes"
			enta:Fire("SetParentAttachment",att)
			ply:SetViewEntity(enta)
			self:SetNW2Entity("Camera",enta)
    */
	timer.Simple(3,function() if IsValid(self) && IsValid(ply) then
	util.ScreenShake(self:GetPos(),122,60,0.4,200,true,ply)
	end end)
	end
	
function ENT:OnRemove()

if IsValid(self.MyPly) then

-- self.MyPly:SetViewEntity(nil)
self.MyPly:SetPos(self:GetPos())
-- local ang = self:GetNW2Entity("Camera"):GetAngles()
local ang = self:GetAngles()
local attName = (self:LookupAttachment("camera_parent") > 0 and "camera_parent") or 
                (self:LookupAttachment("vehicle_driver_eyes") > 0 and "vehicle_driver_eyes") or 
                (self:LookupAttachment("knockout_camera_parent") > 0 and "knockout_camera_parent") or 
                "ViewmodelEyes"
local attId = self:LookupAttachment(attName)
local att = self:GetAttachment(attId)
if (att) then ang = att.Ang end 

if GetConVar("lima_xte_notarget"):GetBool() == true then -- skill issue x2
	self.MyPly:RemoveFlags(FL_NOTARGET)
	end
self.MyPly:SetEyeAngles(Angle(ang.p,ang.y,0))
self.MyPly:SetMoveType(MOVETYPE_WALK)
self.MyPly:Freeze(false)
self.MyPly:DrawShadow(true)
if IsValid(self.MyWeapon) then self.MyPly:SetActiveWeapon(nil) self.MyPly:SelectWeapon(self.MyWeapon:GetClass()) end
self.MyPly:SetLocalVelocity(Vector(0,0,0))

end

end

function ENT:Think()
    if self.PBR then self:SetPlaybackRate( self.PBR ) end

    if (CLIENT) then
        if (LocalPlayer():GetNW2Entity("xen_teleport_effect") == self) then
             if (!self.ViewstackRegistered) then
                 local id = "XenIntro_" .. self:EntIndex()
                 ax.viewstack:RegisterModifier(id, function(client, view)
                     if (!IsValid(self)) then return end
                     
                     local attName = (self:LookupAttachment("camera_parent") > 0 and "camera_parent") or 
                                     (self:LookupAttachment("vehicle_driver_eyes") > 0 and "vehicle_driver_eyes") or 
                                     (self:LookupAttachment("knockout_camera_parent") > 0 and "knockout_camera_parent") or 
                                     "ViewmodelEyes"
                                     
                     local attId = self:LookupAttachment(attName)
                     local att = self:GetAttachment(attId)
                     
                     if (att) then
                         view.origin = att.Pos
                         view.angles = att.Ang
                     end
                     return view
                 end, 1001)
                 self.ViewstackRegistered = true
             end
        end
    end

    if SERVER && IsValid(self.MyPly) then
        self.MyPly:SetActiveWeapon(nil)
        
        -- Enforce movement lock
        if (self.MyPly:GetMoveType() != MOVETYPE_NONE) then
            self.MyPly:SetMoveType(MOVETYPE_NONE)
            self.MyPly:Freeze(true)
        end
        
        if !self.MyPly:Alive() then
            self:Remove() 
        end 
    end

    self:NextThink(CurTime())
    return true 
end

function ENT:PhysicsCollide(data)end
