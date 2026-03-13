--fine...ill organize a bit...
local classicgreenmat = Material("ventrische/nvg/ui/greenmini.png")
local bluegreenmat = Material("ventrische/nvg/ui/whitemini.png")
local lightredmat = Material("ventrische/nvg/ui/redmini.png")
local bluebluemat = Material("ventrische/nvg/ui/bluemini.png")
--sounds n fonts
sound.Add({
	name = "vrnvg_elecsizzle",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 50,
	pitch = 100,
	sound = "ventrische/nvg/sizzlesizzle.mp3"
})

sound.Add({
	name = "vrnvg_elechum",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 50,
	pitch = 100,
	sound = "ventrische/nvg/hum.wav"
})

surface.CreateFont("vrnvgdigits", {
	font = "Sicret Mono PERSONAL Light",
	extended = false,
	size = 15,
	weight = 500,
	antialias = true,
	shadow = true --awful shadow
})

surface.CreateFont("vrnvgdigitsbig", {
	font = "Hind Vadodara SemiBold", --Futura Md BT
	extended = false,
	size = 48, --35
	weight = 1000, --500
	antialias = true,
	shadow = false
})

surface.CreateFont("vrnvgdigitsmenu", {
	font = "Futura Md BT",
	extended = false,
	size = 35,
	weight = 700,
	antialias = true,
	shadow = false
})

surface.CreateFont("vrnvgdigitsNOS", {
	font = "Sicret Mono PERSONAL Light",
	extended = false,
	size = 15,
	weight = 500,
	antialias = true,
	shadow = false
})

surface.CreateFont("vrnvgdigitsBIG", {
	font = "Sicret Mono PERSONAL Light",
	extended = false,
	size = 18,
	weight = 1000,
	antialias = true,
	shadow = false
})

surface.CreateFont("vrnvgdigitsBIGBOY", {
	font = "Hind Vadodara SemiBold",
	extended = false,
	size = 26,
	weight = 500,
	antialias = true,
	shadow = false
})

--presets
function vrnvg_bluegreen()
	local ply = LocalPlayer()
	if ply.vrnvgflipped then vrnvg_blur = 15 end
	vrnvgcolorpresettable[1] = Color(0, 240, 230) --255, 200
	vrnvgcolorpresettable[2] = 0
	vrnvgcolorpresettable[3] = 240
	vrnvgcolorpresettable[4] = 230
	vrnvgcolorpresettable[5] = 0
	vrnvgcolorpresettable[6] = .2
	vrnvgcolorpresettable[7] = .18 --.16
	vrnvgcolorpresettable[8] = .5
end

function vrnvg_lightblue()
	local ply = LocalPlayer()
	if ply.vrnvgflipped then vrnvg_blur = 15 end
	vrnvgcolorpresettable[1] = Color(0, 150, 255)
	vrnvgcolorpresettable[2] = 0
	vrnvgcolorpresettable[3] = 150
	vrnvgcolorpresettable[4] = 255
	vrnvgcolorpresettable[5] = .0
	vrnvgcolorpresettable[6] = .1
	vrnvgcolorpresettable[7] = .2
	vrnvgcolorpresettable[8] = .5
end

function vrnvg_lightred()
	local ply = LocalPlayer()
	if ply.vrnvgflipped then vrnvg_blur = 15 end
	vrnvgcolorpresettable[1] = Color(255, 30, 30) --was 255,35,35
	vrnvgcolorpresettable[2] = 255
	vrnvgcolorpresettable[3] = 70
	vrnvgcolorpresettable[4] = 70
	vrnvgcolorpresettable[5] = .25 --was .2
	vrnvgcolorpresettable[6] = .02
	vrnvgcolorpresettable[7] = .035 --was .02
	vrnvgcolorpresettable[8] = .5
end

