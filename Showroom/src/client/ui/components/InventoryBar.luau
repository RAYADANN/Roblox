--!strict
-- Bottom-center inventory hotbar (screen Scale like BalanceChip / HUD icons).
-- PC: hotkey labels + click / key. Phone: touch only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local InventoryBarLogic = require(ReplicatedStorage.shared.util.InventoryBarLogic)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type InvItem = {
    uid: string,
    rarity: string,
    displayName: string,
    baseIncome: number,
}

export type Props = {
    items: { InvItem },
    handUid: string?,
    onSelect: (uid: string) -> (),
}

local L = theme.Layout.inventory

local HOTKEY_CODES: { Enum.KeyCode } = {
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four,
    Enum.KeyCode.Five,
    Enum.KeyCode.Six,
    Enum.KeyCode.Seven,
    Enum.KeyCode.Eight,
    Enum.KeyCode.Nine,
    Enum.KeyCode.Zero,
}

local function outlinedKey(): { [string]: React.Node }
    return {
        Outline = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = theme.Stroke.body,
            Transparency = 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            LineJoinMode = Enum.LineJoinMode.Round,
            StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
        }),
    }
end

local function Slot(props: {
    item: InvItem,
    index: number,
    selected: boolean,
    showHotkey: boolean,
    cellW: number,
    faceH: number,
    keyH: number?,
    onSelect: (uid: string) -> (),
}): React.Node
    -- Face frame is the selected square; unselected shrinks with UIScale.
    local targetScale = if props.selected then 1 else (1 / L.selectedScale)
    local scale = useFlipperSpring(targetScale, MotionPresets.SPRING_SNAPPY)
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.06,
        pressScale = 0.94,
    })
    local keyLabel = if props.showHotkey then InventoryBarLogic.hotkeyLabel(props.index) else nil
    local icon = IconCatalog.byKey(InventoryBarLogic.eggIconKey(props.item.rarity))

    return React.createElement("Frame", {
        LayoutOrder = props.index,
        Size = UDim2.fromScale(props.cellW, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = if props.selected then 3 else 2,
    }, {
        FaceHost = React.createElement("Frame", {
            Size = UDim2.fromScale(1, props.faceH),
            Position = UDim2.fromScale(0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, {
            Scale = React.createElement("UIScale", { Scale = scale * hoverScale }),
            Hit = React.createElement("ImageButton", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = theme.Colors.white,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Image = "",
                ZIndex = 2,
                [React.Event.Activated] = function()
                    props.onSelect(props.item.uid)
                end,
                [React.Event.MouseEnter] = handlers.onMouseEnter,
                [React.Event.MouseLeave] = handlers.onMouseLeave,
                [React.Event.MouseButton1Down] = handlers.onMouseDown,
                [React.Event.MouseButton1Up] = handlers.onMouseUp,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(L.cornerScale, 0),
                }),
                Stroke = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = L.strokeScale,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
                Egg = React.createElement("ImageLabel", {
                    Size = UDim2.fromScale(1 - L.iconPad * 2, 1 - L.iconPad * 2),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = icon,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 3,
                    Active = false,
                }),
            }),
        }),

        Key = if keyLabel and props.keyH
            then React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, props.keyH),
                Position = UDim2.fromScale(0.5, 1),
                AnchorPoint = Vector2.new(0.5, 1),
                BackgroundTransparency = 1,
                Text = keyLabel,
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 3,
            }, outlinedKey())
            else nil,
    })
end

local function InventoryBar(props: Props): React.Node
    local layout = useLayout()
    local items = props.items
    local showHotkeys = not layout.isTouch

    React.useEffect(function()
        if layout.isTouch or #items == 0 then
            return function() end
        end
        local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end
            for i, item in items do
                local code = HOTKEY_CODES[i]
                if code and input.KeyCode == code then
                    props.onSelect(item.uid)
                    return
                end
            end
        end)
        return function()
            conn:Disconnect()
        end
    end, { items, layout.isTouch, props.onSelect } :: { any })

    if #items == 0 then
        return nil :: any
    end

    local keyBlock = if showHotkeys then L.keyGap + L.keyH else 0
    local units = L.selectedScale + keyBlock
    local barH = L.slotH * units
    local vp = layout.viewport
    -- Square face side = slotH * selectedScale of screen height → width fraction of bar.
    local cellW = if vp.X > 1 then (L.slotH * L.selectedScale * vp.Y) / vp.X else L.slotH
    -- Face height fraction of cell: selected square / full bar (square + key).
    local faceH = L.selectedScale / units
    local keyH = if showHotkeys then L.keyH / units else nil

    local children: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(L.gapScale, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for i, item in items do
        children[`S{i}`] = React.createElement(Slot, {
            item = item,
            index = i,
            selected = props.handUid == item.uid,
            showHotkey = showHotkeys,
            cellW = cellW,
            faceH = faceH,
            keyH = keyH,
            onSelect = props.onSelect,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, barH),
        Position = UDim2.fromScale(0.5, 1 - L.padBottom),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 5,
    }, children)
end

return InventoryBar
