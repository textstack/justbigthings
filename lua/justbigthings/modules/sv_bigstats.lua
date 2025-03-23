JBT = JBT or {}
local JBT = JBT

JBT.STAT_ROUND = 5
JBT.DEFAULT_STAT_VALUE = 100
JBT.SPEED_STATS = {
	"CrouchedWalkSpeed",
	"LadderClimbSpeed",
	"RunSpeed",
	"SlowWalkSpeed",
	"WalkSpeed",
	"JumpPower"
}

-- return number scaled by the appropriate amount
function JBT.PlyStat(ply, default, sqrt)
	if not JBT.GetPersonalSetting(ply, "bigstats") then return default end

	local scale = JBT.PlyScale(ply)
	if scale < JBT.UPPER then
		if not JBT.GetPersonalSetting(ply, "bigstats_small") then return default end
		if scale > JBT.LOWER then return default end
	end

	local max
	if sqrt then
		max = math.sqrt(scale) * default
		return math.max(math.Round(max), 0)
	else
		max = scale * default
		return math.max(math.Round(max / JBT.STAT_ROUND) * JBT.STAT_ROUND, JBT.STAT_ROUND)
	end
end

-- get the original value of a stat
function JBT.PlyOriginalStat(ply, stat, default)
	local amount = ply["JBT_" .. stat]
	if amount then return amount end

	local getFunc = ply["Get" .. stat]
	if getFunc then return getFunc(ply) end

	return default or JBT.DEFAULT_STAT_VALUE, true
end

-- reapply "original" amount to get the rescaled amount
function JBT.PlyResyncStat(ply, stat, noloop)
	if stat == "Speed" and not noloop then
		for _, stat1 in ipairs(JBT.SPEED_STATS) do
			JBT.PlyResyncStat(ply, stat1)
		end

		return
	end

	local amount = JBT.PlyOriginalStat(ply, stat)
	ply["Set" .. stat](ply, amount, true)
end

-- set player's health/armor and max health/armor at once to keep the fractional component
function JBT.PlyRefracStat(ply, stat)
	local getMaxFunc = ply["GetMax" .. stat]
	if not getMaxFunc then return end

	local setFunc = ply["Set" .. stat]
	if not setFunc then return end

	local getFunc = ply[stat]
	if not getFunc then return end

	local oldMax = getMaxFunc(ply)
	if oldMax == 0 then
		setFunc(ply, 0)
		JBT.PlyResyncStat(ply, "Max" .. stat)
		return
	end

	JBT.PlyResyncStat(ply, "Max" .. stat)

	local newMax = getMaxFunc(ply)
	local frac = getFunc(ply) / oldMax
	setFunc(ply, math.floor(frac * newMax))
end

-- quick function to do all the resyncs and refracs needed
function JBT.PlyResyncAllStats(ply)
	JBT.PlyResyncStat(ply, "Speed")
	JBT.PlyRefracStat(ply, "Health")
	JBT.PlyRefracStat(ply, "Armor")
end

local ENTITY = FindMetaTable("Entity")

ENTITY.JBT_SetMaxHealth = ENTITY.JBT_SetMaxHealth or ENTITY.SetMaxHealth
function ENTITY:SetMaxHealth(maxHealth, nofix)
	if not self:IsPlayer() or not JBT.GetPersonalSetting(self, "bigstats") or not JBT.GetPersonalSetting(self, "bigstats_health") then
		self:JBT_SetMaxHealth(maxHealth)
		return
	end

	if not nofix and JBT.RelativeStatSetFix(self, "MaxHealth") then
		self:JBT_SetMaxHealth(maxHealth)
		return
	end

	self.JBT_MaxHealth = maxHealth
	self:JBT_SetMaxHealth(JBT.PlyStat(self, maxHealth))
end

ENTITY.JBT_GetMaxHealth = ENTITY.JBT_GetMaxHealth or ENTITY.GetMaxHealth
function ENTITY:GetMaxHealth()
	if self:IsPlayer() and JBT.GetPersonalSetting(self, "bigstats_health") then
		JBT.RelativeStatGetFix(self, "MaxHealth")
	end

	return self:JBT_GetMaxHealth()
end

local PLAYER = FindMetaTable("Player")

PLAYER.JBT_SetMaxArmor = PLAYER.JBT_SetMaxArmor or PLAYER.SetMaxArmor
function PLAYER:SetMaxArmor(maxArmor, nofix)
	if not JBT.GetPersonalSetting(self, "bigstats") or not JBT.GetPersonalSetting(self, "bigstats_armor") then
		self:JBT_SetMaxArmor(maxArmor)
		return
	end

	if not nofix and JBT.RelativeStatSetFix(self, "MaxArmor") then
		self:JBT_SetMaxArmor(maxArmor)
		return
	end

	self.JBT_MaxArmor = maxArmor
	self:JBT_SetMaxArmor(JBT.PlyStat(self, maxArmor))
end

PLAYER.JBT_GetMaxArmor = PLAYER.JBT_GetMaxArmor or PLAYER.GetMaxArmor
function PLAYER:GetMaxArmor()
	if JBT.GetPersonalSetting(self, "bigstats_armor") then
		JBT.RelativeStatGetFix(self, "MaxArmor")
	end

	return self:JBT_GetMaxArmor()
end

for _, stat in ipairs(JBT.SPEED_STATS) do
	local func = "Set" .. stat
	local oldFunc = "JBT_" .. func

	PLAYER[oldFunc] = PLAYER[oldFunc] or PLAYER[func]
	PLAYER[func] = function(self, amount, nofix)
		if not JBT.GetPersonalSetting(self, "bigstats") or not JBT.GetPersonalSetting(self, "bigstats_speed") then
			self[oldFunc](self, amount)
			return
		end

		if not nofix and JBT.RelativeStatSetFix(self, stat) then
			self[oldFunc](self, amount)
			return
		end

		self["JBT_" .. stat] = amount
		self[oldFunc](self, JBT.PlyStat(self, amount, true))
	end

	local getFunc = "Get" .. stat
	local oldGetFunc = "JBT_" .. getFunc
	PLAYER[oldGetFunc] = PLAYER[oldGetFunc] or PLAYER[getFunc]
	PLAYER[getFunc] = function(self)
		if JBT.GetPersonalSetting(self, "bigstats_speed") then
			JBT.RelativeStatGetFix(self, stat)
		end

		return self[oldGetFunc](self)
	end
end

hook.Add("PlayerSpawn", "JBT_BigStats", function(ply, transition)
	if not JBT.GetPersonalSetting(ply, "bigstats") then return end

	timer.Create("JBT_SetStats_" .. ply:UserID(), 0.2, 1, function()
		if not IsValid(ply) or not ply:Alive() then return end

		JBT.PlyResyncStat(ply, "Speed")

		if transition then return end

		JBT.PlyRefracStat(ply, "Health")
		JBT.PlyRefracStat(ply, "Armor")
	end)
end)

hook.Add("JBT_ScaleChanged", "JBT_BigStats", function(ply, scale)
	if not JBT.GetPersonalSetting(ply, "bigstats") then return end

	JBT.PlyResyncAllStats(ply)
end)