local enable = CreateConVar("jbt_bigstats_enabled", "0", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the big stats module", 0, 1)
local health = CreateConVar("jbt_bigstats_health", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more health", 0, 1)
local armor = CreateConVar("jbt_bigstats_armor", "0", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more armor", 0, 1)
local speed = CreateConVar("jbt_bigstats_speed", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more speed", 0, 1)
local smallMode = CreateConVar("jbt_bigstats_small", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether stats scaling affects small players too", 0, 1)

local statSteps = 5

function JBT.PlyStat(ply, default, sqrt)
	if not enable:GetBool() then return default end

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
		return math.max(math.Round(max / statSteps) * statSteps, statSteps)
	end
end

local defaultStat = 100

-- convert player's health/armor fraction to what it would be with modified max health/armor
-- kind of unstable? works for spawning at least
function JBT.PlyRefracStat(ply, stat)
	local getFunc = ply[stat]
	if not getFunc then return defaultStat end

	local current = getFunc(ply)
	local defaultMax = JBT.GetOriginalStat(ply, "Max" .. stat)

	if defaultMax == 0 then return 0 end

	local newMax = JBT.PlyStat(ply, defaultMax)

	local frac = current / defaultMax
	return frac * newMax
end

-- get the original value of a stat
function JBT.GetOriginalStat(ply, stat)
	local amount = ply["JBT_" .. stat]
	if amount then return amount end

	local getFunc = ply["Get" .. stat]
	if getFunc then return getFunc(ply) end

	return defaultStat, true
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

	self.JBT_MaxHealth = maxHealth

	if not nofix and JBT.RelativeStatSetFix(self, "MaxHealth") then
		self:JBT_SetMaxHealth(maxHealth)
		return
	end

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

	self.JBT_MaxArmor = maxArmor

	if not nofix and JBT.RelativeStatSetFix(self, "MaxArmor") then
		self:JBT_SetMaxArmor(maxArmor)
		return
	end

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

		self["JBT_" .. stat] = amount

		if not nofix and JBT.RelativeStatSetFix(self, stat) then
			self[oldFunc](self, amount)
			return
		end

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

local function setStat(ply, stat)
	local amount = JBT.GetOriginalStat(ply, stat)
	ply["Set" .. stat](ply, amount, true)
end

local function setAllSpeeds()
	for _, ply in player.Iterator() do
		for _, stat in ipairs(speedStats) do
			setStat(ply, stat)
		end
	end
end

local function setAllArmor()
	for _, ply in player.Iterator() do
		setStat(ply, "MaxArmor")
	end
end

local function setAllHealth()
	for _, ply in player.Iterator() do
		setStat(ply, "MaxHealth")
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

local function setPlyStats(ply, transition)
	if not enable:GetBool() then return end

	timer.Create("JBT_SetStats_" .. ply:UserID(), 0.2, 1, function()
		if not IsValid(ply) or not ply:Alive() then return end

		for _, stat in ipairs(speedStats) do
			setStat(ply, stat)
		end

		if transition then return end

		setStat(ply, "MaxHealth")
		setStat(ply, "MaxArmor")

		if health:GetBool() then
			ply:SetHealth(JBT.PlyRefracStat(ply, "Health"))
		end

		if armor:GetBool() then
			ply:SetArmor(JBT.PlyRefracStat(ply, "Armor"))
		end
	end)
end

hook.Add("PlayerSpawn", "JBT_BigStats", setPlyStats)
