AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Author = "Limakenori"
ENT.PrintName = "Intro Animation Bonemerge"
ENT.Spawnable = false
ENT.Category = "Black Mesa"
function ENT:GetPlayerColor()
return (IsValid(self:GetOwner()) && self:GetOwner():GetNW2Vector("PlayerColor")) or Vector(255,255,255) end
if (CLIENT) then

ENT.bonetbl = {
["ValveBiped.Bip01_Spine4"] = true,
["ValveBiped.Bip01_Head1"] = true,
["ValveBiped.Bip01_Neck1"] = true,
["ValveBiped.Bip01_L_Clavicle"] = true,
["ValveBiped.Bip01_R_Clavicle"] = true,
["ValveBiped.Bip01_L_Clavicle"] = true,
["ValveBiped.Bip01_R_Clavicle"] = true,

}

function ENT:Draw() 
if !IsValid(self:GetOwner()) then return end
-- if !IsValid(self:GetOwner():GetNW2Entity("Camera")) then return end
if !game.SinglePlayer() && LocalPlayer() != self:GetOwner() && LocalPlayer() != self:GetOwner():GetOwner() then return end
	self:SetupBones()
	if !self:GetOwner():GetNW2Bool("HasLegs") then
	self.bonetbl = {
["ValveBiped.Bip01_L_UpperArm"]= true, -- "ValveBiped.Bip01_L_Clavicle" 6.028146 0 0 2.738854 -33.527947 -90.505156 0 0 0 0 0 0
["ValveBiped.Bip01_L_Forearm"]= true, -- "ValveBiped.Bip01_L_UpperArm" 11.692556 0 0.000015 -0.00001 -3.45906 -0.000002 0 0 0 0 0 0
["ValveBiped.Bip01_L_Hand"]= true, -- "ValveBiped.Bip01_L_Forearm" 11.481678 0 -0.000019 -6.108479 2.532073 90.136743 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger4"]= true, -- "ValveBiped.Bip01_L_Hand" 3.859703 -0.142399 -1.191974 8.719846 -50.413056 -27.452933 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger41"]= true, -- "ValveBiped.Bip01_L_Finger4" 1.31255 -0.000002 -0.000001 0.553755 -25.194088 -0.000002 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger42"]= true, -- "ValveBiped.Bip01_L_Finger41" 0.729362 0.000004 0 0.28481 -13.997294 0.000002 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger3"]= true, -- "ValveBiped.Bip01_L_Hand" 3.942327 0.046783 -0.431443 4.201388 -46.446697 -8.881647 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger31"]= true, -- "ValveBiped.Bip01_L_Finger3" 1.539101 -0.000004 0 0.255539 -14.197709 0.000002 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger32"]= true, -- "ValveBiped.Bip01_L_Finger31" 1.196323 0.000004 0.000001 0.421755 -24.683139 0.000003 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger2"]= true, -- "ValveBiped.Bip01_L_Hand" 3.883684 -0.046761 0.431443 1.250768 -33.682279 4.921824 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger21"]= true, -- "ValveBiped.Bip01_L_Finger2" 1.719578 0.000008 0 0.316049 -20.99762 0.000002 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger22"]= true, -- "ValveBiped.Bip01_L_Finger21" 1.209179 -0.000004 0 0.176705 -12.39879 0.000002 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger1"]= true, -- "ValveBiped.Bip01_L_Hand" 3.859863 -0.137939 1.332467 -2.449393 -30.465178 20.308432 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger11"]= true, -- "ValveBiped.Bip01_L_Finger1" 1.719431 0 0.000002 0.233433 -20.798867 -0.000002 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger12"]= true, -- "ValveBiped.Bip01_L_Finger11" 1.09967 0.000002 -0.000002 0.14875 -13.999125 -0.000003 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger0"]= true, -- "ValveBiped.Bip01_L_Hand" 0.806047 -0.348923 1.321259 -38.931798 -45.223997 -69.147654 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger01"]= true, -- "ValveBiped.Bip01_L_Finger0" 1.789782 -0.000002 0.000002 0.423227 13.093412 0.000005 0 0 0 0 0 0
["ValveBiped.Bip01_L_Finger02"]= true, -- "ValveBiped.Bip01_L_Finger01" 1.207001 -0.000001 0.000002 0.645532 20.790353 0.000003 0 0 0 0 0 0
["ValveBiped.Anim_Attachment_LH"]= true, -- "ValveBiped.Bip01_L_Hand" 2.67609 -1.712433 -0.000002 -0.000001 89.999982 90.000037 0 0 0 0 0 0
["ValveBiped.Bip01_L_Wrist"]= true, -- "ValveBiped.Bip01_L_Forearm" 11.481709 0 0.000008 -0.000009 0 0.072878 0 0 0 0 0 0
["ValveBiped.Bip01_R_UpperArm"]= true, -- "ValveBiped.Bip01_R_Clavicle" 6.028141 -0.000011 -0.000002 -0.462088 -33.623809 93.935243 0 0 0 0 0 0
["ValveBiped.Bip01_R_Forearm"]= true, -- "ValveBiped.Bip01_R_UpperArm" 11.692547 0 0.000004 -0.000022 -3.459062 0 0 0 0 0 0 0
["ValveBiped.Bip01_R_Hand"]= true, -- "ValveBiped.Bip01_R_Forearm" 11.481695 -0.000001 0.000004 6.108051 2.532071 -89.664285 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger4"]= true, -- "ValveBiped.Bip01_R_Hand" 3.859674 -0.132568 1.193109 -9.083958 -50.365347 27.452701 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger41"]= true, -- "ValveBiped.Bip01_R_Finger4" 1.312557 0 0 -0.683648 -25.191333 0.000009 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger42"]= true, -- "ValveBiped.Bip01_R_Finger41" 0.729362 -0.000001 -0.000003 -0.351446 -13.995672 0.000007 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger3"]= true, -- "ValveBiped.Bip01_R_Hand" 3.942295 0.050323 0.431043 -4.543841 -46.421326 8.880788 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger31"]= true, -- "ValveBiped.Bip01_R_Finger3" 1.539093 0.000002 0 -0.335408 -14.196229 0.000002 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger32"]= true, -- "ValveBiped.Bip01_R_Finger31" 1.196323 0 0 -0.553647 -24.680769 0.000001 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger2"]= true, -- "ValveBiped.Bip01_R_Hand" 3.883654 -0.050331 -0.431043 -1.512837 -33.672464 -4.921994 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger21"]= true, -- "ValveBiped.Bip01_R_Finger2" 1.719582 -0.000004 0 -0.456874 -20.99524 -0.000002 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger22"]= true, -- "ValveBiped.Bip01_R_Finger21" 1.209187 -0.000004 0 -0.255595 -12.397428 -0.000002 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger1"]= true, -- "ValveBiped.Bip01_R_Hand" 3.859827 -0.148945 -1.331283 2.209728 -30.48143 -20.306712 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger11"]= true, -- "ValveBiped.Bip01_R_Finger1" 1.719431 0 0 -0.378894 -20.796644 -0.000009 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger12"]= true, -- "ValveBiped.Bip01_R_Finger11" 1.099663 0.000002 -0.000002 -0.241272 -13.998046 -0.000014 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger0"]= true, -- "ValveBiped.Bip01_R_Hand" 0.806017 -0.359833 -1.318335 38.595463 -45.490341 68.995579 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger01"]= true, -- "ValveBiped.Bip01_R_Finger0" 1.789783 -0.000004 -0.000002 -0.361029 13.09524 0.00001 0 0 0 0 0 0
["ValveBiped.Bip01_R_Finger02"]= true, -- "ValveBiped.Bip01_R_Finger01" 1.206999 0.000001 0 -0.551083 20.792921 0.000007 0 0 0 0 0 0
["ValveBiped.Anim_Attachment_RH"]= true, -- "ValveBiped.Bip01_R_Hand" 2.421068 -1.710659 0.000001 0.000001 -89.999968 -89.999982 0 0 0 0 0 0
["ValveBiped.Bip01_R_Wrist"]= true, -- "ValveBiped.Bip01_R_Forearm" 11.481701 -0.000001 0.000015 -0.000022 -0.000002 0.008594 0 0 0 0 0 0
["ValveBiped.Bip01_L_Ulna"]= true,
["ValveBiped.Bip01_R_Ulna"]= true,
}
end