function vrnvg_classicgreen()
	local ply = LocalPlayer()
	if ply.vrnvgflipped then vrnvg_blur = 15 end
	vrnvgcolorpresettable[1] = Color(50, 255, 50) --25, 255, 25
	vrnvgcolorpresettable[2] = 75
	vrnvgcolorpresettable[3] = 225
	vrnvgcolorpresettable[4] = 75
	vrnvgcolorpresettable[5] = .01
	vrnvgcolorpresettable[6] = .2
	vrnvgcolorpresettable[7] = .01
	vrnvgcolorpresettable[8] = .5
end

--3rd person nvgs
local showthirdpersonnvg = CreateConVar("vrnvg_thirdpersonmodel", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "show nvgs on players when they have it equipped")
local showclientthirdpersonnvg = CreateConVar("vrnvg_clientthirdpersonmodel", 0, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "show nvgs on yourself")
local offsetvec = Vector(-3, -2, 0)
local offsetang = Angle(0, -80, -90)
local fuckthisgodforsakenthing = false
hook.Add("PostPlayerDraw", "vrnvg_playernvgs", function(ply)
	--kinda terrible
	local pl = LocalPlayer()
	if not showthirdpersonnvg:GetBool() then return end
	if ply:GetViewEntity() == ply or not ply:Alive() then
		if ply.vrnvgplayermodel then
			ply.vrnvgplayermodel:Remove()
			ply.vrnvgplayermodel = nil
		end
		--[[if !showclientthirdpersonnvg:GetBool() then
							if ply == LocalPlayer() then return end
					end]]
	end

	if not showclientthirdpersonnvg:GetBool() then
		vrnvg_clientmodel = IsValid(ply) and ply != LocalPlayer()
	else
		vrnvg_clientmodel = IsValid(ply)
	end

	if vrnvg_clientmodel == true then --i think this worked
		if ply:GetModel() != "models/error.mdl" and ply:Alive() and ply:LookupBone("ValveBiped.Bip01_Head1") then
			local boneid = ply:LookupBone("ValveBiped.Bip01_Head1")
			local matrix = ply:GetBoneMatrix(boneid)
			local newpos, newang = LocalToWorld(offsetvec, offsetang, matrix:GetTranslation(), matrix:GetAngles())
			if ply:GetNW2Bool("vrnvgequipped") then
				if not ply.vrnvgplayermodel then
					ply.vrnvgplayermodel = ClientsideModel("models/ventrische/w_quadnods.mdl")
					ply.vrnvgplayermodel:SetNoDraw(false)
					if not ply:GetNW2Bool("vrnvgflipped") then
						ply.vrnvgplayermodel:ResetSequence("flipdown")
					else
						ply.vrnvgplayermodel:ResetSequence("flipup")
					end
				end

				if not ply:GetNW2Bool("vrnvgflipped") then
					if pl:GetViewEntity() == pl then
						ply.vrnvgplayermodel:ResetSequence("flipdown")
					elseif pl:GetViewEntity() != pl and not fuckthisgodforsakenthing then
						ply.vrnvgplayermodel:ResetSequence("flipdown")
						fuckthisgodforsakenthing = true
					end

					ply.vrnvgplayermodel:SetPlaybackRate(1)
					ply.vrnvgplayermodel:SetCycle(0)
				else
					if pl:GetViewEntity() == pl then
						ply.vrnvgplayermodel:ResetSequence("flipup")
					elseif pl:GetViewEntity() != pl and fuckthisgodforsakenthing then
						ply.vrnvgplayermodel:ResetSequence("flipup")
						fuckthisgodforsakenthing = false
					end

					ply.vrnvgplayermodel:SetPlaybackRate(1)
					ply.vrnvgplayermodel:SetCycle(0)
					fuckthisgodforsakenthing = false
				end

				ply.vrnvgplayermodel:SetPos(newpos)
				ply.vrnvgplayermodel:SetAngles(newang)
				ply.vrnvgplayermodel:SetupBones()
				ply.vrnvgplayermodel:FrameAdvance(ft)
				ply.vrnvgplayermodel:DrawModel()
			else
				if ply.vrnvgplayermodel then
					ply.vrnvgplayermodel:Remove()
					ply.vrnvgplayermodel = nil
				end
			end
		end
	end
end)

