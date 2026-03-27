local MainClockModule = {
	name = "Clock",
	description = "Shows a movable in-game clock window.",
	options = {
		{
			type = "toggle",
			key = "clock_twenty_four_hour",
			label = "Use 24-hour time",
			defaultValue = false,
		},
		{
			type = "number",
			key = "clock_offset_hours",
			label = "Time offset",
			managerOrder = 3,
			defaultValue = 0,
			step = 0.5,
			minValue = -12,
			maxValue = 12,
			integer = false,
			displayFormat = "%.1f h",
		},
	},
}

local function MainClock_GetParentMetrics()
	local width
	local height

	width = UIParent and UIParent.GetWidth and UIParent:GetWidth() or nil
	height = UIParent and UIParent.GetHeight and UIParent:GetHeight() or nil

	if not width or width <= 0 then
		width = 800
	end
	if not height or height <= 0 then
		height = 600
	end

	return width, height
end

local function MainClock_GetFormattedTime()
	local hour
	local minute
	local totalMinutes
	local offsetMinutes
	local usesTwentyFourHourTime
	local isPM

	if not GetGameTime then
		return ""
	end

	hour, minute = GetGameTime()
	offsetMinutes = floor((Main.GetNumberSetting("clock_offset_hours", 0) * 60) + 0.5)
	totalMinutes = (hour * 60) + minute + offsetMinutes

	while totalMinutes < 0 do
		totalMinutes = totalMinutes + 1440
	end
	while totalMinutes >= 1440 do
		totalMinutes = totalMinutes - 1440
	end

	hour = floor(totalMinutes / 60)
	minute = Main_Mod(totalMinutes, 60)
	usesTwentyFourHourTime = Main.GetBoolSetting("clock_twenty_four_hour", false)

	if usesTwentyFourHourTime then
		return format(TEXT(TIME_TWENTYFOURHOURS), hour, minute)
	end

	isPM = hour >= 12
	if hour > 12 then
		hour = hour - 12
	end
	if hour == 0 then
		hour = 12
	end
	if isPM then
		return format(TEXT(TIME_TWELVEHOURPM), hour, minute)
	end

	return format(TEXT(TIME_TWELVEHOURAM), hour, minute)
end

function MainClock_ApplySavedPosition()
	local width
	local height
	local xRatio
	local yRatio
	local x
	local y

	width, height = MainClock_GetParentMetrics()
	xRatio = Main.GetNumberSetting("clock_x_ratio", nil)
	yRatio = Main.GetNumberSetting("clock_y_ratio", nil)
	if xRatio ~= nil and yRatio ~= nil then
		x = floor((width * xRatio) + 0.5)
		y = floor((height * yRatio) + 0.5)
	else
		x = Main.GetNumberSetting("clock_x", nil)
		y = Main.GetNumberSetting("clock_y", nil)
		if x ~= nil and y ~= nil and width > 0 and height > 0 then
			Main.SetNumberSetting("clock_x_ratio", x / width, 1, nil)
			Main.SetNumberSetting("clock_y_ratio", y / height, 1, nil)
		end
	end

	if not x or not y then
		return
	end

	MainClockFrame:ClearAllPoints()
	MainClockFrame:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", x, y)
end

local function MainClock_UpdateText()
	if MainClockText then
		MainClockText:SetText(MainClock_GetFormattedTime())
	end
end

function MainClock_OnLoad()
	this.updateElapsed = 0
	MainClock_UpdateText()
	MainClock_ApplySavedPosition()
end

function MainClock_OnUpdate(elapsed)
	if not Main.IsModuleEnabled("clock") then
		return
	end

	this.updateElapsed = this.updateElapsed + elapsed
	if this.updateElapsed >= 0.2 then
		MainClock_UpdateText()
		this.updateElapsed = 0
	end
end

function MainClock_OnMouseDown()
	-- Frame dragging is handled by the engine via TitleRegion
end

function MainClock_OnMouseUp()
	local centerX
	local centerY
	local frameWidth
	local frameHeight
	local left
	local bottom
	local width
	local height

	-- Compute bottom-left from center (GetLeft/GetBottom not available in 0.5.3)
	centerX, centerY = this:GetCenter()
	if not centerX or not centerY then
		return
	end

	frameWidth = this:GetWidth() or 0
	frameHeight = this:GetHeight() or 0
	left = centerX - (frameWidth / 2)
	bottom = centerY - (frameHeight / 2)

	width, height = MainClock_GetParentMetrics()
	Main.SetNumberSetting("clock_x", floor(left + 0.5), 1, nil)
	Main.SetNumberSetting("clock_x_ratio", left / width, 1, nil)
	Main.SetNumberSetting("clock_y", floor(bottom + 0.5), 1, nil)
	Main.SetNumberSetting("clock_y_ratio", bottom / height, nil, nil)
end

function MainClock_OnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetText("Game Time", 1.0, 1.0, 1.0)
	GameTooltip:AddLine(MainClock_GetFormattedTime())
	GameTooltip:Show()
end

function MainClockModule:Init()
	MainClockFrame:Hide()
end

function MainClockModule:Enable()
	MainClock_ApplySavedPosition()
	MainClock_UpdateText()
	MainClockFrame:Show()
end

function MainClockModule:Disable()
	MainClockFrame:Hide()
	if GameTooltip:IsOwned(MainClockTextButton) then
		GameTooltip:Hide()
	end
end

function MainClockModule:ApplyConfig()
	MainClock_UpdateText()
end

function MainClockModule:OnUILayoutChanged()
	if not Main.IsModuleEnabled("clock") then
		return
	end

	MainClock_ApplySavedPosition()
end

Main.RegisterModule("clock", MainClockModule)
