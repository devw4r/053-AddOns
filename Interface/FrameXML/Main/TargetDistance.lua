local MainTargetDistance = {
	name = "Target Distance",
	description = "Shows distance to your current target with local map math and server fallback.",
}

local MAIN_TARGET_DISTANCE_UPDATE_RATE = 1
local MAIN_TARGET_DISTANCE_FORMAT = "%d yds"
local MAIN_TARGET_DISTANCE_PENDING_TEXT = "-- yds"
local MAIN_TARGET_DISTANCE_CONTINENT_SPANS_YARDS = {
	Azeroth = { width = 57 * 533.333333, height = 38 * 533.333333 },
	Kalimdor = { width = 63 * 533.333333, height = 42 * 533.333333 },
}

local function MainTargetDistance_SetText(distanceYards)
	if distanceYards then
		MainTargetDistanceText:SetText(format(MAIN_TARGET_DISTANCE_FORMAT, distanceYards))
	else
		MainTargetDistanceText:SetText("")
	end
end

local function MainTargetDistance_UpdateAnchor()
	if not MainTargetDistanceFrame or not TargetPortrait then
		return
	end

	MainTargetDistanceFrame:ClearAllPoints()
	if TargetName and TargetName.IsVisible and TargetName:IsVisible() and TargetName.GetText and TargetName:GetText() and TargetName:GetText() ~= "" then
		MainTargetDistanceFrame:SetPoint("BOTTOM", "TargetPortrait", "TOP", 0, 16)
	else
		MainTargetDistanceFrame:SetPoint("BOTTOM", "TargetPortrait", "TOP", 0, 4)
	end
end

local function MainTargetDistance_GetMapSpan(mapFileName)
	if not mapFileName then
		return nil, nil
	end

	if string.find(mapFileName, "Azeroth") then
		return MAIN_TARGET_DISTANCE_CONTINENT_SPANS_YARDS.Azeroth.width, MAIN_TARGET_DISTANCE_CONTINENT_SPANS_YARDS.Azeroth.height
	end

	if string.find(mapFileName, "Kalimdor") then
		return MAIN_TARGET_DISTANCE_CONTINENT_SPANS_YARDS.Kalimdor.width, MAIN_TARGET_DISTANCE_CONTINENT_SPANS_YARDS.Kalimdor.height
	end

	return nil, nil
end

local function MainTargetDistance_RestoreMapSelection(continent, zone)
	if not continent then
		return
	end

	if continent == 0 then
		SetMapZoom(0)
	elseif zone and zone > 0 then
		SetMapZoom(continent, zone)
	else
		SetMapZoom(continent)
	end
end

local function MainTargetDistance_SelectContinent(continent)
	local playerX
	local playerY

	if not continent or continent <= 0 then
		return nil
	end

	SetMapZoom(continent)
	playerX, playerY = GetPlayerMapPosition("player")
	if playerX == 0 and playerY == 0 then
		return nil
	end

	return continent, GetMapInfo()
end

local function MainTargetDistance_GetLocalDistanceYards()
	local originalContinent
	local originalZone
	local selectedContinent
	local mapFileName
	local spanX
	local spanY
	local playerX
	local playerY
	local targetX
	local targetY
	local deltaX
	local deltaY

	originalContinent = GetCurrentMapContinent()
	if GetCurrentMapZone then
		originalZone = GetCurrentMapZone()
	else
		originalZone = 0
	end

	-- Target distance should not permanently change the world map selection while probing continents.
	selectedContinent, mapFileName = MainTargetDistance_SelectContinent(originalContinent)
	if not selectedContinent then
		selectedContinent, mapFileName = MainTargetDistance_SelectContinent(1)
	end
	if not selectedContinent then
		selectedContinent, mapFileName = MainTargetDistance_SelectContinent(2)
	end

	if not selectedContinent then
		MainTargetDistance_RestoreMapSelection(originalContinent, originalZone)
		return nil
	end

	spanX, spanY = MainTargetDistance_GetMapSpan(mapFileName)
	playerX, playerY = GetPlayerMapPosition("player")
	targetX, targetY = GetPlayerMapPosition("target")

	MainTargetDistance_RestoreMapSelection(originalContinent, originalZone)

	if not spanX or not spanY then
		return nil
	end
	if not playerX or not playerY or not targetX or not targetY then
		return nil
	end
	if (playerX == 0 and playerY == 0) or (targetX == 0 and targetY == 0) then
		return nil
	end

	deltaX = (targetX - playerX) * spanX
	deltaY = (targetY - playerY) * spanY
	return floor(math.sqrt((deltaX * deltaX) + (deltaY * deltaY)) + 0.5)
end

local function MainTargetDistance_UpdateDisplay()
	local distanceYards

	if not Main.IsModuleEnabled("target_distance") then
		MainTargetDistanceFrame:Hide()
		return
	end

	if not TargetFrame or not TargetFrame:IsVisible() or not UnitExists("target") then
		MainTargetDistance_SetText(nil)
		MainTargetDistanceFrame:Hide()
		return
	end

	MainTargetDistance_UpdateAnchor()
	MainTargetDistanceFrame:Show()
	distanceYards = MainTargetDistance_GetLocalDistanceYards()
	if distanceYards then
		MainTargetDistance_SetText(distanceYards)
		return
	end

	distanceYards = Main.API and Main.API.GetTargetDistanceYards and Main.API:GetTargetDistanceYards() or nil
	if distanceYards then
		MainTargetDistance_SetText(distanceYards)
		return
	end

	if Main.API then
		Main.API:RequestTargetDistance()
	end

	if Main.API and Main.API:IsTargetDistanceUnavailable() then
		MainTargetDistance_SetText(nil)
	else
		MainTargetDistanceText:SetText(MAIN_TARGET_DISTANCE_PENDING_TEXT)
	end
end

function MainTargetDistanceFrame_OnLoad()
	this.elapsed = 0
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("PLAYER_TARGET_CHANGED")
	MainTargetDistance_SetText(nil)
	this:Hide()
end

function MainTargetDistanceFrame_OnEvent(event)
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then
		if Main.API then
			Main.API:ResetTargetDistance()
		end
		this.elapsed = MAIN_TARGET_DISTANCE_UPDATE_RATE
		MainTargetDistance_UpdateDisplay()
	end
end

function MainTargetDistanceFrame_OnUpdate(elapsed)
	if not UnitExists or not UnitExists("target") then
		MainTargetDistance_SetText(nil)
		MainTargetDistanceFrame:Hide()
		return
	end

	this.elapsed = this.elapsed + elapsed
	if this.elapsed < MAIN_TARGET_DISTANCE_UPDATE_RATE then
		return
	end

	this.elapsed = 0
	MainTargetDistance_UpdateDisplay()
end

function MainTargetDistance:Init()
	MainTargetDistanceFrame:Hide()
end

function MainTargetDistance:Enable()
	if Main.API then
		Main.API:ResetTargetDistance()
	end
	MainTargetDistance_UpdateDisplay()
end

function MainTargetDistance:Disable()
	if Main.API then
		Main.API:ResetTargetDistance()
	end
	MainTargetDistance_SetText(nil)
	MainTargetDistanceFrame:Hide()
end

function MainTargetDistance:OnUILayoutChanged()
	if not Main.IsModuleEnabled("target_distance") then
		return
	end

	MainTargetDistance_UpdateDisplay()
end

Main.RegisterModule("target_distance", MainTargetDistance)
