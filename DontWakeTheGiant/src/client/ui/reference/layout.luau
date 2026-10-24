--!strict
-- Absolute design offsets for the reference window. The only size source for this screen.

local tokens = require(script.Parent.tokens)

local Layout = {
    window = UDim2.fromOffset(tokens.windowW, tokens.windowH),
    header = UDim2.fromOffset(tokens.windowW, tokens.headerH),
    close = UDim2.fromOffset(tokens.close, tokens.close),
    title = UDim2.fromOffset(tokens.windowW - tokens.close - tokens.pad * 3, tokens.headerH),
    body = UDim2.fromOffset(
        tokens.windowW - tokens.pad * 2,
        tokens.windowH - tokens.headerH - tokens.pad * 2
    ),
}

return Layout
