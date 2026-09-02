--!strict
-- Hoarcekat: DuelHud (SimPop rails + CTAs). Path: ReplicatedStorage.UI.stories.DuelHud

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DuelHud = require(script.Parent.Parent.components.DuelHud)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local function log(action: string)
    return function()
        print(`[DuelHud] {action}`)
    end
end

return mount(React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = theme.Colors.bg1,
    BorderSizePixel = 0,
}, {
    Hud = React.createElement(DuelHud, {
        statusText = "Practice — shoot the BOT dummies",
        scoreText = "Solo aim",
        skinText = "USP · Default",
        recordText = "W 3  ·  L 1  ·  Sens 1.0",
        hintText = "Alt — cursor · K — sens · shoot wall for crosshair",
        health = 72,
        maxHealth = 100,
        showVsBot = true,
        showRematch = true,
        rematchReady = false,
        settingsOpen = false,
        onSettings = log("settings"),
        onVsBot = log("vsBot"),
        onRematch = log("rematch"),
        onShop = log("shop"),
        onInvite = log("invite"),
        onInventory = log("inventory"),
    }),
}))
