(function()

local MainGuildFrame = {
	name = "Guild Frame",
	description = "Adds a guild roster panel accessible via /groster or the guild chat command.",
}

local GUILD_MAX_ROWS = 10
local GUILD_RANK_NAMES = {
	[0] = "Guild Master",
	[1] = "Officer",
	[2] = "Veteran",
	[3] = "Member",
	[4] = "Initiate",
}
local GUILD_CLASS_NAMES = {
	[1] = "Warrior",
	[2] = "Paladin",
	[3] = "Hunter",
	[4] = "Rogue",
	[5] = "Priest",
	[8] = "Mage",
	[9] = "Warlock",
	[11] = "Druid",
}
local GUILD_CLASS_COLORS = {
	[1] = { r = 0.78, g = 0.61, b = 0.43 },
	[2] = { r = 0.96, g = 0.55, b = 0.73 },
	[3] = { r = 0.67, g = 0.83, b = 0.45 },
	[4] = { r = 1.00, g = 0.96, b = 0.41 },
	[5] = { r = 1.00, g = 1.00, b = 1.00 },
	[8] = { r = 0.41, g = 0.80, b = 0.94 },
	[9] = { r = 0.58, g = 0.51, b = 0.79 },
	[11] = { r = 1.00, g = 0.49, b = 0.04 },
}
local GUILD_DEFAULT_COLOR = { r = 0.5, g = 0.5, b = 0.5 }

local GUILD_RANK_GUILD_MASTER = 0
local GUILD_RANK_OFFICER = 1

local guildSortField = "rank"
local guildSortAsc = true
local guildShowOffline = false
local guildScrollOffset = 0
local guildFiltered = {}
local guildSelectedName = nil

local function GetClassName(classId)
	return GUILD_CLASS_NAMES[classId] or "Unknown"
end

local function GetClassColor(classId)
	return GUILD_CLASS_COLORS[classId] or GUILD_DEFAULT_COLOR
end

local function GetRankName(rank)
	return GUILD_RANK_NAMES[rank] or ("Rank " .. rank)
end

local function GetPlayerRank()
	local roster = Main.API and Main.API:GetGuildRoster() or {}
	local playerName = UnitName and UnitName("player") or nil
	if not playerName or not roster.members then
		return 99
	end
	for index = 1, Main_ArrayCount(roster.members) do
		local member = roster.members[index]
		if member and member.name == playerName then
			return member.rank
		end
	end
	return 99
end

local function IsGuildMaster()
	return GetPlayerRank() == GUILD_RANK_GUILD_MASTER
end

local function IsOfficerOrHigher()
	return GetPlayerRank() <= GUILD_RANK_OFFICER
end

local function GetSelectedMember()
	if not guildSelectedName then
		return nil
	end
	for index = 1, Main_ArrayCount(guildFiltered) do
		local member = guildFiltered[index]
		if member and member.name == guildSelectedName then
			return member
		end
	end
	return nil
end

local function FilterAndSort()
	local roster = Main.API and Main.API:GetGuildRoster() or {}
	local entries = {}
	local count = 0

	for index = 1, Main_ArrayCount(roster.members) do
		local member = roster.members[index]
		if member and (guildShowOffline or member.online) then
			count = count + 1
			entries[count] = member
		end
	end

	Main_SortArray(entries, function(left, right)
		local leftVal, rightVal

		if guildSortField == "name" then
			leftVal = left.name or ""
			rightVal = right.name or ""
		elseif guildSortField == "level" then
			leftVal = left.level or 0
			rightVal = right.level or 0
		elseif guildSortField == "class" then
			leftVal = GetClassName(left.classId)
			rightVal = GetClassName(right.classId)
		elseif guildSortField == "rank" then
			leftVal = left.rank or 99
			rightVal = right.rank or 99
		elseif guildSortField == "online" then
			leftVal = left.online and 0 or 1
			rightVal = right.online and 0 or 1
		else
			leftVal = left.name or ""
			rightVal = right.name or ""
		end

		if leftVal == rightVal then
			-- Secondary sort: rank then name
			local lr = left.rank or 99
			local rr = right.rank or 99
			if lr ~= rr then
				return lr < rr
			end
			return (left.name or "") < (right.name or "")
		end

		if guildSortAsc then
			return leftVal < rightVal
		else
			return leftVal > rightVal
		end
	end)

	guildFiltered = entries
end

local function UpdateHeader()
	local roster = Main.API and Main.API:GetGuildRoster() or {}
	local guildName

	if IsInGuild and IsInGuild() and GetGuildInfo then
		guildName = GetGuildInfo("player")
	end
	if not guildName or guildName == "" then
		guildName = roster.guildName or "Guild"
	end

	if FriendsFrameTitleText then
		FriendsFrameTitleText:SetText(guildName)
	end

	local motdLabel = getglobal("MainGuildFrameMotdLabel")
	if motdLabel then
		motdLabel:SetText("Guild Message Of The Day:")
	end

	local motdText = getglobal("MainGuildFrameMotd")
	if motdText then
		local motd = roster.motd or ""
		if motd ~= "" then
			motdText:SetText(motd)
			motdText:Show()
		else
			motdText:SetText("")
			motdText:Show()
		end
	end

	if MainGuildFrameTotalText then
		local total = roster.totalCount or 0
		local online = roster.onlineCount or 0
		local memberWord = total == 1 and "Guild Member" or "Guild Members"
		MainGuildFrameTotalText:SetText(
			"|cFFFFFFFF" .. total .. "|r " .. memberWord .. " (|cFFFFFFFF" .. online .. "|r |cFF33FF33Online|r)"
		)
	end
end

local function UpdateButtons()
	local playerRank = GetPlayerRank()
	local selected = GetSelectedMember()
	local hasSelection = selected ~= nil
	local playerName = UnitName and UnitName("player") or nil
	local isSelf = hasSelection and selected.name == playerName
	local selectedOnline = hasSelection and selected.online
	local canManage = IsOfficerOrHigher()

	local promoteBtn = getglobal("MainGuildFramePromoteButton")
	local demoteBtn = getglobal("MainGuildFrameDemoteButton")
	local removeBtn = getglobal("MainGuildFrameRemoveButton")
	local inviteBtn = getglobal("MainGuildFrameInviteButton")
	local whisperBtn = getglobal("MainGuildFrameWhisperButton")
	local groupInvBtn = getglobal("MainGuildFrameGroupInviteButton")
	local motdBtn = getglobal("MainGuildFrameSetMotdButton")

	-- Show/hide officer buttons based on rank
	if promoteBtn then
		if canManage then
			promoteBtn:Show()
			if hasSelection and not isSelf and selected.rank > (playerRank + 1) then
				promoteBtn:Enable()
			else
				promoteBtn:Disable()
			end
		else
			promoteBtn:Hide()
		end
	end

	if demoteBtn then
		if canManage then
			demoteBtn:Show()
			if hasSelection and not isSelf and selected.rank > playerRank and selected.rank < 4 then
				demoteBtn:Enable()
			else
				demoteBtn:Disable()
			end
		else
			demoteBtn:Hide()
		end
	end

	if removeBtn then
		if canManage then
			removeBtn:Show()
			if hasSelection and not isSelf and selected.rank > playerRank then
				removeBtn:Enable()
			else
				removeBtn:Disable()
			end
		else
			removeBtn:Hide()
		end
	end

	if inviteBtn then
		if canManage then
			inviteBtn:Show()
			inviteBtn:Enable()
		else
			inviteBtn:Hide()
		end
	end

	if motdBtn then
		if IsGuildMaster() then
			motdBtn:Show()
			motdBtn:Enable()
		else
			motdBtn:Hide()
		end
	end

	if whisperBtn then
		if hasSelection and not isSelf and selectedOnline then
			whisperBtn:Enable()
		else
			whisperBtn:Disable()
		end
	end

	if groupInvBtn then
		if hasSelection and not isSelf and selectedOnline then
			groupInvBtn:Enable()
		else
			groupInvBtn:Disable()
		end
	end
end

local function UpdateRows()
	for index = 1, GUILD_MAX_ROWS do
		local rowFrame = getglobal("MainGuildRow" .. index)
		if not rowFrame then
			break
		end

		local prefix = "MainGuildRow" .. index
		local dataIndex = guildScrollOffset + index
		local member = guildFiltered[dataIndex]
		local nameText = getglobal(prefix .. "Name")
		local levelText = getglobal(prefix .. "Level")
		local classText = getglobal(prefix .. "Class")
		local rankText = getglobal(prefix .. "Rank")
		local onlineText = getglobal(prefix .. "Online")

		if member then
			local cc = GetClassColor(member.classId)

			if nameText then
				nameText:SetText(member.name)
				if member.online then
					if nameText.SetTextColor then nameText:SetTextColor(cc.r, cc.g, cc.b) end
				else
					if nameText.SetTextColor then nameText:SetTextColor(0.5, 0.5, 0.5) end
				end
			end
			if levelText then levelText:SetText(tostring(member.level)) end
			if classText then
				classText:SetText(GetClassName(member.classId))
				if member.online then
					if classText.SetTextColor then classText:SetTextColor(cc.r, cc.g, cc.b) end
				else
					if classText.SetTextColor then classText:SetTextColor(0.5, 0.5, 0.5) end
				end
			end
			if rankText then rankText:SetText(GetRankName(member.rank)) end
			if onlineText then
				if member.online then
					onlineText:SetText("Online")
					if onlineText.SetTextColor then onlineText:SetTextColor(0.2, 1.0, 0.2) end
				else
					onlineText:SetText("Offline")
					if onlineText.SetTextColor then onlineText:SetTextColor(0.5, 0.5, 0.5) end
				end
			end
			if guildSelectedName and guildSelectedName == member.name then
				rowFrame:LockHighlight()
			else
				rowFrame:UnlockHighlight()
			end
			rowFrame:Show()
		else
			if nameText then nameText:SetText("") end
			if levelText then levelText:SetText("") end
			if classText then classText:SetText("") end
			if rankText then rankText:SetText("") end
			if onlineText then onlineText:SetText("") end
			rowFrame:UnlockHighlight()
			rowFrame:Hide()
		end
	end
end

local function UpdateScrollBar()
	local totalRows = Main_ArrayCount(guildFiltered)
	local maxScroll = totalRows - GUILD_MAX_ROWS
	if maxScroll < 0 then maxScroll = 0 end
	if guildScrollOffset > maxScroll then guildScrollOffset = maxScroll end
	if guildScrollOffset < 0 then guildScrollOffset = 0 end

	if MainGuildFrameScrollBar then
		MainGuildFrameScrollBar:SetMinMaxValues(0, maxScroll)
		MainGuildFrameScrollBar:SetValue(guildScrollOffset)
	end
end

local function Refresh()
	FilterAndSort()
	UpdateHeader()
	UpdateScrollBar()
	UpdateRows()
	UpdateButtons()
end

local function RequestRoster()
	if Main.API and Main.API.RequestGuildRoster then
		Main.API:RequestGuildRoster(1)
	end
end

local function SetSort(field, defaultAsc)
	if guildSortField == field then
		guildSortAsc = not guildSortAsc
	else
		guildSortField = field
		guildSortAsc = defaultAsc
	end
	Refresh()
end

function MainGuildFrameScrollBar_OnValueChanged()
	guildScrollOffset = floor(this:GetValue() + 0.5)
	UpdateRows()
end

function MainGuildFrame_OnMouseWheel(delta)
	if delta > 0 then
		guildScrollOffset = guildScrollOffset - 1
	else
		guildScrollOffset = guildScrollOffset + 1
	end

	local maxScroll = Main_ArrayCount(guildFiltered) - GUILD_MAX_ROWS
	if maxScroll < 0 then maxScroll = 0 end
	if guildScrollOffset < 0 then guildScrollOffset = 0 end
	if guildScrollOffset > maxScroll then guildScrollOffset = maxScroll end

	if MainGuildFrameScrollBar then
		MainGuildFrameScrollBar:SetValue(guildScrollOffset)
	end
	UpdateRows()
end

function MainGuildRow_OnClick()
	local dataIndex = guildScrollOffset + this:GetID()
	local member = guildFiltered[dataIndex]
	guildSelectedName = member and member.name or nil
	UpdateRows()
	UpdateButtons()
end

function MainGuildFrameSortName_OnClick()    SetSort("name", true) end
function MainGuildFrameSortLevel_OnClick()   SetSort("level", false) end
function MainGuildFrameSortClass_OnClick()   SetSort("class", true) end
function MainGuildFrameSortRank_OnClick()    SetSort("rank", true) end
function MainGuildFrameSortOnline_OnClick()  SetSort("online", true) end

function MainGuildFrameOnlineToggle_OnClick()
	guildShowOffline = not guildShowOffline
	guildScrollOffset = 0
	Refresh()
end

function MainGuildFrameWhisperButton_OnClick()
	if guildSelectedName and guildSelectedName ~= "" and ChatFrameEditBox then
		ChatFrameEditBox:Show()
		ChatFrameEditBox:SetText("/w " .. guildSelectedName .. " ")
	end
end

function MainGuildFrameGroupInviteButton_OnClick()
	if guildSelectedName and guildSelectedName ~= "" and InviteByName then
		InviteByName(guildSelectedName)
	end
end

function MainGuildFrameInviteButton_OnClick()
	if GuildInviteByName then
		local editBox = ChatFrameEditBox
		if editBox then
			editBox:Show()
			editBox:SetText("/ginvite ")
		end
	end
end

function MainGuildFrameRemoveButton_OnClick()
	if guildSelectedName and guildSelectedName ~= "" and GuildUninviteByName then
		GuildUninviteByName(guildSelectedName)
	end
end

function MainGuildFramePromoteButton_OnClick()
	if guildSelectedName and guildSelectedName ~= "" and GuildPromoteByName then
		GuildPromoteByName(guildSelectedName)
	end
end

function MainGuildFrameDemoteButton_OnClick()
	if guildSelectedName and guildSelectedName ~= "" and GuildDemoteByName then
		GuildDemoteByName(guildSelectedName)
	end
end

function MainGuildFrameSetMotdButton_OnClick()
	if not IsGuildMaster() then
		Main_Print("Only the Guild Master can set the MOTD.")
		return
	end
	if GuildSetMOTD then
		local editBox = ChatFrameEditBox
		if editBox then
			editBox:Show()
			editBox:SetText("/gmotd ")
		end
	end
end

function MainGuildFrame_OnLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	if this.EnableMouseWheel then
		this:EnableMouseWheel(1)
	end

	-- Set toggle label text
	local toggleText = getglobal("MainGuildFrameOnlineToggleText")
	if toggleText then
		toggleText:SetText("Show Offline Members")
	end


	this:Hide()
end

function MainGuildFrame_OnShow()
	guildScrollOffset = 0
	guildSelectedName = nil
	RequestRoster()
	Refresh()
end

function MainGuildFrame_OnEvent(event)
	if event == "PLAYER_ENTERING_WORLD" and Main.API then
		Main.API:ResetGuildRoster()
	end
end

function MainGuildFrame_OnUpdate(elapsed)
	this.elapsed = (this.elapsed or 0) + elapsed
	if this.elapsed < 0.5 then return end
	this.elapsed = 0

	local roster = Main.API and Main.API:GetGuildRoster() or {}
	if roster.loaded then
		Refresh()
		roster.loaded = nil
	end
end

function MainGuildFrame_OnHide()
	guildSelectedName = nil
end

local mainGuildOriginalFriendsFrameUpdate = nil

local function MainGuildFrame_HookFriendsFrame()
	if mainGuildOriginalFriendsFrameUpdate then
		return
	end

	if not FriendsFrame or not FriendsFrame_Update then
		return
	end

	PanelTemplates_SetNumTabs(FriendsFrame, 4)
	PanelTemplates_UpdateTabs(FriendsFrame)

	mainGuildOriginalFriendsFrameUpdate = FriendsFrame_Update
	FriendsFrame_Update = function()
		local guildPanel = getglobal("MainGuildFrame")
		if FriendsFrame.selectedTab == 4 then
			FriendsFrameTopLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft")
			FriendsFrameTopRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight")
			FriendsFrameBottomLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft")
			FriendsFrameBottomRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomRight")
			if FriendsListFrame then FriendsListFrame:Hide() end
			if IgnoreListFrame then IgnoreListFrame:Hide() end
			if WhoFrame then WhoFrame:Hide() end
			if guildPanel then guildPanel:Show() end
			return
		end

		if guildPanel then
			guildPanel:Hide()
		end
		mainGuildOriginalFriendsFrameUpdate()
	end
end

function MainGuildFrame:Init()
	MainGuildFrame_HookFriendsFrame()
end

function MainGuildFrame:Enable()
	if FriendsFrameTab4 then
		FriendsFrameTab4:Show()
	end
end

function MainGuildFrame:Disable()
	local guildPanel = getglobal("MainGuildFrame")
	if FriendsFrameTab4 then
		FriendsFrameTab4:Hide()
	end
	if guildPanel and guildPanel.IsVisible and guildPanel:IsVisible() then
		guildPanel:Hide()
	end
	if FriendsFrame and FriendsFrame.selectedTab == 4 then
		FriendsFrame.selectedTab = 1
		if FriendsFrame_Update then
			FriendsFrame_Update()
		end
		PanelTemplates_UpdateTabs(FriendsFrame)
	end
end

function MainGuildFrame_Toggle()
	if not Main.IsModuleEnabled("guild_frame") then
		Main_Print("Guild Frame module is disabled.")
		return
	end
	if not IsInGuild or not IsInGuild() then
		Main_Print("You are not in a guild.")
		return
	end
	if FriendsFrame then
		FriendsFrame.selectedTab = 4
		ShowUIPanel(FriendsFrame)
		FriendsFrame_Update()
		PanelTemplates_UpdateTabs(FriendsFrame)
	end
end

Main.RegisterModule("guild_frame", MainGuildFrame)

end)()
