--!strict
-- Размеры Offline Earnings = StarterGui (Scale от Window / Stage).

local SG = {
    stage = {
        size = UDim2.fromScale(0.8, 0.8),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
    },
    window = {
        size = UDim2.fromScale(0.7, 0.8),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        aspect = (1280 * 0.7) / (720 * 0.8),
    },
    title = {
        size = UDim2.fromScale(1, 0.12),
        pos = UDim2.fromScale(0.5, 0.06),
        anchor = Vector2.new(0.5, 0.5),
    },
    titleShadow = {
        size = UDim2.fromScale(0.9, 1),
        pos = UDim2.fromScale(0.45, 0.5),
        anchor = Vector2.new(0.5, 0.5),
    },
    titleText = {
        size = UDim2.fromScale(0.9, 1),
        pos = UDim2.fromScale(0.45, 0.4),
        anchor = Vector2.new(0.5, 0.5),
    },
    -- Stage Icon 0.15×0.23 @ (0.203, 0.09) → Title (Window origin Stage 0.15,0.1)
    icon = {
        size = UDim2.fromScale(2.2, 2.2),
        pos = UDim2.fromScale(0.1, 0.25),
        anchor = Vector2.new(0.5, 0.5),
    },

    headline = {
        size = UDim2.fromScale(0.7, 0.15),
        pos = UDim2.fromScale(0.5, 0.25),
        anchor = Vector2.new(0.5, 0.5),
    },
    divider = {
        size = UDim2.fromScale(0.01, 0.3),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
    },

    currentLabel = {
        size = UDim2.fromScale(0.3, 0.05),
        pos = UDim2.fromScale(0.25, 0.4),
        anchor = Vector2.new(0.5, 0.5),
    },
    currentMoney = {
        size = UDim2.fromScale(0.3, 0.6),
        pos = UDim2.fromScale(0.25, 0.54),
        anchor = Vector2.new(0.5, 0.5),
    },
    doubleLabel = {
        size = UDim2.fromScale(0.3, 0.05),
        pos = UDim2.fromScale(0.75, 0.4),
        anchor = Vector2.new(0.5, 0.5),
    },
    doubleMoney = {
        size = UDim2.fromScale(0.3, 0.6),
        pos = UDim2.fromScale(0.75, 0.54),
        anchor = Vector2.new(0.5, 0.5),
    },

    cancel = {
        size = UDim2.fromScale(0.45, 0.12),
        pos = UDim2.fromScale(0.25, 0.85),
        anchor = Vector2.new(0.5, 0.5),
        labelSize = UDim2.fromScale(1, 0.85),
    },
    doubleBtn = {
        size = UDim2.fromScale(0.45, 0.15),
        pos = UDim2.fromScale(0.75, 0.85),
        anchor = Vector2.new(0.5, 0.5),
        badge = {
            size = UDim2.fromScale(0.5, 0.6),
            pos = UDim2.fromScale(0.5, -0.1),
            anchor = Vector2.new(0.5, 0.5),
        },
        label = {
            size = UDim2.fromScale(1, 0.7),
            pos = UDim2.fromScale(0.5, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
        price = {
            size = UDim2.fromScale(0.5, 0.6),
            pos = UDim2.fromScale(0.5, 1.1),
            anchor = Vector2.new(0.5, 0.5),
        },
    },
}

return SG
