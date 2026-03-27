Main.API = {
	channelName = "_addonmain",
	channelPassword = "tP4hSCpd8vWaun",
	joinRetrySeconds = 5,
	requestRetrySeconds = 1,
	fallbackDelaySeconds = 3,
	maxSettingsPayloadLength = 72,
	requestSerial = 0,
	targetDistance = {
		requestRetrySeconds = 1,
	},
	unitAuras = {
		requestRetrySeconds = 1,
		states = {},
	},
}

if Main.RegisterTransportChannel then
	Main.RegisterTransportChannel(Main.API.channelName)
end

function Main.API:CreateRequestToken()
	self.requestSerial = self.requestSerial + 1
	return tostring(self.requestSerial)
end

function Main.API:GetChannelNumber()
	local channelNum
	local now

	channelNum = GetChannelName(self.channelName)
	if channelNum and channelNum > 0 then
		self.joinLastAttempt = nil
		return channelNum
	end

	now = GetTime and GetTime() or 0
	if not self.joinLastAttempt or (now - self.joinLastAttempt) >= self.joinRetrySeconds then
		JoinChannelByName(self.channelName, self.channelPassword)
		self.joinLastAttempt = now
	end

	return nil
end

function Main.API:SendCommand(command, arg1, arg2)
	local channelNum
	local message

	channelNum = self:GetChannelNumber()
	if not channelNum or channelNum <= 0 then
		return nil
	end

	message = command
	if arg1 and arg1 ~= "" then
		message = message .. " " .. arg1
	end
	if arg2 and arg2 ~= "" then
		message = message .. " " .. arg2
	end

	SendChatMessage(message, "CHANNEL", nil, channelNum)
	return 1
end

function Main.API:BeginStartup()
	if self.startedAt then
		return
	end

	self.startedAt = GetTime and GetTime() or 0
	self:RequestConfig(1)
end

function Main.API:RequestConfig(force)
	local now
	local token

	if self.configUnsupported or self.remoteLoaded then
		return nil
	end

	now = GetTime and GetTime() or 0
	if self.requestPending and not force then
		return nil
	end
	if not force and self.lastRequestAt and (now - self.lastRequestAt) < self.requestRetrySeconds then
		return nil
	end

	token = self:CreateRequestToken()
	if self:SendCommand("get_cfg", token) then
		self.requestToken = token
		self.requestPending = 1
		self.lastRequestAt = now
		return 1
	end

	return nil
end

function Main.API:SaveConfig()
	local flags
	local settingsPayload
	local requestToken
	local payload

	if self.configUnsupported or not self.remoteLoaded then
		return nil
	end

	flags, settingsPayload = Main.BuildRemoteConfigState()
	if settingsPayload and string.len(settingsPayload) > self.maxSettingsPayloadLength then
		if not self.warnedPayloadTooLong then
			self.warnedPayloadTooLong = 1
			Main_Print("Addon settings payload is too large to persist through chat transport.")
		end
		return nil
	end

	requestToken = self:CreateRequestToken()
	payload = tostring(floor(flags))
	if settingsPayload and settingsPayload ~= "" then
		payload = payload .. "|" .. settingsPayload
	else
		payload = payload .. "|-"
	end

	if self:SendCommand("set_cfg", requestToken, payload) then
		self.saveToken = requestToken
		self.savePending = 1
		return 1
	end

	return nil
end

function Main.API:HandleConfigMessage(message)
	local flagsText
	local requestToken
	local settingsPayload
	local flags

	_, _, flagsText, requestToken, settingsPayload = string.find(message, "^cfg,(%d+),([^,]+),?(.*)$")
	if not flagsText or not requestToken then
		return
	end

	flags = tonumber(flagsText) or 0
	settingsPayload = settingsPayload or ""

	if self.requestPending and requestToken == self.requestToken then
		self.requestPending = nil
		self.remoteLoaded = 1
		Main.ApplyRemoteConfig(flags, settingsPayload)
		if not Main.Initialized then
			Main_Start()
		end
		return
	end

	if self.savePending and requestToken == self.saveToken then
		self.savePending = nil
		return
	end
end

function Main.API:ResetTargetDistance()
	self.targetDistance.valueYards = nil
	self.targetDistance.unavailable = nil
	self.targetDistance.requestPending = nil
	self.targetDistance.requestToken = nil
	self.targetDistance.lastRequestAt = nil
