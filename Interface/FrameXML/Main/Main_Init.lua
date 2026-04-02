-- Main is a clean rewrite of the legacy custom UI suite in this repository.
Main = Main or {}
Main.Title = "Main"
Main.Version = "0.1.0"
Main.ManagerSlotCount = 17
Main.ManagerSlotMax = 17
Main.ManagerOptionSlotCount = 12
Main.ManagerNumberSlotCount = 4
Main.ManagerModuleSlotOrder = { 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 15, 16, 6, 7, 8, 17 }
Main.LayoutMonitorInterval = 0.25
Main.Modules = Main.Modules or {}
Main.ModuleOrder = Main.ModuleOrder or {}
Main.EventHandlers = Main.EventHandlers or {}

CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS or {
	["WARRIOR"] = {0, 0.25, 0, 0.25},
	["MAGE"] = {0.25, 0.49609375, 0, 0.25},
	["ROGUE"] = {0.49609375, 0.7421875, 0, 0.25},
	["DRUID"] = {0.7421875, 0.98828125, 0, 0.25},
	["HUNTER"] = {0, 0.25, 0.25, 0.5},
	["SHAMAN"] = {0.25, 0.49609375, 0.25, 0.5},
	["PRIEST"] = {0.49609375, 0.7421875, 0.25, 0.5},
	["WARLOCK"] = {0.7421875, 0.98828125, 0.25, 0.5},
	["PALADIN"] = {0, 0.25, 0.5, 0.75},
	["GM"] = {0.5, 0.73828125, 0.5, 0.75},
}

local mainOriginalToString = tostring
local mainOriginalToNumber = tonumber
local mainOriginalStringTable = string
local mainOriginalStringLen = string and string.len or nil
local mainOriginalStringSub = string and string.sub or nil
local mainOriginalStringFind = string and string.find or nil
local mainOriginalStringLower = string and string.lower or nil
local mainOriginalStringGSub = string and string.gsub or nil
local mainOriginalStringFormat = string and string.format or nil
local mainOriginalTableTable = table
local mainOriginalTableGetN = table and table.getn or nil
local mainOriginalTableSort = table and table.sort or nil
local mainOriginalTableInsert = table and table.insert or nil
local mainOriginalTableForEach = table and table.foreach or nil
local mainOriginalMathTable = math
local mainOriginalMathMod = math and math.mod or nil
local mainOriginalMathMin = math and math.min or nil
local mainOriginalMathMax = math and math.max or nil
local mainOriginalMathSqrt = math and math.sqrt or nil

function Main_Print(message)
	if not DEFAULT_CHAT_FRAME or not message then
		return
	end

	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Main:|r " .. message)
end

function Main_IsChecked(control)
	local checked

	if not control or not control.GetChecked then
		return nil
	end

	checked = control:GetChecked()
	if checked == 1 or checked == "1" or checked == true or checked == "true" then
		return 1
	end

	return nil
end

function Main_CopyTable(source)
	local copy = {}
	local nested

	if not source then
		return copy
	end

	Main_ForEach(source, function(key, value)
		if key == "modules" or key == "settings" or key == "moduleBits" then
			nested = {}
			Main_ForEach(value, function(nestedKey, nestedValue)
				nested[nestedKey] = nestedValue
			end)
			copy[key] = nested
		else
			copy[key] = value
		end
	end)

	return copy
end

function Main_ArrayCount(array)
	if not array then
		return 0
	end

	if getn then
		return getn(array)
	end

	if mainOriginalTableGetN then
		return mainOriginalTableGetN(array)
	end

	return 0
end

function Main_SecondsToTimeAbbrev(seconds)
	local value

	if not seconds then
		return ""
	end

	if seconds >= 86400 then
		value = ceil(seconds / 86400)
		return value .. "d"
	end

	if seconds >= 3600 then
		value = ceil(seconds / 3600)
		return value .. "h"
	end

	if seconds >= 60 then
		value = ceil(seconds / 60)
		return value .. "m"
	end

	return ceil(seconds) .. "s"
end

function Main_Mod(value, divisor)
	if mainOriginalMathMod then
		return mainOriginalMathMod(value, divisor)
	end

	return mod(value, divisor)
end

function Main_HasBit(value, bitIndex)
	local mask

	value = Main_ToNumber(value, 0)
	bitIndex = Main_ToNumber(bitIndex, 0)
	mask = 2 ^ bitIndex

	return Main_Mod(floor(value / mask), 2) == 1
end

function Main_SetBit(value, bitIndex, enabled)
	local mask
	local hasBit

	value = Main_ToNumber(value, 0)
	bitIndex = Main_ToNumber(bitIndex, 0)
	mask = 2 ^ bitIndex
	hasBit = Main_HasBit(value, bitIndex)

	if enabled and not hasBit then
		return value + mask
	end

	if not enabled and hasBit then
		return value - mask
	end

	return value
end

function Main_ForEach(source, callback)
	if not source or not callback then
		return
	end

	if foreach then
		foreach(source, callback)
		return
	end

	if mainOriginalTableForEach then
		mainOriginalTableForEach(source, callback)
	end
end

function Main_HasAnyEntries(source)
	local hasAny

	hasAny = nil
	Main_ForEach(source, function()
		hasAny = 1
	end)

	return hasAny
end

function Main_SortArray(values, compareFunc)
	if not values then
		return
	end

	if sort then
		sort(values, compareFunc)
	elseif mainOriginalTableSort then
		mainOriginalTableSort(values, compareFunc)
	end
end

