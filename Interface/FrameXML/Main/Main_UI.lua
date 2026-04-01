local function Main_RegisterManagerPanel()
	local index

	if UIPanelWindows then
		UIPanelWindows["MainManagerFrame"] = { area = "center", pushable = 0 }
	end

	if not UISpecialFrames then
		return
	end

	for index = 1, Main_ArrayCount(UISpecialFrames) do
		if UISpecialFrames[index] == "MainManagerFrame" then
			return
		end
	end

	Main_ArrayInsert(UISpecialFrames, "MainManagerFrame")
end

function Main_OnLoad()
	Main_RegisterManagerPanel()
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("CHAT_MSG_CHANNEL")
end

function Main_OnEvent(event)
	if event == "PLAYER_ENTERING_WORLD" and not Main.StartRequested then
		Main.StartRequested = 1
		Main_AdjustGameMenu()
		Main_Start()
		if Main.API and Main.API.BeginStartup then
			Main.API:BeginStartup()
		end
	elseif event == "CHAT_MSG_CHANNEL" and Main.API and Main.API.HandleChannelMessage then
		Main.API:HandleChannelMessage(arg1, arg2, arg4)
	end

	if Main.DispatchEvent then
		Main.DispatchEvent(event)
	end
end

function Main_OnUpdate()
	if Main.API and Main.API.OnUpdate then
		Main.API:OnUpdate()
	end

	if Main.ProcessPendingConfigApply then
		Main.ProcessPendingConfigApply()
	end

	if Main.ProcessPendingManagerRefresh then
		Main.ProcessPendingManagerRefresh()
	end

	Main_ProcessDeferredModuleRefreshes()
	Main_MonitorUILayout(arg1 or 0)
end

function Main_ProcessDeferredModuleRefreshes()
	local i
	local module

	for i = 1, Main.GetModuleCount() do
		module = Main.GetModuleByIndex(i)
		if module and module.ProcessDeferredRefresh then
			module:ProcessDeferredRefresh()
		end
	end
end

function Main_Start()
	if not Main.ModulesInitialized then
		Main.InitializeModules()
	else
		Main.ApplyConfiguredModuleStates(1)
	end

	Main.LastUILayoutWidth, Main.LastUILayoutHeight = Main_GetUILayoutMetrics()
	Main.Initialized = 1
	Main.RefreshManager()
end

function Main_GetUILayoutMetrics()
	local width
	local height

	width = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 0
	height = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 0

	return width, height
end

function Main_HandleUILayoutChanged()
	local i
	local module

	for i = 1, Main.GetModuleCount() do
		module = Main.GetModuleByIndex(i)
		if module and module.OnUILayoutChanged then
			module:OnUILayoutChanged()
		end
	end
end

function Main_MonitorUILayout(elapsed)
	local width
	local height

	Main.LayoutMonitorElapsed = (Main.LayoutMonitorElapsed or 0) + elapsed
	if Main.LayoutMonitorElapsed < (Main.LayoutMonitorInterval or 0.25) then
		return
	end

	Main.LayoutMonitorElapsed = 0
	width, height = Main_GetUILayoutMetrics()
	if width <= 0 or height <= 0 then
		return
	end

	if not Main.LastUILayoutWidth or not Main.LastUILayoutHeight then
		Main.LastUILayoutWidth = width
		Main.LastUILayoutHeight = height
		return
	end

	if Main.LastUILayoutWidth ~= width or Main.LastUILayoutHeight ~= height then
		Main.LastUILayoutWidth = width
		Main.LastUILayoutHeight = height
		Main_HandleUILayoutChanged()
	end
end

