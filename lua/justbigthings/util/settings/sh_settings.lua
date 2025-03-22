JBT.SETTINGS_NET_SIZE = 8
JBT.SETTINGS_OPTION_NET_SIZE = 8

JBT.DefaultSettings = JBT.DefaultSettings or {}

-- set a default value for a setting, only do this on shared files
-- addWarning adds a warning if the value change needs a restart
function JBT.SetSettingDefault(setting, value, changeCallback)
	local newVal = JBT.ToSetting(value)
	if newVal == nil then return end

	JBT.DefaultSettings[setting] = newVal

	if SERVER and changeCallback then
		JBT.DefaultSettingsCC[setting] = changeCallback
	end
end

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
		value = JBT.DefaultSettings[setting]
	end

	return value ~= 0
end

-- get a server setting that could be overridden by player settings
function JBT.GetPersonalSetting(ply, setting)
	local nwVar = ply:GetNWBool("jbt_" .. setting, -1)
	if nwVar == false then return false end

	local perm = JBT.HasPermission(ply, "jbt_" .. setting)
	if not perm and JBT.GetSettingBool(v .. "_adminonly") then return false end

	return nwVar or perm or JBT.GetSettingBool(v)
end