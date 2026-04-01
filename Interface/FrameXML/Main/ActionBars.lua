local MainActionBars = {
	name = "Action Bars",
	description = "Applies the custom stock-bar layout and bag/microbutton tweaks.",
	reloadRequired = 1,
	options = {
		{
			type = "number",
			key = "actionbars_x_offset",
			label = "Action Bar Horizontal Offset",
			managerOrder = 4,
			requiresModule = "action_bars",
			defaultValue = 0,
			step = 10,
			minValue = -300,
			maxValue = 300,
		},
	},
}

local mainActionBarsOriginalUpdateMicroButtons = nil
local mainActionBarsOriginalShowPetActionBar = nil
local mainActionBarsOriginalHidePetActionBar = nil
local mainActionBarsOriginalShapeshiftBarUpdate = nil
local mainActionBarsOriginalMainMenuExpBarUpdate = nil
local mainActionBarsOriginalPaperDollItemSlotButtonUpdateLock = nil
local mainActionBarsOriginalGameTooltipSetOwner = nil
local MAIN_ACTION_BARS_MICRO_BUTTONS = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"QuestLogMicroButton",
	"SocialsMicroButton",
	"WorldMapMicroButton",
	"MainMenuMicroButton",
	"BugsMicroButton",
}

local function MainActionBars_IsEnabled()
	return Main.IsModuleEnabled("action_bars")
end

local function MainActionBars_UseAlternativeStyle()
	return MainActionBars_IsEnabled()
end

local function MainActionBars_ShouldHideGryphons()
	return Main.GetBoolSetting("actionbars_hide_gryphons", true)
end

local function MainActionBars_GetHorizontalOffset()
	return Main.GetNumberSetting("actionbars_x_offset", 0)
end

local function MainActionBars_CaptureWidgetState(key, widget)
	local texture

	if not key or not widget then
		return
	end

	MainActionBars.originalWidgets = MainActionBars.originalWidgets or {}
	if MainActionBars.originalWidgets[key] then
		return
	end

	-- GetPoint is broken in 0.5.3 (returns garbage data that creates circular
	-- anchor dependencies on restore). Stock positions are restored explicitly
	-- via MainActionBars_ApplyStockLayoutFixes instead.

	texture = widget.GetTexture and widget:GetTexture() or nil

	MainActionBars.originalWidgets[key] = {
		width = widget.GetWidth and widget:GetWidth() or nil,
		height = widget.GetHeight and widget:GetHeight() or nil,
		frameLevel = widget.GetFrameLevel and widget:GetFrameLevel() or nil,
		shown = widget.IsVisible and widget:IsVisible() or nil,
		texture = texture,
		enabledMouse = widget.IsMouseEnabled and widget:IsMouseEnabled() or nil,
	}
end

local function MainActionBars_RestoreWidgetState(key, widget)
	local state
	local relativeTo

	if not key or not widget or not MainActionBars.originalWidgets then
		return
	end

	state = MainActionBars.originalWidgets[key]
	if not state then
		return
	end

	if state.width and widget.SetWidth then
		widget:SetWidth(state.width)
	end
	if state.height and widget.SetHeight then
		widget:SetHeight(state.height)
	end
	if state.frameLevel and widget.SetFrameLevel then
		widget:SetFrameLevel(state.frameLevel)
	end
	if state.texture ~= nil and widget.SetTexture then
		widget:SetTexture(state.texture)
	end
	if widget.GetPoint and state.point then
		widget:ClearAllPoints()
		relativeTo = state.relativeToName or state.parentName or "UIParent"
		widget:SetPoint(state.point, relativeTo, state.relativePoint or state.point, state.xOffset or 0, state.yOffset or 0)
	end
	if state.enabledMouse ~= nil and widget.EnableMouse then
		widget:EnableMouse(state.enabledMouse and 1 or 0)
	end
	if state.shown ~= nil then
		if state.shown then
			widget:Show()
		else
			widget:Hide()
		end
	end
end

