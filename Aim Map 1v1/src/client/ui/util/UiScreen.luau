--!strict
-- Профили ScreenGui: единый порядок слоёв + safe insets для интерактива.

export type Profile = "hud" | "aim" | "modal" | "toast" | "tutorial" | "tooltip" | "fx" | "loading"

local DISPLAY_ORDERS: { [Profile]: number } = {
    hud = 20,
    -- Optical-center overlay (crosshair / hitmarker) above chrome, below menus.
    aim = 25,
    tutorial = 80,
    modal = 92,
    toast = 100,
    tooltip = 110,
    fx = 200,
    loading = 1000,
}

-- Full-bleed (scrim / FX / fullscreen modals) vs interactive (notch + Roblox core UI).
local FULL_BLEED: { [Profile]: boolean } = {
    fx = true,
    loading = true,
    -- Crosshair must sit on the 3D viewport center, not the CoreUISafeInsets rect.
    aim = true,
    -- Inventory / settings overlays: ignore topbar inset so DesignRoot fits the real screen.
    modal = true,
}

local UiScreen = {}

function UiScreen.apply(gui: ScreenGui, profile: Profile)
    gui.ResetOnSpawn = false
    gui.DisplayOrder = DISPLAY_ORDERS[profile]
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if FULL_BLEED[profile] then
        gui.ScreenInsets = Enum.ScreenInsets.None
        gui.IgnoreGuiInset = true
        gui.ClipToDeviceSafeArea = false
    else
        -- Interactive HUD/modals live in the core-safe rect (notch + topbar).
        gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
        gui.IgnoreGuiInset = false
        gui.ClipToDeviceSafeArea = true
    end
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
