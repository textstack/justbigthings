surface.CreateFont("JBT_CategoryName", {
	font = "Arial",
	size = 15
})

local gray = Color(128, 128, 128)

local clientUpdateCallbacks = {}

local function addLocalBool(panel, convar, desc)
	local triSlider = vgui.Create("JBTTriSlider")
	triSlider:Setup("convar", desc)
	triSlider:SetTall(16)

	panel:AddItem(triSlider)

	local cvarReal = GetConVar(convar)

	function triSlider:OnValueChanged(val)
		cvarReal:SetInt(val - 1)
	end

	table.insert(clientUpdateCallbacks, function()
		if not IsValid(triSlider) then return end

		triSlider:SetValue(cvarReal:GetInt() + 1, true)
	end)
end

local function clientSettings(panel)
	panel:Help("Configure personal settings for JustBigThings.")

	addLocalBool(panel, "jbt_cl_bigsit", "BigSit")
	panel:ControlHelp("Whether your sitting eyesight is adjusted based on scale.")

	addLocalBool(panel, "jbt_cl_bigdelta", "BigDelta")
	panel:ControlHelp("Whether your movement animations are adjusted based on scale.")

	if pac then
		addLocalBool(panel, "jbt_cl_pac_bigdraw", "PAC3 BigDraw")
		panel:ControlHelp("Whether your PAC3 draw distance setting should be scaled for each player.")
	end

	for _, func in ipairs(clientUpdateCallbacks) do
		func()
	end
end

local updateCallbacks = {}

local function addAdminableBool(panel, setting, extras)
	local triSlider = panel:Add("JBTTriSlider")
	triSlider:Dock(TOP)
	triSlider:DockMargin(0, 4, 0, 0)
	triSlider:Setup("adminable", extras.Desc)
	triSlider:SetTall(16)

	function triSlider:OnValueChanged(val)
		JBT.SetSetting(setting, val > 1)
		JBT.SetSetting(setting .. "_adminonly", val == 2)
	end

	table.insert(updateCallbacks, function()
		if not IsValid(triSlider) then return end

		if not JBT.GetSettingBool(setting) then
			triSlider:SetValue(1, true)
		elseif JBT.GetSettingBool(setting .. "_adminonly") then
			triSlider:SetValue(2, true)
		else
			triSlider:SetValue(3, true)
		end
	end)
end

local function addNumWang(panel, setting, extras)
	local holder = panel:Add("Panel")
	holder:Dock(TOP)
	holder:DockMargin(0, 4, 0, 0)
	holder:SetTall(16)

	local numWang = holder:Add("DNumberWang")
	numWang:Dock(LEFT)
	numWang:SetWide(32)
	numWang:DockMargin(0, 0, 4, 0)
	numWang:HideWang()

	local min, max = extras.Min, extras.Max
	if min then
		numWang:SetMin(min)
	end
	if max then
		numWang:SetMax(max)
	end

	local label = holder:Add("DLabel")
	label:Dock(FILL)
	label:SetTextColor(color_black)

	if extras.Desc then
		label:SetText(extras.Desc)
	else
		label:SetText(setting)
	end

	function numWang:OnValueChanged(val)
		local newVal = math.floor(val)
		if min then
			newVal = math.max(newVal, min)
		end
		if max then
			newVal = math.min(newVal, max)
		end

		JBT.SetSetting(setting, newVal)
	end

	table.insert(updateCallbacks, function()
		if not IsValid(numWang) then return end
		numWang:SetText(JBT.GetSetting(setting))
	end)
end

local function addBool(panel, setting, extras)
	local checkLabel = panel:Add("DCheckBoxLabel")
	checkLabel:Dock(TOP)
	checkLabel:DockMargin(0, 4, 0, 0)
	checkLabel:SetTextColor(color_black)

	if extras.Desc then
		checkLabel:SetText(extras.Desc)
	else
		checkLabel:SetText(setting)
	end

	function checkLabel:OnChange(value)
		JBT.SetSetting(setting, value)
	end

	table.insert(updateCallbacks, function()
		if not IsValid(checkLabel) then return end
		checkLabel:SetChecked(JBT.GetSettingBool(setting))
	end)

	checkLabel:InvalidateLayout(true)
	checkLabel:SizeToChildren()
end

local function serverSettings(panel)
	panel:Help("Configure server settings for JustBigThings.")

	panel:SetLabel("Server Settings (superadmins only)")

	function panel:PaintOver(w, h)
		local headerHeight = self:GetHeaderHeight()

		if headerHeight >= h then return end
		if LocalPlayer():IsSuperAdmin() then return end

		surface.SetDrawColor(255, 0, 0)
		surface.DrawOutlinedRect(0, headerHeight, w, h - headerHeight, 2)
	end

	for _, category in ipairs(JBT.SettingCategories) do
		if category.ShouldShowFunc and not category.ShouldShowFunc() then continue end

		local section = vgui.Create("DPanel")
		panel:AddItem(section)
		section:DockPadding(4, 4, 4, 4)

		local name = section:Add("DLabel")
		name:Dock(TOP)
		name:SetText(category.Name)
		name:SetTextColor(color_black)
		name:SetFont("JBT_CategoryName")
		name:SizeToContentsY()

		if category.Desc then
			local desc = section:Add("DLabel")
			desc:Dock(TOP)
			desc:SetText(category.Desc)
			desc:SetTextColor(gray)
			desc:SetWrap(true)
			desc:SetAutoStretchVertical(true)
			desc:SizeToContentsY()
		end

		for _, setting in ipairs(category) do
			local extras = JBT.DefaultSettingsExtras[setting]
			if not extras then continue end

			if not extras.IsBool then
				addNumWang(section, setting, extras)
			elseif extras.IsPersonal then
				addAdminableBool(section, setting, extras)
			else
				addBool(section, setting, extras)
			end
		end

		function section:PerformLayout()
			section:SizeToChildren(false, true)
		end

		section:InvalidateLayout(true)
	end

	for _, func in ipairs(updateCallbacks) do
		func()
	end
end

hook.Add("PopulateToolMenu", "JBT_Menu", function()
	spawnmenu.AddToolMenuOption("Utilities", "JustBigThings", "jbt_clientsettings", "Player Settings", "", "", clientSettings)
	spawnmenu.AddToolMenuOption("Utilities", "JustBigThings", "jbt_serversettings", "Server Settings", "", "", serverSettings)
end)

hook.Add("SpawnMenuOpened", "JBT_MenuReload", function()
	for _, func in ipairs(updateCallbacks) do
		func()
	end

	for _, func in ipairs(clientUpdateCallbacks) do
		func()
	end
end)