local personalEnable
if CLIENT then
	personalEnable = CreateClientConVar("jbt_cl_bigdelta", "1", true, true, "Whether your movement animations sync properly with scale (per-player)", 0, 2)
end
local enable = CreateConVar("jbt_bigdelta_enabled", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the big delta module", 0, 1)

local minimumMovingSpeed = 0.5
local speedThatDoesntDoTheStupidIdleThing = 25
local calcIdealsToOverride = {
	[ACT_MP_STAND_IDLE] = true,
	[ACT_MP_RUN] = true,
	[ACT_MP_WALK] = true
}
local unarmed = {
	run_all_01 = true,
	walk_all = true,
	cwalk_all = true
}

-- does the player have bigdelta enabled?
function JBT.PlyNeedsDelta(ply)
	local val
	if CLIENT and ply == LocalPlayer() then
		val = personalEnable:GetInt()
	else
		val = ply:GetNWInt("JBT_BigDelta", 1)
	end

	return val > 1 or (enable:GetBool() and val > 0)
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/game/shared/base_playeranimstate.cpp#L569-L581
function JBT.EstimateYaw(ply, vel)
	ply.JBT_GaitYaw = ply.JBT_GaitYaw or 0

	local len = vel:Length2D()
	if len > minimumMovingSpeed then
		ply.JBT_GaitYaw = math.atan2(vel.y, vel.x)
		ply.JBT_GaitYaw = math.deg(ply.JBT_GaitYaw)
	end

	return ply.JBT_GaitYaw
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/game/shared/base_playeranimstate.cpp#L501-L530
function JBT.CalcMovementPlaybackRate(ply, vel, maxSeqGroundSpeed, scale)
	scale = scale or 1

	local len = vel:Length2D()
	local playbackRate = 0.01

	if len > speedThatDoesntDoTheStupidIdleThing then
		if maxSeqGroundSpeed < 0.001 then
			playbackRate = 0.01
		else
			playbackRate = len / maxSeqGroundSpeed
			playbackRate = math.Clamp(playbackRate / scale, 0.01, 10)
		end
	end

	-- the unarmed move sequence is just so weird
	if unarmed[ply:GetSequenceName(ply:GetSequence())] and len < 120 * math.sqrt(scale) then
		playbackRate = math.max(playbackRate, 1.78 - math.atan(scale))

		if len < 50 then
			playbackRate = math.min(playbackRate, 0.25 + 0.25 / scale)
		end
	end

	-- without dampening there would be a little snap to idle for some reason
	ply.JBT_PlaybackRate = ply.JBT_PlaybackRate or 0.01
	ply.JBT_PlaybackRate = JBT.Dampen(15, ply.JBT_PlaybackRate, playbackRate)

	return ply.JBT_PlaybackRate
end

function JBT.Dampen(speed, from, to)
	return Lerp(1 - math.exp(-speed * FrameTime()), from, to)
end

-- mark a pose as not to be modified by JBT
function JBT.PoseBlock(ply, pose)
	ply.JBT_PoseBlock = ply.JBT_PoseBlock or {}
	ply.JBT_PoseBlock[pose] = true
end

-- set a poseparam
function JBT.SetPoseParam(ply, pose, value)
	if ply.JBT_PoseBlock and ply.JBT_PoseBlock[pose] then return end

	ply:SetPoseParameter(pose, value, true)
end

local ENTITY = FindMetaTable("Entity")

ENTITY.JBT_SetPoseParameter = ENTITY.JBT_SetPoseParameter or ENTITY.SetPoseParameter
function ENTITY:SetPoseParameter(poseName, poseValue, bypass)
	self:JBT_SetPoseParameter(poseName, poseValue)

	if not self:IsPlayer() or bypass then return end

	if type(poseName) == "number" then
		poseName = self:GetPoseParameterName(poseName)
	end

	if poseName == "move_x" or poseName == "move_y" then
		JBT.PoseBlock(self, poseName)
	end
end

ENTITY.JBT_ClearPoseParameters = ENTITY.JBT_ClearPoseParameters or ENTITY.ClearPoseParameters
function ENTITY:ClearPoseParameters()
	self:JBT_ClearPoseParameters()

	if not self:IsPlayer() then return end

	self.JBT_PoseBlock = nil
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/game/shared/base_playeranimstate.cpp#L587
hook.Add("UpdateAnimation", "JBT_BigDelta", function(ply, vel, maxSeqGroundSpeed)
	if not JBT.PlyNeedsDelta(ply) then return end

	local scale = JBT.PlyScale(ply)
	if scale < 1.01 then return end

	local yaw = JBT.EstimateYaw(ply, vel) - ply:EyeAngles().yaw
	local playbackRate = JBT.CalcMovementPlaybackRate(ply, vel, maxSeqGroundSpeed, scale)

	local moveX = math.cos(math.rad(yaw)) * playbackRate
	local moveY = -math.sin(math.rad(yaw)) * playbackRate

	JBT.SetPoseParam(ply, "move_x", moveX)
	JBT.SetPoseParam(ply, "move_y", moveY)
end)

local function gmDetour()
	local gm = gmod.GetGamemode()

	gm.JBT_CalcMainActivity = gm.JBT_CalcMainActivity or gm.CalcMainActivity
	function gm:CalcMainActivity(ply, vel)
		local ideal, override = gm:JBT_CalcMainActivity(ply, vel)

		if not JBT.PlyNeedsDelta(ply) then return ideal, override end

		local scale = JBT.PlyScale(ply)
		if scale < 1.01 then return ideal, override end

		if ply:InVehicle() then return ideal, override end
		if ply.m_bWasNoclipping then return ideal, override end
		if not calcIdealsToOverride[ply.CalcIdeal] then return ideal, override end

		ply.CalcSeqOverride = -1

		local len2d = vel:Length2DSqr()
		if len2d > 22500 * scale then
			ply.CalcIdeal = ACT_MP_RUN
		elseif len2d > 0.25 * scale then
			ply.CalcIdeal = ACT_MP_WALK
		end

		return ply.CalcIdeal, ply.CalcSeqOverride
	end
end

hook.Add("PostGamemodeLoaded", "JBT_BigDelta", gmDetour)
if JBT_LOADED then gmDetour() end

if CLIENT then return end

timer.Create("JBT_UpdateBigDeltaPrefs", 5, 0, function()
	if not enable:GetBool() then return end

	for _, ply in player.Iterator() do
		local set = ply:GetInfoNum("jbt_cl_bigdelta", 1)
		ply:SetNWInt("JBT_BigDelta", set)
	end
end)
