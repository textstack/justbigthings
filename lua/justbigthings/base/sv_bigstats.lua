local enable = CreateConVar("jbt_bigstats_enabled", "0", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the big stats module", 0, 1)
local health = CreateConVar("jbt_bigstats_health", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more health", 0, 1)
local armor = CreateConVar("jbt_bigstats_armor", "0", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more armor", 0, 1)
local speed = CreateConVar("jbt_bigstats_speed", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more speed", 0, 1)
local smallMode = CreateConVar("jbt_bigstats_small", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether stats scaling affects small players too", 0, 1)

local statSteps = 5

function JBT.PlyStat(ply, default)
    if not enable:GetBool() then return default end

    local scale = JBT.PlyScale(ply)
    if scale < 1.01 then
        if not smallMode:GetBool() then return default end
        if scale > 0.99 then return default end
    end

    local max = scale * default
    return math.max(math.Round(max / statSteps) * statSteps, statSteps)
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
    if not self:IsPlayer() or not enable:GetBool() or not health:GetBool() then
        return self:JBT_GetMaxHealth()
    end

    JBT.RelativeStatGetFix(self, "MaxHealth")
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
    if not enable:GetBool() or not armor:GetBool() then
        return self:JBT_GetMaxArmor()
    end

    JBT.RelativeStatGetFix(self, "MaxArmor")
    return self:JBT_GetMaxArmor()
end

local speedStats = {
    "CrouchedWalkSpeed",
    "LadderClimbSpeed",
    "RunSpeed",
    "SlowWalkSpeed",
    "WalkSpeed"
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

        self[oldFunc](self, JBT.PlyStat(self, amount))
    end

    local getFunc = "Get" .. stat
    local oldGetFunc = "JBT_" .. getFunc
    PLAYER[oldGetFunc] = PLAYER[oldGetFunc] or PLAYER[getFunc]
    PLAYER[getFunc] = function(self)
        if not enable:GetBool() or not speed:GetBool() then
            return self[oldGetFunc](self)
        end

        JBT.RelativeStatGetFix(self, stat)
        return self[oldGetFunc](self)
    end
end

local function setSpeeds()
    for _, ply in player.Iterator() do
        for _, stat in ipairs(speedStats) do
            local amount = ply["JBT_" .. stat] or ply["Get" .. stat](ply)
            ply["Set" .. stat](ply, amount, true)
        end
    end
end

local function setArmor()
    for _, ply in player.Iterator() do
        local amount = ply.JBT_MaxArmor or ply:GetMaxArmor()
        ply:SetMaxArmor(amount, true)
    end
end

local function setHealth()
    for _, ply in player.Iterator() do
        local amount = ply.JBT_MaxHealth or ply:GetMaxHealth()
        ply:SetMaxHealth(amount, true)
    end
end

local function setAll()
    setSpeeds()
    setArmor()
    setHealth()
end

cvars.AddChangeCallback("jbt_bigstats_enabled", setAll)
cvars.AddChangeCallback("jbt_bigstats_health", setHealth)
cvars.AddChangeCallback("jbt_bigstats_armor", setArmor)
cvars.AddChangeCallback("jbt_bigstats_speed", setSpeeds)
cvars.AddChangeCallback("jbt_bigstats_small", setAll)
