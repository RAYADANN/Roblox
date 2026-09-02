--!strict
-- Inventory tile: icon + EQUIP + name under the button.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local RarityLogic = require(ReplicatedStorage.shared.util.RarityLogic)
local SimPopBlock = require(script.Parent.Parent.simpop.block.SimPopBlock)
local SimPopButton = require(script.Parent.Parent.simpop.SimPopButton)
local theme = require(script.Parent.Parent.theme)

export type Props = {
    id: string,
    name: string,
    rarity: string,
    image: string?,
    equipped: boolean?,
    owned: boolean?,
    layoutOrder: number?,
    --- Multiplier for icon size (cases use 2).
    iconScale: number?,
    onEquip: (() -> ())?,
}

local ICON_W = 0.82
local ICON_H = 0.5

local function InventorySlot(props: Props): React.Node
    local tone = RarityLogic.blockTone(props.rarity)
    local owned = props.owned == true
    local equipped = props.equipped == true
    local image = props.image
    local hasImage = typeof(image) == "string" and image ~= "" and image ~= "rbxassetid://0"
    local iconMul = math.max(0.1, props.iconScale or 1)
    local dimmed = not owned

    local equipLabel = if not owned then "LOCKED" elseif equipped then "EQUIPPED" else "EQUIP"
    local equipDisabled = not owned or equipped
    local displayName = string.upper(props.name)

    return React.createElement(SimPopBlock, {
        tone = tone,
        size = UDim2.fromScale(1, 1),
        preserveAspect = false,
        selected = equipped,
        -- Keep hover/shine on locked cards; only the button is gated.
        disabled = false,
        layoutOrder = props.layoutOrder,
        children = {
            Icon = if hasImage
                then React.createElement("ImageLabel", {
                    Size = UDim2.fromScale(ICON_W, ICON_H),
                    Position = UDim2.fromScale(0.5, 0.3),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = image :: string,
                    ImageTransparency = if owned then 0 else 0.45,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 2,
                }, {
                    Scale = if iconMul ~= 1
                        then React.createElement("UIScale", { Scale = iconMul })
                        else nil,
                })
                else nil,
            Equip = React.createElement("Frame", {
                Size = UDim2.fromScale(0.88, 0.2),
                Position = UDim2.fromScale(0.5, 0.86),
                AnchorPoint = Vector2.new(0.5, 1),
                BackgroundTransparency = 1,
                ZIndex = 5,
            }, {
                Btn = React.createElement(SimPopButton, {
                    tone = tone,
                    orientation = "horizontal",
                    label = equipLabel,
                    size = UDim2.fromScale(1, 1),
                    preserveAspect = false,
                    disabled = equipDisabled,
                    onActivated = if owned and not equipped then props.onEquip else nil,
                }),
            }),
            Name = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 0.14),
                Position = UDim2.fromScale(0.5, 0.955),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = displayName,
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                TextTransparency = if dimmed then 0.35 else 0,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 3,
            }, {
                Pad = React.createElement("UIPadding", {
                    PaddingLeft = UDim.new(0.04, 0),
                    PaddingRight = UDim.new(0.04, 0),
                }),
                Outline = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = theme.Stroke.title,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                }),
            }),
        },
    })
end

return InventorySlot
