--!strict

local Tokens = {
    strokePanel = 0.01,
    strokeBtn = 0.06,
    strokeText = 0.05,
    strokeTitle = 0.05,
    strokeShadow = 0.07,
    strokeCard = 0.03,
    strokeCardClaimable = 0.055,

    font = Enum.Font.FredokaOne,
    windowBg = Color3.fromRGB(0, 0, 0),
    windowBgTransparency = 0.5,
    titleWhite = Color3.fromRGB(255, 255, 255),
    titleShadow = Color3.fromRGB(0, 0, 0),
    claimGlow = Color3.fromRGB(255, 255, 255),

    -- OP! yellow → orange (референс Day 7)
    opGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 20)),
    }),
}

return Tokens
