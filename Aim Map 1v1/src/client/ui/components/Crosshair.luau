--!strict
-- HUD crosshair from selected preset (CrosshairDatabase). Design @ 1920×1080.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local CrosshairDatabase = require(ReplicatedStorage.shared.data.CrosshairDatabase)
local CrosshairLogic = require(ReplicatedStorage.shared.util.CrosshairLogic)

export type Props = {
    crosshairId: string,
}

local function arm(color: Color3, outline: boolean, size: UDim2, pos: UDim2): React.Node
    return React.createElement("Frame", {
        Size = size,
        Position = pos,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, {
        Stroke = if outline
            then React.createElement("UIStroke", {
                Color = Color3.new(0, 0, 0),
                Thickness = 1,
            })
            else nil,
    })
end

local function Crosshair(props: Props): React.Node
    local id = CrosshairLogic.resolve(props.crosshairId)
    local def = CrosshairDatabase.get(id) or CrosshairDatabase.get(CrosshairLogic.default())
    if not def then
        return nil
    end

    local color = Color3.new(def.r, def.g, def.b)
    -- Preset numbers authored ~1280 space → ×1.5 for 1920 canvas.
    local size = math.floor(def.size * 1.5 + 0.5)
    local gap = math.floor(def.gap * 1.5 + 0.5)
    local thick = math.max(1, math.floor(def.thickness * 1.5 + 0.5))
    local children: { [string]: React.Node } = {}

    if def.style == "dot" or def.style == "cross_dot" then
        local dotSize = if def.style == "dot" then size else math.max(4, thick + 1)
        children.Dot = React.createElement("Frame", {
            Size = UDim2.fromOffset(dotSize, dotSize),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = 7,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Stroke = if def.outline
                then React.createElement("UIStroke", {
                    Color = Color3.new(0, 0, 0),
                    Thickness = 1,
                })
                else nil,
        })
    end

    if def.style == "circle" then
        children.Ring = React.createElement("Frame", {
            Size = UDim2.fromOffset(size, size),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 6,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Stroke = React.createElement("UIStroke", {
                Color = color,
                Thickness = thick,
            }),
        })
    end

    if
        def.style == "cross"
        or def.style == "cross_dot"
        or def.style == "gap_cross"
        or def.style == "t"
    then
        local half = size
        local g = gap
        children.Left = arm(
            color,
            def.outline,
            UDim2.fromOffset(half, thick),
            UDim2.new(0.5, -(g + half / 2), 0.5, 0)
        )
        children.Right = arm(
            color,
            def.outline,
            UDim2.fromOffset(half, thick),
            UDim2.new(0.5, g + half / 2, 0.5, 0)
        )
        children.Bottom = arm(
            color,
            def.outline,
            UDim2.fromOffset(thick, half),
            UDim2.new(0.5, 0, 0.5, g + half / 2)
        )
        if def.style ~= "t" then
            children.Top = arm(
                color,
                def.outline,
                UDim2.fromOffset(thick, half),
                UDim2.new(0.5, 0, 0.5, -(g + half / 2))
            )
        end
    end

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(96, 96),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 5,
    }, children)
end

return Crosshair
