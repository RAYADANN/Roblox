--!strict

local Tokens = {
    strokePanel = 0.01,
    strokeBtn = 0.05,
    strokeText = 0.06,
    strokeTitle = 0.05,
    strokeShadow = 0.07,

    font = Enum.Font.FredokaOne,
    windowBg = Color3.fromRGB(0, 0, 0),
    windowBgTransparency = 0.5,
    titleWhite = Color3.fromRGB(255, 255, 255),
    titleShadow = Color3.fromRGB(0, 0, 0),
    muted = Color3.fromRGB(147, 147, 147),

    -- StarterGui DoubleText / DoubleMoney (rotation -90)
    moneyGradient = {
        rotation = -90,
        color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(48, 255, 11)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 255, 127)),
        }),
    },
}

return Tokens
