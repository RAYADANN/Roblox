--!strict
-- Размеры DailyRewards = StarterGui; Day7 текст — как на референсе.

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
        size = UDim2.fromScale(0.55, 1),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
    },
    titleText = {
        size = UDim2.fromScale(0.55, 1),
        pos = UDim2.fromScale(0.5, 0.4),
        anchor = Vector2.new(0.5, 0.5),
    },
    close = {
        size = UDim2.fromScale(0.075, 0.8),
        pos = UDim2.fromScale(0.95, 0.48),
        anchor = Vector2.new(0.5, 0.5),
    },
    -- Icon относительно Title (не Stage) — иначе Sibling ZIndex перекрывает Close
    icon = {
        size = UDim2.fromScale(2.2, 2.2),
        pos = UDim2.fromScale(0.1, 0.25),
        anchor = Vector2.new(0.5, 0.5),
    },

    -- 3×2 дни 1–6 (центр по X = 0.5, края совпадают с Day7 width 0.85)
    grid = {
        cardSize = UDim2.fromScale(0.27, 0.27),
        xs = { 0.21, 0.5, 0.79 },
        ys = { 0.28, 0.58 },
        anchor = Vector2.new(0.5, 0.5),
    },

    card = {
        value = {
            size = UDim2.fromScale(1, 0.3),
            pos = UDim2.fromScale(0.5, 0.15),
            anchor = Vector2.new(0.5, 0.5),
        },
        subtitle = {
            size = UDim2.fromScale(1, 0.3),
            pos = UDim2.fromScale(0.5, 0.85),
            anchor = Vector2.new(0.5, 0.5),
        },
        icon = {
            size = UDim2.fromScale(1, 1),
            pos = UDim2.fromScale(0.5, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
    },

    day7 = {
        size = UDim2.fromScale(0.85, 0.23),
        pos = UDim2.fromScale(0.5, 0.85),
        anchor = Vector2.new(0.5, 0.5),
        dayLabel = {
            size = UDim2.fromScale(0.22, 0.55),
            pos = UDim2.fromScale(0.14, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
        icon = {
            size = UDim2.fromScale(0.28, 0.72),
            pos = UDim2.fromScale(0.5, 0.4),
            anchor = Vector2.new(0.5, 0.5),
        },
        name = {
            size = UDim2.fromScale(0.42, 0.22),
            pos = UDim2.fromScale(0.5, 0.82),
            anchor = Vector2.new(0.5, 0.5),
        },
        op = {
            size = UDim2.fromScale(0.22, 0.6),
            pos = UDim2.fromScale(0.86, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
    },
}

return SG
