JBT.SETTINGS_FILE = "jbt_settings.json"
JBT.SETTINGS_NET_STRING = "jbtSettings"

util.AddNetworkString(JBT.SETTINGS_NET_STRING)

do
	local newSettings = file.Read(JBT.SETTINGS_FILE, "DATA")
	if newSettings then
		JBT.Settings = util.JSONToTable(newSettings)
	else
		JBT.Settings = JBT.Settings or {}
	end
end

-- set a server setting, will autoconvert non-integer values
function JBT.SetSetting(setting, value)
	local newVal = JBT.ToSetting(value)
	if newVal == nil then return end

	local extras = JBT.DefaultSettingsExtras[setting]
	if extras then
		if extras.IsBool then
			newVal = math.Clamp(newVal, 0, 1)
		end
		if extras.Min then
			newVal = math.max(newVal, extras.Min)
		end
		if extras.Max then
			newVal = math.min(newVal, extras.Max)
		end

		local oldVal = JBT.Settings[setting]
		if extras.CC and oldVal ~= newVal then
			extras.CC(oldVal, newVal)
		end
	end

	JBT.Settings[setting] = newVal
	file.Write(JBT.SETTINGS_FILE, util.TableToJSON(JBT.Settings))

	net.Start(JBT.SETTINGS_NET_STRING)
	net.WriteUInt(1, JBT.SETTINGS_NET_SIZE)
	net.WriteString(setting)
	net.WriteInt(newVal, JBT.SETTINGS_OPTION_NET_SIZE)
	net.Broadcast()
end

concommand.Add("jbt_set_setting", function(ply, _, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then
		ply:ChatPrint("You need to be a superadmin to change JBT's settings")
		return
	end

	if not args[1] then
		return
	end

	if args[2] == "" then
		args[2] = nil
	end

	JBT.SetSetting(args[1], args[2])
	print("[JBT] Set %s to %s", args[1], args[2])
end, nil, nil, FCVAR_PROTECTED)

local function sendAll()
	net.Start(JBT.SETTINGS_NET_STRING)
	net.WriteUInt(table.Count(JBT.Settings), JBT.SETTINGS_NET_SIZE)
	for k, v in pairs(JBT.Settings) do
		net.WriteString(k)
		net.WriteInt(v, JBT.SETTINGS_OPTION_NET_SIZE)
	end
end

-- in case of file reload
if JBT_LOADED then
	sendAll()
	net.Broadcast()
end

gameevent.Listen("player_activate")
hook.Add("player_activate", "JBT_Settings", function(data)
	local ply = Player(data.userid)
	if not ply:IsValid() then return end

	sendAll()
	net.Send(ply)
end)

net.Receive(JBT.SETTINGS_NET_STRING, function(_, ply)
	if not ply:IsSuperAdmin() then
		ply:ChatPrint("You need to be a superadmin to change JBT's settings")
		return
	end

	local setting = net.ReadString()
	local value = net.ReadInt(JBT.SETTINGS_OPTION_NET_SIZE)

	JBT.SetSetting(setting, value)
end)