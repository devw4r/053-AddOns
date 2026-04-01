local MainUnitFrames = {
	name = "Unit Frames",
	description = "Repositions player and target frames, applies the alternative frame style, and controls portraits/status text.",
	reloadRequired = 1,
	options = {
		{
			type = "toggle",
			key = "unitframes_statusbar_text",
			label = "Show unit status text",
			managerOrder = 7,
			defaultValue = true,
		},
		{
			type = "number",
			key = "unitframes_x_offset",
			label = "Unit Frames Horizontal Offset",
			managerOrder = 2,
			requiresModule = "unit_frames",
			defaultValue = -250,
			step = 10,
			minValue = -400,
			maxValue = 0,
		},
		{
			type = "number",
			key = "unitframes_y_offset",
			label = "Unit Frames Vertical Offset",
			managerOrder = 1,
			requiresModule = "unit_frames",
			defaultValue = 320,
			step = 10,
			minValue = 150,
			maxValue = 450,
		},
	},
}

local MAIN_UNIT_FRAMES_TARGET_TEXTURE = "Interface\\FrameXML\\Main\\Media\\UI-TargetingFrame"
local MAIN_UNIT_FRAMES_PLAYER_STATUS_TEXTURE = "Interface\\FrameXML\\Main\\Media\\UI-Player-Status"

local mainUnitFramesOriginalPlayerFrameOnEvent = nil
local mainUnitFramesOriginalTargetFrameUpdate = nil
local mainUnitFramesOriginalUnitFrameUpdateManaType = nil

local function MainUnitFrames_GetOriginalStatusTextValue()
	if MainUnitFrames.originalStatusBarTextValue == nil then
		MainUnitFrames.originalStatusBarTextValue = tonumber(GetCVar("statusBarText")) or 0
	end

	return MainUnitFrames.originalStatusBarTextValue
end

local function MainUnitFrames_IsEnabled()
	return Main.IsModuleEnabled("unit_frames")
end

local function MainUnitFrames_UseAlternativeStyle()
	return MainUnitFrames_IsEnabled()
end

local function MainUnitFrames_ShouldShowStatusText()
	if MainUnitFrames_IsEnabled() then
		return Main.GetBoolSetting("unitframes_statusbar_text", true)
	end

	return MainUnitFrames_GetOriginalStatusTextValue() == 1
end

local function MainUnitFrames_CapturePoint(key, frame)
	local point
	local relativeTo
	local relativePoint
	local xOffset
	local yOffset

	if not key or not frame or not frame.GetPoint then
		return
	end

	MainUnitFrames.originalPoints = MainUnitFrames.originalPoints or {}
	if MainUnitFrames.originalPoints[key] then
		return
	end

	if frame.GetPoint then
		point, relativeTo, relativePoint, xOffset, yOffset = frame:GetPoint()
	end
	MainUnitFrames.originalPoints[key] = {
		point = point or "BOTTOM",
		relativeToName = relativeTo and relativeTo.GetName and relativeTo:GetName() or nil,
		parentName = frame.GetParent and frame:GetParent() and frame:GetParent().GetName and frame:GetParent():GetName() or nil,
		relativePoint = relativePoint or point or "BOTTOM",
		xOffset = xOffset or 0,
		yOffset = yOffset or 0,
	}
end

local function MainUnitFrames_RestorePoint(key, frame)
	local pointData
	local relativeTo

	if not key or not frame or not MainUnitFrames.originalPoints then
		return
	end

	pointData = MainUnitFrames.originalPoints[key]
	if not pointData then
		return
	end

	frame:ClearAllPoints()
	relativeTo = pointData.relativeToName or pointData.parentName or "UIParent"
	frame:SetPoint(pointData.point, relativeTo, pointData.relativePoint, pointData.xOffset, pointData.yOffset)
end