--sway and dlight on gun
vrnvgsway = {}
vrnvgsway.lerpx = 0
vrnvgsway.lerpy = 0
vrnvgsway.angle1 = 0
vrnvgsway.angle2 = 0
vrnvgsway.clampx = 0
vrnvgsway.clampy = 0
local function vrNVG_Miscellaneous()
	local ply = LocalPlayer()
	local eyeang = ply:EyeAngles()
	local ft = FrameTime()
	if not vrnvgcolorpresettable then
		vrnvgcolorpresettable = {
			[1] = Color(0, 240, 230);
			[2] = 0;
			[3] = 240;
			[4] = 230;
			[5] = .0;
			[6] = .2;
			[7] = .18;
			[8] = .5;
		}
	end

	if ply:GetViewEntity() == ply or not ply:Alive() then
		if ply.vrnvgplayermodel then
			ply.vrnvgplayermodel:Remove()
			ply.vrnvgplayermodel = nil
		end
	end

	--mw hud sway
	if ply.quadnodson then
		local rft = RealFrameTime() --was og frametime, was -25 25, was angle) * 2
		vrnvgsway.lerpx = Lerp(rft * 8, vrnvgsway.lerpx, math.Clamp(vrnvgsway.clampx + math.AngleDifference(eyeang.y * 2.25, vrnvgsway.angle1) * 4, -35, 35))
		vrnvgsway.lerpy = Lerp(rft * 8, vrnvgsway.lerpy, math.Clamp(vrnvgsway.clampy + math.AngleDifference(eyeang.p * 2.25, vrnvgsway.angle2) * 3, -35, 35))
		if vrnvgsway.angle1 != eyeang.y * 2.25 then vrnvgsway.angle1 = eyeang.y * 2.25 end
		if vrnvgsway.angle2 != eyeang.p * 2.25 then vrnvgsway.angle2 = eyeang.p * 2.25 end
	end

	--dlights for light on weapons
	if ply.quadnodsonlight and ply:Alive() then
		local vrnvgdlight = DynamicLight(ply:EntIndex())
		local styleofnvg = GetConVar("vrnvg_style")
		if vrnvgdlight then
			vrnvgdlight.pos = ply:GetShootPos()
			vrnvgdlight.r = vrnvgcolorpresettable[2]
			vrnvgdlight.g = vrnvgcolorpresettable[3]
			vrnvgdlight.b = vrnvgcolorpresettable[4]
			vrnvgdlight.Decay = 1000
			if styleofnvg:GetFloat() == 1 then
				vrnvgdlight.brightness = 0.5
				vrnvgdlight.Size = 250
				vrnvgdlight.DieTime = CurTime()
			elseif styleofnvg:GetFloat() == 2 then
				vrnvgdlight.brightness = 0.5
				vrnvgdlight.Size = 75
				vrnvgdlight.DieTime = CurTime()
			end
		end
	end
end

hook.Add("Think", "vrNVG_Miscellaneous_Hook", vrNVG_Miscellaneous)
--hiding default hud
local hide = {
	["CHudWeaponSelection"] = true
}

local function vrnvg_weaponblock(name)
	if blurtoggle then if hide[name] then return false end end
end