local function MainActionBars_CaptureTextureState(key, texture)
	local texLeft
	local texRight
	local texTop
	local texBottom

	if not key or not texture then
		return
	end

	MainActionBars.originalTextures = MainActionBars.originalTextures or {}
	if MainActionBars.originalTextures[key] then
		return
	end

	-- GetPoint is broken in 0.5.3 (see CaptureWidgetState comment).
	if texture.GetTexCoord then
		texLeft, texRight, texTop, texBottom = texture:GetTexCoord()
	end

	MainActionBars.originalTextures[key] = {
		width = texture.GetWidth and texture:GetWidth() or nil,
		height = texture.GetHeight and texture:GetHeight() or nil,
		shown = texture.IsVisible and texture:IsVisible() or nil,
		texture = texture.GetTexture and texture:GetTexture() or nil,
		texLeft = texLeft,
		texRight = texRight,
		texTop = texTop,
		texBottom = texBottom,
	}
end

local function MainActionBars_RestoreTextureState(key, texture)
	local state
	local relativeTo

	if not key or not texture or not MainActionBars.originalTextures then
		return
	end

	state = MainActionBars.originalTextures[key]
	if not state then
		return
	end

	if state.width and texture.SetWidth then
		texture:SetWidth(state.width)
	end
	if state.height and texture.SetHeight then
		texture:SetHeight(state.height)
	end
	if state.texture ~= nil and texture.SetTexture then
		texture:SetTexture(state.texture)
	end
	if state.texLeft ~= nil and texture.SetTexCoord then
		texture:SetTexCoord(state.texLeft, state.texRight, state.texTop, state.texBottom)
	end
	if texture.GetPoint and state.point then
		texture:ClearAllPoints()
		relativeTo = state.relativeToName or state.parentName or "UIParent"
		texture:SetPoint(state.point, relativeTo, state.relativePoint or state.point, state.xOffset or 0, state.yOffset or 0)
	end
	if state.shown ~= nil then
		if state.shown then
			texture:Show()
		else
			texture:Hide()
		end
	end
end

local function MainActionBars_CaptureState()
	local index
	local buttonName
	local bagName

	MainActionBars.originalContainerOffset = MainActionBars.originalContainerOffset or CONTAINER_OFFSET

	MainActionBars_CaptureWidgetState("MainMenuBar", MainMenuBar)
	MainActionBars_CaptureWidgetState("ActionButton1", ActionButton1)
	MainActionBars_CaptureTextureState("SlidingActionBarTexture0", SlidingActionBarTexture0)
	MainActionBars_CaptureWidgetState("PetActionButton1", PetActionButton1)
	MainActionBars_CaptureTextureState("ShapeshiftBarLeft", ShapeshiftBarLeft)
	MainActionBars_CaptureWidgetState("ShapeshiftButton1", ShapeshiftButton1)
	MainActionBars_CaptureTextureState("MainMenuBarLeftEndCap", MainMenuBarLeftEndCap)
	MainActionBars_CaptureTextureState("MainMenuBarRightEndCap", MainMenuBarRightEndCap)
	MainActionBars_CaptureWidgetState("ActionBarUpButton", ActionBarUpButton)
	MainActionBars_CaptureWidgetState("ActionBarDownButton", ActionBarDownButton)
	MainActionBars_CaptureWidgetState("MainMenuExpBar", MainMenuExpBar)
	MainActionBars_CaptureWidgetState("ChatFrame", ChatFrame)
	MainActionBars_CaptureWidgetState("CombatLog", CombatLog)
	MainActionBars_CaptureWidgetState("MainMenuBarBackpackButton", MainMenuBarBackpackButton)
	MainActionBars_CaptureWidgetState("MainMenuBarPerformanceBarFrame", MainMenuBarPerformanceBarFrame)
	MainActionBars_CaptureWidgetState("MainMenuBarPerformanceBar", MainMenuBarPerformanceBar)

	for index = 0, 3 do
		MainActionBars_CaptureTextureState("MainMenuBarTexture" .. index, getglobal("MainMenuBarTexture" .. index))
	end

	for index = 1, Main_ArrayCount(MAIN_ACTION_BARS_MICRO_BUTTONS) do
		buttonName = MAIN_ACTION_BARS_MICRO_BUTTONS[index]
		MainActionBars_CaptureWidgetState(buttonName, getglobal(buttonName))
	end

	for index = 0, 3 do
		bagName = "CharacterBag" .. index .. "Slot"
		MainActionBars_CaptureWidgetState(bagName, getglobal(bagName))
		MainActionBars_CaptureTextureState(bagName .. "NormalTexture", getglobal(bagName .. "NormalTexture"))
	end
