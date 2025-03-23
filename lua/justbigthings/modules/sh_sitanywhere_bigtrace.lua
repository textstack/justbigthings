JBT = JBT or {}
local JBT = JBT

local function bigTrace()
	if not SitAnywhere then return end

	local EMETA = FindMetaTable("Entity")
	local blacklist = SitAnywhere.ClassBlacklist
	local model_blacklist = SitAnywhere.ModelBlacklist
	local SitOnEntsMode = GetConVar("sitting_ent_mode")

	SitAnywhere.JBT_ValidSitTrace = SitAnywhere.JBT_ValidSitTrace or SitAnywhere.ValidSitTrace
	function SitAnywhere.ValidSitTrace(ply, EyeTrace)
		if not JBT.GetPersonalSetting(ply, "sitanywhere_bigtrace") then
			return SitAnywhere.JBT_ValidSitTrace(ply, EyeTrace)
		end

		local scale = JBT.PlyScale(ply)
		if scale < JBT.UPPER and not JBT.GetPersonalSetting(ply, "sitanywhere_bigtrace_small") then
			scale = 1
		end

		if not EyeTrace.Hit then return false end
		if EyeTrace.HitPos:Distance(EyeTrace.StartPos) > JBT.GetSetting("sitanywhere_bigtrace_distance") * scale then return false end

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