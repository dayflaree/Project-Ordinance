-- if you're reading this you're now gay
local enabledofblur = CreateConVar("vrnvg_blurdof", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "best blur mankind has ever made")
local enableedgeblur = CreateConVar("vrnvg_edgeblur", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "blur around the edges of your screen")
local showbathud = CreateConVar("vrnvg_batteryhud", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "cool hud for battery")
local shownewhud = CreateConVar("vrnvg_hud", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "cool hud for equipping")
local batterysound = CreateConVar("vrnvg_batsound", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "cool custom sound when recharged")
local defaultkey = CreateConVar("vrnvg_defkey", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "")
local bloomamount = CreateConVar("vrnvg_bloom", 0.2, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "", 0, 0.5)
local contrastamount = CreateConVar("vrnvg_contrast", 2, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "", 1.5, 2)
local brightnessnshit = CreateConVar("vrnvg_brightness", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "")
local styleofnvg = CreateConVar("vrnvg_style", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "")
local sizzlesounds = CreateConVar("vrnvg_sizzle", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE}, "", 0, 1)
file.CreateDir("nvgs")
--server cvars
local drainrate = CreateConVar("vrnvg_drainrate", 0.70, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The battery drain rate for the NVGs.", 0, 10)
local rechargerate = CreateConVar("vrnvg_rechargerate", 1, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The battery recharge rate for the NVGs.", 0, 10)
local blockchance = CreateConVar("vrnvg_blockchance", 25, {FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The chance of the NVGs taking a bullet for you.", 0, 100)
for k, v in ipairs(engine.GetAddons()) do
	if v.wsid == "167545348" and v.mounted then
		print("Manual Weapon Pickup is installed. Unsubscribe from it for Modern Warfare NVGs to work.")
		timer.Create("vrnvgterribleaddon1", 7, 1, function()
			chat.PlaySound()
			chat.AddText(Color(0, 255, 200), "Manual Weapon Pickup is installed. Unsubscribe from it for Modern Warfare NVGs to work.")
		end)
	end
end

net.Receive("vrnvgwarzone", function() RunConsoleCommand("vrnvgequip") end)
local rx, gx, bx, ry, gy, by = 0, 0, 0, 0, 0, 0
local black = Material("vrview/black.png")
local ca_r = CreateMaterial("ca_r", "UnlitGeneric", {
	["$basetexture"] = "vgui/black",
	["$color2"] = "[1 0 0]",
	["$additive"] = 1,
	["$ignorez"] = 1
})

local ca_g = CreateMaterial("ca_g", "UnlitGeneric", {
	["$basetexture"] = "vgui/black",
	["$color2"] = "[0 1 0]",
	["$additive"] = 1,
	["$ignorez"] = 1
})

local ca_b = CreateMaterial("ca_b", "UnlitGeneric", {
	["$basetexture"] = "vgui/black",
	["$color2"] = "[0 0 1]",
	["$additive"] = 1,
	["$ignorez"] = 1
})

local function vrnvg_chromatic(rx, gx, bx, ry, gy, by)
	local w, h = ScrW(), ScrH()
	render.UpdateScreenEffectTexture()
	local screentx = render.GetScreenEffectTexture()
	ca_r:SetTexture("$basetexture", screentx)
	ca_g:SetTexture("$basetexture", screentx)
	ca_b:SetTexture("$basetexture", screentx)
	--black, needs to be a png or something else in order to not fuck over HUD elements
	render.SetMaterial(black)
	render.DrawScreenQuad()
	--red
	render.SetMaterial(ca_r)
	render.DrawScreenQuadEx(-rx / 2, -ry / 2, w + rx, h + ry)
	--green
	render.SetMaterial(ca_g)
	render.DrawScreenQuadEx(-gx / 2, -gy / 2, w + gx, h + gy)
	--blue
	render.SetMaterial(ca_b)
	render.DrawScreenQuadEx(-bx / 2, -by / 2, w + bx, h + by)
end

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

local blur = Material("pp/blurscreen")
local blurtoggle = false
vrnvg_blur = 0
local function DrawBlur()
	local w, h = ScrW(), ScrH()
	surface.SetMaterial(blur)
	surface.SetDrawColor(255, 255, 255, 255)
	if ax.client:GetViewEntity() != ax.client then return end
	for i = 1, vrnvg_blur do
		blur:SetFloat("$blur", (i / vrnvg_blur) * vrnvg_blur)
		blur:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(0, 0, w, h) --fades out near bottom (edit: not anymore, was h*1.2 )
	end
end

local function vrNVG_Sensitivity()
	if blurtoggle then return 0.75 end
end

hook.Add("AdjustMouseSensitivity", "vrNVG_Sensitivity", vrNVG_Sensitivity)
local edgeblurtex = Material("pp/toytown-top")
local function EdgeBlur(passed, H)
	if not enableedgeblur:GetBool() then return end
	surface.SetMaterial(edgeblurtex)
	surface.SetDrawColor(255, 255, 255, 255)
	for i = 1, passed do
		render.CopyRenderTargetToTexture(render.GetScreenEffectTexture())
		surface.DrawTexturedRect(0, 0, ScrW(), H)
		surface.DrawTexturedRectUV(0, ScrH() - H, ScrW(), H, 0, 1, 1, 0)
		surface.DrawTexturedRectRotated(0, 0, ScrW(), H * 6, 90)
		surface.DrawTexturedRectRotated(ScrW(), 0, ScrW(), H * 6, -90)
	end
end

local function vrplayanim(seq, time)
	local client = ax.client
	if time then
		blurtoggle = true
		timer.Simple(time, function() blurtoggle = false end)
	end

	if client.vrnvgcam then
		client.vrnvgcam:ResetSequence(seq)
		client.vrnvgcam:SetPlaybackRate(1)
		client.vrnvgcam:SetCycle(0)
	end

	if client.vrnvgmodel then
		client.vrnvgmodel:ResetSequence(seq)
		client.vrnvgmodel:SetPlaybackRate(1)
		client.vrnvgmodel:SetCycle(0)
	end
end

--nvg equipping
local nvgflashlerp = 0
net.Receive("vrnvgnetequip", function()
	local boolin = net.ReadBool()
	local client = ax.client
	client.vrnvgequipped = boolin
	if boolin then
		vrplayanim("equip", 1.8)
	else
		vrplayanim("unequip", 1.8) --https://i.imgur.com/UnxjyWy.png
	end
end)

--nvg flipping
net.Receive("vrnvgnetflip", function()
	local boolin = net.ReadBool()
	local client = ax.client
	if boolin then
		client.vrnvgflipped = boolin
		surface.PlaySound("ventrische/nvg/flipdown.mp3")
		timer.Simple(.75, function()
			client.quadnodson = true
			client.quadnodsonlight = true
			--nvg projectedtexture light, no other nvg workshop mod had this on release day (uhhh yeah of course im gonna brag about that..)
			if not client.nvglightdraw then
				client.nvglightdraw = ProjectedTexture()
				client.nvglightdraw:SetTexture("effects/flashlight/soft")
				client.nvglightdraw:SetEnableShadows(false)
				if styleofnvg:GetFloat() == 1 then
					client.nvglightdraw:SetFOV(140)
					client.nvglightdraw:SetVerticalFOV(100)
					client.nvglightdraw:SetBrightness(1 * brightnessnshit:GetFloat())
				elseif styleofnvg:GetFloat() == 2 then
					client.nvglightdraw:SetFOV(60)
					client.nvglightdraw:SetVerticalFOV(55)
					client.nvglightdraw:SetBrightness(2 * brightnessnshit:GetFloat())
				end

				client.nvglightdraw:Update()
			end

			surface.PlaySound("ventrische/nvg/night_vision_on.wav")
			nvgflashlerp = 255
		end)

		vrplayanim("flipdown", 1.3)
	else
		if client.nvglightdraw or client.nvgnobattery then
			surface.PlaySound("ventrische/nvg/flipup.mp3")
			timer.Simple(.25, function()
				client.vrnvgflipped = boolin
				client.quadnodson = false
				if not client.nvgnobattery then
					client.nvglightdraw:Remove()
					client.nvglightdraw = nil
				else
					client.nvgnobattery = false
				end

				surface.PlaySound("ventrische/nvg/night_vision_off.wav")
			end)

			timer.Simple(.22, function()
				--was .20
				client.quadnodsonlight = false
			end)

			vrplayanim("flipup", 1.1)
		end
	end
end)

--nvg just break the thing
local glassposx = 0
local glassposy = 0
net.Receive("vrnvgnetbreakeasymode", function()
	local boolin = net.ReadBool()
	local client = ax.client
	glassposx = math.random(2.5, 1.75)
	glassposy = math.random(4, 20)
	if boolin then
		surface.PlaySound("ventrische/nvg/night_vision_off.wav")
		surface.PlaySound("ventrische/nvg/glasscrack.mp3")
		client.vrnvgbroken = true
		client.nvgnobattery = false
		if client.nvglightdraw then
			client.nvglightdraw:Remove()
			client.nvglightdraw = nil
		end

		client.quadnodsonlight = false
	end
end)

--nvg toss when broken
local vrnvg_curbroken = false
net.Receive("vrnvgnetbreak", function()
	local boolin = net.ReadBool()
	local client = ax.client
	if boolin then
		client.vrnvgequipped = false
		client.vrnvgflipped = false
		surface.PlaySound("ventrische/nvg/breaktoss.mp3")
		vrplayanim("breaktoss", 4.82)
		vrnvg_curbroken = true
		timer.Simple(.3, function()
			client.vrnvgbroken = false
			client.nvgnobattery = false
			client.quadnodson = false
		end)

		timer.Simple(5.5, function() vrnvg_curbroken = false end)
	end
end)

--the meat
local viggy = Material("vrview/ventwhitevig")
local battery = Material("ventrische/nvg/ui/tinybattery.png")
local linebar = Material("ventrische/nvg/ui/linebar8.png")
local scale = Material("ventrische/nvg/ui/scale.png")
local moon = Material("ventrische/nvg/ui/moonnn.png")
local sun = Material("ventrische/nvg/ui/sunnn.png")
local broken = Material("vrview/fx_distort")
local crackref = Material("vrview/glass/glasscrack")
local crack1 = Material("vrview/glass/glasscrack.png")
local crackref2 = Material("vrview/glass/glasscrack2")
local crack2 = Material("vrview/glass/glasscrack20.png") --layering makes it look pretty good
local crackref3 = Material("vrview/glass/glasscrack3")
local crack3 = Material("vrview/glass/glasscrack3.png")
local lightcolor = 0
local lightcolor2 = 0
local humlevel = 0.5
local batteryoffnvgs = 0
local ooga = {}
local nvgbatterylerp = 100
local function vrnvg_hudbackground()
	local client = ax.client
	local ft = FrameTime()
	local eang, epos = EyeAngles(), EyePos()
	local w, h = ScrW(), ScrH()
	local p, q = vrnvgsway.lerpx * 1.1, -vrnvgsway.lerpy * 1.1
	local bluegreencolor = Color(vrnvgcolorpresettable[2], vrnvgcolorpresettable[3], vrnvgcolorpresettable[4], 100)
	local nvgs = client.vrnvgmodel
	local nvgcam = client.vrnvgcam
	if not client:Alive() or not ax.util:IsValidPlayer(client) then --reset on death/spawn
		local viewmodel = client:GetViewModel()
		vrnvg_blur = 0
		client:StopSound("vrnvg_elecsizzle")
		client:StopSound("vrnvg_elechum")
		client.quadnodson = false
		client.vrnvgequipped = false
		client.vrnvgflipped = false
		client.quadnodsonlight = false
		client.vrnvgbroken = false
		if client.vrnvgmodel then
			client.vrnvgmodel:Remove()
			client.vrnvgmodel = nil
			client.vrnvgcam:Remove()
			client.vrnvgcam = nil
		end

		if client.nvglightdraw then
			client.nvglightdraw:Remove()
			client.nvglightdraw = nil
		end

		if IsValid(viewmodel) then if viewmodel:GetSequence() != viewmodel:LookupSequence("idleoff") then vrplayanim("idleoff") end end
		return
	end

	if not client.nvgbattery then client.nvgbattery = 80 end
	if client.vrnvgequipped then
		net.Start("vrnvgnetflashlight")
		net.WriteBool(client.vrnvgflipped and client.nvgbattery > 0 and not client.vrnvgbroken)
		net.SendToServer()
		client.nvgbattery = client:GetNW2Int("vrnvgbattery")
		nvgbatterylerp = Lerp(RealFrameTime() * 1, nvgbatterylerp, client.nvgbattery)
	end

	--[[if vrnvg_blur > 0 and enabledofblur:GetBool() then
		DrawBlur() 
	end]]
	if blurtoggle then
		vrnvg_blur = math.Approach(vrnvg_blur, 4, ft * 20)
	elseif client.quadnodson then
		if client.nvgbattery >= 40 then
			vrnvg_blur = math.Approach(vrnvg_blur, math.random(1, 2), ft * 20)
			humlevel = 0.5
		elseif client.nvgbattery < 40 and client.nvgbattery >= 20 then
			vrnvg_blur = math.Approach(vrnvg_blur, math.random(1, 3), ft * 15)
			humlevel = 0.8
		elseif client.nvgbattery < 20 and client.nvgbattery > 0 then
			vrnvg_blur = math.Approach(vrnvg_blur, math.random(1, 4), ft * 10)
			humlevel = 1
		end
	else
		humlevel = 0.5
		vrnvg_blur = math.Approach(vrnvg_blur, 0, ft * 25)
	end

	--reminder: ignorez wuz here 
	local nvgs = client.vrnvgmodel
	local nvgcam = client.vrnvgcam
	cam.Start3D(epos, eang, 100, 0, 0, w, h, 1, 35)
	if nvgs and client.vrnvghand then
		nvgs:SetPos(epos + Vector(0, 0, 0.3))
		nvgs:SetAngles(eang)
		nvgs:SetupBones()
		nvgs:FrameAdvance(ft)
		client.vrnvghand:SetupBones()
		nvgcam:SetPos(Vector(0, 0, 0))
		nvgcam:SetAngles(Angle(0, 0, 0))
		nvgcam:FrameAdvance(ft)
		client.nvgcamattach = nvgcam:GetAttachment(nvgcam:LookupAttachment("Camera"))
		if client:GetViewEntity() == client and not client:ShouldDrawLocalPlayer() and not sky3d then nvgs:DrawModel() end
	end

	cam.End3D()
	--broken/no battery HUD
	if client.vrnvgbroken or client.nvgnobattery then
		surface.SetDrawColor(Color(255, 255, 255, 255))
		surface.SetMaterial(broken)
		surface.DrawTexturedRect(0, 0, w, h)
	end

	--text battery HUD
	if client.vrnvgequipped and not client.quadnodson and not client.vrnvgbroken and showbathud:GetBool() and client:GetViewEntity() == client then
		local nodbone = nvgs:LookupBone("nod")
		local nodbonep = nvgs:GetBonePosition(nodbone)
		if nodbonep == nvgs:GetPos() then nodbonep = nvgs:GetBoneMatrix(nodbone):GetTranslation() end
		ooga = nodbonep:ToScreen()
		local n, m = math.Round(ooga.x, 0), math.Round(ooga.y, 0)
		local percentage = math.Round(client.nvgbattery * 1.25, 0) .. "%"
		draw.SimpleText(percentage, "vrnvgdigitsbig", n + 3, m + 150 + 3, Color(18, 18, 18, batteryoffnvgs / 1.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(percentage, "vrnvgdigitsbig", n, m + 150, Color(255, 255, 255, batteryoffnvgs), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if batterynvg2dfade or client.nvgbattery > 77 then
			batteryoffnvgs = Lerp(ft * 6, batteryoffnvgs, 0)
		else
			batteryoffnvgs = Lerp(ft, batteryoffnvgs, 200)
		end
	end

	--misc sounds and sizzle
	if client.quadnodson then
		if client.vrnvgflipped and batterysound:GetBool() then rechargedsoundplayedomg = true end
		if not nvghummingrepeat or SysTime() >= nvghummingrepeat then
			nvghummingrepeat = SysTime() + 10 --lazy
			client:EmitSound("vrnvg_elechum", 75, 100, humlevel)
		end

		if client.nvgbattery == 0 then
			client.nvgnobattery = true
			if client.nvglightdraw then
				client.nvglightdraw:Remove()
				client.nvglightdraw = nil
				surface.PlaySound("ventrische/nvg/night_vision_off_c.wav")
			end

			client.quadnodsonlight = false
		end
	else
		if rechargedsoundplayedomg and client.nvgbattery > 77 and not client.vrnvgbroken and client.nvgbattery != 80 then
			surface.PlaySound("ventrische/nvg/ventycustom/recharged.mp3")
			rechargedsoundplayedomg = false
		end

		if client.nvgbattery > 0 then client.nvgnobattery = false end
		nvghummingrepeat = SysTime()
		client:StopSound("vrnvg_elechum")
	end

	--lens crack/glass crack
	if client.vrnvgbroken or client.nvgnobattery then
		client:StopSound("vrnvg_elechum")
		surface.SetDrawColor(Color(0, 0, 0, 255))
		surface.SetMaterial(viggy)
		surface.DrawTexturedRect(0, 0, w, h)
		if not client.nvgnobattery then
			surface.SetDrawColor(Color(255, 255, 255, 50))
			surface.SetMaterial(crack1)
			surface.DrawTexturedRect(w / glassposx, h / glassposy, 1000, 1000)
			surface.SetDrawColor(Color(255, 255, 255, 255))
			surface.SetMaterial(crackref)
			surface.DrawTexturedRect(w / glassposx, h / glassposy, 1000, 1000)
			surface.SetDrawColor(Color(255, 255, 255, 50))
			surface.SetMaterial(crack2)
			surface.DrawTexturedRect(w * .1 - 200, h / 2 + 110, 1000, 1000)
			surface.SetDrawColor(Color(255, 255, 255, 255))
			surface.SetMaterial(crackref2)
			surface.DrawTexturedRect(w * .1 - 200, h / 2 + 110, 1000, 1000)
			surface.SetDrawColor(Color(255, 255, 255, 50))
			surface.SetMaterial(crack3)
			surface.DrawTexturedRect(w * .1 - 700, h / 5 - 700, 1000, 1000)
		end
	end

	--sizzle sound, light blinding, main HUD
	local tr = util.QuickTrace(client:GetShootPos() + client:EyeAngles():Forward() * 250, gui.ScreenToVector(gui.MousePos()), client)
	local lightcolorreg = render.GetLightColor(client:GetPos())
	local lightcoloreye = render.GetLightColor(tr.HitPos)
	local lightcolorreg2 = lightcolorreg.r / 3 + lightcolorreg.g / 3 + lightcolorreg.b / 3
	local lightcoloreye2 = lightcoloreye.r / 3 + lightcoloreye.g / 3 + lightcoloreye.b / 3
	local lightcolorclamp = math.Clamp(lightcolorreg2, 0.003332, .45)
	local lightcoloreyeclamp = math.Clamp(lightcoloreye2, 0.003332, .45)
	lightcolor = Lerp(ft * 4, lightcolor, lightcolorclamp)
	lightcolor2 = Lerp(ft * 4, lightcolor2, lightcoloreyeclamp)
	if client.nvglightdraw then
		client.nvglightdraw:SetColor(vrnvgcolorpresettable[1])
		client.nvglightdraw:SetFarZ(10000)
		if client:GetViewEntity() == client then
			client.nvglightdraw:SetPos(client:GetPos() + Vector(0, 0, 50))
			client.nvglightdraw:SetAngles(client:EyeAngles())
		else
			nvghummingrepeat = SysTime()
			client:StopSound("vrnvg_elechum")
			client.nvglightdraw:SetPos(client:GetPos() + Vector(0, 0, 2400000000))
			client.nvglightdraw:SetAngles(Angle(90, 0, 0))
		end

		client.nvglightdraw:Update()
		--draw.RoundedBox(0, 0, 0, w, h, Color(255,255,255,nvgflashlerp)) / old layer position for flip flash
		nvgflashlerp = math.Approach(nvgflashlerp, 0, RealFrameTime() * 700) --600
		if lightcolor > 0.3 then
			if sizzlesounds:GetFloat() > 0 then
				if not nvgsizzlerepeat or SysTime() >= nvgsizzlerepeat then
					client:EmitSound("vrnvg_elecsizzle")
					nvgsizzlerepeat = SysTime() + 24 --lazy
				end
			end
		elseif lightcolor > 0.1 then
			if nvglightmeter then
				surface.PlaySound("ventrische/nvg/night_vision_lightmeter_warning.wav")
				nvglightmeter = false
			end

			nvgsizzlerepeat = SysTime()
			client:StopSound("vrnvg_elecsizzle")
		else
			nvglightmeter = true
			nvgsizzlerepeat = SysTime()
			client:StopSound("vrnvg_elecsizzle")
		end

		surface.SetDrawColor(Color(0, 0, 0, 255))
		surface.SetMaterial(viggy)
		surface.DrawTexturedRect(0, 0, w, h)
		--battery progress bar hud
		if client.nvgbattery < 18 then
			render.PushFilterMag(TEXFILTER.ANISOTROPIC)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
			surface.SetDrawColor(Color(21, 21, 21, 125))
			surface.SetMaterial(battery)
			surface.DrawTexturedRect(w / 4 - 219 + p, h / 1.4 + 1 + q, 80, 30)
			local capitfucker = math.Clamp(150 * math.sin(SysTime() * 3), 0, 150)
			surface.SetDrawColor(Color(capitfucker, 0, 0, 150))
			surface.SetMaterial(battery)
			surface.DrawTexturedRect(w / 4 - 220 + p, h / 1.4 + q, 80, 30)
			render.PopFilterMag()
			render.PopFilterMin()
			local percentage = math.Round(client.nvgbattery * 1.25, 0)
			draw.SimpleText(percentage .. "%", "vrnvgdigitsBIG", w / 4 - 134 + p, h / 1.4 + 8 + q, Color(21, 21, 21, 125), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
			draw.SimpleText(percentage .. "%", "vrnvgdigitsBIG", w / 4 - 135 + p, h / 1.4 + 7 + q, Color(200, 0, 0, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
		else
			render.PushFilterMag(TEXFILTER.ANISOTROPIC)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
			surface.SetDrawColor(Color(21, 21, 21, 125))
			surface.SetMaterial(battery)
			surface.DrawTexturedRect(w / 4 - 219 + p, h / 1.4 + 1 + q, 80, 30)
			surface.SetDrawColor(Color(21, 21, 21, 125))
			surface.SetMaterial(battery)
			surface.DrawTexturedRect(w / 4 - 220 + p, h / 1.4 + q, 80, 30)
			surface.SetDrawColor(bluegreencolor)
			surface.SetMaterial(battery)
			render.SetScissorRect(0 + p, 0 + q, w / 4 - 230 + nvgbatterylerp * 1.2 + p, ScrH() + q, true)
			surface.DrawTexturedRect(w / 4 - 220 + p, h / 1.4 + q, 80, 30)
			render.SetScissorRect(0, 0, 0, 0, false)
			render.PopFilterMag()
			render.PopFilterMin()
			local percentage = math.Round(client.nvgbattery * 1.25, 0)
			draw.SimpleText(percentage .. "%", "vrnvgdigitsBIG", w / 4 - 134 + p, h / 1.4 + 9 + q, Color(21, 21, 21, 125), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
			draw.SimpleText(percentage .. "%", "vrnvgdigitsBIG", w / 4 - 135 + p, h / 1.4 + 7 + q, Color(vrnvgcolorpresettable[2], vrnvgcolorpresettable[3], vrnvgcolorpresettable[4], 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
		end

		--light detection meter hud
		surface.SetDrawColor(Color(21, 21, 21, 150))
		surface.SetMaterial(scale)
		surface.DrawTexturedRect(w / 4 - 188 + p, h / 1.6 + q - 1 - lightcolor * 500, 30, 5)
		surface.SetDrawColor(bluegreencolor)
		surface.SetMaterial(scale)
		surface.DrawTexturedRect(w / 4 - 190 + p, h / 1.6 + q - 2 - lightcolor * 500, 30, 5)
		local lightvalue = math.Round(lightcolor * 3, 2)
		surface.SetFont("vrnvgdigitsBIG") --vrnvgdigits
		local tw = surface.GetTextSize(lightvalue)
		draw.RoundedBox(4, w / 4 - 154 + p, h / 1.6 + q - 6 - lightcolor * 500, tw + 10, 17, Color(21, 21, 21, 100))
		draw.RoundedBox(4, w / 4 - 155 + p, h / 1.6 + q - 8 - lightcolor * 500, tw + 10, 17, Color(vrnvgcolorpresettable[2] / 1.25, vrnvgcolorpresettable[3] / 1.25, vrnvgcolorpresettable[4] / 1.25, 100))
		render.PushFilterMag(TEXFILTER.ANISOTROPIC)
		render.PushFilterMin(TEXFILTER.ANISOTROPIC) --vrnvgdigitsNOS
		draw.SimpleText(lightvalue, "vrnvgdigitsBIG", w / 4 - 150 + p + 1, h / 1.6 + q - 7 - lightcolor * 500 + 2, Color(0, 0, 0, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
		draw.SimpleText(lightvalue, "vrnvgdigitsBIG", w / 4 - 150 + p, h / 1.6 + q - 7 - lightcolor * 500, Color(vrnvgcolorpresettable[2], vrnvgcolorpresettable[3], vrnvgcolorpresettable[4], 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
		render.PopFilterMag()
		render.PopFilterMin()
		--future me here... these position values are fucked up
		surface.SetDrawColor(Color(21, 21, 21, 150))
		surface.SetMaterial(linebar)
		surface.DrawTexturedRect(w / 4 - 224 + p, h / 1.6 + q - 223, 20, 225)
		surface.SetDrawColor(bluegreencolor)
		surface.SetMaterial(linebar)
		surface.DrawTexturedRect(w / 4 - 225 + p, h / 1.6 + q - 225, 20, 225)
		render.PushFilterMag(TEXFILTER.ANISOTROPIC)
		render.PushFilterMin(TEXFILTER.ANISOTROPIC)
		surface.SetDrawColor(Color(21, 21, 21, 150))
		surface.SetMaterial(moon)
		surface.DrawTexturedRect(w / 4 - 198 + p, h / 1.6 + 8 + q, 8, 12)
		surface.SetDrawColor(bluegreencolor)
		surface.SetMaterial(moon)
		surface.DrawTexturedRect(w / 4 - 200 + p, h / 1.6 + 7 + q, 8, 12)
		render.PopFilterMag()
		render.PopFilterMin()
		surface.SetDrawColor(Color(21, 21, 21, 150))
		surface.SetMaterial(sun)
		surface.DrawTexturedRect(w / 4 - 203 + p, h / 1.6 - 249 + q, 20, 20)
		surface.SetDrawColor(bluegreencolor)
		surface.SetMaterial(sun)
		surface.DrawTexturedRect(w / 4 - 205 + p, h / 1.6 - 250 + q, 20, 20)
		draw.RoundedBox(2, w / 4 - 202 + p, h / 1.6 + q - 227, 10, 225, Color(0, 0, 0, 50)) --uhhh yea i guess this makes it look cooler
		draw.RoundedBox(2, w / 4 - 200 + p, h / 1.6 + q - 225, 11, 225, Color(0, 0, 0, 125)) --was 100
		draw.RoundedBox(0, w / 4 - 200 + p, h / 1.6 + q - lightcolor * 500, 10, lightcolor * 500, bluegreencolor)
	elseif client.vrnvgbroken or client.nvgnobattery then
		draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, nvgflashlerp))
		nvgflashlerp = math.Approach(nvgflashlerp, 0, ft * 20)
		client:StopSound("vrnvg_elecsizzle")
	else
		nvgsizzlerepeat = SysTime()
		client:StopSound("vrnvg_elecsizzle")
	end

	--flash on flip
	draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, nvgflashlerp))
	--chromatic abberation
	if client.quadnodson then vrnvg_chromatic(5, 0, 5, 0, 0, 0) end
	--[[if client.quadnodson and vrnvgcolorpresettable[2] != 255 and vrnvgcolorpresettable[3] != 150 then 
		vrnvg_chromatic( 10, 0, 10, 0, 0, 0 )
	elseif client.quadnodson and vrnvgcolorpresettable[2] == 255 or client.quadnodson and vrnvgcolorpresettable[3] == 150 then 
		vrnvg_chromatic( 5, 0, 5, 0, 0, 0 )
	end]]
end

hook.Add("HUDPaintBackground", "vrnvg_hudbackground", vrnvg_hudbackground)
local function vrnvg_predraweffects() --yea safe to say this blows
	local client = ax.client
	local ft = FrameTime()
	local eang, epos = EyeAngles(), EyePos()
	local w, h = ScrW(), ScrH()
	local p, q = vrnvgsway.lerpx * 1.1, -vrnvgsway.lerpy * 1.1
	local bluegreencolor = Color(vrnvgcolorpresettable[2], vrnvgcolorpresettable[3], vrnvgcolorpresettable[4], 100)
	if ax.util:IsValidPlayer(client) and client:Alive() and client:Health() > 0 and IsValid(client:GetHands()) then
		vrnvghandsmodel = string.Replace(client:GetHands():GetModel(), "models/models/", "models/") or "models/weapons/c_arms_refugee.mdl"
		if not util.IsValidModel(vrnvghandsmodel) then
			local modelpath = client:GetPData(vrnvghandsmodel, 0)
			if modelpath != 0 then
				vrnvghandsmodel = modelpath
				--[[else
										chat.PlaySound() 
										chat.AddText(Color(255,0,0),"Your playermodel has misconfigured hands, use another, or follow this guide (replace 'BodyAnim' with 'vrnvg' for the command) \nhttps://pastebin.com/hgNqSEcG")]]
			end
		end

		if not client.vrnvghand or client.vrnvghand:GetModel() != vrnvghandsmodel then client.vrnvghand = ClientsideModel(vrnvghandsmodel, RENDERGROUP_BOTH) end
		if IsValid(client.vrnvghand) then
			client.vrnvghand:SetParent(client.vrnvgmodel)
			client.vrnvghand:AddEffects(EF_BONEMERGE)
			client.vrnvghand:SetNoDraw(true)
			client.vrnvghand.GetPlayerColor = client:GetHands().GetPlayerColor
			for i = 0, client.vrnvghand:GetNumBodyGroups() do
				local bodyg = client:GetHands():GetBodygroup(i)
				client.vrnvghand:SetBodygroup(i, bodyg)
			end

			local skinszz = client:GetHands():GetSkin()
			client.vrnvghand:SetSkin(skinszz)
		end
	end

	if not client.vrnvgmodel then
		client.vrnvgmodel = ClientsideModel("models/ventrische/c_quadnod2.mdl", RENDERGROUP_BOTH)
		client.vrnvgmodel:ResetSequence("idleoff")
		client.vrnvgmodel:SetNoDraw(true)
		client.vrnvgcam = ClientsideModel("models/ventrische/c_quadnod2.mdl", RENDERGROUP_BOTH)
		client.vrnvgcam:SetNoDraw(true)
		util.PrecacheModel("models/ventrische/c_quadnod2.mdl")
	end

	local nvgs = client.vrnvgmodel
	local nvgcam = client.vrnvgcam
	render.SetStencilWriteMask(0xFF)
	render.SetStencilTestMask(0xFF)
	render.SetStencilReferenceValue(0)
	render.SetStencilPassOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)
	render.ClearStencil()
	render.SetStencilEnable(true)
	render.SetStencilReferenceValue(1)
	render.SetStencilCompareFunction(STENCIL_NEVER)
	render.SetStencilFailOperation(STENCIL_REPLACE)
	cam.Start3D(epos, eang, 100, 0, 0, w, h, 1, 35)
	if nvgs and client.vrnvghand then
		nvgs:SetPos(epos + Vector(0, 0, 0.3))
		nvgs:SetAngles(eang)
		nvgs:SetupBones()
		nvgs:FrameAdvance(ft)
		client.vrnvghand:SetupBones()
		nvgcam:SetPos(Vector(0, 0, 0))
		nvgcam:SetAngles(Angle(0, 0, 0))
		nvgcam:FrameAdvance(ft)
		client.nvgcamattach = nvgcam:GetAttachment(nvgcam:LookupAttachment("Camera"))
		if client:GetViewEntity() == client and not client:ShouldDrawLocalPlayer() and not sky3d then
			nvgs:DrawModel()
			client.vrnvghand:DrawModel()
		end
	end

	cam.End3D()
	render.SetStencilCompareFunction(5)
	render.SetStencilFailOperation(STENCIL_KEEP)
	if vrnvg_blur > 0 and enabledofblur:GetBool() then --depth of field (for some reason this is slightly off, probably due to the weird fuckery im doing drawing these shitty models)
		cam.Start2D(vector_origin, angle_zero)
		local wep = client:GetActiveWeapon()
		if IsValid(wep) then
			if type(wep.GetIronSights) == "function" then
				if wep:GetIronSights() == false then DrawBlur() end
			elseif wep.ARC9 then
				if wep:GetSightAmount() < 0.1 then DrawBlur() end
			elseif not wep.Sighted then
				DrawBlur()
			end
		end

		cam.End2D()
	end

	--render.ClearBuffersObeyStencil( 0, 148, 133, 255, false )
	render.SetStencilEnable(false)
	cam.Start3D(epos, eang, 100, 0, 0, w, h, 1, 35)
	cam.IgnoreZ(true)
	if nvgs and client.vrnvghand then
		nvgs:SetPos(epos + Vector(0, 0, 0.3))
		nvgs:SetAngles(eang)
		nvgs:SetupBones()
		nvgs:FrameAdvance(ft)
		client.vrnvghand:SetupBones()
		nvgcam:SetPos(Vector(0, 0, 0))
		nvgcam:SetAngles(Angle(0, 0, 0))
		nvgcam:FrameAdvance(ft)
		client.nvgcamattach = nvgcam:GetAttachment(nvgcam:LookupAttachment("Camera"))
		if client:GetViewEntity() == client and not client:ShouldDrawLocalPlayer() and not sky3d then
			--nvgs:DrawModel() 
			client.vrnvghand:DrawModel()
		end
	end

	cam.IgnoreZ(false)
	cam.End3D()
end

hook.Add("PreDrawEffects", "vrnvg_predraweffects", vrnvg_predraweffects)

--cam movement
local function vrnvg_calcview(client, origin, angles, fov)
	if not blurtoggle or not client.nvgcamattach or ax.client:GetViewEntity() != ax.client then return end
	if not client:Alive() then return end
	local view = {}
	local camang = client.nvgcamattach.Ang - Angle(0, 90, 90)
	view.angles = angles + Angle(camang.x * 2, camang.y * 2, camang.z * 2)
	return view
end

ax.viewstack:RegisterModifier("vrnvg", function(client, patch)
	if not blurtoggle or not client.nvgcamattach or ax.client:GetViewEntity() != ax.client then return end
	if not client:Alive() then return end
	local view = {}
	local camang = client.nvgcamattach.Ang - Angle(0, 90, 90)
	view.angles = patch.angles + Angle(camang.x * 2, camang.y * 2, camang.z * 2)

	return view
end, 1)

hook.Add("CalcView", "vrnvg_calcview", function()
	-- do nothing, placeholder
end)

--scuffed press/hold detection for equip/dequipping
local lockshittykey = false
local testlerp = 0
local rrft = 60
local function vrnvg_keys()
	local client = ax.client
	local rft = RealFrameTime()
	if not client:Alive() then return end
	if defaultkey:GetBool() and not lockshittykey then
		local uhhfpsig = 1 / rft --upgraded and enhanced.
		if uhhfpsig <= 60 then
			rrft = math.Round(testlerp + 1.5, 0)
		elseif uhhfpsig <= 200 then
			rrft = math.Round(testlerp + 1, 0)
		else
			rrft = math.Round(testlerp + 0.5, 1)
		end

		local capitpwease = math.Clamp(testlerp, 0, 150)
		if capitpwease == 150 and not client.vrnvgflipped then RunConsoleCommand("vrnvgequip") end
		if client.vrnvgequipped and testlerp < 50 and testlerp > 5 then
			if not client.nvgtestdelay or SysTime() >= client.nvgtestdelay then
				RunConsoleCommand("vrnvgflip")
				testlerp = 0
				client.nvgtestdelay = SysTime() * 9999 -- this is kinda fucked
				if batterynvg2dfade then
					batterynvg2dfade = false
				else
					batterynvg2dfade = true
				end
			end
		else
			-- prevents glualint from screaming at me
			if client.nvgtestdelay and SysTime() >= client.nvgtestdelay then
				client.nvgtestdelay = nil
			end
		end

		if input.IsKeyDown(KEY_N) then
			if not gui.IsGameUIVisible() then
				testlerp = rrft
				client.nvgtestdelay = SysTime() + 0.2
			end
		else
			if testlerp >= 50 then testlerp = 0 end
		end
	end

	if ix then
		if ix.gui.chat:GetActive() then
			lockshittykey = true
		else
			lockshittykey = false
		end
	end
end

hook.Add("CreateMove", "vrnvg_keys", vrnvg_keys)
hook.Add("StartChat", "vrnvg_chatboxopen", function(isTeamChat) lockshittykey = true end)
hook.Add("FinishChat", "vrnvg_chatboxclose", function() lockshittykey = false end)
--rip fps on 2010 laptops
local addrl = 0
local addgl = .2
local addbl = .18
local colourl = .5
local contrastl = 2
hook.Add("RenderScreenspaceEffects", "vrnvg_screenspaceeffects", function()
	local client = ax.client
	local ft = FrameTime()
	if not client:Alive() then return end
	local colormod = {
		["$pp_colour_addr"] = addrl,
		["$pp_colour_addg"] = addgl,
		["$pp_colour_addb"] = addbl,
		["$pp_colour_brightness"] = 0,
		["$pp_colour_contrast"] = contrastl,
		["$pp_colour_colour"] = colourl,
		["$pp_colour_mulr"] = 0,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0
	}

	local colormod2 = {
		["$pp_colour_addr"] = addrl,
		["$pp_colour_addg"] = addgl,
		["$pp_colour_addb"] = addbl,
		["$pp_colour_brightness"] = 0,
		["$pp_colour_contrast"] = contrastl,
		["$pp_colour_colour"] = colourl,
		["$pp_colour_mulr"] = 0,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0
	}

	if client.quadnodson and not client.vrnvgbroken and not client.nvgnobattery then
		addrl = Lerp(ft * 4, addrl, vrnvgcolorpresettable[5])
		addgl = Lerp(ft * 4, addgl, vrnvgcolorpresettable[6])
		addbl = Lerp(ft * 4, addbl, vrnvgcolorpresettable[7])
		colourl = Lerp(ft * 4, colourl, vrnvgcolorpresettable[8])
		contrastl = Lerp(ft * 4, contrastl, contrastamount:GetFloat())
		DrawColorModify(colormod)
		if bloomamount:GetFloat() > 0 and render.SupportsPixelShaders_2_0() then
			DrawBloom(0, bloomamount:GetFloat() + lightcolor * 1 + lightcolor2 * 1, 9, 9, 1, 1, 1, 1, 1)
			DrawSharpen(0.7, 0.7)
		end

		EdgeBlur(4, ScrH() * .4)
	elseif client.vrnvgbroken or client.nvgnobattery then
		addrl = Lerp(ft, addrl, 0)
		addgl = Lerp(ft, addgl, 0)
		addbl = Lerp(ft, addbl, 0)
		colourl = Lerp(ft, colourl, 1)
		contrastl = Lerp(ft, contrastl, 1)
		DrawColorModify(colormod2)
		EdgeBlur(4, ScrH() * .4)
	end
end)

--saving stuff
hook.Add("ShutDown", "vrnvg_save", function()
	file.CreateDir("nvgs")
	file.Write("nvgs/vrnvg_color.txt", util.TableToJSON(vrnvgcolorpresettable))
end)

local function LoadNVGPreset()
	local save = file.Read("nvgs/vrnvg_color.txt", "DATA")
	if save then
		save = util.JSONToTable(save)
		vrnvgcolorpresettable = save
	end
end

LoadNVGPreset()
--this is the code i got in return after giving datae cool ideas that helped him blow up that bastard
concommand.Add("vrnvg_registerhands", function(client, cmd, args)
	local handsmodel = client:GetHands():GetModel()
	local modelpath = args[1] or handsmodel
	local isvalidhands = util.IsValidModel(handsmodel)
	local isvalidcustom = util.IsValidModel(modelpath)
	if modelpath != handsmodel and isvalidcustom and not isvalidhands then
		client:SetPData(handsmodel, modelpath)
		print("MW NVGs will now use " .. modelpath .. " instead of " .. handsmodel .. " (hands)")
	elseif isvalidhands then
		print("ERROR: " .. handsmodel .. " is already correct. Aborting")
	elseif not isvalidcustom then
		print("ERROR: " .. modelpath .. " is not a valid model")
	end
end)

--please stop asking me how to equip them now thank you (and read the description for once christ)
surface.CreateFont("vrnvg_notif1", {
	font = "Hind Vadodara SemiBold",
	extended = false,
	size = 34,
	weight = 1500,
	antialias = true,
	shadow = false
})

local function vrNVG_BlurRect(x, y, w, h, alpha)
	surface.SetDrawColor(255, 255, 255, alpha)
	surface.SetMaterial(blur)
	for i = 1, 4 do
		local mul = math.Clamp(5 / 10, 1, 3)
		blur:SetFloat("$blur", ((i * mul) / 3) * 2)
		blur:Recompute()
		render.UpdateScreenEffectTexture()
		local X, Y = 0, 0
		render.SetScissorRect(x, y, x + w, y + h, true)
		surface.DrawTexturedRect(X * -1, Y * -1, ScrW(), ScrH())
		render.SetScissorRect(0, 0, 0, 0, false)
	end
end

local firstnotif = false
local firstnotifalt = false
local notiflerp1 = 0
local notif1text = "Hold N to equip your NVGs."
local notif1textalt = "Woah, it sure is dark in here!"
local notif1textjustincase = "Tap N to flip them up/down."
local holdnlerp = 0
local holdncurtime = 0
local function vrNVG_HudNotif()
	local client = ax.client
	local rft = RealFrameTime()
	local w, h = ScrW(), ScrH()
	if not shownewhud:GetBool() then return end
	--sounds
	if not vrnvg_holdingsoundd then vrnvg_holdingsoundd = CreateSound(client, "caramel/nvg_holding4.mp3") end
	if not vrnvg_notif2 then vrnvg_notif2 = CreateSound(client, "caramel/nvg_notif2.mp3") end
	--first notif
	if game.SinglePlayer() and defaultkey:GetBool() then
		local olduser = file.Read("nvgs/vrnvgupdatethree.txt", "DATA")
		local newuser = file.Read("nvgs/vrnvg_tutorial.txt", "DATA")
		if not olduser and not newuser then --new subscribers
			file.CreateDir("nvgs")
			file.Write("nvgs/vrnvg_tutorial.txt", "read the god damn description")
			timer.Simple(15, function() if not client.vrnvgequipped then firstnotif = true end end)
		elseif olduser and not newuser then
			--old subscribers
			if lightcolor < 0.011 and client:GetMoveType() != MOVETYPE_NOCLIP then
				file.CreateDir("nvgs")
				file.Write("nvgs/vrnvg_tutorial.txt", "u need to be reminded this exists")
				if not client.vrnvgequipped then
					firstnotif = true
					firstnotifalt = true
				end
			end
		end

		if firstnotif and not firstnotifalt then --too lazy to make this all neat
			notiflerp1 = Lerp(rft * 2, notiflerp1, 255)
			notif1text = "Hold N to equip your NVGs."
			vrnvg_notif2:Play()
		elseif firstnotif and firstnotifalt then
			notiflerp1 = Lerp(rft * 2, notiflerp1, 255)
			notif1text = "Hold N to equip your NVGs."
			vrnvg_notif2:Play()
		else
			notiflerp1 = Lerp(rft * 3, notiflerp1, 0)
			--notif1text = "You did it! Congratulations." // they cant read a desc yet here i was thinking they wouldve seen this
			if vrnvg_notif2 then vrnvg_notif2:Stop() end
		end

		--first notif / body ui
		if notiflerp1 > 1 then
			local notif1width, notif2height = 512, 100
			local posx, posy = w * .1 - 200 + notiflerp1 / 2.2, h * .2 - 50
			vrNVG_BlurRect(posx, posy, notif1width, notif2height, notiflerp1)
			draw.RoundedBox(0, posx + 3, posy + 3, notif1width, notif2height, Color(21, 21, 21, notiflerp1 / 2.5))
			draw.RoundedBox(0, posx, posy, notif1width, notif2height, Color(75, 75, 75, notiflerp1 / 1.9))
			draw.RoundedBox(0, posx, posy, notif1width, notif2height, Color(0, 0, 0, notiflerp1 / 1.3))
			local notif1textposx = w * .1 - 70 + notiflerp1 / 2.2
			if firstnotifalt then
				draw.SimpleText(notif1textalt, "vrnvg_notif1", notif1textposx + 1, posy + 18, Color(21, 21, 21, notiflerp1), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
				draw.SimpleText(notif1textalt, "vrnvg_notif1", notif1textposx, posy + 15, Color(255, 255, 255, notiflerp1), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
				draw.SimpleText(notif1text, "vrnvg_notif1", notif1textposx + 1, posy + 53, Color(21, 21, 21, notiflerp1), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
				draw.SimpleText(notif1text, "vrnvg_notif1", notif1textposx, posy + 50, Color(255, 255, 255, notiflerp1), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
			else
				draw.SimpleText(notif1textjustincase, "vrnvg_notif1", notif1textposx + 1, posy + 53, Color(21, 21, 21, notiflerp1), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
				draw.SimpleText(notif1textjustincase, "vrnvg_notif1", notif1textposx, posy + 50, Color(255, 255, 255, notiflerp1), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
				draw.SimpleText(notif1text, "vrnvg_notif1", notif1textposx + 1, posy + 18, Color(21, 21, 21, notiflerp1), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
				draw.SimpleText(notif1text, "vrnvg_notif1", notif1textposx, posy + 15, Color(255, 255, 255, notiflerp1), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
			end
		end
	end

	--holding N ui
	if input.IsKeyDown(KEY_N) and not blurtoggle then
		if SysTime() >= holdncurtime + 0.25 then
			holdnlerp = math.Approach(holdnlerp, 160, rft * 60)
			if firstnotif then vrnvg_holdingsoundd:Play() end
		end
	elseif blurtoggle then
		holdncurtime = SysTime()
		holdnlerp = math.Approach(holdnlerp, 220, rft * 1000)
		if firstnotif then
			firstnotif = false
			firstnotifalt = false
		end
	else
		if not blurtoggle then
			holdncurtime = SysTime()
			holdnlerp = math.Approach(holdnlerp, 0, rft * 500)
		end

		if vrnvg_holdingsoundd then vrnvg_holdingsoundd:FadeOut(0.05) end
	end

	--new updater location
	--local update = file.Read("nvgs/vrnvgupdatethree.txt", "DATA")
	--file.Write("nvgs/vrnvgupdatethree.txt", "wow no way new update nooo way") 
	local update = file.Read("nvgs/vrnvg_updatefour.txt", "DATA")
	if not update and client.vrnvgequipped then
		file.CreateDir("nvgs")
		file.Write("nvgs/vrnvg_updatefour.txt", "newwww update noooo wayyyyyyyyyyyyyyyyyyyyyyy")
		timer.Simple(3.5, function()
			chat.PlaySound()
			chat.AddText(Color(0, 240, 230), "MW NVGs has been updated. \n", Color(210, 210, 230), "1. Visual tweaks, UI changes, q-menu improvements, and a new brief tutorial. \n", "2. C_Hands will now automatically update instead of requiring a respawn. \n", "3. Playermodel NVGs should cause no more errors. \n", "--Fun Fact: You can change settings like the phosphor color or battery drain speed in the Q-MENU OPTIONS. \n")
		end)
	end
end

hook.Add("HUDPaint", "vrNVG_HudNotif", vrNVG_HudNotif)