end

local function MainActionBars_UpdateContainerAnchors()
	if updateContainerFrameAnchors then
		updateContainerFrameAnchors()
	end
end

local function MainActionBars_ApplyTooltipHook()
	if mainActionBarsOriginalGameTooltipSetOwner then
		return
	end

	mainActionBarsOriginalGameTooltipSetOwner = GameTooltip.SetOwner
	function GameTooltip.SetOwner(tooltip, frame, anchor)
		local frameName

		frameName = frame and frame.GetName and frame:GetName() or nil
		if MainActionBars_UseAlternativeStyle() and (frame == MainMenuBarPerformanceBarFrame or (frameName and strfind(frameName, "MicroButton"))) then
			mainActionBarsOriginalGameTooltipSetOwner(tooltip, frame, "ANCHOR_LEFT")
			return
		end

		mainActionBarsOriginalGameTooltipSetOwner(tooltip, frame, anchor or "ANCHOR_RIGHT")
	end
end

local function MainActionBars_ApplyBagButtonLayout()
	local index
	local bagName
	local previousBagName
	local bagButton
	local normalTexture

	CONTAINER_OFFSET = 88

	MainMenuBarBackpackButton:SetWidth(40)
	MainMenuBarBackpackButton:SetHeight(40)
	MainMenuBarBackpackButton:ClearAllPoints()
	MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -4, 44)

	for index = 0, 3 do
		bagName = "CharacterBag" .. index .. "Slot"
		previousBagName = "CharacterBag" .. (index - 1) .. "Slot"
		bagButton = getglobal(bagName)
		normalTexture = getglobal(bagName .. "NormalTexture")

		if bagButton then
			bagButton:SetWidth(30)
			bagButton:SetHeight(30)
			bagButton:ClearAllPoints()
			if index == 0 then
				bagButton:SetPoint("BOTTOMRIGHT", "MainMenuBarBackpackButton", "BOTTOMLEFT", -3, 1)
			else
				bagButton:SetPoint("BOTTOMRIGHT", previousBagName, "BOTTOMLEFT", index < 2 and -3 or -2, 0)
			end
		end

		if normalTexture then
			if bagButton and bagButton.SetNormalTexture then
				bagButton:SetNormalTexture("")
			end
			normalTexture:Hide()
		end
	end

	MainActionBars_UpdateContainerAnchors()
end

local function MainActionBars_RestoreBagButtonLayout()
	local index
	local bagName
	local normalTexture
	local bagButton
	local texturePath

	if MainActionBars.originalContainerOffset ~= nil then
		CONTAINER_OFFSET = MainActionBars.originalContainerOffset
	end

	MainActionBars_RestoreWidgetState("MainMenuBarBackpackButton", MainMenuBarBackpackButton)
	for index = 0, 3 do
		bagName = "CharacterBag" .. index .. "Slot"
		bagButton = getglobal(bagName)
		MainActionBars_RestoreWidgetState(bagName, bagButton)
		normalTexture = getglobal(bagName .. "NormalTexture")
		MainActionBars_RestoreTextureState(bagName .. "NormalTexture", normalTexture)
		texturePath = normalTexture and normalTexture.GetTexture and normalTexture:GetTexture() or nil
		if bagButton and bagButton.SetNormalTexture and texturePath then
			bagButton:SetNormalTexture(texturePath)
		end
	end

	MainActionBars_UpdateContainerAnchors()
end

