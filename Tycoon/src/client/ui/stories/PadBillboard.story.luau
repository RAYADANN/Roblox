--!strict
-- Hoarcekat: paid pad Billboard (TagName + Robux + price). Path: ReplicatedStorage.UI.stories.PadBillboard
-- Screen mock of Workspace IslandMain.Buttons.* BillboardGui — not a world Billboard.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

-- Matches Studio pad Price UIGradient (yellow → dark orange, rot 90).
local PRICE_GRADIENT = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 0)),
    ColorSequenceKeypoint.new(0.642, Color3.fromRGB(244, 163, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
})

local STROKE = Color3.fromRGB(0, 39, 56)

export type CardProps = {
    title: string,
    robux: number,
    owned: boolean?,
}

local function PadBillboardCard(props: CardProps): React.Node
    local owned = props.owned == true
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0),
        }),
        TagName = React.createElement("TextLabel", {
            Size = UDim2.fromScale(1, 0.48),
            BackgroundTransparency = 1,
            Text = props.title,
            Font = theme.Font.display,
            TextScaled = true,
            TextColor3 = theme.Colors.white,
            TextXAlignment = Enum.TextXAlignment.Center,
            LayoutOrder = 1,
        }, {
            Stroke = React.createElement("UIStroke", {
                Color = STROKE,
                Thickness = 0.1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
            }),
        }),
        PriceRow = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 0.48),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 2,
        }, {
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0.01, 0),
            }),
            RobuxIcon = if owned
                then nil
                else React.createElement("ImageLabel", {
                    Size = UDim2.fromScale(0.3, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = IconCatalog.Robux,
                    ScaleType = Enum.ScaleType.Fit,
                    LayoutOrder = 1,
                }, {
                    Aspect = React.createElement("UIAspectRatioConstraint", {
                        AspectRatio = 1,
                        DominantAxis = Enum.DominantAxis.Height,
                    }),
                }),
            Price = React.createElement("TextLabel", {
                Size = if owned then UDim2.fromScale(1, 1) else UDim2.fromScale(0.22, 0.92),
                BackgroundTransparency = 1,
                Text = if owned then "OWNED" else tostring(props.robux),
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                TextXAlignment = if owned
                    then Enum.TextXAlignment.Center
                    else Enum.TextXAlignment.Left,
                LayoutOrder = 2,
            }, {
                Stroke = React.createElement("UIStroke", {
                    Color = STROKE,
                    Thickness = 0.1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
                Gradient = if owned
                    then nil
                    else React.createElement("UIGradient", {
                        Color = PRICE_GRADIENT,
                        Rotation = 90,
                    }),
            }),
        }),
    })
end

local function StoryApp(): React.Node
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(210, 190, 150),
        BorderSizePixel = 0,
    }, {
        Hint = React.createElement("TextLabel", {
            Size = UDim2.fromScale(0.8, 0.06),
            Position = UDim2.fromScale(0.5, 0.12),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Text = "Pad Billboard (Robux) — Auto Collect / X2",
            Font = theme.Font.body,
            TextScaled = true,
            TextColor3 = theme.Colors.bg1,
        }),
        Buy = React.createElement("Frame", {
            Size = UDim2.fromScale(0.42, 0.14),
            Position = UDim2.fromScale(0.5, 0.4),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
        }, {
            Card = React.createElement(PadBillboardCard, {
                title = "Auto Collect",
                robux = 149,
                owned = false,
            }),
        }),
        Owned = React.createElement("Frame", {
            Size = UDim2.fromScale(0.42, 0.14),
            Position = UDim2.fromScale(0.5, 0.62),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
        }, {
            Card = React.createElement(PadBillboardCard, {
                title = "X2 Items",
                robux = 149,
                owned = true,
            }),
        }),
    })
end

return mount.screen(React.createElement(StoryApp))
