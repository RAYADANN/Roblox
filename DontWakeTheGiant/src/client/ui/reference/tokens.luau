--!strict
-- Design pixels for the reference window. Colors stay in theme.
-- Render these with one UIScale on the window. Do not fromScale the widgets.

local theme = require(script.Parent.Parent.theme)

local Tokens = {
    windowW = 720,
    windowH = 460,
    headerH = 72,
    pad = 24,
    close = 44,
    title = 28,
    body = 16,
    stroke = 2,
    zWindow = 50,

    font = theme.Font.title,
    bodyFont = theme.Font.body,
    bg = theme.Colors.panelBg,
    titleColor = theme.Colors.textMain,
    bodyColor = theme.Colors.textSub,
    strokeColor = theme.Colors.primary,
    closeBg = theme.Colors.bg3,
}

return Tokens