function Main_AdjustGameMenu()
	local height
	local reloadVisible

	if not GameMenuFrame then
		return
	end

	reloadVisible = Main.IsModuleEnabled and Main.IsModuleEnabled("reload_button")
	height = 196
	if reloadVisible then
		height = 222
	end

	GameMenuFrame:SetHeight(height)

	if MainGameMenuButtonAddons then
		MainGameMenuButtonAddons:ClearAllPoints()
		MainGameMenuButtonAddons:SetPoint("CENTER", "GameMenuFrame", "TOP", 0, -37)
	end

	if GameMenuButtonOptions then
		GameMenuButtonOptions:ClearAllPoints()
		GameMenuButtonOptions:SetPoint("TOP", "MainGameMenuButtonAddons", "BOTTOM", 0, -1)
	end

	if MainGameMenuButtonReload then
		MainGameMenuButtonReload:ClearAllPoints()
		MainGameMenuButtonReload:SetPoint("TOP", "GameMenuButtonSoundOptions", "BOTTOM", 0, -1)
		if reloadVisible then
			MainGameMenuButtonReload:Show()
		else
			MainGameMenuButtonReload:Hide()
		end
	end

	if GameMenuButtonLogout then
		GameMenuButtonLogout:ClearAllPoints()
		if reloadVisible and MainGameMenuButtonReload then
			GameMenuButtonLogout:SetPoint("TOP", "MainGameMenuButtonReload", "BOTTOM", 0, -1)
		else
			GameMenuButtonLogout:SetPoint("TOP", "GameMenuButtonSoundOptions", "BOTTOM", 0, -1)
		end
	end
end

function Main_ToggleUIPanel(frame)
	if not frame then
		return
	end

	if frame:IsVisible() then
		HideUIPanel(frame)
	else
		ShowUIPanel(frame)
	end
end

function Main.ScheduleManagerRefresh()
	Main.PendingManagerRefresh = 1
end

function Main.ScheduleConfigApply()
	Main.PendingConfigApply = 1
end

function Main.ProcessPendingManagerRefresh()
	if not Main.PendingManagerRefresh then
		return
	end

	Main.PendingManagerRefresh = nil
	if Main.RefreshManager then
		Main.RefreshManager()
	end
end

function Main.ProcessPendingConfigApply()
	if not Main.PendingConfigApply or not Main.PendingAppliedConfigValues then
		return
	end

	Main.PendingConfigApply = nil
	Main.Config.values = Main_CopyTable(Main.PendingAppliedConfigValues)
	Main.PendingAppliedConfigValues = nil

	if Main.ModulesInitialized and Main.ApplyConfiguredModuleStates then
		Main.ApplyConfiguredModuleStates(1, 1)
	end

	if Main.SaveConfig then
		Main.SaveConfig()
	end

	if Main.RefreshManager then
		Main.RefreshManager()
	end
end

function Main_StartMovingFrame(button)
	-- Frame dragging is handled by the engine via TitleRegion
end

function Main_StopMovingFrame()
	-- Frame dragging is handled by the engine via TitleRegion
end

function MainGameMenuButtonAddons_OnLoad()
	this:SetText("Addons")
	Main_AdjustGameMenu()
end

function MainGameMenuButtonAddons_OnClick()
	if PlaySound then
		PlaySound("igMainMenuOption")
	end

	ShowUIPanel(MainManagerFrame)
end

function MainManagerFrame_OnShow()
	Main.ManagerAcceptedChanges = nil
	Main.ManagerConfigSnapshot = Main.CopyConfigValues and Main.CopyConfigValues() or nil
	Main.ManagerDraftConfig = Main.ManagerConfigSnapshot and Main_CopyTable(Main.ManagerConfigSnapshot) or Main.CopyConfigValues()
	MainManagerFrame:ClearAllPoints()
	MainManagerFrame:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
	Main.RefreshManager()
end

