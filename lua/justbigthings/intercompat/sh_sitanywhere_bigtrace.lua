local function bigTrace()
	if not SitAnywhere then return end

	local enable = CreateConVar("jbt_sitanywhere_bigtrace_enabled", "1", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the sit anywhere module", 0, 1)
	local adminOnly = CreateConVar("jbt_sitanywhere_bigtrace_adminonly", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether sitanywhere trace scaling should only be for admins", 0, 1)
	local distance = CreateConVar("jbt_sitanywhere_bigtrace_distance", "100", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "What the base distance check should be for sitting", 0, 9999)

	local EMETA = FindMetaTable("Entity")
	local blacklist = SitAnywhere.ClassBlacklist
	local model_blacklist = SitAnywhere.ModelBlacklist
	local SitOnEntsMode = GetConVar("sitting_ent_mode")

	SitAnywhere.OldValidSitTrace = SitAnywhere.OldValidSitTrace or SitAnywhere.ValidSitTrace

	function SitAnywhere.ValidSitTrace(ply, EyeTrace)
		if not enable:GetBool() then
			return SitAnywhere.OldValidSitTrace(ply, EyeTrace)
		end

		if adminOnly:GetBool() and not JBT.HasPermission(ply, "jbt_sitanywhere_bigtrace") then
			return SitAnywhere.OldValidSitTrace(ply, EyeTrace)
		end

		local scale = JBT.PlyScale(ply)
		if scale < 1.01 then
			return SitAnywhere.OldValidSitTrace(ply, EyeTrace)
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