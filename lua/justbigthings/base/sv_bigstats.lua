local enable = CreateConVar("jbt_bigstats_enabled", "0", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the big stats module", 0, 1)
local adminOnly = CreateConVar("jbt_bigstats_adminonly", "0", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether stats scaling only affects admins", 0, 1)
local health = CreateConVar("jbt_bigstats_health", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more health", 0, 1)
local armor = CreateConVar("jbt_bigstats_armor", "0", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more armor", 0, 1)
local speed = CreateConVar("jbt_bigstats_speed", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more speed", 0, 1)
local smallMode = CreateConVar("jbt_bigstats_small", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether stats scaling affects small players too", 0, 1)

local statRound = 5
local defaultStatValue = 100

-- return number scaled by the appropriate amount
function JBT.PlyStat(ply, default, sqrt)
	if not enable:GetBool() then return default end
	if adminOnly:GetBool() and not JBT.HasPermission(ply, "jbt_bigstats") then return default end

	local scale = JBT.PlyScale(ply)
	if scale < 1.01 then
		if not smallMode:GetBool() then return default end
		if scale > 0.95 then return default end
	end

	local max
	if sqrt then
		max = math.sqrt(scale) * default
		return math.max(math.Round(max), 0)
	else
		max = scale * default
		return math.max(math.Round(max / statRound) * statRound, statRound)
	end
end

-- reapply "original" amount to get the rescaled amount
function JBT.PlyResyncStat(ply, stat)
	local amount = JBT.PlyOriginalStatValue(ply, stat)
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
	setFunc(ply, math.ceil(frac * newMax))
end

-- get the original value of a stat
function JBT.PlyOriginalStatValue(ply, stat)
	local amount = ply["JBT_" .. stat]
	if amount then return amount end

	local getFunc = ply["Get" .. stat]
	if getFunc then return getFunc(ply) end

	return defaultStatValue, true
end

-- if something tries ply:SetMaxHealth(ply:GetMaxHealth() + 1), we need to account for it
function JBT.RelativeStatSetFix(ply, stat)
	return ply["JBT_Get" .. stat]
end
function JBT.RelativeStatGetFix(ply, stat)
	local var = "JBT_Get" .. stat

	ply[var] = true
	timer.Create(var .. "_" .. ply:UserID(), 0, 1, function()
		if not IsValid(ply) then return end

		ply[var] = nil
	end)
end

local ENTITY = FindMetaTable("Entity")

ENTITY.JBT_SetMaxHealth = ENTITY.JBT_SetMaxHealth or ENTITY.SetMaxHealth
function ENTITY:SetMaxHealth(maxHealth, nofix)
	if not self:IsPlayer() or not health:GetBool() then
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
	if self:IsPlayer() and enable:GetBool() and health:GetBool() then
		JBT.RelativeStatGetFix(self, "MaxHealth")
	end

	return self:JBT_GetMaxHealth()
end

local PLAYER = FindMetaTable("Player")

PLAYER.JBT_SetMaxArmor = PLAYER.JBT_SetMaxArmor or PLAYER.SetMaxArmor
function PLAYER:SetMaxArmor(maxArmor, nofix)
	if not armor:GetBool() then
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
	if enable:GetBool() and armor:GetBool() then
		JBT.RelativeStatGetFix(self, "MaxArmor")
	end

	return self:JBT_GetMaxArmor()
end

local speedStats = {
	"CrouchedWalkSpeed",
	"LadderClimbSpeed",
	"RunSpeed",
	"SlowWalkSpeed",
	"WalkSpeed",
	"JumpPower"
}

for _, stat in ipairs(speedStats) do
	local func = "Set" .. stat
	local oldFunc = "JBT_" .. func

	PLAYER[oldFunc] = PLAYER[oldFunc] or PLAYER[func]
	PLAYER[func] = function(self, amount, nofix)
		if not speed:GetBool() then
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
		if enable:GetBool() and speed:GetBool() then
			JBT.RelativeStatGetFix(self, stat)
		end

		return self[oldGetFunc](self)
	end
end

local function setAllSpeeds()
	for _, ply in player.Iterator() do
		for _, stat in ipairs(speedStats) do
			JBT.PlyResyncStat(ply, stat)
		end
	end
end

local function setAllArmor()
	for _, ply in player.Iterator() do
		JBT.PlyRefracStat(ply, "Armor")
	end
end

local function setAllHealth()
	for _, ply in player.Iterator() do
		JBT.PlyRefracStat(ply, "Health")
	end
end

local function setAll()
	setAllSpeeds()
	setAllArmor()
	setAllHealth()
end

cvars.AddChangeCallback("jbt_bigstats_enabled", setAll)
cvars.AddChangeCallback("jbt_bigstats_health", setAllHealth)
cvars.AddChangeCallback("jbt_bigstats_armor", setAllArmor)
cvars.AddChangeCallback("jbt_bigstats_speed", setAllSpeeds)
cvars.AddChangeCallback("jbt_bigstats_small", setAll)

hook.Add("PlayerSpawn", "JBT_BigStats", function(ply, transition)
	if not enable:GetBool() then return end
	if adminOnly:GetBool() and not JBT.HasPermission(ply, "jbt_bigstats") then return end

	timer.Create("JBT_SetStats_" .. ply:UserID(), 0.2, 1, function()
		if not IsValid(ply) or not ply:Alive() then return end

		for _, stat in ipairs(speedStats) do
			JBT.PlyResyncStat(ply, stat)
		end

		if transition then return end

		JBT.PlyRefracStat(ply, "Health")
		JBT.PlyRefracStat(ply, "Armor")
	end)
end)

hook.Add("JBT_ScaleChanged", "JBT_BigStats", function(ply, scale)
	if not enable:GetBool() then return end
	if adminOnly:GetBool() and not JBT.HasPermission(ply, "jbt_bigstats") then return end

	for _, stat in ipairs(speedStats) do
		JBT.PlyResyncStat(ply, stat)
	end

	JBT.PlyRefracStat(ply, "Health")
	JBT.PlyRefracStat(ply, "Armor")
end)