function MainManagerFrame_OnHide()
	local needsReload

	if Main.ManagerAcceptedChanges and Main.ManagerDraftConfig then
		if Main.ManagerConfigSnapshot then
			Main_ForEach(Main.Modules, function(id, module)
				if module.reloadRequired and Main.ManagerConfigSnapshot.modules and Main.ManagerDraftConfig.modules then
					if Main.ManagerConfigSnapshot.modules[id] ~= Main.ManagerDraftConfig.modules[id] then
						needsReload = 1
					end
				end
			end)
		end

		if needsReload then
			Main.Config.values = Main_CopyTable(Main.ManagerDraftConfig)
			if Main.SaveConfig then
				Main.SaveConfig()
			end
			Main.ManagerConfigSnapshot = nil
			Main.ManagerDraftConfig = nil
			Main.ManagerAcceptedChanges = nil
			ReloadUI()
			return
		end

		Main.PendingAppliedConfigValues = Main_CopyTable(Main.ManagerDraftConfig)
		if Main.ScheduleConfigApply then
			Main.ScheduleConfigApply()
		end
	end

	Main.ManagerConfigSnapshot = nil
	Main.ManagerDraftConfig = nil
	Main.ManagerAcceptedChanges = nil
end

function MainManagerOkayButton_OnClick()
	if PlaySound then
		PlaySound("gsTitleOptionOK")
	end

	Main.ManagerAcceptedChanges = 1
	HideUIPanel(MainManagerFrame)
end

function MainManagerCancelButton_OnClick()
	if PlaySound then
		PlaySound("gsTitleOptionExit")
	end

	HideUIPanel(MainManagerFrame)
end

local function Main_GetManagerModuleByIndex(index)
	local pageIndex
	local slotIndex

	pageIndex = ((Main.ManagerModulePage or 1) - 1) * Main.ManagerSlotCount
	slotIndex = Main.ManagerModuleSlotOrder and Main.ManagerModuleSlotOrder[index] or index
	return Main.GetVisibleModuleByIndex(pageIndex + slotIndex)
end

local function Main_GetManagerModulePageCount()
	local totalCount

	totalCount = Main.GetVisibleModuleCount and Main.GetVisibleModuleCount() or Main.GetModuleCount()
	if totalCount <= 0 then
		return 1
	end

	return ceil(totalCount / Main.ManagerSlotCount)
end

local function Main_GetManagerConfigValues()
	if Main.ManagerDraftConfig then
		return Main.ManagerDraftConfig
	end

	return Main.Config.values
end

local function Main_GetManagerConfiguredModuleEnabled(id)
	local values
	local configuredValue

	if not id then
		return nil
	end

	values = Main_GetManagerConfigValues()
	if not values or not values.modules then
		return Main.Config.defaults.modules[id]
	end

	configuredValue = values.modules[id]
	if configuredValue == nil then
		configuredValue = Main.Config.defaults.modules[id]
	end

	return configuredValue
end

local function Main_SetManagerConfiguredModuleEnabled(id, enabled)
	local values

	if not id then
		return
	end

	values = Main_GetManagerConfigValues()
	values.modules = values.modules or {}
	values.modules[id] = enabled and true or false
end

local function Main_GetManagerSettingRaw(key)
	local values
	local settingValue

	if not key then
		return nil
	end

	values = Main_GetManagerConfigValues()
	if not values or not values.settings then
		return nil
	end

	settingValue = values.settings[key]
	if settingValue == nil or settingValue == "" then
		return nil
	end

	return settingValue
end

local function Main_GetManagerBoolSetting(key, defaultValue)
	local value

	value = Main_GetManagerSettingRaw(key)
	if value == nil then
		return defaultValue and true or false
	end

	value = Main_StringLower(Main_ToString(value))
	if value == "1" or value == "true" or value == "yes" or value == "on" then
		return true
	end
	if value == "0" or value == "false" or value == "no" or value == "off" then
		return false
	end

	return defaultValue and true or false
end

local function Main_SetManagerBoolSetting(key, enabled, defaultValue)
	local values

	if not key then
		return
	end

	values = Main_GetManagerConfigValues()
	values.settings = values.settings or {}

	if defaultValue ~= nil and (enabled and true or false) == (defaultValue and true or false) then
		values.settings[key] = nil
	else
		values.settings[key] = enabled and "1" or "0"
	end
end