function Main_ArrayInsert(values, value)
	local nextIndex

	if not values then
		return
	end

	if tinsert then
		tinsert(values, value)
		return
	end

	if mainOriginalTableInsert then
		mainOriginalTableInsert(values, value)
		return
	end

	nextIndex = Main_ArrayCount(values) + 1
	values[nextIndex] = value
end

function Main_ArrayJoin(values, separator)
	local result
	local index

	if not values then
		return ""
	end

	separator = separator or ""
	result = ""
	for index = 1, Main_ArrayCount(values) do
		if index > 1 then
			result = result .. separator
		end
		result = result .. Main_ToString(values[index])
	end

	return result
end

function Main_StringLen(text)
	if text == nil then
		return 0
	end

	if strlen then
		return strlen(text)
	end

	if mainOriginalStringLen then
		return mainOriginalStringLen(text)
	end

	return 0
end

function Main_StringSub(text, first, last)
	if not text then
		return ""
	end

	if strsub then
		return strsub(text, first, last)
	end

	if mainOriginalStringSub then
		return mainOriginalStringSub(text, first, last)
	end

	return text
end

function Main_StringFind(text, pattern, init, plain)
	if not text or not pattern then
		return nil
	end

	if strfind then
		return strfind(text, pattern, init, plain)
	end

	if mainOriginalStringFind then
		return mainOriginalStringFind(text, pattern, init, plain)
	end

	return nil
end

function Main_StringLower(text)
	if text == nil then
		return ""
	end

	if strlower then
		return strlower(text)
	end

	if mainOriginalStringLower then
		return mainOriginalStringLower(text)
	end

	return text
end

function Main_StringGSub(text, pattern, replacement)
	if text == nil then
		return ""
	end

	if gsub then
		return gsub(text, pattern, replacement)
	end

	if mainOriginalStringGSub then
		return mainOriginalStringGSub(text, pattern, replacement)
	end

	return text
end

function Main_StringTrim(text)
	text = Main_ToString(text)
	text = Main_StringGSub(text, "^%s+", "")
	text = Main_StringGSub(text, "%s+$", "")

	return text
end

function Main_ToString(value)
	if value == nil then
		return ""
	end

	if value == true then
		return "true"
	end

	if value == false then
		return "false"
	end

	if mainOriginalToString then
		return mainOriginalToString(value)
	end

	if format then
		return format("%s", value)
	end

	return value
end

function Main_ToNumber(value, defaultValue)
	local numberValue
	local textValue

	if value == nil or value == "" then
		return defaultValue
	end

	if value == true then
		return 1
	end

	if value == false then
		return 0
	end

	if mainOriginalToNumber then
		numberValue = mainOriginalToNumber(value)
		if numberValue ~= nil then
			return numberValue
		end
	end

	textValue = Main_StringTrim(value)
	if Main_StringFind(textValue, "^[-+]?%d+%.?%d*$") or Main_StringFind(textValue, "^[-+]?%d*%.%d+$") then
		return textValue + 0
	end

	return defaultValue
end

if not tostring then
	tostring = Main_ToString
end

if not tonumber then
	tonumber = function(value)
		return Main_ToNumber(value, nil)
	end
end

string = string or {}
if not string.len then
	string.len = Main_StringLen
end
if not string.sub then
	string.sub = Main_StringSub
end
if not string.find then
	string.find = Main_StringFind
end
if not string.lower then
	string.lower = Main_StringLower
end
if not string.gsub then
	string.gsub = Main_StringGSub
end
if not string.format and (mainOriginalStringFormat or format) then
	string.format = mainOriginalStringFormat or format
end

table = table or {}
if not table.getn and getn then
	table.getn = getn
end
if not table.sort and sort then
	table.sort = sort
end
if not table.insert and tinsert then
	table.insert = tinsert
end
if not table.foreach and foreach then
	table.foreach = foreach
end
if not table.concat then
	table.concat = Main_ArrayJoin
end

math = math or {}
if not math.mod and mod then
	math.mod = mod
end
if not math.min and min then
	math.min = min
end
if not math.max and max then
	math.max = max
end
if not math.sqrt and sqrt then
	math.sqrt = sqrt
end

function Main.RegisterEventHandler(eventName, ownerKey, handler)
	local handlers

	if not eventName or not ownerKey or not handler then
		return
	end

	handlers = Main.EventHandlers[eventName]
	if not handlers then
		handlers = {}
		Main.EventHandlers[eventName] = handlers
	end

	handlers[ownerKey] = handler

	if MainLoaderFrame and MainLoaderFrame.RegisterEvent then
		MainLoaderFrame:RegisterEvent(eventName)
	end
end

function Main.UnregisterEventHandler(eventName, ownerKey)
	local handlers
	local hasHandlers

	handlers = eventName and Main.EventHandlers[eventName] or nil
	if not handlers or not ownerKey then
		return
	end

	handlers[ownerKey] = nil
	hasHandlers = Main_HasAnyEntries(handlers)

	if not hasHandlers then
		Main.EventHandlers[eventName] = nil
		if MainLoaderFrame and MainLoaderFrame.UnregisterEvent and eventName ~= "PLAYER_ENTERING_WORLD" and eventName ~= "CHAT_MSG_CHANNEL" then
			MainLoaderFrame:UnregisterEvent(eventName)
		end
	end
end

function Main.DispatchEvent(eventName)
	local handlers
	local ownerKey
	local handler

	handlers = eventName and Main.EventHandlers[eventName] or nil
	if not handlers then
		return
	end

	Main_ForEach(handlers, function(ownerKey, handler)
		if handler then
			handler(eventName)
		end
	end)
end
