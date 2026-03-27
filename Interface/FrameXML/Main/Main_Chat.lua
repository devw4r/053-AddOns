Main.TransportChannels = Main.TransportChannels or {}

local MainOriginalChatFrame_OnEvent = ChatFrame_OnEvent

function Main.RegisterTransportChannel(channelName)
	if not channelName or channelName == "" then
		return
	end

	Main.TransportChannels[Main_StringLower(channelName)] = 1
end

function Main.IsTransportChannelName(channelName)
	local lookupName
	local found

	if not channelName then
		return nil
	end

	lookupName = Main_StringLower(channelName)
	found = nil
	Main_ForEach(Main.TransportChannels, function(registeredName)
		if not found and Main_StringFind(lookupName, registeredName, 1, 1) then
			found = 1
		end
	end)

	if found then
		return 1
	end

	return nil
end

function ChatFrame_OnEvent(event)
	if (event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_CHANNEL_NOTICE" or event == "CHAT_MSG_CHANNEL_NOTICE_USER")
		and arg4 and Main.IsTransportChannelName(arg4) then
		return
	end

	MainOriginalChatFrame_OnEvent(event)
end
