local MainTargetAuras = {
	name = "Target Auras",
	description = "Shows tracked target aura icons from the shared addon API.",
	managerHidden = 1,
	options = {
		{
			type = "toggle",
			key = "unitframes_show_target_auras",
			label = "Show target auras",
			defaultValue = true,
			managerOrder = 4,
			requiresModule = false,
		},
		{
			type = "toggle",
			key = "target_auras_show_numbers",
			label = "Show aura timer numbers",
			defaultValue = false,
			managerOrder = 5,
			requiresModule = false,
		},
	},
}

local MAIN_TARGET_AURAS_UPDATE_RATE = 0.2
local MAIN_TARGET_AURAS_ACTIVE_REFRESH_RATE = 3
local MAIN_TARGET_AURAS_IDLE_REFRESH_RATE = 8
local MAIN_TARGET_AURAS_MAX_BUTTONS = 16
local MAIN_TARGET_AURAS_DEFAULT_ICON = "Interface\\Icons\\Temp"

local mainTargetAurasUnitGainsBuff = AURAADDEDOTHERHELPFUL and Main_StringGSub(format(AURAADDEDOTHERHELPFUL, "", ""), "%.", "") or nil
local mainTargetAurasUnitGainsDebuff = AURAADDEDOTHERHARMFUL and Main_StringGSub(format(AURAADDEDOTHERHARMFUL, "", ""), "%.", "") or nil
local mainTargetAurasUnitLosesAura = AURAREMOVEDOTHER and Main_StringGSub(format(AURAREMOVEDOTHER, "", ""), "%.", "") or nil
local mainTargetAurasUnitChangesAura = AURACHANGEDOTHER and Main_StringGSub(format(AURACHANGEDOTHER, "", "", ""), "%.", "") or nil
local mainTargetAurasPlayerGainsBuff = AURAADDEDSELFHELPFUL and Main_StringGSub(format(AURAADDEDSELFHELPFUL, ""), "%.", "") or nil
local mainTargetAurasPlayerGainsDebuff = AURAADDEDSELFHARMFUL and Main_StringGSub(format(AURAADDEDSELFHARMFUL, ""), "%.", "") or nil
local mainTargetAurasPlayerLosesAura = AURAREMOVEDSELF and Main_StringGSub(format(AURAREMOVEDSELF, ""), "%.", "") or nil
local mainTargetAurasPlayerChangesAura = AURACHANGEDSELF and Main_StringGSub(format(AURACHANGEDSELF, "", ""), "%.", "") or nil

local function MainTargetAuras_GetRemainingSeconds(aura)
	local remaining

	if not aura or not aura.expiresAt then
		return nil
	end

	remaining = aura.expiresAt - (GetTime and GetTime() or 0)
	if remaining < 0 then
		return 0
	end

	return remaining
end

local function MainTargetAuras_CollectEntries()
	local source
	local entries
	local count
	local index
	local aura

	source = Main.API and Main.API.GetUnitAuras and Main.API:GetUnitAuras("target") or nil
	entries = {}
	count = 0
	if not source then
		return entries
	end

	for index = 1, Main_ArrayCount(source) do
		aura = source[index]
		if aura and (aura.remainingMs == nil or aura.remainingMs < 0 or MainTargetAuras_GetRemainingSeconds(aura) > 0) then
			count = count + 1
			entries[count] = aura
		end
	end

	Main_SortArray(entries, function(left, right)
		local leftHarmful
		local rightHarmful
		local leftExpiresAt
		local rightExpiresAt

		leftHarmful = left and left.harmful and 1 or 0
		rightHarmful = right and right.harmful and 1 or 0
		if leftHarmful ~= rightHarmful then
			return leftHarmful > rightHarmful
		end

		leftExpiresAt = left and left.expiresAt or 999999999
		rightExpiresAt = right and right.expiresAt or 999999999
		if leftExpiresAt == rightExpiresAt then
			return (left and left.name or "") < (right and right.name or "")
		end

		return leftExpiresAt < rightExpiresAt
	end)

	return entries
end

local function MainTargetAuras_GetButton(index)
	return getglobal("MainTargetAura" .. index)
end

local function MainTargetAuras_GetCountFontString(button)
	local count

	if not button or not button.GetName then
		return nil
	end

	count = getglobal(button:GetName() .. "Count")
	if count then
		return count
	end

	return getglobal(button:GetName() .. "CountFrameCount")
