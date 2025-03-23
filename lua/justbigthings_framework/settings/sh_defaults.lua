JBT.DefaultSettings = JBT.DefaultSettings or {}
JBT.DefaultSettingsExtras = JBT.DefaultSettingsExtras or {}
JBT.SettingCategories = {} -- can stack on reload

local curCategory

-- set the current setting category for your file, for setting menu organization
-- set as nil to not add stuff to settings
-- desc (optional): description of the category
-- shouldShowFunc (optional): function to call to determine whether to display. Only gets called once.
function JBT.SettingCategory(name, desc, shouldShowFunc)
	curCategory = nil
	if not name then return end

	-- don't think it matters enough to make a lookup for this
	for _, category in ipairs(JBT.SettingCategories) do
		if category.Name == name then
			curCategory = category
		end
	end

	if not curCategory then
		curCategory = { Name = name }
		table.insert(JBT.SettingCategories, curCategory)
	end

	if shouldShowFunc then
		curCategory.ShouldShowFunc = shouldShowFunc
	end
	if desc then
		curCategory.Desc = desc
	end
end

-- set a default value for a setting, only do this on shared files
-- setting: name of setting
-- value: default value
-- desc (optional): description, required to be on settings menu
-- changeCallback (optional): a callback for when the setting is changed
-- notPersonal (optional): set that this boolean will never have GetPersonalSetting used for it
-- min (optional): minimum value of an int setting
-- max (optional): maximum value of an int setting
function JBT.SetSettingDefault(setting, value, desc, changeCallback, notPersonal_min, max)
	local newVal = JBT.ToSetting(value)
	if newVal == nil then return end

	JBT.DefaultSettings[setting] = newVal
	JBT.DefaultSettingsExtras[setting] = {}
	local extras = JBT.DefaultSettingsExtras[setting]

	extras.Desc = desc
	if desc and curCategory then
		table.insert(curCategory, setting)
	end

	if SERVER and changeCallback then
		extras.CC = changeCallback
	end

	if type(value) ~= "boolean" then
		extras.Min = notPersonal_min
		extras.Max = max

		return
	end

	extras.IsBool = true

	if notPersonal_min then return end

	extras.IsPersonal = true

	if CAMI then
		local privilege = {
			Name = "jbt_" .. setting,
			MinAccess = "superadmin"
		}

		CAMI.RegisterPrivilege(privilege)
	end
end

local function setAllSpeeds()
	if CLIENT then return end

	timer.Create("JBT_SetAllSpeeds", 1, 1, function()
		for _, ply in player.Iterator() do
			JBT.PlyResyncStat(ply, "Speed")
		end
	end)
end

local function setAllArmor()
	if CLIENT then return end

	timer.Create("JBT_SetAllArmor", 1, 1, function()
		for _, ply in player.Iterator() do
			JBT.PlyRefracStat(ply, "Armor")
		end
	end)
end

local function setAllHealth()
	if CLIENT then return end

	timer.Create("JBT_SetAllHealth", 1, 1, function()
		for _, ply in player.Iterator() do
			JBT.PlyRefracStat(ply, "Health")
		end
	end)
end

local function setAllStats()
	if CLIENT then return end

	setAllSpeeds()
	setAllArmor()
	setAllHealth()
end

local function setAllMass()
	if CLIENT then return end

	timer.Create("JBT_SetAllMass", 1, 1, function()
		for _, ply in player.Iterator() do
			JBT.PlyResyncMass(ply)
		end
	end)
end

local function bigDrawReset()
	if not JBT.ResetBigDraw then return end

	for _, ply in player.Iterator() do
		JBT.ResetBigDraw(ply)
	end
end

-- THESE ARE THE EPIC DEFAULTS

JBT.SettingCategory("General Settings")
JBT.SetSettingDefault("admin_is_superadmin", false, "Admin only is superadmin only", nil, true)

JBT.SettingCategory("BigUse", "Whether player scale affects +use interaction.")
JBT.SetSettingDefault("biguse", true, "Enable module")
JBT.SetSettingDefault("biguse_small", false, "Affect smaller players")
JBT.SetSettingDefault("biguse_mass", true, "Affect max carry weight")
JBT.SetSettingDefault("biguse_mass_pow", 2, "Carry weight scaling exponent", nil, 1, 3)

JBT.SettingCategory("BigStats", "Whether player scale affects stats.")
JBT.SetSettingDefault("bigstats", false, "Enable module", setAllStats)
JBT.SetSettingDefault("bigstats_small", true, "Affect smaller players", setAllStats)
JBT.SetSettingDefault("bigstats_health", true, "Affect health", setAllHealth)
JBT.SetSettingDefault("bigstats_armor", false, "Affect armor", setAllArmor)
JBT.SetSettingDefault("bigstats_speed", false, "Affect speed", setAllSpeeds)

JBT.SettingCategory("BigMass", "Whether player scale affects mass.")
JBT.SetSettingDefault("bigmass", false, "Enable module", setAllMass)
JBT.SetSettingDefault("bigmass_pow", 2, "Mass scaling exponent", setAllMass, 1, 3)

JBT.SettingCategory("BigDelta", "Whether player scale affects movement animations.")
JBT.SetSettingDefault("bigdelta", true, "Enable by default", nil, true)

JBT.SettingCategory("BigSit", "Whether player scale affects sitting eyeheight.")
JBT.SetSettingDefault("bigsit", true, "Enable by default", nil, true)

JBT.SettingCategory("SitAnywhere BigTrace", "Whether player scale affects SitAnywhere sitting.", function() return SitAnywhere end)
JBT.SetSettingDefault("sitanywhere_bigtrace", true, "Enable module")
JBT.SetSettingDefault("sitanywhere_bigtrace_small", false, "Affect smaller players")
JBT.SetSettingDefault("sitanywhere_bigtrace_distance", 100, "Base sit distance", nil, 0, 1000)

JBT.SettingCategory("PAC3 BigLimit", "Whether PAC3's size limits should be extended.", function() return pac end)
JBT.SetSettingDefault("pac_biglimit", true, "Enable module")
JBT.SetSettingDefault("pac_biglimit_adminonly", true, nil, nil, true)

JBT.SettingCategory("PAC3 BigDraw", "Whether PAC3's draw distance setting should be scaled for each player.", function() return pac end)
JBT.SetSettingDefault("pac_bigdraw", true, "Enable by default", bigDrawReset, true)

JBT.SettingCategory()

local function onCami()
	if not CAMI then return end

	for setting, extras in pairs(JBT.DefaultSettingsExtras) do
		if not extras.IsPersonal then continue end

		local privilege = {
			Name = "jbt_" .. setting,
			MinAccess = "superadmin"
		}

		CAMI.RegisterPrivilege(privilege)
	end
end

timer.Simple(10, onCami)