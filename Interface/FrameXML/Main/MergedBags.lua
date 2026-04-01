local MainMergedBags = {
	name = "Bagnon",
	description = "Replaces the stock inventory bags with one merged frame.",
}

local MAIN_MERGED_BAGS_ID = "merged_bags"
local MAIN_MERGED_BAGS_FRAME_NAME = "MainMergedBagsFrame"
local MAIN_MERGED_BAGS_BAG_IDS = { 0, 1, 2, 3, 4 }
local MAIN_MERGED_BAGS_COLUMNS = 8
local MAIN_MERGED_BAGS_ITEM_SIZE = 37
local MAIN_MERGED_BAGS_ITEM_SPACING = 3
local MAIN_MERGED_BAGS_SIDE_PADDING = 10
local MAIN_MERGED_BAGS_TOP_PADDING = 30
local MAIN_MERGED_BAGS_BOTTOM_PADDING = 12
local MAIN_MERGED_BAGS_MIN_WIDTH = 190
local MAIN_MERGED_BAGS_MIN_HEIGHT = 82
local MAIN_MERGED_BAGS_MAX_BAG_SLOTS = MAX_CONTAINER_ITEMS or 20

local mainMergedBagsVisibleCount = 0
local mainMergedBagsManualOpen = nil
local mainMergedBagsOriginals = {}
local mainMergedBagsOverridesInstalled = nil

local function MainMergedBags_GetFrame()
	return getglobal(MAIN_MERGED_BAGS_FRAME_NAME)
end

local function MainMergedBags_IsEnabled()
	return Main.IsModuleEnabled and Main.IsModuleEnabled(MAIN_MERGED_BAGS_ID) and true or false
end

local function MainMergedBags_IsControlledBag(bagId)
	bagId = Main_ToNumber(bagId, -999)
	return bagId >= 0 and bagId <= 4
end

local function MainMergedBags_CanOpen()
	local frame

	frame = MainMergedBags_GetFrame()
	if CanOpenPanels and not CanOpenPanels() and not (frame and frame:IsVisible()) then
		return nil
	end

	return 1
end

local function MainMergedBags_RegisterSpecialFrame(frameName)
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

local function MainMergedBags_GetBagFrame(bagId)
	return getglobal(MAIN_MERGED_BAGS_FRAME_NAME .. "Bag" .. bagId)
end

local function MainMergedBags_GetButton(bagId, slotId)
	return getglobal(MAIN_MERGED_BAGS_FRAME_NAME .. "Bag" .. bagId .. "Item" .. slotId)
end

local function MainMergedBags_CloseStockFrames()
	local index
	local frame
	local maxFrames

	maxFrames = NUM_CONTAINER_FRAMES or 16
	for index = 1, maxFrames do
		frame = getglobal("ContainerFrame" .. index)
		if frame and frame:IsVisible() then
			frame:Hide()
		end
	end
end

local function MainMergedBags_UpdateBagButtonChecks(isShown)
	local index
	local bagButton

	if MainMenuBarBackpackButton and MainMenuBarBackpackButton.SetChecked then
		MainMenuBarBackpackButton:SetChecked(isShown and 1 or 0)
	end

	for index = 0, 3 do
		bagButton = getglobal("CharacterBag" .. index .. "Slot")
		if bagButton and bagButton.SetChecked then
			if isShown and GetContainerNumSlots and GetContainerNumSlots(index + 1) > 0 then
				bagButton:SetChecked(1)
			else
				bagButton:SetChecked(0)
			end
		end
	end
end