local function MainUnitFrames_CaptureWidgetState(key, widget)
	local texture
	local texLeft
	local texRight
	local texTop
	local texBottom

	if not key or not widget then
		return
	end

	MainUnitFrames.originalWidgets = MainUnitFrames.originalWidgets or {}
	if MainUnitFrames.originalWidgets[key] then
		return
	end

	-- GetPoint is broken in 0.5.3 (returns garbage data that creates circular
	-- anchor dependencies on restore). Stock positions are restored explicitly
	-- via MainUnitFrames_RestoreAlternativeStyle instead.

	texture = widget.GetTexture and widget:GetTexture() or nil
	if widget.GetTexCoord then
		texLeft, texRight, texTop, texBottom = widget:GetTexCoord()
	end

	MainUnitFrames.originalWidgets[key] = {
		width = widget.GetWidth and widget:GetWidth() or nil,
		height = widget.GetHeight and widget:GetHeight() or nil,
		textHeight = widget.GetTextHeight and widget:GetTextHeight() or nil,
		shown = widget.IsVisible and widget:IsVisible() or nil,
		texture = texture,
		texLeft = texLeft,
		texRight = texRight,
		texTop = texTop,
		texBottom = texBottom,
	}
end

local function MainUnitFrames_RestoreWidgetState(key, widget)
	local state

	if not key or not widget or not MainUnitFrames.originalWidgets then
		return
	end

	state = MainUnitFrames.originalWidgets[key]
	if not state then
		return
	end

	if state.width and widget.SetWidth then
		widget:SetWidth(state.width)
	end
	if state.height and widget.SetHeight then
		widget:SetHeight(state.height)
	end
	if state.textHeight and widget.SetTextHeight then
		widget:SetTextHeight(state.textHeight)
	end
	if state.texture ~= nil and widget.SetTexture then
		widget:SetTexture(state.texture)
	end
	if state.texLeft ~= nil and widget.SetTexCoord then
		widget:SetTexCoord(state.texLeft, state.texRight, state.texTop, state.texBottom)
	end
	if state.shown ~= nil then
		if state.shown then
			widget:Show()
		else
			widget:Hide()
		end
	end
end

local function MainUnitFrames_CaptureStyleState()
	MainUnitFrames_CaptureWidgetState("PlayerPortrait", PlayerPortrait)
	MainUnitFrames_CaptureWidgetState("TargetPortrait", TargetPortrait)
	MainUnitFrames_CaptureWidgetState("PlayerFrameTexture", PlayerFrameTexture)
	MainUnitFrames_CaptureWidgetState("TargetFrameTexture", TargetFrameTexture)
	MainUnitFrames_CaptureWidgetState("PlayerAttackModeTexture", PlayerAttackModeTexture)
	MainUnitFrames_CaptureWidgetState("PlayerName", PlayerName)
	MainUnitFrames_CaptureWidgetState("TargetName", TargetName)
	MainUnitFrames_CaptureWidgetState("TargetFrameNameBackground", TargetFrameNameBackground)
	MainUnitFrames_CaptureWidgetState("PlayerFrameHealthBar", PlayerFrameHealthBar)
	MainUnitFrames_CaptureWidgetState("TargetFrameHealthBar", TargetFrameHealthBar)
	MainUnitFrames_CaptureWidgetState("PlayerFrameHealthBarText", PlayerFrameHealthBarText)
	MainUnitFrames_CaptureWidgetState("TargetFrameHealthBarText", TargetFrameHealthBarText)
	MainUnitFrames_CaptureWidgetState("PlayerFrameManaBarText", PlayerFrameManaBarText)
	MainUnitFrames_CaptureWidgetState("TargetFrameManaBarText", TargetFrameManaBarText)
	MainUnitFrames_CaptureWidgetState("PetFrameHealthBarText", PetFrameHealthBarText)
	MainUnitFrames_CaptureWidgetState("PetFrameManaBarText", PetFrameManaBarText)
end

local function MainUnitFrames_ApplyPosition()
	local xOffset
	local yOffset

	if not PlayerFrame or not TargetFrame then
		return
	end

	if MainUnitFrames_IsEnabled() then
		xOffset = Main.GetNumberSetting("unitframes_x_offset", -250)
		yOffset = Main.GetNumberSetting("unitframes_y_offset", 320)

		PlayerFrame:ClearAllPoints()
		PlayerFrame:SetPoint("BOTTOM", "UIParent", "BOTTOM", xOffset, yOffset)

		TargetFrame:ClearAllPoints()
		TargetFrame:SetPoint("BOTTOM", "UIParent", "BOTTOM", -xOffset, yOffset)
	else
		PlayerFrame:ClearAllPoints()
		PlayerFrame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", 6, -4)
		TargetFrame:ClearAllPoints()
		TargetFrame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", 230, -4)
	end
end

