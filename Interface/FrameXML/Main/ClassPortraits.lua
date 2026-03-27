local MainClassPortraits = {
	name = "Class Portraits",
	description = "Replaces player and target 3D portraits with class icon circles.",
}

local MAIN_CLASS_PORTRAITS_TEXTURE = "Interface\\FrameXML\\Main\\Media\\UI-Classes-Circles"

local mainClassPortraitsOriginalUnitFrameUpdate = nil
local mainClassPortraitsOriginalUnitFrameOnEvent = nil
local mainClassPortraitsOriginalPlayerFrameOnEvent = nil
local mainClassPortraitsOriginalTargetFrameUpdate = nil

local function MainClassPortraits_IsEnabled()
	return Main.IsModuleEnabled("class_portraits")
end

local function MainClassPortraits_RefreshPortrait(frame)
	local className
	local textureCoords

	if not frame or not frame.portrait or not frame.unit then
		return
	end

	if MainClassPortraits_IsEnabled() and UnitIsPlayer(frame.unit) and not UnitIsCharmed(frame.unit) then
		className = UnitClass(frame.unit)
		textureCoords = className and CLASS_ICON_TCOORDS[strupper(className)] or nil
		if textureCoords then
			frame.portrait:SetTexture(MAIN_CLASS_PORTRAITS_TEXTURE)
			frame.portrait:SetTexCoord(textureCoords[1], textureCoords[2], textureCoords[3], textureCoords[4])
			return
		end
	end

	SetPortraitTexture(frame.portrait, frame.unit)
	frame.portrait:SetTexCoord(0, 1, 0, 1)
end

local function MainClassPortraits_RefreshAll()
	MainClassPortraits_RefreshPortrait(PlayerFrame)
	MainClassPortraits_RefreshPortrait(TargetFrame)
end

local function MainClassPortraits_InstallHooks()
	if mainClassPortraitsOriginalUnitFrameUpdate then
		return
	end

	mainClassPortraitsOriginalUnitFrameUpdate = UnitFrame_Update
	UnitFrame_Update = function()
		mainClassPortraitsOriginalUnitFrameUpdate()
		MainClassPortraits_RefreshPortrait(this)
	end

	mainClassPortraitsOriginalUnitFrameOnEvent = UnitFrame_OnEvent
	UnitFrame_OnEvent = function(event)
		mainClassPortraitsOriginalUnitFrameOnEvent(event)
		MainClassPortraits_RefreshPortrait(this)
	end

	if PlayerFrame_OnEvent then
		mainClassPortraitsOriginalPlayerFrameOnEvent = PlayerFrame_OnEvent
		PlayerFrame_OnEvent = function(event)
			mainClassPortraitsOriginalPlayerFrameOnEvent(event)
			MainClassPortraits_RefreshPortrait(PlayerFrame)
		end
	end

	if TargetFrame_Update then
		mainClassPortraitsOriginalTargetFrameUpdate = TargetFrame_Update
		TargetFrame_Update = function()
			mainClassPortraitsOriginalTargetFrameUpdate()
			MainClassPortraits_RefreshPortrait(TargetFrame)
		end
	end
end

function MainClassPortraits:Init()
	MainClassPortraits_InstallHooks()
	Main.RegisterEventHandler("PLAYER_ENTERING_WORLD", "class_portraits", function()
		MainClassPortraits_RefreshAll()
	end)
	Main.RegisterEventHandler("PLAYER_TARGET_CHANGED", "class_portraits_target", function()
		MainClassPortraits_RefreshPortrait(TargetFrame)
	end)
end

function MainClassPortraits:Enable()
	MainClassPortraits_RefreshAll()
end

function MainClassPortraits:Disable()
	MainClassPortraits_RefreshAll()
end

Main.RegisterModule("class_portraits", MainClassPortraits)