local function Main_GetManagerNumberSetting(key, defaultValue)
	local value

	value = Main_ToNumber(Main_GetManagerSettingRaw(key), nil)
	if value == nil then
		return defaultValue
	end

	return value
end

local function Main_SetManagerNumberSetting(key, value, defaultValue)
	local values
	local numericValue
	local numericDefault

	if not key then
		return
	end

	numericValue = Main_ToNumber(value, nil)
	if numericValue == nil then
		return
	end

	values = Main_GetManagerConfigValues()
	values.settings = values.settings or {}

	numericDefault = Main_ToNumber(defaultValue, nil)
	if numericDefault ~= nil and numericValue == numericDefault then
		values.settings[key] = nil
	elseif numericValue == floor(numericValue) then
		values.settings[key] = Main_ToString(floor(numericValue))
	else
		values.settings[key] = Main_ToString(numericValue)
	end
end

local function Main_CollectManagerOptions(optionType)
	local moduleIndex
	local module
	local options
	local optionIndex
	local count
	local entries
	local option
	local sortIndex

	entries = {}
	count = 0
	sortIndex = 0

	for moduleIndex = 1, Main.GetModuleCount() do
		module = Main.GetModuleByIndex(moduleIndex)
		options = module and module.options or nil
		for optionIndex = 1, Main_ArrayCount(options) do
			option = options[optionIndex]
			if option and option.type == optionType and not option.managerHidden then
				sortIndex = sortIndex + 1
				count = count + 1
				entries[count] = {
					module = module,
					option = option,
					sortIndex = sortIndex,
					managerOrder = option.managerOrder or (1000 + sortIndex),
				}
			end
		end
	end

	Main_SortArray(entries, function(left, right)
		if left.managerOrder == right.managerOrder then
			return left.sortIndex < right.sortIndex
		end

		return left.managerOrder < right.managerOrder
	end)

	return entries
end

local function Main_GetManagerOptionByTypeIndex(optionType, index)
	local startIndex
	local optionIndex
	local entries
	local entry

	startIndex = 0
	optionIndex = index

	if optionType == "toggle" then
		startIndex = ((Main.ManagerToggleOptionPage or 1) - 1) * Main.ManagerOptionSlotCount
		-- Fill the first four rows in the left column before mirroring them on the right.
		-- The lower two rows are only used once the upper grid is full.
		if not Main.ManagerToggleSlotOrder then
			Main.ManagerToggleSlotOrder = { 1, 2, 3, 4, 9, 5, 6, 7, 8, 10, 11, 12 }
		end
		optionIndex = Main.ManagerToggleSlotOrder[index] or index
	elseif optionType == "number" then
		startIndex = ((Main.ManagerNumberOptionPage or 1) - 1) * Main.ManagerNumberSlotCount
	end

	entries = Main_CollectManagerOptions(optionType)
	entry = entries[startIndex + optionIndex]
	if entry then
		return entry.module, entry.option
	end

	return nil, nil
end

local function Main_GetManagerOptionTotalCount(optionType)
	return Main_ArrayCount(Main_CollectManagerOptions(optionType))
end

local function Main_GetManagerToggleOption(index)
	return Main_GetManagerOptionByTypeIndex("toggle", index)
end

local function Main_GetManagerNumberOption(index)
	return Main_GetManagerOptionByTypeIndex("number", index)
end

local function Main_GetManagerOptionCount(optionType, slotCount)
	local count
	local index

	count = 0
	for index = 1, slotCount do
		if Main_GetManagerOptionByTypeIndex(optionType, index) then
			count = count + 1
		end
	end

	return count
end

local function Main_GetManagerOptionPageCount(optionType, slotCount)
	local totalCount

	totalCount = Main_GetManagerOptionTotalCount(optionType)
	if totalCount <= 0 then
		return 1
	end

	return ceil(totalCount / slotCount)
end

local function Main_FormatManagerNumberValue(option, value)
	if value == nil then
		return ""
	end

	if option and option.displayFormat then
		return format(option.displayFormat, value)
	end

	if value == floor(value) then
		return Main_ToString(floor(value))
	end

	return Main_ToString(value)