local function MainActionBars_GetOrderedMicroButtons()
	local buttons
	local count
	local index
	local buttonName

	buttons = {}
	count = 0

	for index = 1, Main_ArrayCount(MAIN_ACTION_BARS_MICRO_BUTTONS) do
		buttonName = MAIN_ACTION_BARS_MICRO_BUTTONS[index]
		count = count + 1
		buttons[count] = buttonName
		if buttonName == "SpellbookMicroButton" and MainTalentButton_ShouldShow and MainTalentButton_ShouldShow() then
			count = count + 1
			buttons[count] = "MainTalentMicroButton"
		end
	end

	return buttons
end

local function MainActionBars_ApplyMicroButtonLayout()
	local buttons
	local index
	local buttonName
	local previousButtonName
	local button

	buttons = MainActionBars_GetOrderedMicroButtons()
	MainMicroMenuArt:Show()

	for index = 1, Main_ArrayCount(buttons) do
		buttonName = buttons[index]
		previousButtonName = buttons[index - 1]
		button = getglobal(buttonName)

		if button then
			button:ClearAllPoints()
			button:SetFrameLevel(0)

			if index == 1 then
				button:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -198, 4)
			else
				button:SetPoint("BOTTOMRIGHT", previousButtonName, "BOTTOMRIGHT", 28, 0)
			end
		end
	end

	MainMenuBarPerformanceBarFrame:SetFrameLevel(6)
	MainMenuBarPerformanceBarFrame:SetWidth(28)
	MainMenuBarPerformanceBarFrame:SetHeight(6)
	MainMenuBarPerformanceBarFrame:ClearAllPoints()
	MainMenuBarPerformanceBarFrame:SetPoint("BOTTOM", "MainMenuMicroButton", "BOTTOM", 2, 2)

	MainMenuBarPerformanceBar:SetWidth(56)
	MainMenuBarPerformanceBar:SetHeight(10)
	MainMenuBarPerformanceBar:ClearAllPoints()
	MainMenuBarPerformanceBar:SetPoint("CENTER", "MainMenuBarPerformanceBarFrame", "CENTER", 0, 0)

	MainActionBars_ApplyBagButtonLayout()
	if MainTalentButton_UpdateState then
		MainTalentButton_UpdateState()
	end
end

local function MainActionBars_RestoreMicroButtons()
	local index
	local buttonName
	local previousButtonName
	local button

	MainMicroMenuArt:Hide()

	-- Restore stock XML micro button positions (ClearAllPoints first to remove
	-- alternative-layout anchors that would create circular dependencies)
	for index = 1, Main_ArrayCount(MAIN_ACTION_BARS_MICRO_BUTTONS) do
		buttonName = MAIN_ACTION_BARS_MICRO_BUTTONS[index]
		previousButtonName = MAIN_ACTION_BARS_MICRO_BUTTONS[index - 1]
		button = getglobal(buttonName)
		MainActionBars_RestoreWidgetState(buttonName, button)
		if button then
			button:ClearAllPoints()
			if index == 1 then
				button:SetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 546, 2)
			else
				button:SetPoint("BOTTOMLEFT", previousButtonName, "BOTTOMRIGHT", -2, 0)
			end
		end
	end

	MainActionBars_RestoreWidgetState("MainMenuBarPerformanceBarFrame", MainMenuBarPerformanceBarFrame)
	MainActionBars_RestoreWidgetState("MainMenuBarPerformanceBar", MainMenuBarPerformanceBar)
	MainActionBars_RestoreBagButtonLayout()
	if MainTalentButton_UpdateState then
		MainTalentButton_UpdateState()
	end
end

