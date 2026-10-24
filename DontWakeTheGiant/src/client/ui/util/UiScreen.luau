--!strict
-- Профили ScreenGui: единый порядок слоёв.

export type Profile =
    "hud"
    | "modal"
    | "toast"
    | "tutorial"
    | "tooltip"
    | "fx"
    | "currency"
    | "loading"

-- ScreenGui.DisplayOrder. Currency stays above FX so the balance remains readable.
local DISPLAY_ORDERS: { [Profile]: number } = {
    hud = 20,
    tutorial = 80,
    modal = 92,
    toast = 100,
    tooltip = 110,
    fx = 200,
    currency = 250,
    loading = 1000,
}

-- ZIndex when several layers share one ScreenGui.
local LAYER: { [string]: number } = {
    icons = 10,
    window = 50,
    fx = 60,
    money = 100,
}

local UiScreen = {
    Layer = LAYER,
}

function UiScreen.apply(gui: ScreenGui, profile: Profile)
    gui.ResetOnSpawn = false
    gui.DisplayOrder = DISPLAY_ORDERS[profile]
    gui.ScreenInsets = Enum.ScreenInsets.None
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