hook.Add("HUDShouldDraw", "vrnvg_weaponblock", vrnvg_weaponblock)
--qmenu stuff
hook.Add("PopulateToolMenu", "vrnvgtoolmenu", function()
	local ply = LocalPlayer()
	spawnmenu.AddToolMenuOption("Options", "COD: NVGs", "ventnvgsclient", "Configure", "", "", function(panel)
		panel:ClearControls()
		panel:AddControl("Header", {
			Description = "Made by venty\nAnimated by rische\n"
		})

		panel:AddControl("Checkbox", {
			Label = "Depth of Field (DOF)",
			Command = "vrnvg_blurdof"
		})

		panel:AddControl("Checkbox", {
			Label = "Edge-of-screen blur",
			Command = "vrnvg_edgeblur"
		})

		--panel:AddControl("Label", {Text = ""})
		panel:AddControl("Checkbox", {
			Label = "Show NVG Icon",
			Command = "vrnvg_hud"
		})

		panel:AddControl("Checkbox", {
			Label = "Show Battery Percentage",
			Command = "vrnvg_batteryhud"
		})

		panel:AddControl("Checkbox", {
			Label = "Play sound cue on battery recharge",
			Command = "vrnvg_batsound"
		})

		panel:AddControl("Checkbox", {
			Label = "Show NVGs on other players",
			Command = "vrnvg_thirdpersonmodel"
		})

		panel:AddControl("Checkbox", {
			Label = "Show NVGs on yourself",
			Command = "vrnvg_clientthirdpersonmodel"
		})

		panel:AddControl("Label", {
			Text = "^ In first-person your NVGs will duplicate when in front of a mirror. Only enable if playing in third-person."
		})

		panel:AddControl("Checkbox", {
			Label = "Use the default equip/flip key [N]",
			Command = "vrnvg_defkey"
		})

		panel:AddControl("Checkbox", {
			Label = "Sizzle NVGs when in direct light",
			Command = "vrnvg_sizzle"
		})

		panel:AddControl("Slider", {
			Label = "Bloom Amount (0.2)",
			Command = "vrnvg_bloom",
			Type = "float",
			Min = 0,
			Max = 0.5
		})

		panel:AddControl("Slider", {
			Label = "Contrast Amount (2)",
			Command = "vrnvg_contrast",
			Type = "float",
			Min = 1.5,
			Max = 2
		})

		panel:AddControl("Slider", {
			Label = "Overall Brightness (1)",
			Command = "vrnvg_brightness",
			Type = "float",
			Min = 0.1,
			Max = 1.0
		})

		panel:AddControl("Slider", {
			Label = "Visual Style",
			Command = "vrnvg_style",
			Min = 1,
			Max = 2
		})

		--panel:AddControl("Label", {Text = "1 - Default, 2 - IR Light"})
		--panel:AddControl("Label", {Text = "Re-flip your NVGs to see full changes!"})
		local label = vgui.Create("ax.label", panel) --this hook has forced my hand.
		label:SetColor(Color(0, 0, 0, 200))
		label:SetPos(18, 498)
		label:SetFont("vrnvgdigitsBIGBOY")
		label:SetText("Re-flip your NVGs to see all changes!")
		label:SizeToContents()
		local label = vgui.Create("ax.label", panel)
		label:SetColor(Color(156, 64, 64, 250))
		label:SetPos(17, 497)
		label:SetFont("vrnvgdigitsBIGBOY")
		label:SetText("Re-flip your NVGs to see all changes!")
		label:SizeToContents()
		local label = vgui.Create("ax.label", panel) --this hook has forced my hand.
		label:SetColor(Color(0, 0, 0, 200))
		label:SetPos(18, 541)
		label:SetFont("vrnvgdigitsBIGBOY")
		label:SetText("Phosphor/NVG Color Selection")
		label:SizeToContents()
		local label = vgui.Create("ax.label", panel)
		label:SetColor(Color(64, 64, 64, 250))
		label:SetPos(17, 540)
		label:SetFont("vrnvgdigitsBIGBOY")
		label:SetText("Phosphor/NVG Color Selection")
		label:SizeToContents()
		local yy = 555
		local yyy = 670
		vrnvgqmenu1 = vgui.Create("DButton", panel)
		vrnvgqmenu1:SetPos(-10, yy)
		vrnvgqmenu1:SetSize(180, 186)
		vrnvgqmenu1:SetText("")
		vrnvgqmenu1.Paint = function(self)
			draw.RoundedBox(15, 28 + 2, 15 + 2, 112, 112, Color(0, 0, 0, 100))
			draw.RoundedBox(15, 28, 15, 112, 112, Color(0, 0, 0, 100))
			surface.SetMaterial(lightredmat)
			surface.SetDrawColor(Color(0, 0, 0, 200))
			surface.DrawTexturedRect(28, 17, 112, 112)
			surface.SetDrawColor(Color(225, 50, 50, 225))
			surface.DrawTexturedRect(30, 15, 112, 112)
		end

		vrnvgqmenu1.DoClick = function()
			vrnvg_lightred()
			surface.PlaySound("ventrische/nvg/night_vision_on_c.wav")
		end

		vrnvgqmenu2 = vgui.Create("DButton", panel)
		vrnvgqmenu2:SetPos(135, yy)
		vrnvgqmenu2:SetSize(180, 186)
		vrnvgqmenu2:SetText("")
		vrnvgqmenu2.Paint = function(self)
			draw.RoundedBox(15, 28 + 2, 15 + 2, 112, 112, Color(0, 0, 0, 100))
			draw.RoundedBox(15, 28, 15, 112, 112, Color(0, 0, 0, 100))
			surface.SetMaterial(bluegreenmat)
			surface.SetDrawColor(Color(0, 0, 0, 200))
			surface.DrawTexturedRect(28, 17, 112, 112)
			surface.SetDrawColor(Color(50, 210, 210, 225))
			surface.DrawTexturedRect(30, 15, 112, 112)
		end

		vrnvgqmenu2.DoClick = function()
			vrnvg_bluegreen()
			surface.PlaySound("ventrische/nvg/night_vision_on_c.wav")
		end

		vrnvgqmenu3 = vgui.Create("DButton", panel)
		vrnvgqmenu3:SetPos(-10, yyy)
		vrnvgqmenu3:SetSize(180, 186)
		vrnvgqmenu3:SetText("")
		vrnvgqmenu3.Paint = function(self)
			draw.RoundedBox(15, 28 + 2, 15 + 2, 112, 112, Color(0, 0, 0, 100))
			draw.RoundedBox(15, 28, 15, 112, 112, Color(0, 0, 0, 100))
			surface.SetMaterial(bluebluemat)
			surface.SetDrawColor(Color(0, 0, 0, 200))
			surface.DrawTexturedRect(28, 17, 112, 112)
			surface.SetDrawColor(Color(0, 150, 225, 225))
			surface.DrawTexturedRect(30, 15, 112, 112)
		end

		vrnvgqmenu3.DoClick = function()
			vrnvg_lightblue()
			surface.PlaySound("ventrische/nvg/night_vision_on_c.wav")
		end

		vrnvgqmenu4 = vgui.Create("DButton", panel)
		vrnvgqmenu4:SetPos(135, yyy)
		vrnvgqmenu4:SetSize(180, 186)
		vrnvgqmenu4:SetText("")
		vrnvgqmenu4.Paint = function(self)
			draw.RoundedBox(15, 28 + 2, 15 + 2, 112, 112, Color(0, 0, 0, 100))
			draw.RoundedBox(15, 28, 15, 112, 112, Color(0, 0, 0, 100))
			surface.SetMaterial(classicgreenmat)
			surface.SetDrawColor(Color(0, 0, 0, 200))
			surface.DrawTexturedRect(28, 17, 112, 112)
			surface.SetDrawColor(Color(50, 200, 50, 225))
			surface.DrawTexturedRect(30, 15, 112, 112)
		end

		vrnvgqmenu4.DoClick = function()
			vrnvg_classicgreen()
			surface.PlaySound("ventrische/nvg/night_vision_on_c.wav")
		end
	end)

	spawnmenu.AddToolMenuOption("Options", "COD: NVGs", "ventnvgsserver", "Misc/Battery", "", "", function(panel)
		panel:ClearControls()
		panel:AddControl("Header", {
			Description = "Made by venty\nAnimated by rische\n"
		})

		--panel:AddControl("Label", {Text = "Singleplayer/Admin-only settings."})
		--panel:AddControl("Label", {Text = "(Servers may have to change these via RCON.)"})
		panel:AddControl("Slider", {
			Label = "Battery Drain Rate",
			Command = "vrnvg_drainrate",
			Type = "float",
			Min = 0,
			Max = 10
		})

		panel:AddControl("Slider", {
			Label = "Battery Recharge Rate",
			Command = "vrnvg_rechargerate",
			Type = "float",
			Min = 0,
			Max = 10
		})

		panel:AddControl("Slider", {
			Label = "Sacrifice Chance",
			Command = "vrnvg_blockchance",
			Min = 0,
			Max = 100
		})

		panel:AddControl("Label", {
			Text = "^ The chance of your NVGs taking a bullet."
		})
	end)
end)