local function MainUnitFrames_SetStatusBarTextState(bar, visible)
	local previousThis

	if not bar or not bar.TextString then
		return
	end

	if visible then
		bar.TextString:Show()
	else
		bar.TextString:Hide()
	end

	if TextStatusBar_UpdateTextString then
		previousThis = this
		this = bar
		TextStatusBar_UpdateTextString()
		this = previousThis
	end
end

local function MainUnitFrames_ApplyAlternativeStyle()
	if not PlayerFrameTexture or not TargetFrameTexture then
		return
	end

	PlayerFrameTexture:SetTexture(MAIN_UNIT_FRAMES_TARGET_TEXTURE)
	PlayerFrameTexture:SetTexCoord(1, 0, 0, 1)
	PlayerFrameTexture:SetWidth(256)
	PlayerFrameTexture:SetHeight(128)
	PlayerFrameTexture:ClearAllPoints()
	PlayerFrameTexture:SetPoint("CENTER", "PlayerFrame", "CENTER", -5, -18)

	if PlayerAttackModeTexture then
		PlayerAttackModeTexture:SetTexture(MAIN_UNIT_FRAMES_PLAYER_STATUS_TEXTURE)
		PlayerAttackModeTexture:SetTexCoord(0, 1, 0, 1)
		PlayerAttackModeTexture:SetWidth(256)
		PlayerAttackModeTexture:SetHeight(128)
		PlayerAttackModeTexture:ClearAllPoints()
		PlayerAttackModeTexture:SetPoint("CENTER", "PlayerFrame", "CENTER", 30, -27)
	end

	TargetFrameTexture:SetTexture(MAIN_UNIT_FRAMES_TARGET_TEXTURE)
	TargetFrameTexture:SetTexCoord(0, 1, 0, 1)
	TargetFrameTexture:SetWidth(256)
	TargetFrameTexture:SetHeight(128)
	TargetFrameTexture:ClearAllPoints()
	TargetFrameTexture:SetPoint("CENTER", "TargetFrame", "CENTER", 5, -18)

	if PlayerName then
		PlayerName:SetWidth(120)
		PlayerName:ClearAllPoints()
		PlayerName:SetPoint("TOP", "PlayerFrame", "TOP", 34, -2)
	end

	if TargetName then
		TargetName:SetWidth(120)
		TargetName:ClearAllPoints()
		TargetName:SetPoint("TOP", "TargetFrame", "TOP", -34, -2)
	end

	if TargetFrameNameBackground then
		TargetFrameNameBackground:Hide()
	end

	if PlayerFrameHealthBar then
		PlayerFrameHealthBar:SetHeight(28)
		PlayerFrameHealthBar:ClearAllPoints()
		PlayerFrameHealthBar:SetPoint("TOPRIGHT", "PlayerFrame", "TOPRIGHT", -2, -16)
	end

	if TargetFrameHealthBar then
		TargetFrameHealthBar:SetHeight(28)
		TargetFrameHealthBar:ClearAllPoints()
		TargetFrameHealthBar:SetPoint("TOPLEFT", "TargetFrame", "TOPLEFT", 2, -16)
	end

	if PlayerFrameHealthBarText then
		PlayerFrameHealthBarText:SetTextHeight(14)
		PlayerFrameHealthBarText:ClearAllPoints()
		PlayerFrameHealthBarText:SetPoint("CENTER", "PlayerFrameHealthBar", "CENTER", 0, 0)
	end

	if TargetFrameHealthBarText then
		TargetFrameHealthBarText:SetTextHeight(14)
		TargetFrameHealthBarText:ClearAllPoints()
		TargetFrameHealthBarText:SetPoint("CENTER", "TargetFrameHealthBar", "CENTER", 0, 0)
	end

	if PlayerFrameManaBarText then
		PlayerFrameManaBarText:SetTextHeight(14)
		PlayerFrameManaBarText:ClearAllPoints()
		PlayerFrameManaBarText:SetPoint("CENTER", "PlayerFrameManaBar", "CENTER", 0, 0)
	end

	if TargetFrameManaBarText then
		TargetFrameManaBarText:SetTextHeight(14)
		TargetFrameManaBarText:ClearAllPoints()
		TargetFrameManaBarText:SetPoint("CENTER", "TargetFrameManaBar", "CENTER", 0, 0)
	end

	if PetFrameHealthBarText then
		PetFrameHealthBarText:SetTextHeight(14)
		PetFrameHealthBarText:ClearAllPoints()
		PetFrameHealthBarText:SetPoint("CENTER", "PetFrame", "CENTER", 15, 2)
	end

	if PetFrameManaBarText then
		PetFrameManaBarText:SetTextHeight(14)
		PetFrameManaBarText:ClearAllPoints()
		PetFrameManaBarText:SetPoint("CENTER", "PetFrame", "CENTER", 15, -8)
	end
