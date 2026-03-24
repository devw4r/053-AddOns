TARGETDISTANCE_UPDATE_RATE = 0.1

local mapFileName = nil;
local mapSpanYardsX = nil;
local mapSpanYardsY = nil;

-- World map tile size used by the client/server world coordinate system.
local TILE_SIZE_YARDS = 533.333333;
local ADT_BLOCKS = 64;

-- Continent extents (in tiles) from DBFilesClient WorldMapArea (areaID = 0).
-- Azeroth:  left=5   right=61  top=23 bottom=60  -> 57 x 38
-- Kalimdor: left=1   right=63  top=10 bottom=51  -> 63 x 42
local CONTINENT_TILE_SPANS = {
	Azeroth = { width = 57, height = 38 },
	Kalimdor = { width = 63, height = 42 }
};
local targetDistanceEnabled = 1;
local TARGETDISTANCE_ADDON_CHANNEL = "_addondistance";
local TARGETDISTANCE_ADDON_PASSWORD = "tP4hSCpd8vWaun";
local serverDistanceYards = nil;
local serverDistanceRequestPending = nil;
local serverDistanceUnavailable = nil;

local function TargetDistance_GetAddonChannelNum()
	local channelNum = GetChannelName(TARGETDISTANCE_ADDON_CHANNEL);
	if (channelNum and channelNum > 0) then
		return channelNum;
	end

	JoinChannelByName(TARGETDISTANCE_ADDON_CHANNEL, TARGETDISTANCE_ADDON_PASSWORD);
	return nil;
end

local function TargetDistance_RequestServerDistance()
	if (not targetDistanceEnabled) then
		return nil;
	end

	if (serverDistanceRequestPending or serverDistanceUnavailable) then
		return nil;
	end

	local channelNum = TargetDistance_GetAddonChannelNum();
	if (channelNum and channelNum > 0) then
		SendChatMessage("getunitdistance target", "CHANNEL", nil, channelNum);
		serverDistanceRequestPending = 1;
		return 1;
	end

	return nil;
end

local function TargetDistance_ConsumeServerDistanceMessage(message)
	if (not message) then
		return;
	end

	-- Addon error payload format starts with a negative code, e.g. "-3, target".
	if (string.sub(message, 1, 1) == "-") then
		serverDistanceYards = nil;
		serverDistanceUnavailable = 1;
		serverDistanceRequestPending = nil;
		return;
	end

	local commaIndex = string.find(message, ",");
	if (not commaIndex) then
		return;
	end

	local unitId = string.lower(string.gsub(string.sub(message, 1, commaIndex - 1), "%s+", ""));
	if (unitId ~= "target") then
		return;
	end

	local distanceValue = tonumber(string.gsub(string.sub(message, commaIndex + 1), "%s+", ""));
	if (distanceValue) then
		serverDistanceYards = math.floor(distanceValue + 0.5);
		serverDistanceUnavailable = nil;
		serverDistanceRequestPending = nil;
	end
end

function TargetDistance_UpdateMapSpan()
	mapSpanYardsX = nil;
	mapSpanYardsY = nil;

	if (not mapFileName) then
		return;
	end

	if (string.find(mapFileName, "Azeroth") ~= nil) then
		mapSpanYardsX = CONTINENT_TILE_SPANS.Azeroth.width * TILE_SIZE_YARDS;
		mapSpanYardsY = CONTINENT_TILE_SPANS.Azeroth.height * TILE_SIZE_YARDS;
		return;
	end

	if (string.find(mapFileName, "Kalimdor") ~= nil) then
		mapSpanYardsX = CONTINENT_TILE_SPANS.Kalimdor.width * TILE_SIZE_YARDS;
		mapSpanYardsY = CONTINENT_TILE_SPANS.Kalimdor.height * TILE_SIZE_YARDS;
		return;
	end

	-- Fallback for unknown/custom maps:
	-- use full WDT span (64 ADTs * 533.333 yards).
	-- This is generic and usually better than disabling, but less accurate than explicit spans.
	mapSpanYardsX = ADT_BLOCKS * TILE_SIZE_YARDS;
	mapSpanYardsY = ADT_BLOCKS * TILE_SIZE_YARDS;
end

function TargetDistance_OnLoad()
	TargetDistanceFrame.TimeSinceLastUpdate = 0;
	TargetDistanceText:SetText("");
	
	if(not (Cosmos_RegisterConfiguration == nil)) then
		Cosmos_RegisterConfiguration("COS_TARGETDISTANCEHEADER", "SEPARATOR", TARGETDISTANCE_SEP, TARGETDISTANCE_SEP_INFO );
		Cosmos_RegisterConfiguration("COS_TARGETDISTANCE", "CHECKBOX", 
			TARGETDISTANCE_CHECK, 
			TARGETDISTANCE_CHECK_INFO,
			TargetDistance_Toggle,
			1
			);
	else
		-- ADD STANDALONE CONFIG HERE
	end

	TargetDistanceFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
	TargetDistanceFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	TargetDistanceFrame:RegisterEvent("CHAT_MSG_CHANNEL");
	TargetDistance_OnEvent();
	
end