local function MainMergedBags_UpdateItem(button)
	local bagId
	local slotId
	local texture
	local itemCount
	local locked
	local cooldown

	if not button then
		return
	end

	bagId = button:GetParent() and button:GetParent():GetID() or nil
	slotId = button:GetID()
	if bagId == nil or not slotId or not GetContainerItemInfo then
		return
	end

	texture, itemCount, locked = GetContainerItemInfo(bagId, slotId)
	SetItemButtonTexture(button, texture)
	SetItemButtonCount(button, itemCount)

	if locked then
		SetItemButtonTextureVertexColor(button, 0.5, 0.5, 0.5)
	else
		SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0)
	end

	if texture then
		if ContainerFrame_UpdateCooldown then
			ContainerFrame_UpdateCooldown(bagId, button)
		end
	else
		cooldown = getglobal(button:GetName() .. "Cooldown")
		if cooldown then
			cooldown:Hide()
		end
	end

	if SetItemButtonNormalTextureVertexColor then
		SetItemButtonNormalTextureVertexColor(button, 1, 1, 1)
	end
end

local function MainMergedBags_UpdateVisibleItems()
	local bagIndex
	local bagId
	local slotId
	local button

	for bagIndex = 1, Main_ArrayCount(MAIN_MERGED_BAGS_BAG_IDS) do
		bagId = MAIN_MERGED_BAGS_BAG_IDS[bagIndex]
		for slotId = 1, MAIN_MERGED_BAGS_MAX_BAG_SLOTS do
			button = MainMergedBags_GetButton(bagId, slotId)
			if button and button:IsShown() then
				MainMergedBags_UpdateItem(button)
			end
		end
	end
end

local function MainMergedBags_UpdateLayout()
	local frame
	local rows
	local usedColumns
	local width
	local height

	frame = MainMergedBags_GetFrame()
	if not frame then
		return
	end

	if mainMergedBagsVisibleCount > 0 then
		rows = ceil(mainMergedBagsVisibleCount / MAIN_MERGED_BAGS_COLUMNS)
		if mainMergedBagsVisibleCount < MAIN_MERGED_BAGS_COLUMNS then
			usedColumns = mainMergedBagsVisibleCount
		else
			usedColumns = MAIN_MERGED_BAGS_COLUMNS
		end
		width = (usedColumns * MAIN_MERGED_BAGS_ITEM_SIZE) + ((usedColumns - 1) * MAIN_MERGED_BAGS_ITEM_SPACING) + (MAIN_MERGED_BAGS_SIDE_PADDING * 2)
		height = (rows * MAIN_MERGED_BAGS_ITEM_SIZE) + ((rows - 1) * MAIN_MERGED_BAGS_ITEM_SPACING) + MAIN_MERGED_BAGS_TOP_PADDING + MAIN_MERGED_BAGS_BOTTOM_PADDING
	else
		width = MAIN_MERGED_BAGS_MIN_WIDTH
		height = MAIN_MERGED_BAGS_MIN_HEIGHT
	end

	if width < MAIN_MERGED_BAGS_MIN_WIDTH then
		width = MAIN_MERGED_BAGS_MIN_WIDTH
	end
	if height < MAIN_MERGED_BAGS_MIN_HEIGHT then
		height = MAIN_MERGED_BAGS_MIN_HEIGHT
	end

	frame:SetWidth(width)
	frame:SetHeight(height)
end

local function MainMergedBags_Generate()
	local frame
	local bagIndex
	local bagId
	local bagSize
	local slotId
	local button
	local visibleIndex
	local column
	local row

	frame = MainMergedBags_GetFrame()
	if not frame then
		return
	end

	visibleIndex = 0

	for bagIndex = 1, Main_ArrayCount(MAIN_MERGED_BAGS_BAG_IDS) do
		bagId = MAIN_MERGED_BAGS_BAG_IDS[bagIndex]
		bagSize = GetContainerNumSlots and GetContainerNumSlots(bagId) or 0
		bagSize = Main_ToNumber(bagSize, 0) or 0

		for slotId = 1, MAIN_MERGED_BAGS_MAX_BAG_SLOTS do
			button = MainMergedBags_GetButton(bagId, slotId)
			if button then
				if slotId <= bagSize then
					visibleIndex = visibleIndex + 1
					button:SetID(slotId)
					button:ClearAllPoints()
					column = Main_Mod(visibleIndex - 1, MAIN_MERGED_BAGS_COLUMNS)
					row = floor((visibleIndex - 1) / MAIN_MERGED_BAGS_COLUMNS)
						button:SetPoint(
							"TOPLEFT",
							MAIN_MERGED_BAGS_FRAME_NAME,
							"TOPLEFT",
							MAIN_MERGED_BAGS_SIDE_PADDING + (column * (MAIN_MERGED_BAGS_ITEM_SIZE + MAIN_MERGED_BAGS_ITEM_SPACING)),
							-(MAIN_MERGED_BAGS_TOP_PADDING + (row * (MAIN_MERGED_BAGS_ITEM_SIZE + MAIN_MERGED_BAGS_ITEM_SPACING)))
					)
					MainMergedBags_UpdateItem(button)
					button:Show()
				else
					button:Hide()
				end
			end
		end
	end

	mainMergedBagsVisibleCount = visibleIndex
	MainMergedBags_UpdateLayout()
