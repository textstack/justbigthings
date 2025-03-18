JBT.Settings = JBT.Settings or {}

JBT.SETTINGS_NET_SIZE = 8
JBT.SETTINGS_OPTION_NET_SIZE = 8
JBT.SETTINGS_NET_STRING = "jbtSettings"

-- allow superadmins to set server settings from client
function JBT.SetSetting(setting, value)
	if not LocalPlayer():IsSuperAdmin() then
		return true
	end

	local newVal
	if type(value) == "boolean" then
		newVal = value and 1 or 0
	else
		newVal = tonumber(value)
		if not newVal then return end
	end

	net.Start(JBT.SETTINGS_NET_STRING)
	net.WriteString(setting)
	net.WriteInt(newVal, JBT.SETTINGS_OPTION_NET_SIZE)
	net.SendToServer()
end

-- get a server setting, will return the fallback if nill and return a boolean if isBool is true
function JBT.GetSetting(setting, fallback, isBool)
	local value = JBT.Settings[setting]
	if value == nil then return fallback end

	if isBool then return value ~= 0 end
	return value
end

net.Receive(JBT.SETTINGS_NET_STRING, function()
	local count = net.ReadUInt(JBT.SETTINGS_NET_SIZE)

	for i = 1, count do
		local setting = net.ReadString()
		local value = net.ReadInt(JBT.SETTINGS_OPTION_NET_SIZE)

		JBT.Settings[setting] = value
	end
end)