end

local function MainTargetAuras_GetBorder(button)
	if not button or not button.GetName then
		return nil
	end

	return getglobal(button:GetName() .. "Border")
end

local function MainTargetAuras_IsCountEnabled()
	return Main.GetBoolSetting and Main.GetBoolSetting("target_auras_show_numbers", false)
end

local function MainTargetAuras_ShouldShow()
	return Main.IsModuleEnabled("target_auras") and Main.GetBoolSetting("unitframes_show_target_auras", true)
end

local function MainTargetAuras_GetRefreshRate()
	local entries

	if not MainTargetAuras_ShouldShow() then
		return nil
	end

	entries = Main.API and Main.API.GetUnitAuras and Main.API:GetUnitAuras("target") or nil
	if entries and Main_ArrayCount(entries) > 0 then
		return MAIN_TARGET_AURAS_ACTIVE_REFRESH_RATE
	end

	return MAIN_TARGET_AURAS_IDLE_REFRESH_RATE
end

local function MainTargetAuras_FormatCountText(remainingSeconds)
	if not remainingSeconds or remainingSeconds <= 0 then
		return ""
	end

	if remainingSeconds >= 86400 then
		return ceil(remainingSeconds / 86400) .. "d"
	end
	if remainingSeconds >= 3600 then
		return ceil(remainingSeconds / 3600) .. "h"
	end
	if remainingSeconds >= 60 then
		return tostring(ceil(remainingSeconds / 60))
	end

	return tostring(ceil(remainingSeconds))
end

local function MainTargetAuras_ShowTooltip(button, resetOwner)
	local aura
	local remainingSeconds

	aura = button and button.aura or nil
	if not aura then
		return
	end

	if resetOwner then
		GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT")
	end
	if GameTooltip.ClearLines then
		GameTooltip:ClearLines()
	end
	GameTooltip:SetText(aura.name or "", 1.0, 1.0, 1.0)
	if aura.harmful then
		GameTooltip:AddLine("Debuff", "", 1.0, 0.2, 0.2)
	else
		GameTooltip:AddLine("Buff", "", 0.2, 0.8, 1.0)
	end
	remainingSeconds = MainTargetAuras_GetRemainingSeconds(aura)
	if remainingSeconds and remainingSeconds > 0 then
		GameTooltip:AddLine(Main_SecondsToTimeAbbrev(remainingSeconds) .. " remaining", "", 1.0, 0.82, 0.0)
	end
	GameTooltip:Show()
end

local function MainTargetAuras_ShouldResetCooldown(previousAura, aura)
	if not aura then
		return nil
	end

	if not previousAura then
		return 1
	end

	if previousAura.name ~= aura.name or previousAura.harmful ~= aura.harmful or previousAura.iconPath ~= aura.iconPath then
		return 1
	end

	if not previousAura.expiresAt or not aura.expiresAt then
		return 1
	end

	if math.abs(previousAura.expiresAt - aura.expiresAt) > 1.2 then
		return 1
	end

	return nil
end

local function MainTargetAuras_SetButton(button, aura)
	local previousAura
	local icon
	local cooldown
	local count
	local border
	local durationSeconds
	local remainingSeconds

	if not button then
		return
	end

	previousAura = button.aura
	button.aura = aura
	icon = getglobal(button:GetName() .. "Icon")
	cooldown = getglobal(button:GetName() .. "Cooldown")
	count = MainTargetAuras_GetCountFontString(button)
	border = MainTargetAuras_GetBorder(button)

	if icon then
		icon:SetTexture((aura and aura.iconPath) or MAIN_TARGET_AURAS_DEFAULT_ICON)
	end

	if aura then
		remainingSeconds = MainTargetAuras_GetRemainingSeconds(aura)
		durationSeconds = aura.remainingMs and aura.remainingMs > 0 and (aura.remainingMs / 1000) or nil
		if cooldown and remainingSeconds and remainingSeconds > 0 and MainTargetAuras_ShouldResetCooldown(previousAura, aura) then
			CooldownFrame_SetTimer(cooldown, aura.receivedAt or (GetTime and GetTime() or 0), durationSeconds or remainingSeconds, 1)
		elseif cooldown then
			if not previousAura or not aura or aura.name ~= previousAura.name then
				CooldownFrame_SetTimer(cooldown, 0, 0, 0)
			end
		end

		if border then
			if aura.harmful then
				border:Show()
			else
				border:Hide()
			end
		end

		if count then
			if MainTargetAuras_IsCountEnabled() and remainingSeconds and remainingSeconds > 0 then
				count:SetText(MainTargetAuras_FormatCountText(remainingSeconds))
				if count.SetTextColor then
					count:SetTextColor(1.0, 0.82, 0.0)
				end
				count:Show()
			else
				count:SetText("")
				count:Hide()
			end
		end

		button:Show()
	else
		if cooldown then
			CooldownFrame_SetTimer(cooldown, 0, 0, 0)
		end
		if border then
			border:Hide()
		end
		if count then
			count:SetText("")
			count:Hide()
		end
		button:Hide()
	end
