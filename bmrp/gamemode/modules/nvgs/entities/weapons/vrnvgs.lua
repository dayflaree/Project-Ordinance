AddCSLuaFile()

SWEP.DrawCrosshair = false
SWEP.DrawAmmo = false
SWEP.PrintName = "NVG"
SWEP.Slot = 15
SWEP.SlotPos = 15
SWEP.ViewModelFOV = 90
SWEP.Instructions = ""
SWEP.Author = ""
SWEP.Contact = ""
SWEP.Weight = 0
SWEP.ViewModelFlip = false
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.ViewModel = "models/ventrische/c_quadnod2.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = false
SWEP.Primary.Recoil = 0
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 0
SWEP.Primary.Cone = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.Delay = 0
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Ammo = "none"

local function SyncInventory( client )
	if ( !IsValid( client ) ) then return end

	local character = client:GetCharacter()
	if ( !character ) then return end

	local inventory = character:GetInventory()
	if ( !inventory ) then return end

	ax.inventory:Sync( inventory )
end

function SWEP:Initialize()
	return true
end

function SWEP:PrimaryAttack()
	return false
end

function SWEP:SecondaryAttack()
	return false
end

function SWEP:Deploy()
	if ( CLIENT ) then return end

	local s = self
	local client = self:GetOwner()
	local viewmodel = client:GetViewModel()
	if ( IsValid( viewmodel ) ) then
		local anim = viewmodel:LookupSequence( "idleoff" )
		viewmodel:SendViewModelMatchingSequence( anim )
		if ( s.slamholdtype ) then
			s:SetHoldType( "slam" )
			client.vrnvgequipped = !client.vrnvgequipped
			net.Start( "vrnvgnetequip" )
			net.WriteBool( client.vrnvgequipped )
			net.Send( client )
			if ( client.vrnvgequipped ) then
				client:EmitSound( "ventrische/nvg/equip.mp3" )
			else
				client:EmitSound( "ventrische/nvg/unequip.mp3" )
			end

			timer.Simple( 2, function()
				if ( client:Alive() ) then
					client:SelectWeapon( client.vrnvglast:GetClass() )
					client:StripWeapon( s:GetClass() )
					s.slamholdtype = false

					SyncInventory( client )
				end
			end )
		elseif ( s.cameraholdtype ) then
			s:SetHoldType( "camera" )
			client.vrnvgflipped = !client.vrnvgflipped
			net.Start( "vrnvgnetflip" )
			net.WriteBool( client.vrnvgflipped )
			net.Send( client )

			if ( !client.vrnvgflipped ) then
				timer.Simple( 1, function()
					if ( client:Alive() ) then
						client:SelectWeapon( client.vrnvglast:GetClass() )
						client:StripWeapon( s:GetClass() )
						s.cameraholdtype = false

						SyncInventory( client )
					end
				end )
			else
				if ( client:FlashlightIsOn() ) then client:Flashlight( false ) end
				timer.Simple( 1.3, function()
					if ( client:Alive() ) then
						client:SelectWeapon( client.vrnvglast:GetClass() )
						client:StripWeapon( s:GetClass() )
						s.cameraholdtype = false

						SyncInventory( client )
					end
				end )
			end
		elseif ( s.brokentoss and client.vrnvgbroken ) then
			s:SetHoldType( "slam" )
			net.Start( "vrnvgnetbreak" )
			net.WriteBool( true )
			net.Send( client )
			client.vrnvgequipped = false
			client.vrnvgflipped = false

			local character = client:GetCharacter()
			if ( character ) then
				local inventory = character:GetInventory()
				if ( inventory ) then
					local removeIds = {}
					for itemId, itemData in pairs( inventory:GetItems() ) do
						if ( itemData.class == "nvgs" ) then
							removeIds[ #removeIds + 1 ] = itemId
						end
					end

					for _, itemId in ipairs( removeIds ) do
						inventory:RemoveItem( itemId )
					end
				end
			end

			timer.Simple( 4.82, function()
				if ( client:Alive() ) then
					client:SelectWeapon( client.vrnvglast:GetClass() )
					client:StripWeapon( s:GetClass() )
					s.brokentoss = false
					client.vrnvgbroken = false

					SyncInventory( client )
				end
			end )
		end
	else
		print( "NVGs: your current viewmodel is screwed, swap playermodels." )
	end
end
