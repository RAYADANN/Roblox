--!strict
-- Studio-only: тестовый фасад HUD для MCP/execute. Живёт в ReplicatedStorage,
-- чтобы bind из LocalScript и вызов из execute делили один синглтон.

export type HudApi = {
	openTab: (self: HudApi, tabId: string) -> (),
	closePanel: (self: HudApi) -> (),
}

local StudioTestHud = {}

local _hud: HudApi? = nil

function StudioTestHud.bind(hud: HudApi): ()
	_hud = hud
end

function StudioTestHud.clear(): ()
	_hud = nil
end

function StudioTestHud.openTab(tabId: string): boolean
	if _hud then
		_hud:openTab(tabId)
		return true
	end
	return false
end

function StudioTestHud.closePanel(): boolean
	if _hud then
		_hud:closePanel()
		return true
	end
	return false
end

function StudioTestHud.isBound(): boolean
	return _hud ~= nil
end

return StudioTestHud