end

local function MainUnitFrames_RestoreAlternativeStyle()
	local playerUsesNoManaTexture
	local attackVisible

	playerUsesNoManaTexture = UnitManaMax and UnitManaMax("player") == 0
	attackVisible = PlayerAttackModeTexture and PlayerAttackModeTexture.IsVisible and PlayerAttackModeTexture:IsVisible()

	if PlayerFrameTexture then
		if playerUsesNoManaTexture then
			PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-NoMana")
			if PlayerFrameBackground then
				PlayerFrameBackground:SetHeight(30)
			end
		else
			PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame")
			if PlayerFrameBackground then
				PlayerFrameBackground:SetHeight(41)
			end
		end
		PlayerFrameTexture:SetTexCoord(1.0, 0.25, 0, 0.59375)
		PlayerFrameTexture:SetWidth(192)
		PlayerFrameTexture:SetHeight(77)
		PlayerFrameTexture:ClearAllPoints()
		PlayerFrameTexture:SetPoint("TOPLEFT", "PlayerFrame", "TOPLEFT", 0, 0)
	end

	if PlayerAttackModeTexture then
		PlayerAttackModeTexture:SetTexture("Interface\\TargetingFrame\\UI-Player-AttackStatus")
		PlayerAttackModeTexture:SetTexCoord(0, 0.703125, 0, 1.0)
		PlayerAttackModeTexture:SetWidth(182)
		PlayerAttackModeTexture:SetHeight(64)
		PlayerAttackModeTexture:ClearAllPoints()
		PlayerAttackModeTexture:SetPoint("TOPLEFT", "PlayerFrame", "TOPLEFT", 10, -8)
		if attackVisible then
			PlayerAttackModeTexture:Show()
		else
			PlayerAttackModeTexture:Hide()
		end
	end

	if TargetFrameTexture then
		TargetFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame")
		TargetFrameTexture:SetTexCoord(0.25, 1.0, 0, 0.59375)
		TargetFrameTexture:SetWidth(192)
		TargetFrameTexture:SetHeight(77)
		TargetFrameTexture:ClearAllPoints()
		TargetFrameTexture:SetPoint("TOPLEFT", "TargetFrame", "TOPLEFT", 0, 0)
	end

	if PlayerName then
		PlayerName:SetWidth(100)
		PlayerName:ClearAllPoints()
		PlayerName:SetPoint("CENTER", "PlayerFrame", "CENTER", 35, 14)
	end

	if TargetName then
		TargetName:SetWidth(100)
		TargetName:ClearAllPoints()
		TargetName:SetPoint("CENTER", "TargetFrame", "CENTER", -35, 14)
	end

	if TargetFrameNameBackground then
		TargetFrameNameBackground:SetWidth(119)
		TargetFrameNameBackground:SetHeight(19)
		TargetFrameNameBackground:ClearAllPoints()
		TargetFrameNameBackground:SetPoint("TOPRIGHT", "TargetFrame", "TOPRIGHT", -70, -15)
		TargetFrameNameBackground:Show()
	end

	if PlayerFrameHealthBar then
		PlayerFrameHealthBar:SetWidth(119)
		PlayerFrameHealthBar:SetHeight(12)
		PlayerFrameHealthBar:ClearAllPoints()
		PlayerFrameHealthBar:SetPoint("TOPLEFT", "PlayerFrame", "TOPLEFT", 70, -35)
	end

	if PlayerFrameManaBar then
		PlayerFrameManaBar:SetWidth(119)
		PlayerFrameManaBar:SetHeight(12)
		PlayerFrameManaBar:ClearAllPoints()
		PlayerFrameManaBar:SetPoint("TOPLEFT", "PlayerFrame", "TOPLEFT", 70, -45)
	end

	if TargetFrameHealthBar then
		TargetFrameHealthBar:SetWidth(119)
		TargetFrameHealthBar:SetHeight(12)
		TargetFrameHealthBar:ClearAllPoints()
		TargetFrameHealthBar:SetPoint("TOPRIGHT", "TargetFrame", "TOPRIGHT", -70, -35)
	end

	if TargetFrameManaBar then
		TargetFrameManaBar:SetWidth(119)
		TargetFrameManaBar:SetHeight(12)
		TargetFrameManaBar:ClearAllPoints()
		TargetFrameManaBar:SetPoint("TOPRIGHT", "TargetFrame", "TOPRIGHT", -70, -45)
	end

	if PlayerFrameHealthBarText then
		PlayerFrameHealthBarText:SetTextHeight(14)
		PlayerFrameHealthBarText:ClearAllPoints()
		PlayerFrameHealthBarText:SetPoint("CENTER", "PlayerFrame", "TOPLEFT", 130, -40)
	end

	if TargetFrameHealthBarText then
		TargetFrameHealthBarText:SetTextHeight(14)
	end

	if PlayerFrameManaBarText then
		PlayerFrameManaBarText:SetTextHeight(14)
		PlayerFrameManaBarText:ClearAllPoints()
		PlayerFrameManaBarText:SetPoint("CENTER", "PlayerFrame", "TOPLEFT", 130, -51)
	end

	if TargetFrameManaBarText then
		TargetFrameManaBarText:SetTextHeight(14)
	end

	if PetFrameHealthBarText then
		PetFrameHealthBarText:SetTextHeight(14)
		PetFrameHealthBarText:ClearAllPoints()
		PetFrameHealthBarText:SetPoint("CENTER", "PetFrame", "TOPLEFT", 82, -27)
	end

	if PetFrameManaBarText then
		PetFrameManaBarText:SetTextHeight(14)
		PetFrameManaBarText:ClearAllPoints()
		PetFrameManaBarText:SetPoint("CENTER", "PetFrame", "TOPLEFT", 82, -35)
	end