local function MainActionBars_ApplyStockLayoutFixes()
	local index
	local bagName
	local previousBagName
	local bagButton

	if not MainMenuBar or not MainMenuExpBar then
		return
	end

	MainMenuBar:SetWidth(1024)
	MainMenuBar:SetHeight(53)
	MainMenuBar:ClearAllPoints()
	MainMenuBar:SetPoint("BOTTOM", "UIParent", "BOTTOM", 0, 0)
	MainMenuBar:EnableMouse(1)

	MainMenuExpBar:SetWidth(1024)
	MainMenuExpBar:SetHeight(13)
	MainMenuExpBar:SetFrameLevel(1)
	MainMenuExpBar:ClearAllPoints()
	MainMenuExpBar:SetPoint("TOP", "MainMenuBar", "TOP", 0, 0)

	if MainMenuBarPerformanceBarFrame then
		MainMenuBarPerformanceBarFrame:SetWidth(16)
		MainMenuBarPerformanceBarFrame:SetHeight(64)
		MainMenuBarPerformanceBarFrame:ClearAllPoints()
		MainMenuBarPerformanceBarFrame:SetPoint("BOTTOMRIGHT", "MainMenuExpBar", "BOTTOMRIGHT", -226, -50)
	end

	if MainMenuBarPerformanceBar then
		MainMenuBarPerformanceBar:SetWidth(20)
		MainMenuBarPerformanceBar:SetHeight(66)
		MainMenuBarPerformanceBar:ClearAllPoints()
		MainMenuBarPerformanceBar:SetPoint("TOPRIGHT", "MainMenuBarPerformanceBarFrame", "TOPRIGHT", 0, 0)
	end

	if MainMenuBarBackpackButton then
		MainMenuBarBackpackButton:SetWidth(37)
		MainMenuBarBackpackButton:SetHeight(37)
		MainMenuBarBackpackButton:ClearAllPoints()
		MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", "MainMenuBarArtFrame", "BOTTOMRIGHT", -6, 2)
	end

	for index = 0, 3 do
		bagName = "CharacterBag" .. index .. "Slot"
		previousBagName = "CharacterBag" .. (index - 1) .. "Slot"
		bagButton = getglobal(bagName)
		if bagButton then
			bagButton:ClearAllPoints()
			if index == 0 then
				bagButton:SetPoint("RIGHT", "MainMenuBarBackpackButton", "LEFT", -5, 0)
			else
				bagButton:SetPoint("RIGHT", previousBagName, "LEFT", -5, 0)
			end
		end
	end

	MainActionBars_UpdateContainerAnchors()

	ActionButton1:ClearAllPoints()
	ActionButton1:SetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 4)

	ActionBarUpButton:ClearAllPoints()
	ActionBarUpButton:SetPoint("CENTER", "MainMenuBarArtFrame", "TOPLEFT", 522, -22)
	ActionBarDownButton:ClearAllPoints()
	ActionBarDownButton:SetPoint("CENTER", "MainMenuBarArtFrame", "TOPLEFT", 522, -42)

	MainMenuBarLeftEndCap:ClearAllPoints()
	MainMenuBarLeftEndCap:SetPoint("BOTTOM", "MainMenuBarArtFrame", "BOTTOM", -544, 0)
	MainMenuBarRightEndCap:ClearAllPoints()
	MainMenuBarRightEndCap:SetPoint("BOTTOM", "MainMenuBarArtFrame", "BOTTOM", 544, 0)

	ChatFrame:ClearAllPoints()
	ChatFrame:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 32, 82)
	CombatLog:ClearAllPoints()
	CombatLog:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -32, 82)

	SlidingActionBarTexture0:ClearAllPoints()
	SlidingActionBarTexture0:SetPoint("TOPLEFT", "PetActionBarFrame", "TOPLEFT", 0, 0)
	PetActionButton1:ClearAllPoints()
	PetActionButton1:SetPoint("BOTTOMLEFT", "PetActionBarFrame", "BOTTOMLEFT", 36, 1)
	ShapeshiftBarLeft:ClearAllPoints()
	ShapeshiftBarLeft:SetPoint("BOTTOMLEFT", "ShapeshiftBarFrame", "BOTTOMLEFT", 0, 0)
	ShapeshiftButton1:ClearAllPoints()
	ShapeshiftButton1:SetPoint("BOTTOMLEFT", "ShapeshiftBarFrame", "BOTTOMLEFT", 11, 3)
end