--derma....
local function vrnvg_closecolormenu()
	if vrnvgframe then
		vrnvgframe:AlphaTo(0, 0.25)
		timer.Simple(0.25, function()
			if vrnvgframe then
				vrnvgframe:Remove()
				vrnvgframe = nil
			end
		end)

		closedisbiatch = true
	end
end

local function vrnvg_colormenu()
	if vrnvgframe then
		vrnvgframe:Remove()
		vrnvgframe = nil
	end

	vrnvgframe = vgui.Create("DFrame")
	vrnvgframe:SetAlpha(0)
	vrnvgframe:AlphaTo(255, 0.25)
	vrnvgframe:SetSize(825, 250)
	vrnvgframe:SetTitle("")
	vrnvgframe:ShowCloseButton(false)
	vrnvgframe:Center()
	vrnvgframe:MakePopup()
	vrnvgframe:SetDraggable(false)
	vrnvgframe.lerp1 = 0
	vrnvgframe.Paint = function(self)
		vrnvgframe.lerp1 = Lerp(FrameTime() * 6, vrnvgframe.lerp1, 825)
		draw.RoundedBox(0, 415 - vrnvgframe.lerp1 / 2, 0, vrnvgframe.lerp1, self:GetTall(), Color(0, 0, 0, 125))
	end

	vrnvgbutton1 = vgui.Create("DButton", vrnvgframe)
	vrnvgbutton1:SetAlpha(0)
	vrnvgbutton1:AlphaTo(255, 1.5)
	vrnvgbutton1:SetPos(25, 35)
	vrnvgbutton1:SetSize(180, 186)
	vrnvgbutton1:SetText("")
	vrnvgbutton1.lerp1 = 0
	vrnvgbutton1.lerp2 = 0
	vrnvgbutton1.lerp3 = 0
	vrnvgbutton1.Paint = function(self)
		local ft = FrameTime()
		if self:IsHovered() then
			self.lerp1 = Lerp(ft * 6, self.lerp1, 25)
			self.lerp2 = Lerp(ft * 6, self.lerp2, 150)
			self.lerp3 = Lerp(ft * 10, self.lerp3, 0)
		else
			self.lerp1 = Lerp(ft * 6, self.lerp1, 0)
			self.lerp2 = Lerp(ft * 6, self.lerp2, 0)
			self.lerp3 = Lerp(ft * 6, self.lerp3, 200)
		end

		draw.RoundedBox(self.lerp1 / 2, 2, 66 - self.lerp1 * 2.5, 170, 30 + self.lerp2, Color(0, 0, 0, 100))
		draw.RoundedBox(self.lerp1 / 2, 0, 64 - self.lerp1 * 2.5, 170, 30 + self.lerp2, Color(0, 0, 0, 100))
		draw.SimpleText("RED", "vrnvgdigitsmenu", 87, 82 + self.lerp2 / 2.5, Color(0, 0, 0, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("RED", "vrnvgdigitsmenu", 85, 80 + self.lerp2 / 2.5, Color(150 + self.lerp2, 50, 50, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		surface.SetMaterial(lightredmat)
		surface.SetDrawColor(Color(0, 0, 0, self.lerp2 / 1.5))
		surface.DrawTexturedRect(28, 17, 112, 112)
		surface.SetDrawColor(Color(150 + self.lerp2 / 2, 50, 50, self.lerp2))
		surface.DrawTexturedRect(30, 15, 112, 112)
	end

	vrnvgbutton1.DoClick = function()
		vrnvg_closecolormenu()
		vrnvg_lightred()
		surface.PlaySound("ventrische/nvg/night_vision_on_c.wav")
	end

	vrnvgbutton2 = vgui.Create("DButton", vrnvgframe)
	vrnvgbutton2:SetAlpha(0)
	vrnvgbutton2:AlphaTo(255, 1.5)
	vrnvgbutton2:SetPos(225, 35)
	vrnvgbutton2:SetSize(180, 186)
	vrnvgbutton2:SetText("")
	vrnvgbutton2.lerp1 = 0
	vrnvgbutton2.lerp2 = 0
	vrnvgbutton2.lerp3 = 0
	vrnvgbutton2.Paint = function(self)
		local ft = FrameTime()
		if self:IsHovered() then
			self.lerp1 = Lerp(ft * 6, self.lerp1, 25)
			self.lerp2 = Lerp(ft * 6, self.lerp2, 150)
			self.lerp3 = Lerp(ft * 10, self.lerp3, 0)
		else
			self.lerp1 = Lerp(ft * 6, self.lerp1, 0)
			self.lerp2 = Lerp(ft * 6, self.lerp2, 0)
			self.lerp3 = Lerp(ft * 6, self.lerp3, 200)
		end

		draw.RoundedBox(self.lerp1 / 2, 2, 66 - self.lerp1 * 2.5, 170, 30 + self.lerp2, Color(0, 0, 0, 100))
		draw.RoundedBox(self.lerp1 / 2, 0, 64 - self.lerp1 * 2.5, 170, 30 + self.lerp2, Color(0, 0, 0, 100))
		draw.SimpleText("WHITE", "vrnvgdigitsmenu", 87, 82 + self.lerp2 / 2.5, Color(0, 0, 0, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("WHITE", "vrnvgdigitsmenu", 85, 80 + self.lerp2 / 2.5, Color(0, 150 + self.lerp2, 150 + self.lerp2 / 2, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		surface.SetMaterial(bluegreenmat)
		surface.SetDrawColor(Color(0, 0, 0, self.lerp2 / 1.5))
		surface.DrawTexturedRect(28, 17, 112, 112)
		surface.SetDrawColor(Color(0, 150 + self.lerp2 / 2, 150 + self.lerp2 / 3, self.lerp2))
		surface.DrawTexturedRect(30, 15, 112, 112)
	end

	vrnvgbutton2.DoClick = function()
		vrnvg_closecolormenu()
		vrnvg_bluegreen()
		surface.PlaySound("ventrische/nvg/night_vision_on_c.wav")
	end

	vrnvgbutton3 = vgui.Create("DButton", vrnvgframe)
	vrnvgbutton3:SetAlpha(0)
	vrnvgbutton3:AlphaTo(255, 1.5)
	vrnvgbutton3:SetPos(425, 35)
	vrnvgbutton3:SetSize(180, 186)
	vrnvgbutton3:SetText("")
	vrnvgbutton3.lerp1 = 0
	vrnvgbutton3.lerp2 = 0
	vrnvgbutton3.lerp3 = 0
	vrnvgbutton3.Paint = function(self)
		local ft = FrameTime()
		if self:IsHovered() then
			self.lerp1 = Lerp(ft * 6, self.lerp1, 25)
			self.lerp2 = Lerp(ft * 6, self.lerp2, 150)
			self.lerp3 = Lerp(ft * 10, self.lerp3, 0)
		else
			self.lerp1 = Lerp(ft * 6, self.lerp1, 0)
			self.lerp2 = Lerp(ft * 6, self.lerp2, 0)
			self.lerp3 = Lerp(ft * 6, self.lerp3, 200)
		end

		draw.RoundedBox(self.lerp1 / 2, 2, 66 - self.lerp1 * 2.5, 170, 30 + self.lerp2, Color(0, 0, 0, 100))
		draw.RoundedBox(self.lerp1 / 2, 0, 64 - self.lerp1 * 2.5, 170, 30 + self.lerp2, Color(0, 0, 0, 100))
		draw.SimpleText("BLUE", "vrnvgdigitsmenu", 87, 82 + self.lerp2 / 2.5, Color(0, 0, 0, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("BLUE", "vrnvgdigitsmenu", 85, 80 + self.lerp2 / 2.5, Color(0, 100 + self.lerp2 / 2, 150 + self.lerp2, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		surface.SetMaterial(bluebluemat)
		surface.SetDrawColor(Color(0, 0, 0, self.lerp2 / 1.5))
		surface.DrawTexturedRect(28, 17, 112, 112)
		surface.SetDrawColor(Color(0, 100 + self.lerp2 / 3, 150 + self.lerp2 / 2, self.lerp2))
		surface.DrawTexturedRect(30, 15, 112, 112)
	end

	vrnvgbutton3.DoClick = function()
		vrnvg_closecolormenu()
		vrnvg_lightblue()
		surface.PlaySound("ventrische/nvg/night_vision_on_c.wav")
	end

	vrnvgbutton4 = vgui.Create("DButton", vrnvgframe)
	vrnvgbutton4:SetAlpha(0)
	vrnvgbutton4:AlphaTo(255, 1.5)
	vrnvgbutton4:SetPos(625, 35)
	vrnvgbutton4:SetSize(180, 186)
	vrnvgbutton4:SetText("")
	vrnvgbutton4.lerp1 = 0
	vrnvgbutton4.lerp2 = 0
	vrnvgbutton4.lerp3 = 0
	vrnvgbutton4.Paint = function(self)
		local ft = FrameTime()
		if self:IsHovered() then
			self.lerp1 = Lerp(ft * 6, self.lerp1, 25)
			self.lerp2 = Lerp(ft * 6, self.lerp2, 150)
			self.lerp3 = Lerp(ft * 10, self.lerp3, 0)
		else
			self.lerp1 = Lerp(ft * 6, self.lerp1, 0)
			self.lerp2 = Lerp(ft * 6, self.lerp2, 0)
			self.lerp3 = Lerp(ft * 6, self.lerp3, 200)
		end

		draw.RoundedBox(self.lerp1 / 2, 2, 66 - self.lerp1 * 2.5, 170, 30 + self.lerp2, Color(0, 0, 0, 100))
		draw.RoundedBox(self.lerp1 / 2, 0, 64 - self.lerp1 * 2.5, 170, 30 + self.lerp2, Color(0, 0, 0, 100))
		draw.SimpleText("GREEN", "vrnvgdigitsmenu", 87, 82 + self.lerp2 / 2.5, Color(0, 0, 0, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("GREEN", "vrnvgdigitsmenu", 85, 80 + self.lerp2 / 2.5, Color(0, 150 + self.lerp2 / 2, 0, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		surface.SetMaterial(classicgreenmat)
		surface.SetDrawColor(Color(0, 0, 0, self.lerp2 / 1.5))
		surface.DrawTexturedRect(28, 17, 112, 112)
		surface.SetDrawColor(Color(0, 150 + self.lerp2 / 3, 0, self.lerp2))
		surface.DrawTexturedRect(30, 15, 112, 112)
	end

	vrnvgbutton4.DoClick = function()
		vrnvg_closecolormenu()
		vrnvg_classicgreen()
		surface.PlaySound("ventrische/nvg/night_vision_on_c.wav")
	end
end

concommand.Add("+vrnvgcolormenu", function(ply)
	if not closedisbiatch and ply.vrnvgflipped and not ply.vrnvgbroken and not ply.nvgnobattery then
		surface.PlaySound("ventrische/nvg/ventycustom/menuopen.mp3")
		vrnvg_colormenu()
		closedisbiatch = true
	end
end)

concommand.Add("-vrnvgcolormenu", function(ply)
	if not vrnvgframe then closedisbiatch = false end
	if vrnvgframe and closedisbiatch then
		vrnvg_closecolormenu()
		closedisbiatch = false
	end
end)
