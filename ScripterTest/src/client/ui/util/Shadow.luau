--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

local function shadowElement(def: theme.ShadowDef): React.Node
    return React.createElement("UIShadow", {
        BlurRadius = def.blurRadius,
        Offset = def.offset,
        Spread = def.spread,
        Color = def.color,
        Transparency = def.transparency,
        ZIndex = def.zIndex,
        Enabled = true,
    })
end

return {
    element = shadowElement,
}