end

local function MainTargetAuras_UpdateDisplay()
	local entries
	local index

	if not Main.IsModuleEnabled("target_auras") then
		MainTargetAurasFrame:Hide()
		return
	end

	if not MainTargetAuras_ShouldShow() then
		MainTargetAurasFrame:Hide()
		return
	end

	if not TargetFrame or not TargetFrame:IsVisible() or not UnitExists("target") or
		((UnitIsDead and UnitIsDead("target")) or (UnitHealth and UnitHealth("target") == 0)) then
		MainTargetAurasFrame:Hide()
		return
	end

	entries = MainTargetAuras_CollectEntries()
	for index = 1, MAIN_TARGET_AURAS_MAX_BUTTONS do
		MainTargetAuras_SetButton(MainTargetAuras_GetButton(index), entries[index])
	end

	MainTargetAurasFrame:Show()
end

local function MainTargetAuras_RequestSnapshot(force)
	if not MainTargetAuras_ShouldShow() or not Main.API or not Main.API.RequestUnitAuras or not UnitExists or not UnitExists("target") then
		return
	end

	Main.API:RequestUnitAuras("target", force)
end

local function MainTargetAuras_ExtractTargetName(message, marker, capturePattern, targetCaptureIndex)
	local payload
	local firstValue
	local secondValue
	local thirdValue

	if not marker or not message or not Main_StringFind(message, marker) then
		return nil
	end

	payload = Main_StringGSub(message, marker, "`")
	payload = Main_StringGSub(payload, "%.$", "")
	_, _, firstValue, secondValue, thirdValue = Main_StringFind(payload, capturePattern)

	if targetCaptureIndex == 1 then
		return firstValue
	end
	if targetCaptureIndex == 2 then
		return secondValue
	end

	return thirdValue
end

local function MainTargetAuras_CombatMessageAffectsCurrentTarget(message)
	local currentTarget
	local targetName

	if not message or not UnitExists or not UnitExists("target") then
		return nil
	end

	currentTarget = UnitName and UnitName("target") or nil
	if not currentTarget or currentTarget == "" then
		return nil
	end

	targetName = MainTargetAuras_ExtractTargetName(message, mainTargetAurasUnitGainsBuff, "^(.-)`(.-)$", 1)
	if targetName == currentTarget then
		return 1
	end

	targetName = MainTargetAuras_ExtractTargetName(message, mainTargetAurasUnitGainsDebuff, "^(.-)`(.-)$", 1)
	if targetName == currentTarget then
		return 1
	end

	targetName = MainTargetAuras_ExtractTargetName(message, mainTargetAurasUnitLosesAura, "^(.-)`(.-)$", 2)
	if targetName == currentTarget then
		return 1
	end

	targetName = MainTargetAuras_ExtractTargetName(message, mainTargetAurasUnitChangesAura, "^(.-)`(.-)`(.-)$", 1)
	if targetName == currentTarget then
		return 1
	end

	return nil
end

local function MainTargetAuras_CombatMessageAffectsPlayer(message)
	if not message then
		return nil
	end

	if mainTargetAurasPlayerGainsBuff and Main_StringFind(message, mainTargetAurasPlayerGainsBuff) then
		return 1
	end
	if mainTargetAurasPlayerGainsDebuff and Main_StringFind(message, mainTargetAurasPlayerGainsDebuff) then
		return 1
	end
	if mainTargetAurasPlayerLosesAura and Main_StringFind(message, mainTargetAurasPlayerLosesAura) then
		return 1
	end
	if mainTargetAurasPlayerChangesAura and Main_StringFind(message, mainTargetAurasPlayerChangesAura) then
		return 1
	end

	return nil
