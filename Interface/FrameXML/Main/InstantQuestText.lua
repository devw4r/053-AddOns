local MainInstantQuestText = {
	name = "Instant Quest Text",
	description = "Removes quest text fades and displays quest text immediately.",
}

local function MainInstantQuestText_ApplyImmediateState()
	if QuestGreetingScrollChildFrame then
		QuestGreetingScrollChildFrame:SetAlpha(1)
	end

	if QuestDetailScrollChildFrame then
		QuestDetailScrollChildFrame:SetAlpha(1)
	end

	if QuestProgressScrollChildFrame then
		QuestProgressScrollChildFrame:SetAlpha(1)
	end

	if QuestRewardScrollChildFrame then
		QuestRewardScrollChildFrame:SetAlpha(1)
	end

	if QuestFrameDetailPanel then
		QuestFrameDetailPanel.fadingProgress = 1024
	end
end

function MainInstantQuestText:Enable()
	QUEST_FADING_ENABLE = nil
	MainInstantQuestText_ApplyImmediateState()
end

function MainInstantQuestText:Disable()
	QUEST_FADING_ENABLE = 1
end

Main.RegisterModule("instant_quest_text", MainInstantQuestText)