local function MainActionBars_ApplyAlternativeLayout()
	local index
	local horizontalOffset

	for index = 0, 3 do
		getglobal("MainMenuBarTexture" .. index):Hide()
	end

	horizontalOffset = MainActionBars_GetHorizontalOffset()

	MainActionBarArt:Show()
	MainActionBarArt:ClearAllPoints()
	MainActionBarArt:SetPoint("BOTTOM", "UIParent", "BOTTOM", horizontalOffset, -2)
	MainXPBarBackground:Show()
	MainMenuBar:EnableMouse(0)

	ActionButton1:ClearAllPoints()
	ActionButton1:SetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 7)

	SlidingActionBarTexture0:ClearAllPoints()
	SlidingActionBarTexture0:SetPoint("TOPLEFT", "PetActionBarFrame", "TOPLEFT", 0, 0)
	PetActionButton1:ClearAllPoints()
	PetActionButton1:SetPoint("TOP", "PetActionBarFrame", "LEFT", 51, 9)

	ShapeshiftBarLeft:ClearAllPoints()
	ShapeshiftBarLeft:SetPoint("BOTTOMLEFT", "ShapeshiftBarFrame", "BOTTOMLEFT", 0, 0)
	ShapeshiftButton1:ClearAllPoints()
	ShapeshiftButton1:SetPoint("TOP", "ShapeshiftBarLeft", "LEFT", 25, 7)

	if MainActionBars_ShouldHideGryphons() then
		MainMenuBarLeftEndCap:Hide()
		MainMenuBarRightEndCap:Hide()
	else
		MainMenuBarLeftEndCap:Show()
		MainMenuBarRightEndCap:Show()
		MainMenuBarLeftEndCap:ClearAllPoints()
		MainMenuBarLeftEndCap:SetPoint("LEFT", "MainActionBarArt", "LEFT", -96, 0)
		MainMenuBarRightEndCap:ClearAllPoints()
		MainMenuBarRightEndCap:SetPoint("RIGHT", "MainActionBarArt", "RIGHT", 96, 0)
	end

	ActionBarUpButton:ClearAllPoints()
	ActionBarUpButton:SetPoint("CENTER", "MainMenuBarArtFrame", "TOPLEFT", 521, -19)
	ActionBarDownButton:ClearAllPoints()
	ActionBarDownButton:SetPoint("CENTER", "MainMenuBarArtFrame", "TOPLEFT", 521, -38)

	MainMenuExpBar:SetWidth(542)
	MainMenuExpBar:SetHeight(10)
	MainMenuExpBar:ClearAllPoints()
	MainMenuExpBar:SetPoint("BOTTOM", "UIParent", "BOTTOM", horizontalOffset, 0)
	MainMenuExpBar:SetFrameLevel(0)

	MainMenuBar:ClearAllPoints()
	MainMenuBar:SetPoint("BOTTOM", "UIParent", "BOTTOM", 237 + horizontalOffset, 11)

	MainXPBarBackground:SetWidth(542)
	MainXPBarBackground:SetHeight(10)
	MainXPBarBackground:ClearAllPoints()
	MainXPBarBackground:SetPoint("BOTTOM", "MainMenuBar", "BOTTOM", -237, -10)

	MainActionBars_ApplyMicroButtonLayout()

	ChatFrame:ClearAllPoints()
	ChatFrame:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 32, 94)
	CombatLog:ClearAllPoints()
	CombatLog:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -32, 94)
	MainActionBars.alternativeApplied = true
end