end

function Main.API:RequestTargetDistance(force)
	local state
	local now
	local token

	if not UnitExists or not UnitExists("target") then
		return nil
	end

	state = self.targetDistance
	now = GetTime and GetTime() or 0

	if state.requestPending and not force then
		return nil
	end
	if not force and state.lastRequestAt and (now - state.lastRequestAt) < state.requestRetrySeconds then
		return nil
	end
	token = self:CreateRequestToken()
	if self:SendCommand("get_target_dist_version", "target", token) then
		state.requestPending = 1
		state.requestToken = token
		state.lastRequestAt = now
		return 1
	end

	return nil
end

function Main.API:GetTargetDistanceYards()
	return self.targetDistance.valueYards
end

function Main.API:IsTargetDistanceUnavailable()
	return self.targetDistance.unavailable
end

function Main.API:GetUnitAuraState(unitId)
	local safeUnitId

	safeUnitId = string.lower(tostring(unitId or "target"))
	if not self.unitAuras.states[safeUnitId] then
		self.unitAuras.states[safeUnitId] = {
			entries = {},
		}
	end

	return self.unitAuras.states[safeUnitId]
end

function Main.API:ResetUnitAuras(unitId)
	local state

	state = self:GetUnitAuraState(unitId)
	state.entries = {}
	state.activeToken = nil
	state.requestPending = nil
	state.requestToken = nil
	state.lastRequestAt = nil
	state.unitGuid = nil
	state.unavailable = nil
end

function Main.API:RequestUnitAuras(unitId, force)
	local state
	local now
	local token
	local safeUnitId

	if self.auraUnsupported then
		return nil
	end

	safeUnitId = unitId or "target"
	if not UnitExists or not UnitExists(safeUnitId) then
		return nil
	end

	state = self:GetUnitAuraState(unitId)
	now = GetTime and GetTime() or 0

	if state.requestPending and not force then
		return nil
	end
	if not force and state.lastRequestAt and (now - state.lastRequestAt) < self.unitAuras.requestRetrySeconds then
		return nil
	end

	token = self:CreateRequestToken()
	if self:SendCommand("get_auras_version", unitId, token) then
		state.requestPending = 1
		state.requestToken = token
		state.lastRequestAt = now
		return 1
	end

	return nil
end

function Main.API:GetUnitAuras(unitId)
	return self:GetUnitAuraState(unitId).entries
end

function Main.API:IsUnitAurasUnavailable(unitId)
	return self:GetUnitAuraState(unitId).unavailable
end

function Main.API:HandleTargetDistanceMessage(message)
	local unitId
	local distanceRaw
	local requestToken
	local distanceValue
	local state

	_, _, unitId, distanceRaw, requestToken = string.find(message, "^([^,]+),([^,]+),([^,]+)$")
	if not unitId or not distanceRaw or not requestToken then
		return nil
	end

	unitId = string.lower(string.gsub(unitId, "%s+", ""))
	if unitId ~= "target" then
		return nil
	end

	requestToken = string.gsub(requestToken, "%s+", "")
	state = self.targetDistance
	if state.requestToken and requestToken ~= state.requestToken then
		return 1
	end

	distanceValue = tonumber(string.gsub(distanceRaw, "%s+", ""))
	if not distanceValue then
		return nil
	end

	state.valueYards = floor(distanceValue + 0.5)
	state.unavailable = nil
	state.requestPending = nil
	state.requestToken = nil
	return 1
end

