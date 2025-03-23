local PANEL = {}

local types = {
	adminable = {
		{
			Icon = Material("icon16/cross.png"),
			Color = Color(255, 128, 128),
			Tooltip = "disabled"
		},
		{
			Icon = Material("icon16/shield.png"),
			Color = Color(255, 225, 128),
			Tooltip = "admin only"
		},
		{
			Icon = Material("icon16/tick.png"),
			Color = Color(128, 255, 128),
			Tooltip = "enabled"
		}
	},
	convar = {
		{
			Icon = Material("icon16/cross.png"),
			Color = Color(255, 128, 128),
			Tooltip = "disabled"
		},
		{
			Icon = Material("icon16/asterisk_yellow.png"),
			Color = Color(255, 225, 128),
			Tooltip = "server default"
		},
		{
			Icon = Material("icon16/tick.png"),
			Color = Color(128, 255, 128),
			Tooltip = "enabled"
		}
	}
}

function PANEL:Init()
	self.Type = "adminable"
	self.State = 1
	self.SlideCount = 3 -- in case we want to do more than 3 in some other reality

	local slideHolder = self:Add("DPanel")
	self.SlideHolder = slideHolder

	slideHolder:Dock(LEFT)
	slideHolder:SetWide(12 * self.SlideCount + 4)
	slideHolder:DockMargin(0, 0, 4, 0)
	slideHolder:SetCursor("hand")

	function slideHolder.Paint(pnl, w, h)
		surface.SetDrawColor(226, 226, 226)
		surface.DrawRect(4, 4, w - 8, h - 8)

		for i = 1, self.SlideCount do
			surface.SetDrawColor(types[self.Type][i].Color:Unpack())
			surface.DrawRect(i * 12 - 6, 6, 4, 4)
		end

		surface.SetDrawColor(128, 128, 128)
		surface.DrawOutlinedRect(4, 4, w - 8, h - 8)
	end

	local slider = slideHolder:Add("DPanel")
	self.Slider = slider
	slider:SetSize(16, 16)
	slider:SetPos(0, 0)
	slider:SetCursor("hand")
	slider:SetTooltip(types[self.Type][self.State].Tooltip)

	function slider.GetToggle()
		return false
	end

	local press

	function slideHolder.OnMousePressed(pnl, keyCode)
		if keyCode ~= MOUSE_LEFT then return end
		slideHolder:MouseCapture(true)
		press = true
	end

	function slideHolder.OnMouseReleased(pnl, keyCode)
		if keyCode ~= MOUSE_LEFT then return end
		slideHolder:MouseCapture(false)

		if not press then return end
		press = nil

		if not slideHolder:IsHovered() and not slider:IsHovered() then return end

		self.State = self.State - 1
		self.State = ((self.State + 1) % self.SlideCount)
		self.State = self.State + 1

		self:SetValue(self.State)
	end

	slider.OnMousePressed = slideHolder.OnMousePressed
	slider.OnMouseReleased = slideHolder.OnMouseReleased

	function slider.Paint(pnl, w, h)
		derma.SkinHook("Paint", "Button", pnl, w, h)

		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(types[self.Type][self.State].Icon)
		surface.DrawTexturedRect(0, 0, w, h)

		if pnl:IsHovered() then
			surface.SetDrawColor(255, 255, 255, 48)
			surface.DrawRect(2, 2, w - 4, h - 4)
		end
	end

	local label = self:Add("DLabel")
	self.Label = label

	label:Dock(FILL)
	label:SetTextColor(color_black)
end

function PANEL:GetValue()
	return self.State
end

function PANEL:SetValue(val, noUpdate)
	self.State = math.Clamp(val, 1, self.SlideCount)

	self.Slider:Stop()
	self.Slider:MoveTo(self.State * 12 - 12, 0, 0.03)
	self.Slider:SetTooltip(types[self.Type][self.State].Tooltip)

	if not noUpdate then
		self:OnValueChanged(self.State)
	end
end

function PANEL:OnValueChanged(val)
	--
end

-- set the trislider type and what it's setting
function PANEL:Setup(_type, desc)
	self.Type = _type
	self.Label:SetText(desc or "")
end

vgui.Register("JBTTriSlider", PANEL, "Panel")