--!strict
-- Размеры Rewards = StarterGui + сетка 3×4 как на референсе.

local SG = {
    stage = {
        size = UDim2.fromScale(0.8, 0.8),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
    },
    window = {
        size = UDim2.fromScale(0.8, 0.9),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        aspect = (1280 * 0.8) / (720 * 0.9),
    },
    title = {
        size = UDim2.fromScale(1, 0.12),
        pos = UDim2.fromScale(0.5, 0.06),
        anchor = Vector2.new(0.5, 0.5),
    },
    titleShadow = {
        size = UDim2.fromScale(0.3, 1),
        pos = UDim2.fromScale(0.27, 0.5),
        anchor = Vector2.new(0.5, 0.5),
    },
    titleText = {
        size = UDim2.fromScale(0.3, 1),
        pos = UDim2.fromScale(0.27, 0.4),
        anchor = Vector2.new(0.5, 0.5),
    },
    close = {
        size = UDim2.fromScale(0.075, 0.8),
        pos = UDim2.fromScale(0.95, 0.48),
        anchor = Vector2.new(0.5, 0.5),
    },
    icon = {
        size = UDim2.fromScale(2.2, 2.2),
        pos = UDim2.fromScale(0.075, 0.25),
        anchor = Vector2.new(0.5, 0.5),
    },

    -- 4 колонки × 3 ряда
    grid = {
        columns = 4,
        cardSize = UDim2.fromScale(0.2, 0.175),
        xs = { 0.14, 0.38, 0.62, 0.86 },
        ys = { 0.26, 0.46, 0.66 },
        anchor = Vector2.new(0.5, 0.5),
    },

    card = {
        stroke = 0.03,
        value = {
            size = UDim2.fromScale(1, 0.28),
            pos = UDim2.fromScale(0.5, 0.14),
            anchor = Vector2.new(0.5, 0.5),
        },
        subtitle = {
            size = UDim2.fromScale(1, 0.28),
            pos = UDim2.fromScale(0.5, 0.88),
            anchor = Vector2.new(0.5, 0.5),
        },
        icon = {
            size = UDim2.fromScale(1.35, 1.033),
            pos = UDim2.fromScale(0.5, 0.52),
            anchor = Vector2.new(0.5, 0.5),
        },
        case = {
            size = UDim2.fromScale(0.8, 0.8),
            pos = UDim2.fromScale(0.5, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
    },

    leaving = {
        size = UDim2.fromScale(0.55, 0.1),
        pos = UDim2.fromScale(0.3, 0.88),
        anchor = Vector2.new(0.5, 0.5),
    },
    skip = {
        size = UDim2.fromScale(0.32, 0.15),
        pos = UDim2.fromScale(0.78, 0.88),
        anchor = Vector2.new(0.5, 0.5),
        labelSize = UDim2.fromScale(1, 0.7),
        labelPos = UDim2.fromScale(0.5, 0.45),
        priceSize = UDim2.fromScale(0.45, 0.5),
        pricePos = UDim2.fromScale(0.5, 1),
        robuxSize = UDim2.fromScale(0.5, 1),
        robuxPos = UDim2.fromScale(0.25, 0.5),
        amountSize = UDim2.fromScale(0.55, 1),
        amountPos = UDim2.fromScale(0.68, 0.5),
    },
}

return SG