function Main.API:HandleAuraMessage(message)
	local unitId
	local name
	local harmfulText
	local textureText
	local remainingText
	local requestToken
	local unitGuid
	local iconPath
	local state
	local remainingMs
	local now
	local entry

	if string.find(message, "^%d+$") then
		return 1
	end

	_, _, unitId, name, harmfulText, textureText, remainingText, requestToken, unitGuid, iconPath =
		string.find(message, "^([^,]+),([^,]*),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),?(.*)$")
	if not unitId or not requestToken then
		return nil
	end

	unitId = string.lower(string.gsub(unitId, "%s+", ""))
	requestToken = string.gsub(requestToken, "%s+", "")
	state = self:GetUnitAuraState(unitId)
	if state.requestToken and requestToken ~= state.requestToken then
		return 1
	end

	if state.activeToken ~= requestToken or state.unitGuid ~= unitGuid then
		state.entries = {}
		state.activeToken = requestToken
		state.unitGuid = unitGuid
	end

	remainingMs = tonumber(string.gsub(remainingText, "%s+", ""))
	if not remainingMs then
		return nil
	end

	now = GetTime and GetTime() or 0
	entry = {
		name = name or "",
		harmful = harmfulText == "1",
		textureId = tonumber(textureText) or 0,
		iconPath = iconPath and iconPath ~= "" and iconPath or nil,
		remainingMs = remainingMs,
		receivedAt = now,
	}
	if remainingMs >= 0 then
		entry.expiresAt = now + (remainingMs / 1000)
	end

	state.entries[Main_ArrayCount(state.entries) + 1] = entry
	state.unavailable = nil
	if state.requestPending and requestToken == state.requestToken then
		state.requestPending = nil
		state.requestToken = nil
	end

	return 1
end

function Main.API:HandleErrorMessage(message)
	local errorCode
	local unitId
	local requestToken
	local state
	local auraState
	local configCommandFailed
	local configRequestFailed
	local configSaveFailed
	local targetDistanceFailed
	local auraRequestFailed

	_, _, errorCode, unitId, requestToken = string.find(message, "^(-?%d+),%s*([^,]+),?%s*(.*)$")
	if not errorCode then
		return
	end

	if unitId then
		unitId = string.lower(string.gsub(unitId, "%s+", ""))
	end
	if requestToken then
		requestToken = string.gsub(requestToken, "%s+", "")
	end

	configRequestFailed = self.requestPending and requestToken == self.requestToken
	configSaveFailed = self.savePending and requestToken == self.saveToken

	if configRequestFailed then
		self.requestPending = nil
	end
	if configSaveFailed then
		self.savePending = nil
	end

	state = self.targetDistance
	targetDistanceFailed = state.requestPending and requestToken == state.requestToken and unitId == "target"
	if targetDistanceFailed then
		state.requestPending = nil
		state.requestToken = nil
		state.valueYards = nil
		state.unavailable = 1
	end

	auraState = nil
	if unitId and self.unitAuras and self.unitAuras.states and self.unitAuras.states[unitId] then
		auraState = self.unitAuras.states[unitId]
	end
	auraRequestFailed = auraState and auraState.requestPending and requestToken == auraState.requestToken
	if auraRequestFailed then
		auraState.requestPending = nil
		auraState.requestToken = nil
		auraState.entries = {}
		if errorCode == "-2" then
			auraState.activeToken = requestToken
			auraState.unavailable = nil
		elseif errorCode == "-1" then
			auraState.activeToken = nil
			auraState.unavailable = 1
		else
			auraState.activeToken = nil
			auraState.unavailable = nil
		end
	end

	if errorCode == "-1" and auraRequestFailed then
		self.auraUnsupported = 1
		if not self.warnedAuraUnsupported then
			self.warnedAuraUnsupported = 1
			Main_Print("Server target aura API is unavailable.")
		end
	end

	if self.guildRoster and self.guildRoster.requestPending and requestToken == self.guildRoster.requestToken then
		self.guildRoster.requestPending = nil
		self.guildRoster.requestToken = nil
	end

	configCommandFailed = configRequestFailed or configSaveFailed
	if errorCode == "-1" and configCommandFailed then
		self.configUnsupported = 1
		if not self.warnedConfigUnsupported then
			self.warnedConfigUnsupported = 1
			Main_Print("Server addon settings API is unavailable. Using local defaults for this session.")
		end
		if not Main.Initialized then
			Main_Start()
		end
	end
end

function Main.API:ResetGuildRoster()
	self.guildRoster = self.guildRoster or {}
	self.guildRoster.members = {}
	self.guildRoster.guildName = nil
	self.guildRoster.motd = nil
	self.guildRoster.onlineCount = 0
	self.guildRoster.totalCount = 0
	self.guildRoster.requestPending = nil
	self.guildRoster.requestToken = nil
	self.guildRoster.lastRequestAt = nil
	self.guildRoster.loaded = nil
end

