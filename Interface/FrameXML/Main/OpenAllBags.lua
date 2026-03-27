local MainOpenAllBags = {
	name = "Open All Bags",
	description = "Adds a button near the backpack to toggle all bags.",
	managerHidden = 1,
	options = {
		{
			type = "toggle",
			key = "actionbars_show_open_bags",
			label = "Show open bags button",
			defaultValue = false,
			managerOrder = 10,
			requiresModule = false,
		},
	},
}

local function MainOpenAllBags_ShouldShow()
	return Main.IsModuleEnabled("open_all_bags") and Main.GetBoolSetting("actionbars_show_open_bags", false)
end

function MainOpenAllBags_UpdateState()
	if not MainOpenAllBagsButton then
		return
	end

	if MainOpenAllBags_ShouldShow() then
		MainOpenAllBagsButton:Show()
		if MainActionBars_PositionOpenAllBagsButton then
			MainActionBars_PositionOpenAllBagsButton()
		end
	else
		MainOpenAllBagsButton:Hide()
	end
end

function MainOpenAllBagsButton_OnLoad()
	this:RegisterForClicks("LeftButtonUp")
end

function MainOpenAllBagsButton_OnClick()
	OpenAllBags()
end

function MainOpenAllBagsButton_OnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_LEFT")
	GameTooltip:AddLine("Open Bags")
	GameTooltip:AddLine("Click to open or close all bags.")
	GameTooltip:Show()
end

function MainOpenAllBagsButton_OnLeave()
	GameTooltip:Hide()
end

function MainOpenAllBags:Init()
	MainOpenAllBags_UpdateState()
end

function MainOpenAllBags:Enable()
	MainOpenAllBags_UpdateState()
end

function MainOpenAllBags:Disable()
	MainOpenAllBagsButton:Hide()
end

function MainOpenAllBags:ApplyConfig()
	MainOpenAllBags_UpdateState()
end

function MainOpenAllBags:OnUILayoutChanged()
	MainOpenAllBags_UpdateState()
end

Main.RegisterModule("open_all_bags", MainOpenAllBags)
