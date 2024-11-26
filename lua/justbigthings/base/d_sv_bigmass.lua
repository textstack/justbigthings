-- The player seems to have TWO physics objects for crouching and standing.
-- TODO: somehow find and affect both of these at once

local enable = CreateConVar("jbt_bigmass_enabled", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the big mass module", 0, 1)
local power = CreateConVar("jbt_bigmass_pow", "2", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "The mathematical power for how player mass scales with size", 1, 3)

local defaultMass = 85
function JBT.PlyMass(ply)
	if not enable:GetBool() then return defaultMass end

	local scale = JBT.PlyScale(ply)
	if math.abs(scale - 1) < 0.01 then return defaultMass end

	return defaultMass * scale ^ power:GetInt()
end

local PHYSOBJ = FindMetaTable("PhysObj")

PHYSOBJ.OldSetMass = PHYSOBJ.OldSetMass or PHYSOBJ.SetMass

function JBT.SetMass(ply)
	local phys = ply:GetPhysicsObject()
	if not IsValid(phys) then return end

	ply.JBT_OldMass = ply.JBT_OldMass or phys:GetMass()
	if ply.JBT_OldMass ~= defaultMass then
		phys:OldSetMass(ply.JBT_OldMass)
		return
	end

	phys:OldSetMass(JBT.PlyMass(ply))
end

function PHYSOBJ:SetMass(mass)
	if not enable:GetBool() then
		self:OldSetMass(mass)
		return
	end

	local ply = self:GetEntity()
	if not ply:IsPlayer() then
		self:OldSetMass(mass)
		return
	end

	ply.JBT_OldMass = mass
	JBT.SetMass(ply)
end

local function setEveryone()
	for _, ply in player.Iterator() do
		JBT.SetMass(ply)
	end
end

cvars.AddChangeCallback("jbt_bigmass_enabled", setEveryone)
cvars.AddChangeCallback("jbt_bigmass_pow", setEveryone)

hook.Add("PlayerSpawn", "JBT_BigMass", function(ply)
	if not enable:GetBool() then return end

	JBT.SetMass(ply)
end)

local function crouchSetMass(ply, key)
	if not enable:GetBool() then return end
	if key ~= IN_DUCK then return end

	timer.Create("JBT_Ducking_" .. ply:UserID(), 0.5, 1, function()
		if not IsValid(ply) then return end
		if not enable:GetBool() then return end

		JBT.SetMass(ply)
	end)
end

hook.Add("KeyPress", "JBT_BigMass", crouchSetMass)
hook.Add("KeyRelease", "JBT_BigMass", crouchSetMass)

local ENTITY = FindMetaTable("Entity")

ENTITY.OldSetModelScale = ENTITY.OldSetModelScale or ENTITY.SetModelScale
function ENTITY:SetModelScale(scale, deltaTime)
	self:OldSetModelScale(scale, deltaTime)

	if not enable:GetBool() then return end
	if not self:IsPlayer() then return end

	timer.Create("JBT_Rescale_" .. self:UserID(), deltaTime, 1, function()
		if not IsValid(self) then return end
		if not enable:GetBool() then return end

		JBT.SetMass(self)
	end)
end

local PLAYER = FindMetaTable("Player")

PLAYER.OldResetHull = PLAYER.OldResetHull or PLAYER.ResetHull
function PLAYER:ResetHull()
	self:OldResetHull()
	JBT.SetMass(self)
end

PLAYER.OldSetHull = PLAYER.OldSetHull or PLAYER.SetHull
function PLAYER:SetHull(mins, maxs)
	self:OldSetHull(mins, maxs)
	if not enable:GetBool() then return end

	JBT.SetMass(self)
end

PLAYER.OldSetHullDuck = PLAYER.OldSetHullDuck or PLAYER.SetHullDuck
function PLAYER:SetHullDuck(mins, maxs)
	self:OldSetHullDuck(mins, maxs)
	if not enable:GetBool() then return end

	JBT.SetMass(self)
end