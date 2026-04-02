Main.Config = {
	backend = "session",
	moduleBits = {
		buff_durations = 0,
		instant_quest_text = 1,
		clock = 2,
		merged_bags = 3,
		target_distance = 4,
		tutorial_extend = 5,
		extended_stats = 6,
		reload_button = 7,
		talent_button = 8,
		chat_copy = 9,
		target_auras = 10,
		unit_frames = 11,
		client_tweaks = 12,
		action_bars = 13,
		class_portraits = 14,
		guild_frame = 15,
		always_track = 16,
		atlas_loot = 17,
	},
	defaults = {
		modules = {
			buff_durations = true,
			instant_quest_text = true,
			clock = false,
			merged_bags = true,
			target_distance = false,
			tutorial_extend = true,
			extended_stats = false,
			reload_button = true,
			talent_button = true,
			chat_copy = true,
			target_auras = true,
			unit_frames = true,
			client_tweaks = true,
			action_bars = true,
			class_portraits = true,
			guild_frame = true,
			always_track = false,
			atlas_loot = true,
		},
		settings = {
		},
	},
	booleanSettingBits = {
		buff_durations_blink_white = 0,
		clock_twenty_four_hour = 1,
		target_auras_show_numbers = 2,
		unitframes_alternative_style = 3,
		unitframes_statusbar_text = 5,
		unitframes_show_target_auras = 6,
		actionbars_alternative_style = 7,
		actionbars_hide_gryphons = 8,
		actionbars_show_talent_button = 9,
		client_auto_loot = 11,
	},
	booleanSettingDefaults = {
		buff_durations_blink_white = true,
		clock_twenty_four_hour = false,
		target_auras_show_numbers = false,
		unitframes_alternative_style = true,
		unitframes_statusbar_text = true,
		unitframes_show_target_auras = true,
		actionbars_alternative_style = true,
		actionbars_hide_gryphons = true,
		actionbars_show_talent_button = true,
		client_auto_loot = true,
	},
	numericSettingAliases = {
		actionbars_x_offset = "ax",
		clock_offset_hours = "co",
		clock_x = "cx",
		clock_y = "cy",
		clock_x_ratio = "xr",
		clock_y_ratio = "yr",
		unitframes_x_offset = "ux",
		unitframes_y_offset = "uy",
	},
	numericSettingDefaults = {
		actionbars_x_offset = 0,
		clock_offset_hours = 0,
		clock_x = nil,
		clock_y = nil,
		clock_x_ratio = nil,
		clock_y_ratio = nil,
		unitframes_x_offset = -250,
		unitframes_y_offset = 320,
	},
	numericSettingOrder = {
		"actionbars_x_offset",
		"clock_offset_hours",
		"clock_x",
		"clock_y",
		"clock_x_ratio",
		"clock_y_ratio",
		"unitframes_x_offset",
		"unitframes_y_offset",
	},
}

Main.Config.values = Main_CopyTable(Main.Config.defaults)
Main.Config.numericSettingKeysByAlias = {}
Main_ForEach(Main.Config.numericSettingAliases, function(key, alias)
	Main.Config.numericSettingKeysByAlias[alias] = key
end)

function Main.CopyConfigValues()
	return Main_CopyTable(Main.Config.values)
end

local function Main_ConfigIsValidSettingFragment(text, allowColon)
	local i
	local character

	if text == nil then
		return nil
	end

	text = Main_ToString(text)
	for i = 1, Main_StringLen(text) do
		character = Main_StringSub(text, i, i)
		if Main_StringFind(character, "[A-Za-z0-9]") then
		elseif character == "_" or character == "-" or character == "." then
		elseif allowColon and character == ":" then
		else
			return nil
		end
	end

	return text
end

local function Main_ConfigShouldPersistModule(moduleId)
	return moduleId ~= nil
end

local function Main_ConfigGetHighestSetBit(value)
	local highestBit
	local bitIndex

	value = Main_ToNumber(value, 0)
	if value <= 0 then
		return -1
	end

	highestBit = -1
	for bitIndex = 0, 63 do
		if Main_HasBit(value, bitIndex) then
			highestBit = bitIndex
		end
	end

	return highestBit
end

local function Main_ConfigParseBoolText(value)
	if value == nil then
		return nil
	end

	value = Main_StringLower(Main_ToString(value))
	if value == "1" or value == "true" or value == "yes" or value == "on" then
		return true
	end
	if value == "0" or value == "false" or value == "no" or value == "off" then
		return false
	end

	return nil
end

local function Main_ConfigGetBooleanSettingDefault(key)
	return Main.Config.booleanSettingDefaults[key] and true or false
end

local function Main_ConfigResolvePersistedSettingKey(persistedKey)
	local key

	key = Main.Config.numericSettingKeysByAlias[persistedKey]
	if key then
		return key, "number"
	end

	if Main.Config.numericSettingAliases[persistedKey] then
		return persistedKey, "number"
	end

	if Main.Config.booleanSettingBits[persistedKey] ~= nil then
		return persistedKey, "boolean"
	end

	return nil, nil
