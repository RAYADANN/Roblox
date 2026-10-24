--!strict
-- Карточка несомого предмета (GDD 11.1): имя, редкость, вес, множитель шума, кнопка «бросить».

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Button = require(script.Parent.Button)
local ItemsConfig = require(ReplicatedStorage.shared.data.ItemsConfig)
local NoiseLogic = require(ReplicatedStorage.shared.util.NoiseLogic)
local Rarity = require(ReplicatedStorage.shared.data.Rarity)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
    itemId: string,
    onDrop: () -> (),
}

local function CarryCard(props: Props): React.Node
    local layout = useLayout()
    local def = ItemsConfig.BY_ID[props.itemId]
    if not def then
        return nil
    end
    local color = (Rarity.DEFS :: any)[def.rarity].color
    local noiseMult = NoiseLogic.carryMult(def.weight, ItemsConfig.CARRY_NOISE_MULT)

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(layout.px(320), layout.px(92)),
        Position = UDim2.new(0.5, 0, 1, -layout.gap(16)),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = theme.Colors.panelBg,
        BorderSizePixel = 0,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
        Stroke = React.createElement("UIStroke", { Color = color, Thickness = 3 }),
        Name = React.createElement("TextLabel", {
            Size = UDim2.new(1, -layout.px(130), 0, layout.px(30)),
            Position = UDim2.fromOffset(layout.gap(12), layout.gap(8)),
            BackgroundTransparency = 1,
            Text = def.name,
            TextColor3 = color,
            Font = theme.Font.heavy,
            TextSize = layout.text(20, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }),
        Stats = React.createElement("TextLabel", {
            Size = UDim2.new(1, -layout.px(130), 0, layout.px(40)),
            Position = UDim2.fromOffset(layout.gap(12), layout.px(40)),
            BackgroundTransparency = 1,
            Text = `{def.rarity} · Weight {def.weight}\nNoise x{noiseMult}`,
            TextColor3 = theme.Colors.textSub,
            Font = theme.Font.body,
            TextSize = layout.text(18, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }),
        Drop = React.createElement("Frame", {
            Size = UDim2.fromOffset(layout.px(110), layout.touch(48)),
            Position = UDim2.new(1, -layout.gap(10), 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
        }, {
            Button = React.createElement(
                Button,
                { label = "DROP (Q)", variant = "secondary", onActivated = props.onDrop }
            ),
        }),
    })
end

return CarryCard
