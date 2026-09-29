--!strict
-- Hoarcekat: Rebirth modal (perks + progress). Path: ReplicatedStorage.UI.stories.Rebirth

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignRoot = require(script.Parent.Parent.DesignRoot)
local RebirthLogic = require(ReplicatedStorage.shared.util.RebirthLogic)
local RebirthPanel = require(script.Parent.Parent.components.RebirthPanel)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local REBIRTHS = 0

local function Story(): React.Node
    local canAfford, setCanAfford = React.useState(true)
    local need = RebirthLogic.cost(REBIRTHS)
    local coins = if canAfford then need else math.floor(need * 0.25)

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Colors.bg2,
        BorderSizePixel = 0,
    }, {
        Canvas = React.createElement(DesignRoot, {}, {
            Panel = React.createElement(RebirthPanel, {
                coins = coins,
                rebirths = REBIRTHS,
                onClose = function()
                    print("[Rebirth story] close")
                end,
                onRebirth = function()
                    print("[Rebirth story] rebirth")
                end,
                onSkip = function()
                    print("[Rebirth story] skip")
                end,
            }),
        }),
        Toggle = React.createElement("TextButton", {
            Size = UDim2.fromOffset(160, 36),
            Position = UDim2.new(0, 12, 1, -12),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Color3.fromRGB(40, 44, 48),
            BorderSizePixel = 0,
            Text = if canAfford then "State: ready" else "State: not ready",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            ZIndex = 50,
            [React.Event.Activated] = function()
                setCanAfford(not canAfford)
            end,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
        }),
    })
end

return mount.screen(React.createElement(Story))