function TargetDistance_Toggle(toggle)
	if ( toggle == 1 ) then 
		targetDistanceEnabled = 1;
		if ((TargetFrame) and (TargetFrame:IsVisible())) then
			TargetDistanceFrame:Show();
		else
			TargetDistanceFrame:Hide();
		end
	else
		targetDistanceEnabled = 0;
		TargetDistanceFrame:Hide();
		TargetDistanceText:SetText("");
		serverDistanceYards = nil;
		serverDistanceUnavailable = nil;
		serverDistanceRequestPending = nil;
	end
end

function TargetDistance_OnUpdate(arg1)
	if (not targetDistanceEnabled) then
		return;
	end

	if ( (( TaxiFrame ) and ( TaxiFrame:IsVisible() )) or (( MerchantFrame ) and ( MerchantFrame:IsVisible() )) or ((TradeSkillFrame) and (TradeSkillFrame:IsVisible())) or ((SuggestFrame) and (SuggestFrame:IsVisible())) or ((WhoFrame) and (WhoFrame:IsVisible())) or ((AuctionFrame) and (AuctionFrame:IsVisible())) or ((MailFrame) and (MailFrame:IsVisible())) ) then
		TargetDistanceFrame:Show();
		TargetDistanceText:SetText("Disabled");
		return;
	end
	TargetDistanceFrame.TimeSinceLastUpdate = TargetDistanceFrame.TimeSinceLastUpdate + arg1;
	if((not TargetFrame) or (not TargetFrame:IsVisible())) then
		TargetDistanceText:SetText("");
		TargetDistanceFrame:Hide();
		return;
	end
	TargetDistanceFrame:Show();

	if( TargetDistanceFrame.TimeSinceLastUpdate > TARGETDISTANCE_UPDATE_RATE ) then
		local distance = nil;
		if ( TargetDistance_SetContinent() == 1) then
			distance = TargetDistance_GetDistanceText();
		end

		if (distance) then
			TargetDistanceText:SetText(format(TARGETDISTANCE_DISTANCE,distance));
		else
			if (serverDistanceYards) then
				TargetDistanceText:SetText(format(TARGETDISTANCE_DISTANCE, serverDistanceYards));
			else
				TargetDistance_RequestServerDistance();
				TargetDistanceText:SetText("Disabled");
			end
		end

		TargetDistanceFrame.TimeSinceLastUpdate = 0;
	end
end

function TargetDistance_OnEvent()
	if (event == "CHAT_MSG_CHANNEL") then
		local channelName = arg4 and string.lower(arg4) or nil;
		if (channelName and string.find(channelName, TARGETDISTANCE_ADDON_CHANNEL)) then
			TargetDistance_ConsumeServerDistanceMessage(arg1);
		end
		return;
	end

	if (event == "PLAYER_ENTERING_WORLD") then
		serverDistanceYards = nil;
		serverDistanceUnavailable = nil;
		serverDistanceRequestPending = nil;
	end

	if (event == "PLAYER_TARGET_CHANGED") then
		serverDistanceYards = nil;
		serverDistanceUnavailable = nil;
		serverDistanceRequestPending = nil;
	end

	if (not targetDistanceEnabled) then
		TargetDistanceFrame:Hide();
		return;
	end

	if ((not TargetFrame) or (not TargetFrame:IsVisible())) then
		TargetDistanceText:SetText("");
		TargetDistanceFrame:Hide();
	else
		TargetDistanceFrame:Show();
	end
end

function TargetDistance_GetDistanceText()
	if (mapFileName == nil or mapSpanYardsX == nil or mapSpanYardsY == nil) then
		return nil;
	end

	local tx, ty = GetPlayerMapPosition("target"); 
	local px, py = GetPlayerMapPosition("player");
	
	if(tx == 0 and ty == 0) then
		  -- probably in an instance, no map position
		return nil;
	end
	
	if(px == 0 and py == 0) then
		  -- probably in an instance, no map position
		return nil;
	end

	local xdelta = (tx - px) * mapSpanYardsX;
	local ydelta = (ty - py) * mapSpanYardsY;

	-- Match server spell range checks as closely as possible with available API data (2D planar distance).
	local distance = math.sqrt((xdelta * xdelta) + (ydelta * ydelta));
	distance = math.floor(distance + 0.5);

	return distance.."";
end

function TargetDistance_SetContinent()
	local continent = GetCurrentMapContinent();
	local x = 0;
	local y = 0;
	local foundValidMap = nil;

	-- Try the currently selected continent first.
	if (continent and continent > 0) then
		SetMapZoom(continent, nil);
		x, y = GetPlayerMapPosition("player");
		if (x ~= 0 or y ~= 0) then
			foundValidMap = 1;
		end
	end

	-- If coordinates are invalid, probe both classic continents.
	if (not foundValidMap) then
		SetMapZoom(1, nil);
		x, y = GetPlayerMapPosition("player");
		if (x ~= 0 or y ~= 0) then
			foundValidMap = 1;
		else
			SetMapZoom(2, nil);
			x, y = GetPlayerMapPosition("player");
			if (x ~= 0 or y ~= 0) then
				foundValidMap = 1;
			end
		end
	end

	if (not foundValidMap) then
		return 0;
	end

	mapFileName = GetMapInfo();
	if (not mapFileName) then
		return 0;
	end

	TargetDistance_UpdateMapSpan();
	return 1;
end
