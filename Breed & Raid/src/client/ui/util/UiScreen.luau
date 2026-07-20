--!strict

export type Profile = "hud" | "modal" | "toast"

local DISPLAY_ORDERS: { [Profile]: number } = {
	hud = 20,
	modal = 92,
	toast = 100,
}

local UiScreen = {}

function UiScreen.apply(gui: ScreenGui, profile: Profile)
	gui.ResetOnSpawn = false
	gui.DisplayOrder = DISPLAY_ORDERS[profile]
	gui.IgnoreGuiInset = true
end

function UiScreen.ensure(parent: Instance, name: string, profile: Profile): ScreenGui
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("ScreenGui") then
		UiScreen.apply(existing, profile)
		return existing
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.Parent = parent
	UiScreen.apply(gui, profile)
	return gui
end

return UiScreen
