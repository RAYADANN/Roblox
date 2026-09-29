--!strict
-- Токены Index UI.

local Tokens = {
    strokePanel = 0.01,
    strokeCard = 0.02,
    strokeBtn = 0.05,
    strokeText = 0.055,
    strokeTitle = 0.05,
    strokeShadow = 0.07,

    font = Enum.Font.FredokaOne,
    windowBg = Color3.fromRGB(0, 0, 0),
    windowBgTransparency = 0.5,
    titleWhite = Color3.fromRGB(255, 255, 255),
    titleShadow = Color3.fromRGB(0, 0, 0),
    -- StarterGui NormalItem price ($100/Toy) UIGradient
    valueGradient = {
        rotation = 90,
        color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(48, 255, 11)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 255, 127)),
        }),
    },
    muted = Color3.fromRGB(180, 180, 180),
}

return Tokens
