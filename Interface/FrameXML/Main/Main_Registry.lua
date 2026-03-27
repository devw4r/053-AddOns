function Main.RegisterModule(id, definition)
	local count

	if not id or not definition or Main.Modules[id] then
		return
	end

	definition.id = id
	definition.name = definition.name or id
	definition.description = definition.description or ""

	Main.Modules[id] = definition
	count = Main_ArrayCount(Main.ModuleOrder)
	Main.ModuleOrder[count + 1] = id
end

function Main.GetModule(id)
	return Main.Modules[id]
end

function Main.GetRuntimeModuleEnabled(id)
	local module

	module = Main.GetModule(id)
	if module and module.runtimeEnabled ~= nil then
		return module.runtimeEnabled
	end

	return nil
end

function Main.GetModuleByIndex(index)
	local id

	id = Main.ModuleOrder[index]
	if not id then
		return nil
	end

	return Main.Modules[id]
end

function Main.GetModuleCount()
	return Main_ArrayCount(Main.ModuleOrder)
end

function Main.IsModuleVisibleInManager(module)
	return module and not module.managerHidden
end

function Main.GetVisibleModuleCount()
	local i
	local module
	local count

	count = 0
	for i = 1, Main.GetModuleCount() do
		module = Main.GetModuleByIndex(i)
		if Main.IsModuleVisibleInManager(module) then
			count = count + 1
		end
	end

	return count
end

function Main.GetVisibleModuleByIndex(index)
	local i
	local module
	local visibleCount

	visibleCount = 0
	for i = 1, Main.GetModuleCount() do
		module = Main.GetModuleByIndex(i)
		if Main.IsModuleVisibleInManager(module) then
			visibleCount = visibleCount + 1
			if visibleCount == index then
				return module
			end
		end
	end

	return nil
end

function Main.InitializeModule(id)
	local module

	module = Main.GetModule(id)
	if not module or module.initialized then
		return
	end

	module.initialized = 1
	if module.Init then
		module:Init()
	end
end

function Main.EnableModule(id, skipRefresh, forceLive)
	local module

	module = Main.GetModule(id)
	if not module then
		return
	end

	Main.InitializeModule(id)
	Main.SetConfiguredModuleEnabled(id, true, 1)

	if module.reloadRequired and Main.Initialized and not forceLive then
		if not skipRefresh then
			Main.SaveConfig()
		end

		if not skipRefresh and Main.ScheduleManagerRefresh then
			Main.ScheduleManagerRefresh()
		elseif not skipRefresh and Main.RefreshManager then
			Main.RefreshManager()
		end
		return
	end

	if module.runtimeEnabled ~= true then
		module.runtimeEnabled = true
		if module.Enable then
			module:Enable()
		end
	end
	if module.ApplyConfig then
		module:ApplyConfig()
	end

	if not skipRefresh then
		Main.SaveConfig()
	end

	if not skipRefresh and Main.RefreshManager then
		Main.RefreshManager()
	end
end

function Main.DisableModule(id, skipRefresh, forceLive)
	local module

	module = Main.GetModule(id)
	if not module then
		return
	end

	Main.InitializeModule(id)
	Main.SetConfiguredModuleEnabled(id, false, 1)

	if module.reloadRequired and Main.Initialized and not forceLive then
		if not skipRefresh then
			Main.SaveConfig()
		end

		if not skipRefresh and Main.ScheduleManagerRefresh then
			Main.ScheduleManagerRefresh()
		elseif not skipRefresh and Main.RefreshManager then
			Main.RefreshManager()
		end
		return
	end

	if module.runtimeEnabled ~= false then
		module.runtimeEnabled = false
		if module.Disable then
			module:Disable()
		end
	end

	if not skipRefresh then
		Main.SaveConfig()
	end

	if not skipRefresh and Main.RefreshManager then
		Main.RefreshManager()
	end
end

function Main.IsModuleEnabled(id)
	local module

	module = Main.GetModule(id)
	if module then
		if module.runtimeEnabled ~= nil then
			return module.runtimeEnabled
		end
	end

	return Main.GetConfiguredModuleEnabled(id)
end

function Main.ApplyConfiguredModuleStates(skipRefresh, forceLive)
	local i
	local module

	for i = 1, Main.GetModuleCount() do
		module = Main.GetModuleByIndex(i)
		if module then
			if Main.GetConfiguredModuleEnabled(module.id) then
				Main.EnableModule(module.id, 1, forceLive)
			else
				Main.DisableModule(module.id, 1, forceLive)
			end
		end
	end

	if not skipRefresh and Main.RefreshManager then
		Main.RefreshManager()
	end
end

function Main.InitializeModules()
	local i
	local module

	if Main.ModulesInitialized then
		Main.ApplyConfiguredModuleStates(1)
		return
	end

	for i = 1, Main.GetModuleCount() do
		module = Main.GetModuleByIndex(i)
		if module then
			Main.InitializeModule(module.id)
		end
	end

	Main.ModulesInitialized = 1
	Main.ApplyConfiguredModuleStates(1)
end
