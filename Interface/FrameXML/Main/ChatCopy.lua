local MainChatCopy = {
	name = "Chat Copy",
	description = "Adds a chat log copy window and button for the default chat frame.",
}

local MainChatCopyOriginalAddMessage = nil
local MAIN_CHAT_COPY_MAX_CHARS = 100000

local function MainChatCopy_Append(text, red, green, blue)
	local line
	local redValue
	local greenValue
	local blueValue

	if not Main.IsModuleEnabled("chat_copy") or not text or text == "" then
		return
	end

	redValue = floor(((red or 1) * 255) + 0.5)
	greenValue = floor(((green or 1) * 255) + 0.5)
	blueValue = floor(((blue or 1) * 255) + 0.5)
	line = format("|cff%02x%02x%02x%s|r", redValue, greenValue, blueValue, text)

	if not Main.ChatCopyContents or Main.ChatCopyContents == "" then
		Main.ChatCopyContents = line
	else
		Main.ChatCopyContents = strsub(Main.ChatCopyContents, -MAIN_CHAT_COPY_MAX_CHARS)
		Main.ChatCopyContents = Main.ChatCopyContents .. "\n" .. line
	end

	if MainChatCopyFrame and MainChatCopyFrame:IsVisible() then
		MainChatCopyEditBox:SetText(Main.ChatCopyContents)
	end
end

function MainChatCopyButton_OnClick()
	Main_ToggleUIPanel(MainChatCopyFrame)
end

function MainChatCopyButton_OnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	GameTooltip:SetText("Chat Copy", 1.0, 1.0, 1.0)
	GameTooltip:AddLine("Open a copyable view of recent chat output.")
	GameTooltip:Show()
end

function MainChatCopyButton_OnLeave()
	GameTooltip:Hide()
end

function MainChatCopyEditBox_OnShow()
	MainChatCopyEditBox:SetText(Main.ChatCopyContents or "")
	if MainChatCopyEditBox.SetFocus then
		MainChatCopyEditBox:SetFocus()
	end
end

function MainChatCopyEditBox_OnTextChanged()
	local scrollBar
	local minValue
	local maxValue

	scrollBar = getglobal(this:GetParent():GetName() .. "ScrollBar")
	this:GetParent():UpdateScrollChildRect()
	minValue, maxValue = scrollBar:GetMinMaxValues()
	if maxValue > 0 and this.max ~= maxValue then
		this.max = maxValue
		scrollBar:SetValue(maxValue)
	end
end

function MainChatCopyEditBox_OnEscapePressed()
	HideUIPanel(MainChatCopyFrame)
end

function MainChatCopy:Init()
	if not self.hookedAddMessage and ChatFrame and ChatFrame.AddMessage then
		MainChatCopyOriginalAddMessage = ChatFrame.AddMessage
		function ChatFrame:AddMessage(text, red, green, blue)
			MainChatCopy_Append(text, red, green, blue)
			MainChatCopyOriginalAddMessage(self, text, red, green, blue)
		end
		self.hookedAddMessage = 1
	end

	if MainChatCopyFrame then
		MainChatCopyFrame:Hide()
	end
	if MainChatCopyButton then
		MainChatCopyButton:Hide()
	end
end

function MainChatCopy:Enable()
	if MainChatCopyButton then
		MainChatCopyButton:Show()
	end
end

function MainChatCopy:Disable()
	if GameTooltip and GameTooltip:IsOwned(MainChatCopyButton) then
		GameTooltip:Hide()
	end
	if MainChatCopyFrame then
		MainChatCopyFrame:Hide()
	end
	if MainChatCopyButton then
		MainChatCopyButton:Hide()
	end
end

Main.RegisterModule("chat_copy", MainChatCopy)