end

local function MainMergedBags_Open(automatic)
	local frame

	if not MainMergedBags_CanOpen() then
		return
	end

	frame = MainMergedBags_GetFrame()
	if not frame then
		return
	end

	MainMergedBags_CloseStockFrames()
	MainMergedBags_Generate()
	frame:Show()
	if not automatic then
		mainMergedBagsManualOpen = 1
	end
end

local function MainMergedBags_Close(automatic)
	local frame

	frame = MainMergedBags_GetFrame()
	if not frame then
		mainMergedBagsManualOpen = nil
		return
	end

	if automatic and mainMergedBagsManualOpen then
		return
	end

	mainMergedBagsManualOpen = nil
	frame:Hide()
end

local function MainMergedBags_Toggle()
	local frame

	frame = MainMergedBags_GetFrame()
	if frame and frame:IsVisible() then
		MainMergedBags_Close()
	else
		MainMergedBags_Open()
	end
end

local function MainMergedBags_InstallOverrides()
	if mainMergedBagsOverridesInstalled then
		return
	end

	mainMergedBagsOriginals.ToggleBag = ToggleBag
	mainMergedBagsOriginals.ToggleBackpack = ToggleBackpack
	mainMergedBagsOriginals.OpenBag = OpenBag
	mainMergedBagsOriginals.CloseBag = CloseBag
	mainMergedBagsOriginals.IsBagOpen = IsBagOpen
	mainMergedBagsOriginals.OpenBackpack = OpenBackpack
	mainMergedBagsOriginals.CloseBackpack = CloseBackpack
	mainMergedBagsOriginals.OpenAllBags = OpenAllBags
	mainMergedBagsOriginals.CloseAllBags = CloseAllBags

	function ToggleBag(id)
		if MainMergedBags_IsEnabled() and MainMergedBags_IsControlledBag(id) then
			MainMergedBags_Toggle()
			return
		end

		if mainMergedBagsOriginals.ToggleBag then
			mainMergedBagsOriginals.ToggleBag(id)
		end
	end

	function ToggleBackpack()
		if MainMergedBags_IsEnabled() then
			MainMergedBags_Toggle()
			return
		end

		if mainMergedBagsOriginals.ToggleBackpack then
			mainMergedBagsOriginals.ToggleBackpack()
		end
	end

	function OpenBag(id)
		if MainMergedBags_IsEnabled() and MainMergedBags_IsControlledBag(id) then
			MainMergedBags_Open(1)
			return
		end

		if mainMergedBagsOriginals.OpenBag then
			mainMergedBagsOriginals.OpenBag(id)
		end
	end

	function CloseBag(id)
		if MainMergedBags_IsEnabled() and MainMergedBags_IsControlledBag(id) then
			MainMergedBags_Close(1)
			return
		end

		if mainMergedBagsOriginals.CloseBag then
			mainMergedBagsOriginals.CloseBag(id)
		end
	end

	function IsBagOpen(id)
		local frame

		if MainMergedBags_IsEnabled() and MainMergedBags_IsControlledBag(id) then
			frame = MainMergedBags_GetFrame()
			if frame and frame:IsVisible() then
				return 1
			end
			return nil
		end

		if mainMergedBagsOriginals.IsBagOpen then
			return mainMergedBagsOriginals.IsBagOpen(id)
		end

		return nil
	end

	function OpenBackpack()
		if MainMergedBags_IsEnabled() then
			MainMergedBags_Open(1)
			return
		end

		if mainMergedBagsOriginals.OpenBackpack then
			mainMergedBagsOriginals.OpenBackpack()
		end
	end

	function CloseBackpack()
		if MainMergedBags_IsEnabled() then
			MainMergedBags_Close(1)
			return
		end

		if mainMergedBagsOriginals.CloseBackpack then
			mainMergedBagsOriginals.CloseBackpack()
		end
	end

	function OpenAllBags(forceOpen)
		if MainMergedBags_IsEnabled() then
			if forceOpen then
				MainMergedBags_Open(1)
			else
				MainMergedBags_Toggle()
			end
			return
		end

		if mainMergedBagsOriginals.OpenAllBags then
			mainMergedBagsOriginals.OpenAllBags(forceOpen)
		end
	end

	function CloseAllBags()
		if MainMergedBags_IsEnabled() then
			MainMergedBags_Close()
			return
		end

		if mainMergedBagsOriginals.CloseAllBags then
			mainMergedBagsOriginals.CloseAllBags()
		end
	end

	mainMergedBagsOverridesInstalled = 1
