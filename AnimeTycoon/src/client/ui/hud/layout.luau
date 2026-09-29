--!strict
-- Размеры HUD = StarterGui.ScreenGui.HUD.

local SG = {
    money = {
        size = UDim2.fromScale(0.3, 0.1),
        pos = UDim2.fromScale(0.14, 0.92),
        anchor = Vector2.new(0.5, 0.5),
        icon = {
            size = UDim2.fromScale(0.3, 1.5),
            pos = UDim2.fromScale(0.2, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
        amount = {
            size = UDim2.fromScale(0.6, 1),
            pos = UDim2.fromScale(0.65, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
    },
    icons = {
        size = UDim2.fromScale(0.2, 0.5),
        pos = UDim2.fromScale(0.12, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        buttonSize = UDim2.fromScale(0.4, 0.3),
        -- 2×2: Shop / Rebirth top; Gift / Index bottom
        shop = { pos = UDim2.fromScale(0.25, 0.2), anchor = Vector2.new(0.5, 0.5) },
        rebirth = { pos = UDim2.fromScale(0.75, 0.2), anchor = Vector2.new(0.5, 0.5) },
        gift = { pos = UDim2.fromScale(0.25, 0.6), anchor = Vector2.new(0.5, 0.5) },
        index = { pos = UDim2.fromScale(0.75, 0.6), anchor = Vector2.new(0.5, 0.5) },
        label = {
            size = UDim2.fromScale(1, 0.37),
            pos = UDim2.fromScale(0.5, 0.95),
            anchor = Vector2.new(0.5, 0.5),
        },
        icon = {
            size = UDim2.fromScale(1, 1),
            pos = UDim2.fromScale(0.5, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
    },
}

return SG