local function MainActionBars_RestoreAlternativeLayout()
	local index

	for index = 0, 3 do
		MainActionBars_RestoreTextureState("MainMenuBarTexture" .. index, getglobal("MainMenuBarTexture" .. index))
	end

	MainActionBarArt:Hide()
	MainXPBarBackground:Hide()
	MainMenuBar:EnableMouse(1)

	MainActionBars_RestoreWidgetState("MainMenuBar", MainMenuBar)
	MainActionBars_RestoreWidgetState("ActionButton1", ActionButton1)
	MainActionBars_RestoreTextureState("SlidingActionBarTexture0", SlidingActionBarTexture0)
	MainActionBars_RestoreWidgetState("PetActionButton1", PetActionButton1)
	MainActionBars_RestoreTextureState("ShapeshiftBarLeft", ShapeshiftBarLeft)
	MainActionBars_RestoreWidgetState("ShapeshiftButton1", ShapeshiftButton1)
	MainActionBars_RestoreTextureState("MainMenuBarLeftEndCap", MainMenuBarLeftEndCap)
	MainActionBars_RestoreTextureState("MainMenuBarRightEndCap", MainMenuBarRightEndCap)
	MainActionBars_RestoreWidgetState("ActionBarUpButton", ActionBarUpButton)
	MainActionBars_RestoreWidgetState("ActionBarDownButton", ActionBarDownButton)
	MainActionBars_RestoreWidgetState("MainMenuExpBar", MainMenuExpBar)
	MainActionBars_RestoreWidgetState("ChatFrame", ChatFrame)
	MainActionBars_RestoreWidgetState("CombatLog", CombatLog)
	MainActionBars_RestoreMicroButtons()
	MainActionBars_ApplyStockLayoutFixes()
end

local function MainActionBars_UpdateGryphonButton()
	if not MainActionBarsGryphonButton then
		return
	end

	if not MainActionBars_IsEnabled() then
		MainActionBarsGryphonButton:Hide()
		return
	end

	MainActionBarsGryphonButton:Show()
	if MainActionBars_ShouldHideGryphons() then
		MainActionBarsGryphonButton:SetAlpha(1.0)
	else
		MainActionBarsGryphonButton:SetAlpha(0.55)
	end
end

local function MainActionBars_RestoreStockLayout()
	local index
	local bagButton
	local previousThis

	MainActionBars_RestoreAlternativeLayout()

	if mainActionBarsOriginalUpdateMicroButtons then
		mainActionBarsOriginalUpdateMicroButtons()
	elseif UpdateMicroButtons then
		UpdateMicroButtons()
	end

	if mainActionBarsOriginalMainMenuExpBarUpdate then
		mainActionBarsOriginalMainMenuExpBarUpdate()
	elseif MainMenuExpBar_Update then
		MainMenuExpBar_Update()
	end

	if mainActionBarsOriginalShapeshiftBarUpdate then
		mainActionBarsOriginalShapeshiftBarUpdate()
	elseif ShapeshiftBar_Update then
		ShapeshiftBar_Update()
	end

	if mainActionBarsOriginalPaperDollItemSlotButtonUpdateLock then
		previousThis = this
		for index = 0, 3 do
			bagButton = getglobal("CharacterBag" .. index .. "Slot")
			if bagButton then
				this = bagButton
				mainActionBarsOriginalPaperDollItemSlotButtonUpdateLock()
			end
		end
		this = previousThis
	end

	MainActionBars_UpdateGryphonButton()
	if MainTalentButton_UpdateState then
		MainTalentButton_UpdateState()
	end
end

local function MainActionBars_RefreshLayout()
	if MainActionBars_UseAlternativeStyle() then
		MainActionBars_ApplyAlternativeLayout()
	else
		MainActionBars_RestoreStockLayout()
	end

	MainActionBars_UpdateGryphonButton()
end