end

local function Main_IsManagerModuleAvailable(module)
	if not module then
		return nil
	end

	if module.IsAvailable then
		return module:IsAvailable() and true or false
	end

	return true
end

local function Main_IsManagerOptionDisabled(module, option)
	if option and option.requiresModule and not Main_GetManagerConfiguredModuleEnabled(option.requiresModule) then
		return 1
	end

	if option and option.disabledFunc and option.disabledFunc(module, option) then
		return 1
	end

	return nil
end

local function Main_RunWithThis(frame, callback)
	local previousThis

	if not frame or not callback then
		return
	end

	previousThis = this
	this = frame
	callback()
	this = previousThis
end

function MainModuleToggle_OnClick()
	local module
	local enabled

	module = Main_GetManagerModuleByIndex(this:GetID())
	if not module then
		return
	end

	enabled = Main_IsChecked(this) and true or false
	Main_SetManagerConfiguredModuleEnabled(module.id, enabled)
	if Main.ScheduleManagerRefresh then
		Main.ScheduleManagerRefresh()
	else
		Main.RefreshManager()
	end
end

function MainManagerOptionToggle_OnClick()
	local module
	local option
	local enabled

	module, option = Main_GetManagerToggleOption(this:GetID())
	if not module or not option or not option.key then
		return
	end

	enabled = Main_IsChecked(this) and true or false
	if option.requiresModule ~= false and not Main_GetManagerConfiguredModuleEnabled(module.id) then
		Main_SetManagerConfiguredModuleEnabled(module.id, true)
	end

	Main_SetManagerBoolSetting(option.key, enabled, option.defaultValue)
	if module.ApplyConfig and (module.runtimeEnabled or option.requiresModule == false) then
		module:ApplyConfig()
	end
	if Main.ScheduleManagerRefresh then
		Main.ScheduleManagerRefresh()
	else
		Main.RefreshManager()
	end
end

local function Main_SetManagerNumberOptionDisplay(index, option, value)
	local optionFrame
	local valueLabel

	optionFrame = getglobal("MainManagerNumberOption" .. index)
	if not optionFrame then
		return
	end

	valueLabel = getglobal(optionFrame:GetName() .. "Value")
	if valueLabel then
		valueLabel:SetText(Main_FormatManagerNumberValue(option, value))
	end
end

local function Main_SetManagerNumberOptionValue(index, value, slider)
	local module
	local option
	local step
	local nextValue

	module, option = Main_GetManagerNumberOption(index)
	if not module or not option or not option.key then
		return
	end

	step = Main_ToNumber(option.step, 1) or 1
	nextValue = Main_ToNumber(value, option.defaultValue or 0)

	if step > 0 then
		nextValue = floor((nextValue / step) + 0.5) * step
	end

	if option.minValue ~= nil and nextValue < option.minValue then
		nextValue = option.minValue
	end
	if option.maxValue ~= nil and nextValue > option.maxValue then
		nextValue = option.maxValue
	end
	if option.integer ~= false then
		nextValue = floor(nextValue + 0.5)
	end

	if option.requiresModule ~= false and not Main_GetManagerConfiguredModuleEnabled(module.id) then
		Main_SetManagerConfiguredModuleEnabled(module.id, true)
	end

	Main_SetManagerNumberSetting(option.key, nextValue, option.defaultValue)
	Main_SetManagerNumberOptionDisplay(index, option, nextValue)

	if slider and slider.GetValue and slider.SetValue and slider:GetValue() ~= nextValue then
		Main.ManagerSyncing = 1
		slider:SetValue(nextValue)
		Main.ManagerSyncing = nil
	end

	if Main.ScheduleManagerRefresh then
		Main.ScheduleManagerRefresh()
	else
		Main.RefreshManager()
	end
end

function MainManagerNumberSlider_OnValueChanged(value)
	local index

	index = this:GetID()
	if Main.ManagerSyncing then
		return
	end

	Main_SetManagerNumberOptionValue(index, value, this)
