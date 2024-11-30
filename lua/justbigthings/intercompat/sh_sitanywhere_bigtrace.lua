local enable = CreateConVar("jbt_sitanywhere_bigtrace_enabled", "1", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the sit anywhere module", 0, 1)
local adminOnly = CreateConVar("jbt_sitanywhere_bigtrace_adminonly", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether sitanywhere trace scaling should only be for admins", 0, 1)
local distance = CreateConVar("jbt_sitanywhere_bigtrace_distance", "100", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "What the base distance check should be for sitting", 0, 9999)
local smallMode = CreateConVar("jbt_sitanywhere_bigtrace_small", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether smaller players get a smaller range for sitanywhere", 0, 1)

local function bigTrace()
	if not SitAnywhere then return end

	local EMETA = FindMetaTable("Entity")
	local blacklist = SitAnywhere.ClassBlacklist
	local model_blacklist = SitAnywhere.ModelBlacklist
	local SitOnEntsMode = GetConVar("sitting_ent_mode")

	SitAnywhere.JBT_ValidSitTrace = SitAnywhere.JBT_ValidSitTrace or SitAnywhere.ValidSitTrace
	function SitAnywhere.ValidSitTrace(ply, EyeTrace)
		if not JBT.HasEnabled(ply, enable, "JBT_SitAnywhere_BigTrace") then
			return SitAnywhere.JBT_ValidSitTrace(ply, EyeTrace)
		end

		if not JBT.AdminOnlyCheck(ply, adminOnly, "jbt_sitanywhere_bigtrace", "JBT_SitAnywhere_BigTrace") then
			return SitAnywhere.JBT_ValidSitTrace(ply, EyeTrace)
		end

		local scale = JBT.PlyScale(ply)
		if scale < 1.01 and not JBT.HasEnabled(ply, smallMode, "JBT_SitAnywhere_BigTrace_Small") then
			scale = 1
		end

		if not EyeTrace.Hit then return false end
		if EyeTrace.HitPos:Distance(EyeTrace.StartPos) > distance:GetFloat() * scale then return false end

		local t = hook.Run("CheckValidSit", ply, EyeTrace)
		if t == false or t == true then return t end

		if not EyeTrace.HitWorld then
			if SitOnEntsMode:GetInt() == 0 then return false end
			if blacklist[string.lower(EyeTrace.Entity:GetClass())] then return false end
			if EyeTrace.Entity:GetModel() and model_blacklist[string.lower(EyeTrace.Entity:GetModel())] then return false end
		end

		if EMETA.CPPIGetOwner and SitOnEntsMode:GetInt() >= 1 then
			if SitOnEntsMode:GetInt() == 1 then
				if not EyeTrace.HitWorld then
					local owner = EyeTrace.Entity:CPPIGetOwner()
					if type(owner) == "Player" and owner ~= nil and owner:IsValid() and owner:IsPlayer() then
						return false
					end
				end
			elseif SitOnEntsMode:GetInt() == 2 then
				if not EyeTrace.HitWorld then
					local owner = EyeTrace.Entity:CPPIGetOwner()
					if type(owner) == "Player" and owner ~= nil and owner:IsValid() and owner:IsPlayer() and owner ~= ply then
						return false
					end
				end
			end
		end

		return true
	end

	return true
end

timer.Create("JBT_SitAnywhere", 1, 60, function()
	if bigTrace() then
		timer.Remove("JBT_SitAnywhere")
	end
end)