local MainTalentButton = {
	name = "Talents Button",
	description = "Adds a talents micro button beside the main menu icons.",
	managerHidden = 1,
	options = {
		{
			type = "toggle",
			key = "actionbars_show_talent_button",
			label = "Show talents button",
			managerOrder = 10,
			defaultValue = true,
			requiresModule = false,
		},
	},
}

local MainTalentButtonOriginalUpdateMicroButtons = nil

function MainTalentButton_ShouldShow()
	return Main.IsModuleEnabled("talent_button") and Main.GetBoolSetting("actionbars_show_talent_button", true)
end

local function MainTalentButton_UpdateAnchor()
	if not MainTalentMicroButton then
		return
	end

	if Main.IsModuleEnabled("action_bars") then
		return
	end

	MainTalentMicroButton:ClearAllPoints()
	MainTalentMicroButton:SetPoint("BOTTOMLEFT", "BugsMicroButton", "BOTTOMRIGHT", -2, 0)

	if BugsMicroButton and BugsMicroButton.GetFrameLevel then
		MainTalentMicroButton:SetFrameLevel(BugsMicroButton:GetFrameLevel())
	end
end

local function MainTalentButton_UpdateTooltip()
	if MainTalentMicroButton then
		MainTalentMicroButton.tooltipText = MicroButtonTooltipText(TEXT(TALENTS_BUTTON), "TOGGLETALENTS")
	end
end

function MainTalentButton_UpdateState()
	if not MainTalentMicroButton then
		return
	end

	if not MainTalentButton_ShouldShow() then
		MainTalentMicroButton:Hide()
		return
	end

	MainTalentButton_UpdateAnchor()
	MainTalentMicroButton:Show()
	if TalentTrainerFrame and TalentTrainerFrame:IsVisible() then
		MainTalentMicroButton:SetButtonState("PUSHED", 1)
	else
		MainTalentMicroButton:SetButtonState("NORMAL")
	end
end

function MainTalentMicroButton_OnLoad()
	LoadMicroButtonTextures("Talents")
	this:RegisterEvent("UPDATE_BINDINGS")
	MainTalentButton_UpdateTooltip()
	this:Hide()
end

function MainTalentMicroButton_OnEvent(event)
	if event == "UPDATE_BINDINGS" then
		MainTalentButton_UpdateTooltip()
	end
end

function MainTalentMicroButton_OnClick()
	ToggleCharacter("TalentTrainerFrame")
	UpdateMicroButtons()
end

function MainTalentButton:Init()
	if not self.hookedUpdate then
		-- Wrap the stock updater so the extra button tracks the same refresh points as the built-in micro buttons.
		MainTalentButtonOriginalUpdateMicroButtons = UpdateMicroButtons
		function UpdateMicroButtons()
			if MainTalentButtonOriginalUpdateMicroButtons then
				MainTalentButtonOriginalUpdateMicroButtons()
			end
			MainTalentButton_UpdateState()
		end
		self.hookedUpdate = 1
	end

	MainTalentButton_UpdateState()
end

function MainTalentButton:Enable()
	MainTalentButton_UpdateState()
	if UpdateMicroButtons then
		UpdateMicroButtons()
	end
end

function MainTalentButton:Disable()
	if GameTooltip and GameTooltip:IsOwned(MainTalentMicroButton) then
		GameTooltip:Hide()
	end
	MainTalentButton_UpdateState()
	if UpdateMicroButtons then
		UpdateMicroButtons()
	end
end

function MainTalentButton:ApplyConfig()
	MainTalentButton_UpdateState()
	if UpdateMicroButtons then
		UpdateMicroButtons()
	end
end

function MainTalentButton:OnUILayoutChanged()
	MainTalentButton_UpdateState()
end

Main.RegisterModule("talent_button", MainTalentButton)
