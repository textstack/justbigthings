local enable = CreateConVar("jbt_bigmass_enabled", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the big mass module", 0, 1)

local function gmDetour()
	if JBT_NOGM then return end

	local gm = gmod.GetGamemode()

	gm.JBT_PlayerFootstep = gm.JBT_PlayerFootstep or gm.PlayerFootstep or function() end
	function gm:PlayerFootstep(ply, pos, foot, snd, vol, filter)
		if self:JBT_PlayerFootstep(ply, pos, foot, snd, vol, filter) then return true end
		if JBT.HasEnabled(ply, enable, "JBT_BigMass") then return true end
	end
end

hook.Add("PostGamemodeLoaded", "JBT_BigMass", gmDetour)
if JBT_LOADED then gmDetour() end