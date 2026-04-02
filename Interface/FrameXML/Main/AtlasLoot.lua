local MainAtlasLoot = {
	name = "AtlasLoot",
	description = "Adds a basic Atlas browser with dungeon maps and loot buttons.",
}

local MAIN_ATLAS_LOOT_ID = "atlas_loot"
local MAIN_ATLAS_LOOT_FRAME_NAME = "MainAtlasFrame"
local MAIN_ATLAS_LOOT_BUTTON_NAME = "MainAtlasLootButton"
local MAIN_ATLAS_LOOT_MAX_BUTTONS = 8

local mainAtlasLootInstanceIndex = 1
local mainAtlasLootBossIndex = 1
local mainAtlasLootButtons = nil

local function MainAtlasLoot_RegisterSpecialFrame(frameName)
	local index

	if not UISpecialFrames or not frameName then
		return
	end

	for index = 1, Main_ArrayCount(UISpecialFrames) do
		if UISpecialFrames[index] == frameName then
			return
		end
	end

	Main_ArrayInsert(UISpecialFrames, frameName)
end

local function MainAtlasLoot_GetData()
	return MainAtlasLootData or {}
end

local function MainAtlasLoot_IsEnabled()
	return Main.IsModuleEnabled and Main.IsModuleEnabled(MAIN_ATLAS_LOOT_ID) and true or false
end

local function MainAtlasLoot_GetEntryHyperlink(entry)
	local fullLink
	local startPos
	local hStart

	if not entry then
		return nil
	end

	if entry.link then
		fullLink = entry.link
		startPos = string.find(fullLink, "|H")
		if startPos then
			startPos = startPos + 2
			hStart = string.find(fullLink, "|h", startPos)
			if hStart then
				return string.sub(fullLink, startPos, hStart - 1)
			end
		end
		return fullLink
	end

	if entry.id then
		return "item:" .. entry.id
	end

	return nil
end

local function MainAtlasLoot_GetEntryName(entry)
	local textStart
	local textEnd

	if not entry then
		return ""
	end

	if entry.name and entry.name ~= "" then
		return entry.name
	end

	if entry.text and entry.text ~= "" then
		return entry.text
	end

	if entry.link then
		textStart = string.find(entry.link, "|h%[")
		if textStart then
			textStart = textStart + 3
			textEnd = string.find(entry.link, "%]|h", textStart)
			if textEnd then
				return string.sub(entry.link, textStart, textEnd - 1)
			end
		end
	end

	if entry.id then
		return "Item " .. entry.id
	end

	return ""
end

local function MainAtlasLoot_GetCurrentInstance()
	local data

	data = MainAtlasLoot_GetData()
	return data[mainAtlasLootInstanceIndex]
end

local function MainAtlasLoot_GetCurrentBoss()
	local instance

	instance = MainAtlasLoot_GetCurrentInstance()
	if not instance or not instance.bosses then
		return nil
	end

	return instance.bosses[mainAtlasLootBossIndex]
end

local function MainAtlasLoot_NormalizeSelection()
	local data
	local instance
	local bossCount

	data = MainAtlasLoot_GetData()
	if Main_ArrayCount(data) <= 0 then
		mainAtlasLootInstanceIndex = 1
		mainAtlasLootBossIndex = 1
		return
	end

	if mainAtlasLootInstanceIndex < 1 then
		mainAtlasLootInstanceIndex = Main_ArrayCount(data)
	elseif mainAtlasLootInstanceIndex > Main_ArrayCount(data) then
		mainAtlasLootInstanceIndex = 1
	end

	instance = data[mainAtlasLootInstanceIndex]
	if not instance or not instance.bosses or Main_ArrayCount(instance.bosses) <= 0 then
		mainAtlasLootBossIndex = 1
		return
	end

	bossCount = Main_ArrayCount(instance.bosses)
	if mainAtlasLootBossIndex < 1 then
		mainAtlasLootBossIndex = bossCount
	elseif mainAtlasLootBossIndex > bossCount then
		mainAtlasLootBossIndex = 1
	end
end

