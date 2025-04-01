JBT = JBT or {}
local JBT = JBT

JBT.FEET_MIN_PITCH = 45
JBT.FEET_MAX_SNDLEVEL = 100
JBT.FEET_BIG = 3
JBT.FEET_HUGE = 8
JBT.FOOTSTEP_SOUNDS = {
	{
		mat = { "glass" },
		sounds = {
			"physics/glass/glass_sheet_impact_hard1.wav",
			"physics/glass/glass_sheet_impact_hard2.wav",
			"physics/glass/glass_sheet_impact_hard3.wav"
		}
	},
	{
		mat = { "wood" },
		sounds = {
			"physics/wood/wood_box_impact_hard1.wav",
			"physics/wood/wood_box_impact_hard2.wav",
			"physics/wood/wood_box_impact_hard3.wav",
			"physics/wood/wood_box_impact_hard4.wav",
			"physics/wood/wood_box_impact_hard5.wav",
			"physics/wood/wood_box_impact_hard6.wav"
		}
	},
	{
		mat = { "rubber" },
		sounds = {
			"physics/rubber/rubber_tire_impact_hard1.wav",
			"physics/rubber/rubber_tire_impact_hard2.wav",
			"physics/rubber/rubber_tire_impact_hard3.wav"
		}
	},
	{
		mat = { "plaster" },
		sounds = {
			"physics/plaster/drywall_impact_hard1.wav",
			"physics/plaster/drywall_impact_hard2.wav",
			"physics/plaster/drywall_impact_hard3.wav"
		}
	},
	{
		mat = { "chainlink" },
		sounds = {
			"physics/metal/metal_chainlink_impact_hard1.wav",
			"physics/metal/metal_chainlink_impact_hard2.wav",
			"physics/metal/metal_chainlink_impact_hard3.wav",
		}
	},
	{
		mat = { "metalgrate" },
		sounds = {
			"physics/metal/metal_grate_impact_hard1.wav",
			"physics/metal/metal_grate_impact_hard2.wav",
			"physics/metal/metal_grate_impact_hard3.wav"
		}
	},
	{
		mat = { "metal", "duct" },
		sounds = {
			"physics/metal/metal_barrel_impact_hard1.wav",
			"physics/metal/metal_barrel_impact_hard2.wav",
			"physics/metal/metal_barrel_impact_hard3.wav"
		}
	},
	{
		mat = { "grass", "sand", "dirt", "snow", "gravel" },
		sounds = {
			"physics/flesh/flesh_impact_hard1.wav",
			"physics/flesh/flesh_impact_hard2.wav",
			"physics/flesh/flesh_impact_hard3.wav",
			"physics/flesh/flesh_impact_hard4.wav",
			"physics/flesh/flesh_impact_hard5.wav",
			"physics/flesh/flesh_impact_hard6.wav",
		}
	},
	default = {
		"physics/concrete/rock_impact_hard1.wav",
		"physics/concrete/rock_impact_hard2.wav",
		"physics/concrete/rock_impact_hard3.wav"
	}
}

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
		if IsValid(ply.JBT_Phys) then
			ply.JBT_Phys:JBT_SetMass(mass)
		end
		if IsValid(ply.JBT_CPhys) then
			ply.JBT_CPhys:JBT_SetMass(mass)
		end

		return
	end

	if not nofix and JBT.RelativeStatSetFix(ply, "Mass") then
		self:JBT_SetMass(mass)
		return
	end

	ply.JBT_Mass = mass
	local newMass = JBT.PlyMass(ply, self)

	self:JBT_SetMass(newMass)
	if IsValid(ply.JBT_Phys) then
		ply.JBT_Phys:JBT_SetMass(newMass)
	end
	if IsValid(ply.JBT_CPhys) then
		ply.JBT_CPhys:JBT_SetMass(newMass)
	end
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

-- players have TWO physics objects for both crouching and standing
function JBT.CrouchFindPhys(ply, key)
	if key ~= IN_DUCK then return end

	timer.Create("JBT_Ducking_" .. ply:UserID(), 0, 1, function()
		if not IsValid(ply) then return end

		if ply:Crouching() then
			ply.JBT_CPhys = ply:GetPhysicsObject()
		else
			ply.JBT_Phys = ply:GetPhysicsObject()
		end

		if not JBT.GetPersonalSetting(ply, "bigmass") then return end

		JBT.PlyResyncMass(ply)
	end)
end

hook.Add("KeyPress", "JBT_BigMass", JBT.CrouchFindPhys)
hook.Add("KeyRelease", "JBT_BigMass", JBT.CrouchFindPhys)

function JBT.FeetSndLevel(scale)
	return math.min(30 + scale * 20, JBT.FEET_MAX_SNDLEVEL)
end

function JBT.FeetPitch(scale)
	return math.max(100 / (0.75 + scale * 0.25), JBT.FEET_MIN_PITCH)
end

function JBT.FeetPitchBig(scale)
	return math.max(120 / (0.9 + scale * 0.1), JBT.FEET_MIN_PITCH)
end

function JBT.FeetPitchHuge(scale)
	return math.max(110 / (0.9 + scale * 0.025), JBT.FEET_MIN_PITCH)
end

function JBT.FeetSound(_, _, _, snd)
	return snd
end

function JBT.FeetSoundBig(_, _, _, snd)
	local bigSound
	for _, v in ipairs(JBT.FOOTSTEP_SOUNDS) do
		local match
		for _, v1 in ipairs(v.mat) do
			if string.find(snd, v1) then
				match = true
				break
			end
		end

		if match then
			bigSound = v.sounds[math.random(#v.sounds)]
			break
		end
	end
	if not bigSound then
		bigSound = JBT.FOOTSTEP_SOUNDS.default[math.random(#JBT.FOOTSTEP_SOUNDS.default)]
	end

	return bigSound
end

function JBT.FeetSoundHuge()
	return "physics/concrete/boulder_impact_hard" .. math.random(4) .. ".wav"
end

local function gmDetour()
	if JBT_NOGM then return end

	local gm = gmod.GetGamemode()

	gm.JBT_PlayerFootstep = gm.JBT_PlayerFootstep or gm.PlayerFootstep or function() end
	function gm:PlayerFootstep(ply, pos, foot, snd, vol, filter)
		if self:JBT_PlayerFootstep(ply, pos, foot, snd, vol, filter) then return true end

		if not JBT.GetPersonalSetting(ply, "bigmass") then return end

		for _, v in ipairs(JBT.FEET_NO_OVERRIDE) do
			if string.find(snd, v) then return end
		end

		local scale = JBT.PlyScale(ply)
		if scale < JBT.UPPER and scale > JBT.LOWER then return end

		if scale <= JBT.FEET_BIG then
			ply:EmitSound(JBT.FeetSound(ply, pos, foot, snd, vol, filter),
					JBT.FeetSndLevel(scale), JBT.FeetPitch(scale), vol, CHAN_BODY)
		elseif scale <= JBT.FEET_HUGE then -- stompy
			ply:EmitSound(JBT.FeetSoundBig(ply, pos, foot, snd, vol, filter),
					JBT.FeetSndLevel(scale), JBT.FeetPitchBig(scale), vol, CHAN_BODY)
		else -- mega stompy
			ply:EmitSound(JBT.FeetSoundHuge(ply, pos, foot, snd, vol, filter),
					JBT.FeetSndLevel(scale), JBT.FeetPitchHuge(scale), vol, CHAN_BODY)
		end

		return true
	end
end

hook.Add("PostGamemodeLoaded", "JBT_BigMass", gmDetour)
if JBT_LOADED then gmDetour() end