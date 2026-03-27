local MainClientTweaks = {
	name = "Client Settings",
	description = "Applies small client-side behavior toggles.",
	managerHidden = 1,
	options = {
		{
			type = "toggle",
			key = "client_auto_loot",
			label = "Auto-loot",
			defaultValue = true,
		},
	},
}

local function MainClientTweaks_OnLootOpened()
	local itemCount
	local slot

	if not Main.IsModuleEnabled("client_tweaks") or not Main.GetBoolSetting("client_auto_loot", true) then
		return
	end

	itemCount = GetNumLootItems()
	for slot = 1, itemCount do
		LootSlot(slot, 0)
	end
end

function MainClientTweaks:Init()
	-- Auto-loot is event-driven, so register once and let the handler check the module state.
	--
	-- Do not expose a live UI scale option here. The 0.5.3 client applies UI scale
	-- through the internal "scaleui" console command, which calls CGGameUI::ScaleUI()
	-- and CLayoutFrame::SetLayoutScale(). That path is not script-exposed to Lua.
	Main.RegisterEventHandler("LOOT_OPENED", "client_tweaks", MainClientTweaks_OnLootOpened)
end

Main.RegisterModule("client_tweaks", MainClientTweaks)