local function MainAtlasLoot_UpdateSelectorState()
	local data
	local instance
	local boss
	local instanceCount
	local bossCount

	MainAtlasLoot_NormalizeSelection()
	data = MainAtlasLoot_GetData()
	instance = MainAtlasLoot_GetCurrentInstance()
	boss = MainAtlasLoot_GetCurrentBoss()
	instanceCount = Main_ArrayCount(data)
	bossCount = instance and instance.bosses and Main_ArrayCount(instance.bosses) or 0

	if MainAtlasInstanceText then
		MainAtlasInstanceText:SetText(instance and instance.name or "")
	end
	if MainAtlasBossText then
		MainAtlasBossText:SetText(boss and boss.name or "")
	end

	if MainAtlasInstancePrevButton then
		if instanceCount > 1 then
			MainAtlasInstancePrevButton:Enable()
			MainAtlasInstanceNextButton:Enable()
		else
			MainAtlasInstancePrevButton:Disable()
			MainAtlasInstanceNextButton:Disable()
		end
	end

	if MainAtlasBossPrevButton then
		if bossCount > 1 then
			MainAtlasBossPrevButton:Enable()
			MainAtlasBossNextButton:Enable()
		else
			MainAtlasBossPrevButton:Disable()
			MainAtlasBossNextButton:Disable()
		end
	end
end

local function MainAtlasLoot_SetLootButton(button, entry)
	local icon

	if not button then
		return
	end

	button.itemData = entry
	if not entry then
		SetItemButtonTexture(button, nil)
		button:Hide()
		return
	end

	icon = entry.icon
	SetItemButtonTexture(button, icon)
	SetItemButtonCount(button, 0)
	if SetItemButtonNormalTextureVertexColor then
		SetItemButtonNormalTextureVertexColor(button, 1, 1, 1)
	end
	button:Show()
end

local function MainAtlasLoot_UpdateDisplay()
	local instance
	local boss
	local loot
	local button
	local buttonIndex
	local entry
	local text
	local lootName

	MainAtlasLoot_UpdateSelectorState()
	instance = MainAtlasLoot_GetCurrentInstance()
	boss = MainAtlasLoot_GetCurrentBoss()

	if MainAtlasTitleText then
		if instance and instance.name then
			MainAtlasTitleText:SetText(instance.name)
		else
			MainAtlasTitleText:SetText("AtlasLoot")
		end
	end

	if MainAtlasMap then
		if instance and instance.texture then
			MainAtlasMap:SetTexture(instance.texture)
		else
			MainAtlasMap:SetTexture(nil)
		end
	end

	if MainAtlasInfoText then
		text = ""
		if instance and instance.location then
			text = text .. "Location: " .. instance.location
		end
		if boss and boss.name then
			if text ~= "" then
				text = text .. "\n\n"
			end
			text = text .. "Boss: " .. boss.name
		end
		if boss and boss.loot and Main_ArrayCount(boss.loot) > 0 then
			text = text .. "\n\nLoot:"
			for buttonIndex = 1, Main_ArrayCount(boss.loot) do
				loot = boss.loot[buttonIndex]
				lootName = MainAtlasLoot_GetEntryName(loot)
				if lootName ~= "" then
					text = text .. "\n - " .. lootName
				end
			end
		end
		MainAtlasInfoText:SetText(text)
	end

	for buttonIndex = 1, MAIN_ATLAS_LOOT_MAX_BUTTONS do
		button = mainAtlasLootButtons and mainAtlasLootButtons[buttonIndex] or getglobal("MainAtlasLootButton" .. buttonIndex)
		entry = boss and boss.loot and boss.loot[buttonIndex] or nil
		MainAtlasLoot_SetLootButton(button, entry)
	end
end

local function MainAtlasLoot_UpdateLauncherState()
	if not MainAtlasLootButton then
		return
	end

	if MainAtlasLoot_IsEnabled() then
		MainAtlasLootButton:Show()
	else
		MainAtlasLootButton:Hide()
	end
end

local function MainAtlasLoot_Toggle()
	if not MainAtlasLoot_IsEnabled() then
		Main_Print("AtlasLoot is disabled.")
		return
	end

	Main_ToggleUIPanel(MainAtlasFrame)
end

local function MainAtlasLoot_RaiseTooltipFrame(frame)
	if not frame then
		return
	end

	if frame.SetFrameStrata then
		frame:SetFrameStrata("TOOLTIP")
	end
	if frame.Raise then
		frame:Raise()
	end
end

local function MainAtlasLoot_RegisterSlashCommand()
	SlashCmdList = SlashCmdList or {}
	SlashCmdList.MAINATLASLOOT = function()
		MainAtlasLoot_Toggle()
	end
	SLASH_MAINATLASLOOT1 = "/atlas"
	SLASH_MAINATLASLOOT2 = "/atlasloot"
end

