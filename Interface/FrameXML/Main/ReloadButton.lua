local MainReloadButton = {
	name = "Reload Button",
	description = "Adds a Reload UI button to the escape menu.",
}

local function MainReloadButton_UpdateVisibility()
	if MainGameMenuButtonReload then
		if Main.IsModuleEnabled("reload_button") then
			MainGameMenuButtonReload:Show()
		else
			MainGameMenuButtonReload:Hide()
		end
	end

	-- Some debug builds expose a standalone reload button. Hide it while the cleaner menu button is active.
	if ReloadButton then
		if Main.IsModuleEnabled("reload_button") then
			ReloadButton:Hide()
		else
			ReloadButton:Show()
		end
	end

	if Main_AdjustGameMenu then
		Main_AdjustGameMenu()
	end
end

function MainReloadButton:Init()
	MainReloadButton_UpdateVisibility()
end

function MainReloadButton:Enable()
	MainReloadButton_UpdateVisibility()
end

function MainReloadButton:Disable()
	MainReloadButton_UpdateVisibility()
end

Main.RegisterModule("reload_button", MainReloadButton)