end

local function MainMergedBags_OnEnteringWorld()
	local frame

	if not MainMergedBags_IsEnabled() then
		return
	end

	frame = MainMergedBags_GetFrame()
	MainMergedBags_CloseStockFrames()
	if frame and frame:IsVisible() then
		MainMergedBags_Generate()
	end
end

local function MainMergedBags_OnBagUpdate()
	local frame

	if not MainMergedBags_IsEnabled() then
		return
	end

	frame = MainMergedBags_GetFrame()
	if frame and frame:IsVisible() then
		MainMergedBags_Generate()
	end
end

local function MainMergedBags_OnCooldownOrLockChanged()
	local frame

	if not MainMergedBags_IsEnabled() then
		return
	end

	frame = MainMergedBags_GetFrame()
	if frame and frame:IsVisible() then
		MainMergedBags_UpdateVisibleItems()
	end
end

function MainMergedBagsFrame_OnShow()
	MainMergedBags_UpdateBagButtonChecks(1)
	if PlaySound then
		PlaySound("igBackPackOpen")
	end
end

function MainMergedBagsFrame_OnHide()
	MainMergedBags_UpdateBagButtonChecks(nil)
	if PlaySound then
		PlaySound("igBackPackClose")
	end
end

function MainMergedBagsCloseButton_OnClick()
	MainMergedBags_Close()
end

function MainMergedBags:Init()
	MainMergedBags_RegisterSpecialFrame(MAIN_MERGED_BAGS_FRAME_NAME)
	MainMergedBags_InstallOverrides()
	Main.RegisterEventHandler("PLAYER_ENTERING_WORLD", "merged_bags_entering_world", MainMergedBags_OnEnteringWorld)
	Main.RegisterEventHandler("BAG_UPDATE", "merged_bags_bag_update", MainMergedBags_OnBagUpdate)
	Main.RegisterEventHandler("BAG_UPDATE_COOLDOWN", "merged_bags_cooldown", MainMergedBags_OnCooldownOrLockChanged)
	Main.RegisterEventHandler("ITEM_LOCK_CHANGED", "merged_bags_lock", MainMergedBags_OnCooldownOrLockChanged)
end

function MainMergedBags:Enable()
	local frame

	frame = MainMergedBags_GetFrame()
	MainMergedBags_CloseStockFrames()
	if frame and frame:IsVisible() then
		MainMergedBags_Generate()
	end
end

function MainMergedBags:Disable()
	MainMergedBags_Close()
end

function MainMergedBags:ApplyConfig()
	if MainMergedBags_IsEnabled() then
		self:Enable()
	else
		self:Disable()
	end
end

Main.RegisterModule(MAIN_MERGED_BAGS_ID, MainMergedBags)