function MainAtlasFrame_OnLoad()
	local index

	mainAtlasLootButtons = {}
	for index = 1, MAIN_ATLAS_LOOT_MAX_BUTTONS do
		mainAtlasLootButtons[index] = getglobal("MainAtlasLootButton" .. index)
	end

	if MainAtlasInstancePrevButton and MainAtlasInstancePrevButton.SetText then
		MainAtlasInstancePrevButton:SetText("<")
	end
	if MainAtlasInstanceNextButton and MainAtlasInstanceNextButton.SetText then
		MainAtlasInstanceNextButton:SetText(">")
	end
	if MainAtlasBossPrevButton and MainAtlasBossPrevButton.SetText then
		MainAtlasBossPrevButton:SetText("<")
	end
	if MainAtlasBossNextButton and MainAtlasBossNextButton.SetText then
		MainAtlasBossNextButton:SetText(">")
	end

	if MainAtlasInfoText and MainAtlasInfoText.SetTextHeight then
		MainAtlasInfoText:SetTextHeight(15)
	end
end

function MainAtlasFrame_OnShow()
	MainAtlasLoot_UpdateDisplay()
end

function MainAtlasCloseButton_OnClick()
	HideUIPanel(MainAtlasFrame)
end

function MainAtlasInstancePrevButton_OnClick()
	mainAtlasLootInstanceIndex = mainAtlasLootInstanceIndex - 1
	mainAtlasLootBossIndex = 1
	MainAtlasLoot_UpdateDisplay()
end

function MainAtlasInstanceNextButton_OnClick()
	mainAtlasLootInstanceIndex = mainAtlasLootInstanceIndex + 1
	mainAtlasLootBossIndex = 1
	MainAtlasLoot_UpdateDisplay()
end

function MainAtlasBossPrevButton_OnClick()
	mainAtlasLootBossIndex = mainAtlasLootBossIndex - 1
	MainAtlasLoot_UpdateDisplay()
end

function MainAtlasBossNextButton_OnClick()
	mainAtlasLootBossIndex = mainAtlasLootBossIndex + 1
	MainAtlasLoot_UpdateDisplay()
end

function MainAtlasLootButton_OnClick()
	local hyperlink
	local chatLink
	local entry

	entry = this and this.itemData or nil
	if not entry then
		return
	end

	hyperlink = MainAtlasLoot_GetEntryHyperlink(entry)
	if not hyperlink then
		return
	end

	chatLink = entry.link or hyperlink

	if IsShiftKeyDown and IsShiftKeyDown() and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
		ChatFrameEditBox:Insert(chatLink)
	elseif SetItemRef then
		SetItemRef(hyperlink)
		MainAtlasLoot_RaiseTooltipFrame(ItemRefTooltip)
	end
end

function MainAtlasLootButton_OnEnter()
	local hyperlink

	if not this or not this.itemData then
		return
	end

	hyperlink = MainAtlasLoot_GetEntryHyperlink(this.itemData)
	if not hyperlink or not GameTooltip then
		return
	end

	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink(hyperlink)
end

function MainAtlasLootButton_OnLeave()
	if GameTooltip then
		GameTooltip:Hide()
	end
end

function MainAtlasLootLauncherButton_OnClick()
	MainAtlasLoot_Toggle()
end

function MainAtlasLootLauncherButton_OnEnter()
	if not GameTooltip then
		return
	end

	GameTooltip:SetOwner(this, "ANCHOR_LEFT")
	GameTooltip:SetText("AtlasLoot", 1.0, 1.0, 1.0)
	GameTooltip:AddLine("Click to open or close Atlas.")
	GameTooltip:Show()
end

function MainAtlasLootLauncherButton_OnLeave()
	if GameTooltip then
		GameTooltip:Hide()
	end
end

function MainAtlasLoot:Init()
	MainAtlasLoot_RegisterSpecialFrame(MAIN_ATLAS_LOOT_FRAME_NAME)
	MainAtlasLoot_RegisterSlashCommand()
	MainAtlasLoot_UpdateLauncherState()
end

function MainAtlasLoot:Enable()
	MainAtlasLoot_UpdateLauncherState()
end

function MainAtlasLoot:Disable()
	if MainAtlasFrame and MainAtlasFrame:IsVisible() then
		HideUIPanel(MainAtlasFrame)
	end
	MainAtlasLoot_UpdateLauncherState()
end

function MainAtlasLoot:ApplyConfig()
	MainAtlasLoot_UpdateLauncherState()
end

function MainAtlasLoot:OnUILayoutChanged()
	MainAtlasLoot_UpdateLauncherState()
end

Main.RegisterModule(MAIN_ATLAS_LOOT_ID, MainAtlasLoot)
