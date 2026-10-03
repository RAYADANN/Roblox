--!strict
-- Hoarcekat: Roblox-native text FX lab (не AE-shimmer).
-- Path: ReplicatedStorage.UI.stories.RobloxTextFx

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FxCell = require(script.Parent.robloxTextFx.FxCell)
local mount = require(script.Parent.mount)

local SAMPLES = {
    "Golden",
    "Galaxy",
    "+50K",
    "CLAIM",
    "Rare",
    "Diamond",
    "Mythic",
    "+1.2M",
    "Secret",
    "LIMITED",
}

local function Story(): React.Node
    local cells: { [string]: React.Node } = {
        Layout = React.createElement("UIGridLayout", {
            CellSize = UDim2.fromOffset(176, 96),
            CellPadding = UDim2.fromOffset(10, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirectionMaxCells = 5,
        }),
    }

    for variant = 1, 10 do
        cells["V" .. variant] = React.createElement(FxCell, {
            variant = variant,
            sampleText = SAMPLES[variant],
            layoutOrder = variant,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(10, 12, 18),
        BorderSizePixel = 0,
    }, {
        Pad = React.createElement("UIPadding", {
            PaddingTop = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
        }),
        Intro = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundTransparency = 1,
            Text = "Roblox-native text FX lab — FredokaOne + UIStroke. Pick for mutation/rarity later.\nHardSweep / StripeBand / ScaleBounce / FloatBob / Blink / StrokeThrob / HueCycle / PopBurst / SnapSheen / DualFlash",
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(170, 178, 200),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
        }),
        Grid = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, -56),
            Position = UDim2.fromOffset(0, 52),
            BackgroundTransparency = 1,
        }, cells),
    })
end

return mount.screen(React.createElement(Story))