end

local function MainUnitFrames_ApplyStyle()
	if MainUnitFrames_UseAlternativeStyle() then
		MainUnitFrames_ApplyAlternativeStyle()
	else
		MainUnitFrames_RestoreAlternativeStyle()
	end
end

local function MainUnitFrames_RefreshStatusBars()
	local statusTextValue

	statusTextValue = MainUnitFrames_ShouldShowStatusText() and 1 or 0
	SetCVar("statusBarText", statusTextValue)

	if OptionsFrameCheckButtons and OptionsFrameCheckButtons["STATUS_BAR_TEXT"] then
		OptionsFrameCheckButtons["STATUS_BAR_TEXT"].value = statusTextValue
	end

	MainUnitFrames_SetStatusBarTextState(PlayerFrameHealthBar, statusTextValue == 1)
	MainUnitFrames_SetStatusBarTextState(PlayerFrameManaBar, statusTextValue == 1)
	MainUnitFrames_SetStatusBarTextState(TargetFrameHealthBar, statusTextValue == 1)
	MainUnitFrames_SetStatusBarTextState(TargetFrameManaBar, statusTextValue == 1)
	MainUnitFrames_SetStatusBarTextState(PetFrameHealthBar, statusTextValue == 1)
	MainUnitFrames_SetStatusBarTextState(PetFrameManaBar, statusTextValue == 1)
end

local function MainUnitFrames_RefreshUnitManaText(frame)
	local maxValue
	local manaText

	if not frame or not frame.unit or not frame.GetName then
		return
	end

	manaText = getglobal(frame:GetName() .. "ManaBarText")
	if not manaText then
		return
	end

	SetTextStatusBarTextPrefix(frame.manabar)
	maxValue = UnitManaMax(frame.unit)
	if not maxValue or maxValue == 0 then
		manaText:Hide()
	else
		manaText:Show()
	end
end