end

function MainManagerModulesPrev_OnClick()
	if (Main.ManagerModulePage or 1) > 1 then
		Main.ManagerModulePage = Main.ManagerModulePage - 1
		Main.RefreshManager()
	end
end

function MainManagerModulesNext_OnClick()
	local pageCount

	pageCount = Main_GetManagerModulePageCount()
	if (Main.ManagerModulePage or 1) < pageCount then
		Main.ManagerModulePage = Main.ManagerModulePage + 1
		Main.RefreshManager()
	end
end

function MainManagerToggleOptionsPrev_OnClick()
	if (Main.ManagerToggleOptionPage or 1) > 1 then
		Main.ManagerToggleOptionPage = Main.ManagerToggleOptionPage - 1
		Main.RefreshManager()
	end
end

function MainManagerToggleOptionsNext_OnClick()
	local pageCount

	pageCount = Main_GetManagerOptionPageCount("toggle", Main.ManagerOptionSlotCount)
	if (Main.ManagerToggleOptionPage or 1) < pageCount then
		Main.ManagerToggleOptionPage = Main.ManagerToggleOptionPage + 1
		Main.RefreshManager()
	end
end

function MainManagerNumberOptionsPrev_OnClick()
	if (Main.ManagerNumberOptionPage or 1) > 1 then
		Main.ManagerNumberOptionPage = Main.ManagerNumberOptionPage - 1
		Main.RefreshManager()
	end
end

function MainManagerNumberOptionsNext_OnClick()
	local pageCount

	pageCount = Main_GetManagerOptionPageCount("number", Main.ManagerNumberSlotCount)
	if (Main.ManagerNumberOptionPage or 1) < pageCount then
		Main.ManagerNumberOptionPage = Main.ManagerNumberOptionPage + 1
		Main.RefreshManager()
	end
end

