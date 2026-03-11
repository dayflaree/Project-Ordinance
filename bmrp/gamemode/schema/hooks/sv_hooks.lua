function SCHEMA:ShouldEnableUltravision(client)
    if ( !self:HasNearbyPowerOutage(client:GetPos()) ) then return false end
end

function SCHEMA:OnPlayerItemAction(client, item, action)
    if ( item.class == "flashlight" ) then
        if ( action == "drop" ) then
            client:AllowFlashlight(false)
        elseif ( action == "take" ) then
            client:AllowFlashlight(true)
        end
    end
end
