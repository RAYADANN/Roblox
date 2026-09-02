--!strict
-- Right-side kill-flex CTA. Shows until the next round starts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Button = require(script.Parent.Button)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local SkinDatabase = require(ReplicatedStorage.shared.data.SkinDatabase)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)

export type Props = {
    token: number,
    skinId: string,
    owned: boolean,
    equipped: boolean,
    onEquip: () -> (),
}

local PANEL_W = 286
local PANEL_H = 244
local PREVIEW_W = 250
local PREVIEW_H = 94

local function rarityLabel(rarity: string): string
    return string.upper(string.sub(rarity, 1, 1)) .. string.sub(rarity, 2)
end

local function SkinOfferPanel(props: Props): React.Node
    local def = SkinDatabase.get(props.skinId)
    if not def then
        return nil
    end

    local scaleTarget, setScaleTarget = React.useState(0.88)
    local cardScale = useFlipperSpring(scaleTarget, MotionPresets.SPRING_BOUNCY)
    local skinImages = UiImageCatalog.skins :: { [string]: string }
    local image = skinImages[props.skinId] or "rbxassetid://0"
    local hasImage = image ~= "" and image ~= "rbxassetid://0"
    local rarityColor = theme.Rarity[def.rarity] or theme.Colors.textSub
    local tracer = SkinDatabase.tracerRgb(props.skinId)
    local buttonLabel = if props.equipped
        then "Equipped"
        elseif props.owned then "Equip"
        else "Not owned"
    local hintText = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        then "Tap Equip before next round"
        else "Press Y or Equip before next round"

    React.useEffect(function()
        setScaleTarget(1.06)
        local popBack = task.delay(0.08, function()
            setScaleTarget(1)
        end)
        return function()
            task.cancel(popBack)
        end
    end, { props.token })

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(PANEL_W, PANEL_H),
        BackgroundColor3 = theme.Colors.panelBg,
        BorderSizePixel = 0,
    }, {
        Scale = React.createElement("UIScale", {
            Scale = cardScale,
        }),
        Corner = React.createElement("UICorner", {
            CornerRadius = theme.Radius.panel,
        }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.dockBorder,
            Thickness = theme.Stroke.medium,
        }),
        Accent = React.createElement("Frame", {
            Size = UDim2.new(0, 4, 1, 0),
            BackgroundColor3 = rarityColor,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = theme.Radius.panel,
            }),
        }),
        Title = React.createElement("TextLabel", {
            Size = UDim2.new(1, -32, 0, 30),
            Position = UDim2.fromOffset(18, 14),
            BackgroundTransparency = 1,
            Text = "Skin offer",
            TextColor3 = theme.Colors.textMuted,
            TextSize = 17,
            Font = theme.Font.body,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Name = React.createElement("TextLabel", {
            Size = UDim2.new(1, -32, 0, 36),
            Position = UDim2.fromOffset(18, 34),
            BackgroundTransparency = 1,
            Text = SkinDatabase.displayName(props.skinId),
            TextColor3 = theme.Colors.textMain,
            TextSize = 28,
            Font = theme.Font.heavy,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Rarity = React.createElement("TextLabel", {
            Size = UDim2.new(1, -32, 0, 24),
            Position = UDim2.fromOffset(18, 66),
            BackgroundTransparency = 1,
            Text = rarityLabel(def.rarity),
            TextColor3 = rarityColor,
            TextSize = 18,
            Font = theme.Font.title,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Preview = React.createElement("Frame", {
            Size = UDim2.fromOffset(PREVIEW_W, PREVIEW_H),
            Position = UDim2.fromOffset(18, 96),
            BackgroundColor3 = theme.Colors.bg3,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = theme.Radius.btn,
            }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.bg4,
                Thickness = theme.Stroke.thin,
            }),
            Bar = React.createElement("Frame", {
                Size = UDim2.new(1, -18, 0, 6),
                Position = UDim2.fromOffset(9, PREVIEW_H - 15),
                BackgroundColor3 = Color3.fromRGB(tracer.r, tracer.g, tracer.b),
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = theme.Radius.pill,
                }),
            }),
            Content = if hasImage
                then React.createElement("ImageLabel", {
                    Size = UDim2.new(1, -18, 1, -22),
                    Position = UDim2.fromOffset(9, 8),
                    BackgroundTransparency = 1,
                    Image = image,
                    ScaleType = Enum.ScaleType.Fit,
                })
                else React.createElement("TextLabel", {
                    Size = UDim2.new(1, -20, 1, -24),
                    Position = UDim2.fromOffset(10, 8),
                    BackgroundTransparency = 1,
                    Text = "USP",
                    TextColor3 = theme.Colors.textMain,
                    TextSize = 34,
                    Font = theme.Font.heavy,
                }),
        }),
        Hint = React.createElement("TextLabel", {
            Size = UDim2.new(1, -32, 0, 24),
            Position = UDim2.fromOffset(18, 195),
            BackgroundTransparency = 1,
            Text = hintText,
            TextColor3 = theme.Colors.textSub,
            TextSize = 16,
            Font = theme.Font.body,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Action = React.createElement("Frame", {
            Size = UDim2.fromOffset(214, 52),
            Position = UDim2.fromOffset(18, 218),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
        }, {
            Button = React.createElement(Button, {
                label = buttonLabel,
                onActivated = props.onEquip,
                variant = if props.equipped then "secondary" else "sell",
                disabled = not props.owned or props.equipped,
                width = 214,
                height = 52,
            }),
        }),
    })
end

return SkinOfferPanel
