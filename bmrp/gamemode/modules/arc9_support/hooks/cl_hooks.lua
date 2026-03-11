
local MODULE = MODULE

-- we want the ui to close when the player moves too far away from a workbench
-- theres probably a better way to do this, but it seems like SWEP:ThinkCustomize() is used as a VARIABLE instead of a direct call so it doesnt really override nicely
function MODULE:Think()
    if ( !ax.config:Get("arc9.weapons.benches", true) ) then return end

    local client = ax.client
    if ( !ax.util:IsValidPlayer(client) or !client:GetCharacter() ) then return end

    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) or !weapons.IsBasedOn(weapon:GetClass(), "arc9_base") ) then return end

    if ( weapon:GetCustomize() and !hook.Run("NearWeaponBench", client) ) then
        weapon:SetCustomize(false)

        net.Start("ARC9_togglecustomize")
            net.WriteBool(false)
        net.SendToServer()
    end
end
