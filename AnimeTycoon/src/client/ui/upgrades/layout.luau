--!strict
-- Размеры Upgrades = StarterGui.ScreenGui.Upgrade (Scale от Stage / Window).

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
        aspect = (1280 * 0.8 * 0.8) / (720 * 0.8 * 0.9),
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
        size = UDim2.fromScale(0.4, 0.256 / 0.12),
        pos = UDim2.fromScale(0.06, 0.3),
        anchor = Vector2.new(0.5, 0.5),
    },

    -- Scroll area below Title (Window fractions).
    -- Title center 0.06 h=0.12 → bottom ≈ 0.12; Home first row was at Y=0.29.
    scroll = {
        size = UDim2.fromScale(1, 0.84),
        pos = UDim2.fromScale(0.5, 0.58),
        anchor = Vector2.new(0.5, 0.5),
        -- Home↔Luck centers 0.32 apart, row h=0.28 → gap 0.04 of Window
        -- as fraction of scroll viewport (0.84):
        gapFrac = 0.04 / 0.84,
        padFrac = 0.02 / 0.84,
        -- Home Size Y = 0.28 of Window → of scroll:
        rowHFrac = 0.28 / 0.84,
        barThickness = 6,
    },

    -- Home / Luck item template (fractions of the row frame).
    row = {
        widthScale = 0.98,
        anchor = Vector2.new(0.5, 0.5),
        bg = {
            size = UDim2.fromScale(1, 1),
            pos = UDim2.fromScale(0, 0),
            anchor = Vector2.new(0, 0),
        },
        icon = {
            size = UDim2.fromScale(0.2, 1.15),
            pos = UDim2.fromScale(0.15, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
        title = {
            size = UDim2.fromScale(0.48, 0.35),
            pos = UDim2.fromScale(0.28, 0.2),
            anchor = Vector2.new(0, 0.5),
        },
        desc = {
            size = UDim2.fromScale(0.48, 0.25),
            pos = UDim2.fromScale(0.28, 0.5),
            anchor = Vector2.new(0, 0.5),
        },
        current = {
            size = UDim2.fromScale(0.48, 0.35),
            pos = UDim2.fromScale(0.28, 0.8),
            anchor = Vector2.new(0, 0.5),
        },
        money = {
            size = UDim2.fromScale(0.2, 0.43),
            pos = UDim2.fromScale(0.87, 0.27),
            anchor = Vector2.new(0.5, 0.5),
        },
        robux = {
            size = UDim2.fromScale(0.2, 0.43),
            pos = UDim2.fromScale(0.87, 0.75),
            anchor = Vector2.new(0.5, 0.5),
        },
        buttonLabel = {
            size = UDim2.fromScale(0.9, 0.9),
            pos = UDim2.fromScale(0.5, 0.45),
            anchor = Vector2.new(0.5, 0.5),
        },
        robuxIcon = {
            size = UDim2.fromScale(0.5, 1),
            pos = UDim2.fromScale(0.3, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
        robuxText = {
            size = UDim2.fromScale(1, 1),
            pos = UDim2.fromScale(0.67, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
    },
}

return SG
