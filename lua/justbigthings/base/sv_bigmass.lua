local enable = CreateConVar("jbt_bigmass_enabled", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the big mass module", 0, 1)
local power = CreateConVar("jbt_bigmass_pow", "2", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "The mathematical power for how player mass scales with size", 1, 3)

-- return mass scaled to appropriate amount
function JBT.PlyMass(ply, phys)
	local default = JBT.PlyOriginalMass(ply, phys)

	if not JBT.HasEnabled(ply, enable, "JBT_BigMass") then return default end

	local scale = JBT.PlyScale(ply)
	if scale < 1.01 and scale > 0.95 then return default end

	return math.Round(default * scale ^ power:GetInt(), 2)
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

	if not JBT.HasEnabled(ply, enable, "JBT_BigMass") then
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
	if ply:IsPlayer() and JBT.HasEnabled(ply, enable, "JBT_BigMass") then
		JBT.RelativeStatGetFix(ply, "Mass")
	end

	return self:JBT_GetMass()
end

local function setEveryone()
	for _, ply in player.Iterator() do
		JBT.PlyResyncMass(ply)
	end
end

cvars.AddChangeCallback("jbt_bigmass_enabled", setEveryone)
cvars.AddChangeCallback("jbt_bigmass_pow", setEveryone)

hook.Add("PlayerSpawn", "JBT_BigMass", function(ply)
	if not JBT.HasEnabled(ply, enable, "JBT_BigMass") then return end

	JBT.PlyResyncMass(ply)
end)

hook.Add("JBT_ScaleChanged", "JBT_BigStats", function(ply, scale)
	if not JBT.HasEnabled(ply, enable, "JBT_BigMass") then return end

	JBT.PlyResyncMass(ply)
end)

-- players have TWO physics objects for both crouching and standing
local function crouchFindPhys(ply, key)
	if key ~= IN_DUCK then return end

	timer.Create("JBT_Ducking_" .. ply:UserID(), 0, 1, function()
		if not IsValid(ply) then return end

		local set
		if not IsValid(ply.JBT_Phys) or not IsValid(ply.JBT_CPhys) then
			set = true
		end

		if ply:Crouching() then
			ply.JBT_CPhys = ply:GetPhysicsObject()
		else
			ply.JBT_Phys = ply:GetPhysicsObject()
		end

		if not JBT.HasEnabled(ply, enable, "JBT_BigMass") then return end
		if not set then return end
		if not IsValid(ply.JBT_Phys) or not IsValid(ply.JBT_CPhys) then return end

		JBT.PlyResyncMass(ply)
	end)
end

hook.Add("KeyPress", "JBT_BigMass", crouchFindPhys)
hook.Add("KeyRelease", "JBT_BigMass", crouchFindPhys)

local sounds = {
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

local function gmDetour()
	if JBT_NOGM then return end

	local gm = gmod.GetGamemode()

	gm.JBT_PlayerFootstep = gm.JBT_PlayerFootstep or gm.PlayerFootstep or function() end
	function gm:PlayerFootstep(ply, pos, foot, snd, vol, filter)
		if self:JBT_PlayerFootstep(ply, pos, foot, snd, vol, filter) then return true end

		if not JBT.HasEnabled(ply, enable, "JBT_BigMass") then return end
		if string.find(snd, "ladder") or string.find(snd, "wade") or string.find(snd, "slosh") then return end

		local scale = JBT.PlyScale(ply)
		if scale < 1.01 and scale > 0.95 then return end

		if scale <= 3 then
			local sndLevel = math.min(30 + scale * 20, 100)
			local pitch = 100 / (0.75 + scale * 0.25)

			ply:EmitSound(snd, sndLevel, pitch, vol, CHAN_BODY)
		elseif scale <= 8 then
			-- stompy

			local bigSound
			for _, v in ipairs(sounds) do
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
				bigSound = sounds.default[math.random(#sounds.default)]
			end

			local pitch = math.max(120 / (0.9 + scale * 0.1), 45)

			ply:EmitSound(bigSound, 100, pitch, vol, CHAN_BODY)
		else
			-- mega stompy

			local pitch = math.max(110 / (0.9 + scale * 0.025), 45)

			ply:EmitSound("physics/concrete/boulder_impact_hard" .. math.random(4) .. ".wav", 100, pitch, vol, CHAN_BODY)
		end

		return true
	end
end

hook.Add("PostGamemodeLoaded", "JBT_BigMass", gmDetour)
if JBT_LOADED then gmDetour() end