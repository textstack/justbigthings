local enable = CreateConVar("jbt_bigstats_enabled", "0", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the big stats module", 0, 1)
local health = CreateConVar("jbt_bigstats_health", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more health", 0, 1)
local armor = CreateConVar("jbt_bigstats_armor", "0", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more armor", 0, 1)
local speed = CreateConVar("jbt_bigstats_speed", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether bigger players get more speed", 0, 1)
local smallMode = CreateConVar("jbt_bigstats_small", "1", FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE, "Whether stats scaling affects small players too", 0, 1)