function Main.API:RequestGuildRoster(force)
	local state
	local now
	local token

	self.guildRoster = self.guildRoster or {}
	state = self.guildRoster
	now = GetTime and GetTime() or 0

	if state.requestPending and not force then
		return nil
	end
	if not force and state.lastRequestAt and (now - state.lastRequestAt) < 2 then
		return nil
	end

	token = self:CreateRequestToken()
	if self:SendCommand("get_guild_roster", token) then
		state.requestPending = 1
		state.requestToken = token
		state.lastRequestAt = now
		return 1
	end

	return nil
end

function Main.API:GetGuildRoster()
	self.guildRoster = self.guildRoster or {}
	return self.guildRoster
end

function Main.API:HandleGuildRosterHeader(message)
	local requestToken
	local guildName
	local motd
	local onlineCount
	local totalCount
	local state

	_, _, requestToken, guildName, motd, onlineCount, totalCount =
		string.find(message, "^gr,([^,]+),([^,]*),([^,]*),([^,]*),([^,]*)$")
	if not requestToken then
		return nil
	end

	self.guildRoster = self.guildRoster or {}
	state = self.guildRoster

	if state.requestToken and requestToken ~= state.requestToken then
		return 1
	end

	state.members = {}
	state.guildName = guildName or ""
	state.motd = motd or ""
	state.onlineCount = tonumber(onlineCount) or 0
	state.totalCount = tonumber(totalCount) or 0
	state.activeToken = requestToken
	state.requestPending = nil
	state.requestToken = nil
	state.loaded = 1

	return 1
end

function Main.API:HandleGuildRosterMember(message)
	local name
	local level
	local classId
	local rank
	local online
	local state
	local entry
	local count

	_, _, name, level, classId, rank, online =
		string.find(message, "^gm,([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")
	if not name then
		return nil
	end

	self.guildRoster = self.guildRoster or {}
	state = self.guildRoster
	count = Main_ArrayCount(state.members)
	entry = {
		name = name,
		level = tonumber(level) or 0,
		classId = tonumber(classId) or 0,
		rank = tonumber(rank) or 0,
		online = online == "1",
	}
	state.members[count + 1] = entry
	state.loaded = 1

	return 1
end

function Main.API:HandleChannelMessage(message, sender, channelName)
	local playerName

	if not message or not channelName then
		return
	end

	if not string.find(string.lower(channelName), string.lower(self.channelName)) then
		return
	end

	playerName = UnitName("player")
	if playerName and sender and string.lower(sender) ~= string.lower(playerName) then
		return
	end

	if string.find(message, "^cfg,") then
		self:HandleConfigMessage(message)
	elseif string.find(message, "^gr,") then
		self:HandleGuildRosterHeader(message)
	elseif string.find(message, "^gm,") then
		self:HandleGuildRosterMember(message)
	elseif string.sub(message, 1, 1) == "-" then
		self:HandleErrorMessage(message)
	elseif not self:HandleTargetDistanceMessage(message) then
		self:HandleAuraMessage(message)
	end
end

function Main.API:OnUpdate()
	local now
	local distanceState
	local unitId
	local auraState

	if not self.startedAt then
		return
	end

	now = GetTime and GetTime() or 0

	if not Main.Initialized and (now - self.startedAt) >= self.fallbackDelaySeconds then
		Main_Start()
	end

	if self.requestPending and self.lastRequestAt and (now - self.lastRequestAt) >= self.requestRetrySeconds then
		self.requestPending = nil
	end

	if not self.configUnsupported and not self.remoteLoaded and not self.requestPending then
		self:RequestConfig()
	end

	distanceState = self.targetDistance
	if distanceState.requestPending and distanceState.lastRequestAt and
		(now - distanceState.lastRequestAt) >= distanceState.requestRetrySeconds then
		distanceState.requestPending = nil
		distanceState.requestToken = nil
	end

	Main_ForEach(self.unitAuras.states, function(unitId, auraState)
		if auraState.requestPending and auraState.lastRequestAt and
			(now - auraState.lastRequestAt) >= self.unitAuras.requestRetrySeconds then
			auraState.requestPending = nil
			auraState.requestToken = nil
		end
	end)

	if self.guildRoster and self.guildRoster.requestPending and self.guildRoster.lastRequestAt and
		(now - self.guildRoster.lastRequestAt) >= 5 then
		self.guildRoster.requestPending = nil
		self.guildRoster.requestToken = nil
	end
end
