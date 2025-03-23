JBT = JBT or {}
local JBT = JBT

local personalEnable = CreateClientConVar("jbt_cl_pac_bigdraw", "1", true, false, "Whether your PAC3 draw distance setting should be scaled for each player", 0, 2)

local function drawDist()
	if not pac then return end

	local cvarDist = GetConVar("pac_draw_distance")

	local result
	local function canBigDraw()
		if result ~= nil then return result end

		local val = personalEnable:GetInt()
		result = val > 1 or (JBT.GetSettingBool("pac_bigdraw") and val > 0)

		timer.Simple(0, function()
			result = nil
		end)

		return result
	end

	local baseDist
	function JBT.ResetBigDraw(ply)
		if ply.JBT_BigDist then
			ply.pac_draw_distance = nil
			ply.JBT_BigDist = nil
		end

		if not canBigDraw() then return end

		local scale = JBT.PlyScale(ply)
		if scale < JBT.UPPER then return end

		if baseDist == nil then
			baseDist = cvarDist:GetInt()
			timer.Simple(0, function()
				baseDist = nil
			end)
		end

		if baseDist > 0 then
			ply.pac_draw_distance = baseDist * scale
		end

		ply.JBT_BigDist = true
	end

	cvars.AddChangeCallback("pac_draw_distance", function()
		for _, ply in player.Iterator() do
			JBT.ResetBigDraw(ply)
		end
	end)

	cvars.AddChangeCallback("jbt_cl_pac_bigdraw", function()
		for _, ply in player.Iterator() do
			JBT.ResetBigDraw(ply)
		end
	end)

	gameevent.Listen("player_activate")
	hook.Add("player_activate", "JBT_PAC3_BigDraw", function(data)
		JBT.ResetBigDraw(Player(data.userid))
	end)

	hook.Add("JBT_ScaleChanged", "JBT_PAC3_BigDraw", function(ply, scale)
		JBT.ResetBigDraw(ply)
	end)

	for _, ply in player.Iterator() do
		JBT.ResetBigDraw(ply)
	end
end

if JBT_LOADED then
	drawDist()
else
	hook.Add("InitPostEntity", "JBT_PAC3_BigDraw", function()
		timer.Simple(10, drawDist)
	end)
end