end

function MainTargetAurasFrame_OnLoad()
	this.displayElapsed = 0
	this.refreshElapsed = 0
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("PLAYER_TARGET_CHANGED")
	this:RegisterEvent("CHAT_MSG_COMBAT_LOG_ENEMY")
	this:RegisterEvent("CHAT_MSG_COMBAT_LOG_SELF")
	this:RegisterEvent("CHAT_MSG_COMBAT_LOG_PARTY")
	this:Hide()
end

function MainTargetAurasFrame_OnEvent(event)
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then
		if Main.API and Main.API.ResetUnitAuras then
			Main.API:ResetUnitAuras("target")
		end
		this.displayElapsed = MAIN_TARGET_AURAS_UPDATE_RATE
		this.refreshElapsed = 0
		MainTargetAuras_RequestSnapshot(1)
		MainTargetAuras_UpdateDisplay()
		return
	end

	if not MainTargetAuras_ShouldShow() then
		return
	end

	if (event == "CHAT_MSG_COMBAT_LOG_ENEMY" or event == "CHAT_MSG_COMBAT_LOG_PARTY")
		and MainTargetAuras_CombatMessageAffectsCurrentTarget(arg1) then
		this.refreshElapsed = 0
		MainTargetAuras_RequestSnapshot(1)
		return
	end

	if event == "CHAT_MSG_COMBAT_LOG_SELF" and UnitIsUnit and UnitIsUnit("target", "player")
		and MainTargetAuras_CombatMessageAffectsPlayer(arg1) then
		this.refreshElapsed = 0
		MainTargetAuras_RequestSnapshot(1)
	end
end

function MainTargetAurasFrame_OnUpdate(elapsed)
	local refreshRate

	if not MainTargetAuras_ShouldShow() then
		MainTargetAurasFrame:Hide()
		return
	end

	if not UnitExists or not UnitExists("target") then
		MainTargetAurasFrame:Hide()
		return
	end

	this.displayElapsed = this.displayElapsed + elapsed
	this.refreshElapsed = this.refreshElapsed + elapsed

	refreshRate = MainTargetAuras_GetRefreshRate()
	if refreshRate and this.refreshElapsed >= refreshRate then
		this.refreshElapsed = 0
		MainTargetAuras_RequestSnapshot(nil)
	end

	if this.displayElapsed < MAIN_TARGET_AURAS_UPDATE_RATE then
		return
	end

	this.displayElapsed = 0
	MainTargetAuras_UpdateDisplay()
end

function MainTargetAuraButton_OnEnter()
	if not this or not this.aura then
		return
	end

	MainTargetAuras_ShowTooltip(this, 1)
	this.updateTooltip = nil
end

function MainTargetAuraButton_OnLeave()
	GameTooltip:Hide()
	this.updateTooltip = nil
end

function MainTargetAuraButton_OnUpdate(elapsed)
	return
end

function MainTargetAuras:Init()
	MainTargetAurasFrame:Hide()
end

function MainTargetAuras:Enable()
	if Main.API and Main.API.ResetUnitAuras then
		Main.API:ResetUnitAuras("target")
	end
	if MainTargetAurasFrame then
		MainTargetAurasFrame.refreshElapsed = 0
	end
	MainTargetAuras_RequestSnapshot(1)
	MainTargetAuras_UpdateDisplay()
end

function MainTargetAuras:ApplyConfig()
	if MainTargetAuras_ShouldShow() then
		if MainTargetAurasFrame then
			MainTargetAurasFrame.refreshElapsed = 0
		end
		MainTargetAuras_RequestSnapshot(1)
	end
	MainTargetAuras_UpdateDisplay()
end

function MainTargetAuras:Disable()
	local index

	if Main.API and Main.API.ResetUnitAuras then
		Main.API:ResetUnitAuras("target")
	end

	for index = 1, MAIN_TARGET_AURAS_MAX_BUTTONS do
		MainTargetAuras_SetButton(MainTargetAuras_GetButton(index), nil)
	end
	MainTargetAurasFrame:Hide()
end

Main.RegisterModule("target_auras", MainTargetAuras)
