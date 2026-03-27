SlashCmdList.MAINADDONS = function()
	Main_ToggleUIPanel(MainManagerFrame)
end

SLASH_MAINADDONS1 = "/main"
SLASH_MAINADDONS2 = "/mainaddons"

SlashCmdList.MAINGUILDROSTER = function()
	if MainGuildFrame_Toggle then
		MainGuildFrame_Toggle()
	end
end

SLASH_MAINGUILDROSTER1 = "/groster"
SLASH_MAINGUILDROSTER2 = "/guildroster"
