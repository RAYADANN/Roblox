--!strict
-- ScreenGui profiles: HUD uses CoreUISafeInsets; modals ignore inset.

export type Profile = "hud" | "modal" | "toast" | "tutorial" | "tooltip" | "fx" | "loading"

local DISPLAY_ORDERS: { [Profile]: number } = {
    hud = 20,
    tutorial = 80,
    modal = 92,
    toast = 100,
    tooltip = 110,
    fx = 200,
    loading = 1000,
}

local FULL_BLEED: { [Profile]: boolean } = {
    fx = true,
    loading = true,
    modal = true,
    tutorial = true,
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