end

local function Main_ConfigApplyBooleanSettingValue(key, enabled)
	local defaultValue

	defaultValue = Main_ConfigGetBooleanSettingDefault(key)
	Main.SetBoolSetting(key, enabled and true or false, 1, defaultValue)
end

local function Main_ConfigApplyNumberSettingValue(key, value)
	Main.SetNumberSetting(key, value, 1, Main.Config.numericSettingDefaults[key])
end

function Main.BuildModuleMask()
	local mask
	local moduleId
	local bitIndex

	mask = 0
	Main_ForEach(Main.Config.defaults.modules, function(moduleId)
		bitIndex = Main.Config.moduleBits[moduleId]
		if bitIndex ~= nil and Main_ConfigShouldPersistModule(moduleId) then
			mask = Main_SetBit(mask, bitIndex, 1)
		end
	end)

	return mask
end

local function Main_ConfigBuildBooleanSettingFlags()
	local flags
	local mask
	local key
	local bitIndex

	flags = 0
	mask = 0
	Main_ForEach(Main.Config.booleanSettingBits, function(key, bitIndex)
		mask = Main_SetBit(mask, bitIndex, 1)
		if Main.GetBoolSetting(key, Main_ConfigGetBooleanSettingDefault(key)) then
			flags = Main_SetBit(flags, bitIndex, 1)
		end
	end)

	return flags, mask
end

function Main.GetConfiguredModuleEnabled(id)
	local value

	if not id then
		return nil
	end

	value = Main.Config.values.modules[id]
	if value == nil then
		value = Main.Config.defaults.modules[id]
	end

	return value
end

function Main.SetConfiguredModuleEnabled(id, enabled, skipSave)
	if not id then
		return
	end

	Main.Config.values.modules[id] = enabled and true or false

	if not skipSave then
		Main.SaveConfig()
	end
end

function Main.GetSetting(key, defaultValue)
	local value

	if not key then
		return defaultValue
	end

	value = Main.Config.values.settings[key]
	if value == nil or value == "" then
		return defaultValue
	end

	return value
end

function Main.SetSetting(key, value, skipSave)
	local safeKey
	local safeValue

	safeKey = Main_ConfigIsValidSettingFragment(key, nil)
	if not safeKey then
		return
	end

	if value == nil or value == "" then
		Main.Config.values.settings[safeKey] = nil
	else
		safeValue = Main_ConfigIsValidSettingFragment(value, 1)
		if not safeValue then
			return
		end
		Main.Config.values.settings[safeKey] = safeValue
	end

	if not skipSave then
		Main.SaveConfig()
	end
end

function Main.GetBoolSetting(key, defaultValue)
	local value

	value = Main.GetSetting(key, nil)
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

function Main.SetBoolSetting(key, enabled, skipSave, defaultValue)
	if defaultValue ~= nil and (enabled and true or false) == (defaultValue and true or false) then
		Main.SetSetting(key, nil, skipSave)
		return
	end

	Main.SetSetting(key, enabled and "1" or "0", skipSave)
end

function Main.GetNumberSetting(key, defaultValue)
	local value

	value = Main_ToNumber(Main.GetSetting(key, nil), nil)
	if value == nil then
		return defaultValue
	end

	return value
end

function Main.SetNumberSetting(key, value, skipSave, defaultValue)
	local numericValue
	local numericDefault
	local textValue

	numericValue = Main_ToNumber(value, nil)
	if numericValue == nil then
		return
	end

	numericDefault = Main_ToNumber(defaultValue, nil)
	if numericDefault ~= nil and numericValue == numericDefault then
		Main.SetSetting(key, nil, skipSave)
		return
	end

	if numericValue == floor(numericValue) then
		textValue = Main_ToString(floor(numericValue))
	else
		textValue = Main_ToString(numericValue)
	end

	Main.SetSetting(key, textValue, skipSave)
end

function Main.BuildModuleFlags()
	local flags
	local moduleId
	local bitIndex

	flags = 0

	Main_ForEach(Main.Config.defaults.modules, function(moduleId)
		bitIndex = Main.Config.moduleBits[moduleId]
		if bitIndex ~= nil and Main_ConfigShouldPersistModule(moduleId) and Main.GetConfiguredModuleEnabled(moduleId) then
			flags = Main_SetBit(flags, bitIndex, 1)
		end
	end)

	return flags
end

function Main.BuildSettingsPayload()
	local parts
	local count
	local settingFlags
	local settingMask
	local moduleMask
	local index
	local key
	local value
	local alias

	parts = {}
	count = 0

	moduleMask = Main.BuildModuleMask()
	settingFlags, settingMask = Main_ConfigBuildBooleanSettingFlags()

	-- The addon chat request has a tight payload budget, so booleans are packed into bitfields
	-- and only numeric overrides are emitted as key/value pairs.
	count = count + 1
	parts[count] = "mm=" .. Main_ToString(floor(moduleMask))
	count = count + 1
	parts[count] = "sm=" .. Main_ToString(floor(settingMask))
	count = count + 1
	parts[count] = "sf=" .. Main_ToString(floor(settingFlags))

	for index = 1, Main_ArrayCount(Main.Config.numericSettingOrder) do
		key = Main.Config.numericSettingOrder[index]
		alias = Main.Config.numericSettingAliases[key]
		value = Main_ConfigIsValidSettingFragment(Main.Config.values.settings[key], 1)
		if alias and value and value ~= "" then
			count = count + 1
			parts[count] = alias .. "=" .. value
		end
	end

	if count == 0 then
		return ""
	end

	return Main_ArrayJoin(parts, ";")
