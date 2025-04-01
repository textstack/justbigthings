JBT = JBT or {}
local JBT = JBT

-- return mass scaled to appropriate amount
function JBT.PlyMass(ply, phys)
	local default = JBT.PlyOriginalMass(ply, phys)

	if not JBT.GetPersonalSetting(ply, "bigmass") then return default end

	local scale = JBT.PlyScale(ply)
	if scale < JBT.UPPER and scale > JBT.LOWER then return default end

	return math.Round(default * scale ^ JBT.GetSetting("bigmass_pow"), 2)
end

-- get original mass value
function JBT.PlyOriginalMass(ply, phys)
	local amount = ply.JBT_Mass
	if amount then return amount end

	return phys:GetMass()
end

-- rescale mass according to original value
function JBT.PlyResyncMass(ply)
	local phys = ply:GetPhysicsObject()
	if not IsValid(phys) then return end

	local amount = JBT.PlyOriginalMass(ply, phys)
	phys:SetMass(amount, true)
end

local PHYSOBJ = FindMetaTable("PhysObj")

PHYSOBJ.JBT_SetMass = PHYSOBJ.JBT_SetMass or PHYSOBJ.SetMass
function PHYSOBJ:SetMass(mass, nofix)
	local ply = self:GetEntity()
	if not ply:IsPlayer() then
		self:JBT_SetMass(mass)
		return
	end

	if not JBT.GetPersonalSetting(ply, "bigmass") then
		self:JBT_SetMass(mass)
		return
	end

	if not nofix and JBT.RelativeStatSetFix(ply, "Mass") then
		self:JBT_SetMass(mass)
		return
	end

	ply.JBT_Mass = mass
	local newMass = JBT.PlyMass(ply, self)

	self:JBT_SetMass(newMass)
end

PHYSOBJ.JBT_GetMass = PHYSOBJ.JBT_GetMass or PHYSOBJ.GetMass
function PHYSOBJ:GetMass()
	local ply = self:GetEntity()
	if ply:IsPlayer() and JBT.GetPersonalSetting(ply, "bigmass") then
		JBT.RelativeStatGetFix(ply, "Mass")
	end

	return self:JBT_GetMass()
end

hook.Add("PlayerSpawn", "JBT_BigMass", function(ply)
	if not JBT.GetPersonalSetting(ply, "bigmass") then return end

	timer.Create("JBT_SetMass_" .. ply:UserID(), 0.2, 1, function()
		if not IsValid(ply) or not ply:Alive() then return end

		JBT.PlyResyncMass(ply)
	end)
end)

hook.Add("JBT_ScaleChanged", "JBT_BigStats", function(ply, scale)
	if not JBT.GetPersonalSetting(ply, "bigmass") then return end

	JBT.PlyResyncMass(ply)
end)

-- players get a new physics object when they crouch
function JBT.CrouchFindPhys(ply, key)
	if key ~= IN_DUCK then return end

	timer.Create("JBT_Ducking_" .. ply:UserID(), 0, 0.5, function()
		if not IsValid(ply) then return end
		if not JBT.GetPersonalSetting(ply, "bigmass") then return end

		JBT.PlyResyncMass(ply)
	end)
end

hook.Add("KeyPress", "JBT_BigMass", JBT.CrouchFindPhys)
hook.Add("KeyRelease", "JBT_BigMass", JBT.CrouchFindPhys)