local function MainUnitFrames_RestoreStockFrames()
	local info
	local powerType

	if PlayerFrame then
		PlayerFrame:ClearAllPoints()
		PlayerFrame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", 6, -4)
	end
	if TargetFrame then
		TargetFrame:ClearAllPoints()
		TargetFrame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", 230, -4)
	end
	MainUnitFrames_RestoreAlternativeStyle()
	SetCVar("statusBarText", MainUnitFrames_GetOriginalStatusTextValue())

	if PlayerName then
		PlayerName:SetText(UnitName("player"))
	end
	if TargetName then
		TargetName:SetText(UnitName("target"))
	end

	if PlayerFrameHealthBar then
		UnitFrameHealthBar_Update(PlayerFrameHealthBar, "player")
	end
	if PlayerFrameManaBar then
		UnitFrameManaBar_Update(PlayerFrameManaBar, "player")
		powerType = UnitPowerType("player")
		info = ManaBarColor and ManaBarColor[powerType] or nil
		if info then
			PlayerFrameManaBar:SetStatusBarColor(info.r, info.g, info.b)
			SetTextStatusBarTextPrefix(PlayerFrameManaBar, info.prefix)
		end
	end

	if TargetFrame and TargetFrame:IsVisible() and UnitExists("target") then
		if TargetFrameHealthBar then
			UnitFrameHealthBar_Update(TargetFrameHealthBar, "target")
		end
		if TargetFrameManaBar then
			UnitFrameManaBar_Update(TargetFrameManaBar, "target")
			powerType = UnitPowerType("target")
			info = ManaBarColor and ManaBarColor[powerType] or nil
			if info then
				TargetFrameManaBar:SetStatusBarColor(info.r, info.g, info.b)
				SetTextStatusBarTextPrefix(TargetFrameManaBar, info.prefix)
			end
		end
	end

	MainUnitFrames_RefreshStatusBars()
end

local function MainUnitFrames_InstallStyleHooks()
	if not mainUnitFramesOriginalPlayerFrameOnEvent and PlayerFrame_OnEvent then
		mainUnitFramesOriginalPlayerFrameOnEvent = PlayerFrame_OnEvent
		PlayerFrame_OnEvent = function(event)
			mainUnitFramesOriginalPlayerFrameOnEvent(event)
			if MainUnitFrames_UseAlternativeStyle() then
				MainUnitFrames.pendingStyleRefresh = true
			end
		end
	end

	if not mainUnitFramesOriginalTargetFrameUpdate and TargetFrame_Update then
		mainUnitFramesOriginalTargetFrameUpdate = TargetFrame_Update
		TargetFrame_Update = function()
			mainUnitFramesOriginalTargetFrameUpdate()
			if MainUnitFrames_UseAlternativeStyle() then
				MainUnitFrames.pendingStyleRefresh = true
			end
		end
	end

	if not mainUnitFramesOriginalUnitFrameUpdateManaType and UnitFrame_UpdateManaType then
		mainUnitFramesOriginalUnitFrameUpdateManaType = UnitFrame_UpdateManaType
		UnitFrame_UpdateManaType = function()
			mainUnitFramesOriginalUnitFrameUpdateManaType()
			if MainUnitFrames_UseAlternativeStyle() then
				MainUnitFrames.pendingStyleRefresh = true
			end
		end
	end
end

local function MainUnitFrames_ApplyAll()
	if not MainUnitFrames_IsEnabled() then
		MainUnitFrames_RestoreStockFrames()
		return
	end

	MainUnitFrames_ApplyPosition()
	MainUnitFrames_ApplyStyle()
	MainUnitFrames_RefreshStatusBars()
end

function MainUnitFrames:Init()
	MainUnitFrames_CapturePoint("player", PlayerFrame)
	MainUnitFrames_CapturePoint("target", TargetFrame)
	MainUnitFrames_CaptureStyleState()
	MainUnitFrames_GetOriginalStatusTextValue()
	MainUnitFrames_InstallStyleHooks()
	Main.RegisterEventHandler("PLAYER_ENTERING_WORLD", "unit_frames", function()
		MainUnitFrames_ApplyAll()
	end)
end

function MainUnitFrames:Enable()
	MainUnitFrames_ApplyAll()
end

function MainUnitFrames:Disable()
	MainUnitFrames_RestoreStockFrames()
end

function MainUnitFrames:ApplyConfig()
	MainUnitFrames_ApplyAll()
end

function MainUnitFrames:OnUILayoutChanged()
	MainUnitFrames_ApplyAll()
end

function MainUnitFrames:ProcessDeferredRefresh()
	if MainUnitFrames.pendingStyleRefresh then
		MainUnitFrames.pendingStyleRefresh = nil
		if MainUnitFrames_UseAlternativeStyle() then
			MainUnitFrames_ApplyStyle()
		end
	end
end

Main.RegisterModule("unit_frames", MainUnitFrames)
