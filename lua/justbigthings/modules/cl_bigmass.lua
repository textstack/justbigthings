JBT = JBT or {}
local JBT = JBT

local function gmDetour()
	if JBT_NOGM then return end

	local gm = gmod.GetGamemode()

	gm.JBT_PlayerFootstep = gm.JBT_PlayerFootstep or gm.PlayerFootstep or function() end
	function gm:PlayerFootstep(ply, pos, foot, snd, vol, filter)
		if self:JBT_PlayerFootstep(ply, pos, foot, snd, vol, filter) then return true end

		local scale = JBT.PlyScale(ply)
		if scale < JBT.UPPER and scale > JBT.LOWER then return end

		for _, v in ipairs(JBT.FEET_NO_OVERRIDE) do
			if string.find(snd, v) then return end
		end

		if JBT.GetPersonalSetting(ply, "bigmass") then return true end
	end
end

hook.Add("PostGamemodeLoaded", "JBT_BigMass", gmDetour)
if JBT_LOADED then gmDetour() end