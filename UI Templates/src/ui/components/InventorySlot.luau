--!strict
-- Slot card fills grid cell (1×1). Inner chrome uses Scale; stroke from theme.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ActionButton = require(script.Parent.ActionButton)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local useMountAppear = require(script.Parent.Parent.hooks.useMountAppear)

export type Item = {
    id: string,
    name: string,
    rarity: theme.SlotRarity?,
    count: number,
    max: number?,
}

export type Props = {
    item: Item,
    selected: boolean?,
    layoutOrder: number?,
    appearDelay: number?,
    onSelect: ((id: string) -> ())?,
    onEquip: ((id: string) -> ())?,
    onUpgrade: ((id: string) -> ())?,
}

local function InventorySlot(props: Props): React.Node
    local item = props.item
    local selected = props.selected == true
    local appearScale, appearTransparency = useMountAppear({
        delay = props.appearDelay or 0,
        fromScale = 0.92,
    })
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.04,
        pressScale = 0.97,
    })
    local scale = appearScale * hoverScale

    local children: { [string]: React.Node } = {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(theme.Radius.slot, 0),
        }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = theme.Stroke.slot,
            Transparency = appearTransparency,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
        Pad = React.createElement("UIPadding", {
            PaddingTop = UDim.new(0.06, 0),
            PaddingBottom = UDim.new(0.06, 0),
            PaddingLeft = UDim.new(0.06, 0),
            PaddingRight = UDim.new(0.06, 0),
        }),
        Qty = React.createElement("TextLabel", {
            Size = UDim2.fromScale(0.45, 0.2),
            Position = UDim2.fromScale(1, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Text = `x{item.count}`,
            Font = theme.Font.display,
            TextScaled = true,
            TextColor3 = theme.Colors.white,
            TextTransparency = appearTransparency,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 2,
        }, {
            Outline = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.text,
                Transparency = appearTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            }),
        }),
        Name = React.createElement("TextLabel", {
            Size = UDim2.fromScale(1, 0.22),
            Position = UDim2.fromScale(0.5, 1),
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundTransparency = 1,
            Text = item.name,
            Font = theme.Font.display,
            TextScaled = true,
            TextColor3 = theme.Colors.white,
            TextTransparency = appearTransparency,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 2,
        }, {
            Outline = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.text,
                Transparency = appearTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            }),
        }),
    }

    if selected then
        children.Actions = React.createElement("Frame", {
            Size = UDim2.fromScale(0.92, 0.48),
            Position = UDim2.fromScale(0.5, 0.48),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ZIndex = 3,
        }, {
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0.06, 0),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            Upgrade = React.createElement(ActionButton, {
                tone = "buy",
                shine = "linear",
                label = "Upgrade",
                size = UDim2.fromScale(1, 0.44),
                lockAspect = false,
                appearDelay = (props.appearDelay or 0) + 0.08,
                layoutOrder = 1,
                onActivated = function()
                    if props.onUpgrade then
                        props.onUpgrade(item.id)
                    end
                end,
            }),
            Equip = React.createElement(ActionButton, {
                tone = "equip",
                shine = "linear",
                label = "Equip",
                size = UDim2.fromScale(1, 0.44),
                lockAspect = false,
                appearDelay = (props.appearDelay or 0) + 0.12,
                layoutOrder = 2,
                onActivated = function()
                    if props.onEquip then
                        props.onEquip(item.id)
                    end
                end,
            }),
        })
    end

    return React.createElement("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Colors.slotEmpty,
        BackgroundTransparency = appearTransparency,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ClipsDescendants = true,
        LayoutOrder = props.layoutOrder,
        [React.Event.Activated] = function()
            if props.onSelect then
                props.onSelect(item.id)
            end
        end,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, children)
end

return InventorySlot