if LocalPlayer() == self:GetOwner():GetOwner() then
	local parent = self:GetOwner()
    local attName = (parent:LookupAttachment("camera_parent") > 0 and "camera_parent") or 
                    (parent:LookupAttachment("vehicle_driver_eyes") > 0 and "vehicle_driver_eyes") or 
                    (parent:LookupAttachment("knockout_camera_parent") > 0 and "knockout_camera_parent") or 
                    "ViewmodelEyes"
    local attId = parent:LookupAttachment(attName)
    local att = parent:GetAttachment(attId)
    
    if (att) then
        for i = 0, self:GetBoneCount() - 1 do
            local ab = (self:GetOwner():GetNW2Bool("HasLegs") && true) or nil
            if ( (ab == nil && self.bonetbl[self:GetBoneName(i)] == ab && self.bonetbl[self:GetBoneName(self:GetBoneParent( i ))] == ab) or (ab == true && self.bonetbl[self:GetBoneName(i)] == ab)) then
            
            local mat = self:GetBoneMatrix(i)
            if mat then
            mat:Scale(Vector(0,0,0))
                        self:SetBoneMatrix( i, mat )
                        local pos,ang = self:GetBonePosition( i )
                        -- self:SetBonePosition( i, self:GetOwner():GetNW2Entity("Camera"):GetPos() + self:GetOwner():GetNW2Entity("Camera"):GetForward()*-610,  ang)
                        self:SetBonePosition( i, att.Pos + att.Ang:Forward()*-610,  ang)
            end end
        end
	end
	end
	self:DrawModel()
end end

function ENT:Initialize()
end
	
function ENT:OnRemove()
end


function ENT:PhysicsCollide(data)end
