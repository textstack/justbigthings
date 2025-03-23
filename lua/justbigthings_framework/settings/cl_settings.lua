JBT.Settings = JBT.Settings or {}

JBT.SETTINGS_NET_STRING = "jbtSettings"

-- allow superadmins to set server settings from client
function JBT.SetSetting(setting, value)
	if not LocalPlayer():IsSuperAdmin() then return true end

	local newVal = JBT.ToSetting(value)
	if newVal == nil then return end

	net.Start(JBT.SETTINGS_NET_STRING)
	net.WriteString(setting)
	net.WriteInt(newVal, JBT.SETTINGS_OPTION_NET_SIZE)
	net.SendToServer()
end

net.Receive(JBT.SETTINGS_NET_STRING, function()
	local count = net.ReadUInt(JBT.SETTINGS_NET_SIZE)

	for i = 1, count do
		local setting = net.ReadString()
		local value = net.ReadInt(JBT.SETTINGS_OPTION_NET_SIZE)

		JBT.Settings[setting] = value
	end
end)