JBT.DefaultSettings = JBT.DefaultSettings or {}

JBT.SETTINGS_NET_SIZE = 8
JBT.SETTINGS_OPTION_NET_SIZE = 11

-- get a server setting
function JBT.GetSetting(setting)
	local value = JBT.Settings[setting]
	if value == nil then return JBT.DefaultSettings[setting] end

	return value
end

-- get a server setting as a bool
function JBT.GetSettingBool(setting)
	local value = JBT.Settings[setting]
	if value == nil then
		value = JBT.DefaultSettings[setting] or 0
	end

	return value ~= 0
end

-- get a server setting that could be overridden by player settings
function JBT.GetPersonalSetting(ply, setting)
	local nwVar = ply:GetNWBool("jbt_" .. setting, -1)
	if nwVar == false then return false end

	if JBT.GetSettingBool(setting .. "_adminonly") and not JBT.HasPermission(ply, "jbt_" .. setting) then return false end

	return nwVar or JBT.GetSettingBool(setting)
end