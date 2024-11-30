local enable = CreateConVar("jbt_pac_biglimit_enabled", "1", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the pac size limit module", 0, 1)
local adminOnly = CreateConVar("jbt_pac_biglimit_adminonly", "1", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether the modified size limit is for admins only", 0, 1)
local amount = CreateConVar("jbt_pac_biglimit_max", "100", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "How much the pac size max is modified", 0.01, 1000)
local amountMin = CreateConVar("jbt_pac_biglimit_min", "0.01", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "How much the pac size min is modified", 0.01, 1000)

local PLAYER = FindMetaTable("Player")

-- this will just spam the console if it isn't limited
PLAYER.JBT_SetStepSize = PLAYER.JBT_SetStepSize or PLAYER.SetStepSize
function PLAYER:SetStepSize(stepHeight)
	self:JBT_SetStepSize(math.min(stepHeight, 512))
end

local function biggerSizeLimit()
	if not pac or not pac.emut or not pac.emut.registered_mutators or not pac.emut.registered_mutators.size then
		return
	end

	local size = pac.emut.registered_mutators.size

	size.JBT_ReadArguments = size.JBT_ReadArguments or size.ReadArguments
	function size:ReadArguments()
		local multiplier = math.Clamp(net.ReadFloat(), 0.01, math.max(10, amount:GetFloat()))
		local other = false
		local hidden_state

		if net.ReadBool() then
			other = {}
			other.StandingHullHeight = net.ReadFloat()
			other.CrouchingHullHeight = net.ReadFloat()
			other.HullWidth = net.ReadFloat()
		end

		if net.ReadBool() then
			hidden_state = net.ReadTable()
		end

		return multiplier, other, hidden_state
	end

	size.JBT_Mutate = size.JBT_Mutate or size.Mutate
	function size:Mutate(multiplier, other, hidden_state)
		-- the linter is wrong
		local ply = self.Owner
		if not ply:IsPlayer() then
			self:JBT_Mutate(math.Clamp(multiplier, 0.1, 10), other, hidden_state)
			return
		end

		if not JBT.HasEnabled(ply, enable, "JBT_Pac_BigLimit") then
			self:JBT_Mutate(math.Clamp(multiplier, 0.1, 10), other, hidden_state)
			return
		end

		if not JBT.AdminOnlyCheck(ply, adminOnly, "jbt_pac_biglimit", "JBT_Pac_BigLimit") then
			self:JBT_Mutate(math.Clamp(multiplier, 0.1, 10), other, hidden_state)
			return
		end

		self:JBT_Mutate(math.Clamp(multiplier, amountMin:GetFloat(), amount:GetFloat()), other, hidden_state)
	end

	return true
end

timer.Create("JBT_Pac3", 1, 60, function()
	if biggerSizeLimit() then
		timer.Remove("JBT_Pac3")
	end
end)