function Main.RefreshManager()
	local i
	local toggle
	local label
	local description
	local module
	local toggleOptionCount
	local numberOptionCount
	local optionToggle
	local optionLabel
	local optionModule
	local option
	local optionFrame
	local valueLabel
	local decrementButton
	local incrementButton
	local toggleOptionPageCount
	local numberOptionPageCount
	local modulePageCount
	local slider
	local optionValue
	local moduleAvailable

	modulePageCount = Main_GetManagerModulePageCount()
	if (Main.ManagerModulePage or 1) > modulePageCount then
		Main.ManagerModulePage = modulePageCount
	end
	if (Main.ManagerModulePage or 1) < 1 then
		Main.ManagerModulePage = 1
	end

	for i = 1, Main.ManagerSlotMax do
		toggle = getglobal("MainModuleToggle" .. i)
		description = getglobal("MainModuleDescription" .. i)
		module = nil
		if i <= Main.ManagerSlotCount then
			module = Main_GetManagerModuleByIndex(i)
		end

		if description then
			description:Hide()
		end

		if toggle then
			if module then
				moduleAvailable = Main_IsManagerModuleAvailable(module)
				label = getglobal(toggle:GetName() .. "Text")
				if label then
					label:SetText(module.name)
					if label.SetWidth then
						label:SetWidth(184)
					end
					if label.SetJustifyH then
						label:SetJustifyH("LEFT")
					end
					if moduleAvailable then
						label:SetTextColor(1, 0.82, 0)
					else
						label:SetTextColor(0.5, 0.5, 0.5)
					end
				end

				if Main_GetManagerConfiguredModuleEnabled(module.id) then
					toggle:SetChecked(1)
				else
					toggle:SetChecked(0)
				end
				if moduleAvailable then
					toggle:Enable()
				else
					toggle:Disable()
				end
				toggle:Show()
			else
				toggle:Hide()
			end
		end
	end

	if MainManagerModulePageText then
		if modulePageCount > 1 then
			MainManagerModulePageText:SetText(format("Page %d / %d", Main.ManagerModulePage or 1, modulePageCount))
			MainManagerModulePageText:Show()
		else
			MainManagerModulePageText:Hide()
		end
	end

	if MainManagerModulesPrev then
		if modulePageCount > 1 then
			MainManagerModulesPrev:Show()
			if (Main.ManagerModulePage or 1) > 1 then
				MainManagerModulesPrev:Enable()
			else
				MainManagerModulesPrev:Disable()
			end
		else
			MainManagerModulesPrev:Hide()
		end
	end

	if MainManagerModulesNext then
		if modulePageCount > 1 then
			MainManagerModulesNext:Show()
			if (Main.ManagerModulePage or 1) < modulePageCount then
				MainManagerModulesNext:Enable()
			else
				MainManagerModulesNext:Disable()
			end
		else
			MainManagerModulesNext:Hide()
		end
	end

	if MainSessionOnlyText then
		MainSessionOnlyText:SetText("")
		MainSessionOnlyText:Hide()
	end

	if MainManagerIntroText then
		MainManagerIntroText:Hide()
	end

	toggleOptionPageCount = Main_GetManagerOptionPageCount("toggle", Main.ManagerOptionSlotCount)
	if (Main.ManagerToggleOptionPage or 1) > toggleOptionPageCount then
		Main.ManagerToggleOptionPage = toggleOptionPageCount
	end
	if (Main.ManagerToggleOptionPage or 1) < 1 then
		Main.ManagerToggleOptionPage = 1
	end
	numberOptionPageCount = Main_GetManagerOptionPageCount("number", Main.ManagerNumberSlotCount)
	if (Main.ManagerNumberOptionPage or 1) > numberOptionPageCount then
		Main.ManagerNumberOptionPage = numberOptionPageCount
	end
	if (Main.ManagerNumberOptionPage or 1) < 1 then
		Main.ManagerNumberOptionPage = 1
	end

	toggleOptionCount = Main_GetManagerOptionCount("toggle", Main.ManagerOptionSlotCount)
	numberOptionCount = Main_GetManagerOptionCount("number", Main.ManagerNumberSlotCount)
	if MainManagerOptionsTitle then
		if (toggleOptionCount + numberOptionCount) > 0 then
			MainManagerOptionsTitle:SetText("Extra Options")
			MainManagerOptionsTitle:Show()
		else
			MainManagerOptionsTitle:Hide()
		end
	end

	if MainManagerOptionsText then
		MainManagerOptionsText:SetText("")
		MainManagerOptionsText:Hide()
	end

	if MainManagerToggleOptionsPageText then
		if toggleOptionPageCount > 1 then
			MainManagerToggleOptionsPageText:SetText(format("Page %d / %d", Main.ManagerToggleOptionPage or 1, toggleOptionPageCount))
			MainManagerToggleOptionsPageText:Show()
		else
			MainManagerToggleOptionsPageText:Hide()
		end
	end

	if MainManagerToggleOptionsPrev then
		if toggleOptionPageCount > 1 then
			MainManagerToggleOptionsPrev:Show()
			if (Main.ManagerToggleOptionPage or 1) > 1 then
				MainManagerToggleOptionsPrev:Enable()
			else
				MainManagerToggleOptionsPrev:Disable()
			end
		else
			MainManagerToggleOptionsPrev:Hide()
		end
	end

	if MainManagerToggleOptionsNext then
		if toggleOptionPageCount > 1 then
			MainManagerToggleOptionsNext:Show()
			if (Main.ManagerToggleOptionPage or 1) < toggleOptionPageCount then
				MainManagerToggleOptionsNext:Enable()
			else
				MainManagerToggleOptionsNext:Disable()
			end
		else
			MainManagerToggleOptionsNext:Hide()
		end
	end

	if MainManagerNumberOptionsPageText then
		if numberOptionPageCount > 1 then
			MainManagerNumberOptionsPageText:SetText(format("Page %d / %d", Main.ManagerNumberOptionPage or 1, numberOptionPageCount))
			MainManagerNumberOptionsPageText:Show()
		else
			MainManagerNumberOptionsPageText:Hide()
		end
	end

	if MainManagerNumberOptionsPrev then
		if numberOptionPageCount > 1 then
			MainManagerNumberOptionsPrev:Show()
			if (Main.ManagerNumberOptionPage or 1) > 1 then
				MainManagerNumberOptionsPrev:Enable()
			else
				MainManagerNumberOptionsPrev:Disable()
			end
		else
			MainManagerNumberOptionsPrev:Hide()
		end
	end

	if MainManagerNumberOptionsNext then
		if numberOptionPageCount > 1 then
			MainManagerNumberOptionsNext:Show()
			if (Main.ManagerNumberOptionPage or 1) < numberOptionPageCount then
				MainManagerNumberOptionsNext:Enable()
			else
				MainManagerNumberOptionsNext:Disable()
			end
		else
			MainManagerNumberOptionsNext:Hide()
		end
	end

	for i = 1, Main.ManagerOptionSlotCount do
		optionToggle = getglobal("MainManagerOptionToggle" .. i)
		optionModule, option = Main_GetManagerToggleOption(i)

		if optionToggle then
			if optionModule and option then
				local optionDisabled = Main_IsManagerOptionDisabled(optionModule, option)
				optionLabel = getglobal(optionToggle:GetName() .. "Text")
				if optionLabel then
					optionLabel:SetText(option.label or option.key or "Option")
					if optionLabel.SetWidth then
						optionLabel:SetWidth(184)
					end
					if optionLabel.SetJustifyH then
						optionLabel:SetJustifyH("LEFT")
					end
					if optionDisabled then
						optionLabel:SetTextColor(0.5, 0.5, 0.5)
					else
						optionLabel:SetTextColor(1, 0.82, 0)
					end
				end

				if Main_GetManagerBoolSetting(option.key, option.defaultValue) then
					optionToggle:SetChecked(1)
				else
					optionToggle:SetChecked(0)
				end
				if optionDisabled then
					optionToggle:Disable()
				else
					optionToggle:Enable()
				end
				optionToggle:Show()
			else
				optionToggle:Hide()
			end
		end
	end

	for i = 1, Main.ManagerNumberSlotCount do
		optionFrame = getglobal("MainManagerNumberOption" .. i)
		optionModule, option = Main_GetManagerNumberOption(i)

		if optionFrame then
			if optionModule and option then
				local optionDisabled = Main_IsManagerOptionDisabled(optionModule, option)
				optionLabel = getglobal(optionFrame:GetName() .. "Label")
				valueLabel = getglobal(optionFrame:GetName() .. "Value")
				slider = getglobal(optionFrame:GetName() .. "Slider")
				optionValue = Main_GetManagerNumberSetting(option.key, option.defaultValue or 0)

				if optionLabel then
					optionLabel:SetText(option.label or option.key or "Value")
					if optionDisabled then
						optionLabel:SetTextColor(0.5, 0.5, 0.5)
					else
						optionLabel:SetTextColor(1, 0.82, 0)
					end
				end
				Main_SetManagerNumberOptionDisplay(i, option, optionValue)
				if slider then
					Main.ManagerSyncing = 1
					slider:SetMinMaxValues(option.minValue or 0, option.maxValue or 100)
					slider:SetValueStep(Main_ToNumber(option.step, 1) or 1)
					slider:SetValue(optionValue)
					Main.ManagerSyncing = nil
					if optionDisabled then
						slider:EnableMouse(0)
						slider:SetAlpha(0.4)
					else
						slider:EnableMouse(1)
						slider:SetAlpha(1)
					end
					slider:Show()
				end
				if valueLabel then
					if optionDisabled then
						valueLabel:SetTextColor(0.5, 0.5, 0.5)
					else
						valueLabel:SetTextColor(1, 0.82, 0)
					end
				end
				optionFrame:Show()
			else
				optionFrame:Hide()
			end
		end
	end

	Main_AdjustGameMenu()
end
