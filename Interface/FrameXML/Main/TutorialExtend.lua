local MainTutorialExtend = {
	name = "Tutorial Extend",
	description = "Shows the stock tutorial prompts again for brand new characters.",
}

local MAIN_TUTORIAL_EXTEND_MAX_PLAYED_SECONDS = 60
local MAIN_TUTORIAL_EXTEND_TUTORIAL_COUNT = 18

local function MainTutorialExtend_IsEligible()
	return UnitXP("player") == 0
end

local function MainTutorialExtend_InitializeTutorials()
	local tutorialIndex

	if not MainTutorialExtend_IsEligible() or MainTutorialExtend.initializedThisSession then
		return
	end

	for tutorialIndex = 1, MAIN_TUTORIAL_EXTEND_TUTORIAL_COUNT do
		TutorialFrame_NewTutorial(tutorialIndex)
	end

	MainTutorialExtend.initializedThisSession = 1

	-- The stock API only flashes the question mark button. Open the first tutorial automatically
	-- so new characters actually see the re-queued help prompts.
	if TutorialFrame and TutorialFrameQuestionMarkButton and not TutorialFrame:IsVisible() then
		ShowUIPanel(TutorialFrame)
		UIFrameFlashRemoveFrame(TutorialFrameQuestionMarkButton)
		TutorialFrameQuestionMarkButton:Hide()
	end
end

local function MainTutorialExtend_RequestTimePlayed()
	if MainTutorialExtend.requestPending then
		return
	end

	MainTutorialExtend.requestPending = 1
	RequestTimePlayed()
end

local function MainTutorialExtend_UpdateRegistration()
	if not MainTutorialExtendFrame then
		return
	end

	MainTutorialExtendFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	MainTutorialExtendFrame:UnregisterEvent("TIME_PLAYED_MSG")

	if not Main.IsModuleEnabled("tutorial_extend") then
		return
	end

	if not MainTutorialExtend_IsEligible() then
		return
	end

	MainTutorialExtendFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	MainTutorialExtendFrame:RegisterEvent("TIME_PLAYED_MSG")
end

function MainTutorialExtendFrame_OnLoad()
	MainTutorialExtend_UpdateRegistration()
end

function MainTutorialExtendFrame_OnEvent(event)
	if not Main.IsModuleEnabled("tutorial_extend") then
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		MainTutorialExtend.initializedThisSession = nil
		MainTutorialExtend_RequestTimePlayed()
	elseif event == "TIME_PLAYED_MSG" then
		MainTutorialExtend.requestPending = nil
		if floor(arg1) < MAIN_TUTORIAL_EXTEND_MAX_PLAYED_SECONDS then
			MainTutorialExtend_InitializeTutorials()
		end
		MainTutorialExtend_UpdateRegistration()
	end
end

function MainTutorialExtend:Init()
	MainTutorialExtend_UpdateRegistration()
end

function MainTutorialExtend:Enable()
	MainTutorialExtend_UpdateRegistration()
	if MainTutorialExtend_IsEligible() then
		MainTutorialExtend_RequestTimePlayed()
	end
end

function MainTutorialExtend:Disable()
	MainTutorialExtend.requestPending = nil
	MainTutorialExtend.initializedThisSession = nil
	MainTutorialExtend_UpdateRegistration()
end

Main.RegisterModule("tutorial_extend", MainTutorialExtend)
