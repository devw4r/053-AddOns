local MainBuffDurations = {
	name = "Buff Durations",
	description = "Shows time remaining on player buffs and debuffs.",
	options = {
		{
			type = "toggle",
			key = "buff_durations_blink_white",
			label = "Invert warning color",
			defaultValue = true,
		},
	},
}

local mainOriginalBuffButtonUpdate = nil
local mainOriginalBuffButtonOnUpdate = nil
local MAIN_BUFF_DURATION_WARNING_TIME = 60

local function MainBuffDurations_GetFontString(button)
	if not button or not button.GetName then
		return nil
	end

	return getglobal("Main" .. button:GetName() .. "Duration")
end

local function MainBuffDurations_HideAll()
	local i
	local duration

	for i = 0, 23 do
		duration = getglobal("MainBuffButton" .. i .. "Duration")
		if duration then
			duration:Hide()
		end
	end
end

local function MainBuffDurations_UpdateButton(button)
	local duration
	local timeLeft

	duration = MainBuffDurations_GetFontString(button)
	if not duration then
		return
	end

	if not Main.IsModuleEnabled("buff_durations") then
		duration:Hide()
		return
	end

	if not button.buffIndex or button.buffIndex < 0 or button.untilCancelled == 1 then
		duration:Hide()
		return
	end

	timeLeft = GetPlayerBuffTimeLeft(button.buffIndex)
	if not timeLeft then
		duration:Hide()
		return
	end

	duration:SetText(Main_SecondsToTimeAbbrev(timeLeft))
	if timeLeft < MAIN_BUFF_DURATION_WARNING_TIME then
		if Main.GetBoolSetting("buff_durations_blink_white", true) then
			duration:SetVertexColor(1.0, 1.0, 1.0)
		else
			duration:SetVertexColor(1.0, 0.82, 0.0)
		end
	else
		if Main.GetBoolSetting("buff_durations_blink_white", true) then
			duration:SetVertexColor(1.0, 0.82, 0.0)
		else
			duration:SetVertexColor(1.0, 1.0, 1.0)
		end
	end
	duration:Show()
end

local function MainBuffDurations_RefreshAll()
	local i
	local button

	for i = 0, 23 do
		button = getglobal("BuffButton" .. i)
		if button and button:IsVisible() then
			MainBuffDurations_UpdateButton(button)
		end
	end
end

local function MainBuffDurations_InstallHooks()
	if not mainOriginalBuffButtonUpdate then
		mainOriginalBuffButtonUpdate = BuffButton_Update
		BuffButton_Update = function()
			mainOriginalBuffButtonUpdate()
			MainBuffDurations_UpdateButton(this)
		end
	end

	if not mainOriginalBuffButtonOnUpdate then
		mainOriginalBuffButtonOnUpdate = BuffButton_OnUpdate
		BuffButton_OnUpdate = function()
			mainOriginalBuffButtonOnUpdate()
			MainBuffDurations_UpdateButton(this)
		end
	end
end

function MainBuffFrame_OnLoad()
	local i
	local duration

	for i = 0, 23 do
		duration = getglobal("MainBuffButton" .. i .. "Duration")
		if duration then
			duration:SetPoint("TOP", "BuffButton" .. i, "BOTTOM", 0, 0)
			duration:Hide()
		end
	end
end

function MainBuffDurations:Init()
	MainBuffDurations_InstallHooks()
	MainBuffDurations_HideAll()
end

function MainBuffDurations:Enable()
	MainBuffDurations_RefreshAll()
end

function MainBuffDurations:Disable()
	MainBuffDurations_HideAll()
end

function MainBuffDurations:ApplyConfig()
	MainBuffDurations_RefreshAll()
end

Main.RegisterModule("buff_durations", MainBuffDurations)
