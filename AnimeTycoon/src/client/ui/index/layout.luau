--!strict
-- Размеры Index = StarterGui.ScreenGui.Index (Scale от Window / Stage).

local SG = {
    stage = {
        size = UDim2.fromScale(0.8, 0.8),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
    },
    window = {
        size = UDim2.fromScale(0.7, 0.9),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        aspect = (1280 * 0.7) / (720 * 0.9),
    },
    title = {
        size = UDim2.fromScale(1, 0.12),
        pos = UDim2.fromScale(0.5, 0.06),
        anchor = Vector2.new(0.5, 0.5),
    },
    titleShadow = {
        size = UDim2.fromScale(0.2, 1),
        pos = UDim2.fromScale(0.27, 0.5),
        anchor = Vector2.new(0.5, 0.5),
    },
    titleText = {
        size = UDim2.fromScale(0.2, 1),
        pos = UDim2.fromScale(0.27, 0.4),
        anchor = Vector2.new(0.5, 0.5),
    },
    close = {
        size = UDim2.fromScale(0.075, 0.8),
        pos = UDim2.fromScale(0.95, 0.48),
        anchor = Vector2.new(0.5, 0.5),
    },
    -- Stage Icon 0.15×0.23 @ (0.203, 0.09) → Title (Window×title)
    icon = {
        size = UDim2.fromScale(0.4, 0.256 / 0.12),
        pos = UDim2.fromScale((0.203 - 0.15) / 0.7, (0.09 - 0.05) / 0.9 / 0.12),
        anchor = Vector2.new(0.5, 0.5),
    },

    tab = {
        size = UDim2.fromScale(0.16, 0.09),
        y = 0.2,
        firstX = 0.14,
        stepX = 0.18,
        anchor = Vector2.new(0.5, 0.5),
        labelSize = UDim2.fromScale(0.9, 0.9),
        labelPos = UDim2.fromScale(0.5, 0.45),
    },

    -- Скролл сетки под табами (доли Window)
    content = {
        top = 0.26,
        bottom = 0.03,
    },

    -- NormalItem 0.28×0.47 Window → 3 в ряд, вертикальный скролл
    card = {
        size = UDim2.fromScale(0.28, 0.47),
        columns = 3,
        pad = 0.04,
        gap = 0.02,
        rowGap = 0.03,
        bottomPad = 0.04,
        anchor = Vector2.new(0.5, 0.5),
        name = {
            size = UDim2.fromScale(1, 0.2),
            pos = UDim2.fromScale(0.5, 0.1),
            anchor = Vector2.new(0.5, 0.5),
        },
        value = {
            size = UDim2.fromScale(1, 0.15),
            pos = UDim2.fromScale(0.5, 0.65),
            anchor = Vector2.new(0.5, 0.5),
        },
        mutation = {
            size = UDim2.fromScale(1, 0.15),
            pos = UDim2.fromScale(0.5, 0.78),
            anchor = Vector2.new(0.5, 0.5),
        },
        rare = {
            size = UDim2.fromScale(1, 0.15),
            pos = UDim2.fromScale(0.5, 0.92),
            anchor = Vector2.new(0.5, 0.5),
        },
        lock = {
            size = UDim2.fromScale(0.5, 0.5),
            pos = UDim2.fromScale(0.5, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
    },
}

return SG