local function MainActionBars_InstallHooks()
	if not mainActionBarsOriginalUpdateMicroButtons then
		mainActionBarsOriginalUpdateMicroButtons = UpdateMicroButtons
		function UpdateMicroButtons()
			mainActionBarsOriginalUpdateMicroButtons()
			if MainActionBars_UseAlternativeStyle() and not MainActionBars.inMicroRefresh then
				MainActionBars.inMicroRefresh = true
				MainActionBars_ApplyMicroButtonLayout()
				MainActionBars.inMicroRefresh = nil
			end
		end
	end

	if not mainActionBarsOriginalShapeshiftBarUpdate then
		mainActionBarsOriginalShapeshiftBarUpdate = ShapeshiftBar_Update
		function ShapeshiftBar_Update()
			mainActionBarsOriginalShapeshiftBarUpdate()
			if MainActionBars_UseAlternativeStyle() then
				MainActionBars.pendingLayoutRefresh = true
			end
		end
	end

	if not mainActionBarsOriginalShowPetActionBar then
		mainActionBarsOriginalShowPetActionBar = ShowPetActionBar
		function ShowPetActionBar()
			mainActionBarsOriginalShowPetActionBar()
			if MainActionBars_UseAlternativeStyle() then
				MainActionBars.pendingLayoutRefresh = true
			end
		end
	end

	if not mainActionBarsOriginalHidePetActionBar then
		mainActionBarsOriginalHidePetActionBar = HidePetActionBar
		function HidePetActionBar()
			mainActionBarsOriginalHidePetActionBar()
			if MainActionBars_UseAlternativeStyle() then
				MainActionBars.pendingLayoutRefresh = true
			end
		end
	end

	if not mainActionBarsOriginalMainMenuExpBarUpdate then
		mainActionBarsOriginalMainMenuExpBarUpdate = MainMenuExpBar_Update
		function MainMenuExpBar_Update()
			mainActionBarsOriginalMainMenuExpBarUpdate()
			if MainActionBars_UseAlternativeStyle() then
				MainMenuExpBar:SetFrameLevel(0)
				MainActionBars.pendingLayoutRefresh = true
			end
		end
	end

	if not mainActionBarsOriginalPaperDollItemSlotButtonUpdateLock then
		mainActionBarsOriginalPaperDollItemSlotButtonUpdateLock = PaperDollItemSlotButton_UpdateLock
		function PaperDollItemSlotButton_UpdateLock()
			local buttonName

			if MainActionBars_UseAlternativeStyle() and this and this.GetName then
				buttonName = this:GetName()
				if strfind(buttonName, "CharacterBag") then
					return
				end
			end

			mainActionBarsOriginalPaperDollItemSlotButtonUpdateLock()
		end
	end

	MainActionBars_ApplyTooltipHook()
end

function MainActionBars:Init()
	MainActionBars_CaptureState()
	MainActionBars_InstallHooks()
	Main.RegisterEventHandler("PLAYER_ENTERING_WORLD", "action_bars", function()
		if MainActionBars_IsEnabled() then
			MainActionBars_RefreshLayout()
		elseif MainActionBars.alternativeApplied then
			MainActionBars_RestoreStockLayout()
			MainActionBars.alternativeApplied = nil
		end
	end)
	if MainActionBarsGryphonButton then
		MainActionBarsGryphonButton:Hide()
	end
end

function MainActionBars:Enable()
	MainActionBars_RefreshLayout()
	if UpdateMicroButtons then
		UpdateMicroButtons()
	end
end

function MainActionBars:Disable()
	if MainActionBars.alternativeApplied then
		MainActionBars_RestoreStockLayout()
		MainActionBars.alternativeApplied = nil
	end
end

function MainActionBars:ApplyConfig()
	MainActionBars_RefreshLayout()
	if UpdateMicroButtons then
		UpdateMicroButtons()
	end
end

function MainActionBars:OnUILayoutChanged()
	if not MainActionBars_IsEnabled() then
		return
	end

	MainActionBars:ApplyConfig()
end

function MainActionBars:ProcessDeferredRefresh()
	if MainActionBars.pendingLayoutRefresh then
		MainActionBars.pendingLayoutRefresh = nil
		MainActionBars_RefreshLayout()
	end
end

function MainActionBarsGryphonButton_OnLoad()
	this:SetText("G")
	this:Hide()
end

function MainActionBarsGryphonButton_OnClick()
	Main.SetBoolSetting("actionbars_hide_gryphons", not MainActionBars_ShouldHideGryphons(), nil, true)
	MainActionBars_RefreshLayout()
end

function MainActionBarsGryphonButton_OnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	if MainActionBars_ShouldHideGryphons() then
		GameTooltip:SetText("Show Gryphons", 1.0, 1.0, 1.0)
	else
		GameTooltip:SetText("Hide Gryphons", 1.0, 1.0, 1.0)
	end
	GameTooltip:AddLine("Toggle Gryphons side art")
	GameTooltip:Show()
end

function MainActionBarsGryphonButton_OnLeave()
	GameTooltip:Hide()
end

Main.RegisterModule("action_bars", MainActionBars)
