local enable = CreateConVar("jbt_pac_sizelimit_enabled", "1", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the pac size limit module", 0, 1)
local adminOnly = CreateConVar("jbt_pac_sizelimit_adminonly", "1", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether the modified size limit is for admins only", 0, 1)
local amount = CreateConVar("jbt_pac_sizelimit_max", "100", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "How much the pac size max is modified", 0.01, 1000)
local amountMin = CreateConVar("jbt_pac_sizelimit_min", "0.01", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "How much the pac size min is modified", 0.01, 1000)

local function biggerSizeLimit()
	if not pac or not pac.emut or not pac.emut.registered_mutators or not pac.emut.registered_mutators.size then
		return
	end

	local size = pac.emut.registered_mutators.size

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

	size.OldMutate = size.OldMutate or size.Mutate
	function size:Mutate(multiplier, other, hidden_state)
		if not enable:GetBool() then
			self:OldMutate(math.Clamp(multiplier, 0.1, 10), other, hidden_state)
			return
		end

		if not adminOnly:GetBool() then
			self:OldMutate(math.Clamp(multiplier, amountMin:GetFloat(), amount:GetFloat()), other, hidden_state)
			return
		end

		-- the linter is wrong
		local ply = self.Owner
		if not ply:IsPlayer() then
			self:OldMutate(math.Clamp(multiplier, 0.1, 10), other, hidden_state)
			return
		end

		if JBT.HasPermission(ply, "jbt_pac_sizelimit") then
			self:OldMutate(math.Clamp(multiplier, amountMin:GetFloat(), amount:GetFloat()), other, hidden_state)
		end
	end

	return true
end

timer.Create("pacNewSizeLimit", 1, 60, function()
	if biggerSizeLimit() then
		timer.Remove("pacNewSizeLimit")
	end
end)