end

function Main.BuildRemoteConfigState()
	return Main.BuildModuleFlags(), Main.BuildSettingsPayload()
end

function Main.ApplyRemoteConfig(flags, settingsPayload)
	local moduleId
	local bitIndex
	local key
	local value
	local resolvedKey
	local resolvedType
	local segment
	local separatorStart
	local separatorEnd
	local equalsStart
	local equalsEnd
	local cursor
	local moduleMask
	local settingMask
	local settingFlags
	local highestLegacyModuleBit
	local parsedBooleanValue

	Main.Config.backend = "server"
	Main.Config.values = Main_CopyTable(Main.Config.defaults)

	if settingsPayload and settingsPayload ~= "" then
		cursor = 1
		while cursor <= Main_StringLen(settingsPayload) do
			separatorStart, separatorEnd = Main_StringFind(settingsPayload, ";", cursor)
			if separatorStart then
				segment = Main_StringSub(settingsPayload, cursor, separatorStart - 1)
				cursor = separatorEnd + 1
			else
				segment = Main_StringSub(settingsPayload, cursor)
				cursor = Main_StringLen(settingsPayload) + 1
			end

			equalsStart, equalsEnd = Main_StringFind(segment, "=")
			if equalsStart then
				key = Main_ConfigIsValidSettingFragment(Main_StringSub(segment, 1, equalsStart - 1), nil)
				value = Main_ConfigIsValidSettingFragment(Main_StringSub(segment, equalsEnd + 1), 1)
				if key and value and value ~= "" then
					if key == "mm" then
						moduleMask = Main_ToNumber(value, nil)
					elseif key == "sm" then
						settingMask = Main_ToNumber(value, nil)
					elseif key == "sf" then
						settingFlags = Main_ToNumber(value, nil)
					else
						resolvedKey, resolvedType = Main_ConfigResolvePersistedSettingKey(key)
						if resolvedType == "boolean" then
							parsedBooleanValue = Main_ConfigParseBoolText(value)
							if parsedBooleanValue ~= nil then
								Main_ConfigApplyBooleanSettingValue(resolvedKey, parsedBooleanValue)
							end
						elseif resolvedType == "number" then
							Main_ConfigApplyNumberSettingValue(resolvedKey, value)
						end
					end
				end
			end
		end
	end

	highestLegacyModuleBit = Main_ConfigGetHighestSetBit(flags)
	Main_ForEach(Main.Config.defaults.modules, function(moduleId)
		bitIndex = Main.Config.moduleBits[moduleId]
		if bitIndex == nil or not Main_ConfigShouldPersistModule(moduleId) then
			return
		end

		if moduleMask ~= nil then
			if Main_HasBit(moduleMask, bitIndex) then
				Main.Config.values.modules[moduleId] = Main_HasBit(flags, bitIndex) and true or false
			end
		elseif highestLegacyModuleBit >= bitIndex then
			Main.Config.values.modules[moduleId] = Main_HasBit(flags, bitIndex) and true or false
		end
	end)

	if settingFlags ~= nil then
		if settingMask == nil then
			settingMask = 0
			Main_ForEach(Main.Config.booleanSettingBits, function(key, bitIndex)
				settingMask = Main_SetBit(settingMask, bitIndex, 1)
			end)
		end

		Main_ForEach(Main.Config.booleanSettingBits, function(key, bitIndex)
			if Main_HasBit(settingMask, bitIndex) then
				Main_ConfigApplyBooleanSettingValue(key, Main_HasBit(settingFlags, bitIndex))
			end
		end)
	end

	if Main.ModulesInitialized and Main.ApplyConfiguredModuleStates then
		Main.ApplyConfiguredModuleStates(1, 1)
	end

	if Main.RefreshManager then
		Main.RefreshManager()
	end
end

function Main.RestoreConfigValues(snapshot, skipRefresh)
	if not snapshot then
		return
	end

	Main.Config.values = Main_CopyTable(snapshot)

	if Main.ModulesInitialized and Main.ApplyConfiguredModuleStates then
		Main.ApplyConfiguredModuleStates(1)
	end

	if not skipRefresh and Main.RefreshManager then
		Main.RefreshManager()
	end
end

function Main.SaveConfig()
	if Main.SuppressConfigSaves then
		return
	end

	if Main.Config.backend ~= "server" then
		return
	end

	if Main.API and Main.API.SaveConfig then
		Main.API:SaveConfig()
	end
end

function Main.IsSessionOnlyConfig()
	return Main.Config.backend ~= "server"
end
