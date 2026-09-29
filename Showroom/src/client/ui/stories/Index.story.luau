--!strict
-- Hoarcekat: Index modal (egg tabs + pet cards + evolutions).
-- Path: ReplicatedStorage.UI.stories.Index

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignRoot = require(script.Parent.Parent.DesignRoot)
local IndexPanel = require(script.Parent.Parent.components.IndexPanel)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local DEMO_OWNED: { [string]: boolean } = {
    cat = true,
    cat_ember = true,
    dog = true,
    owl = true,
    owl_moss = true,
    fish = true,
    fish_frost = true,
    ember_cat = true,
}

local function Story(): React.Node
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Colors.bg2,
        BorderSizePixel = 0,
    }, {
        Dim = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = theme.Colors.black,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Canvas = React.createElement(DesignRoot, {}, {
                Panel = React.createElement(IndexPanel, {
                    ownedEvolutions = DEMO_OWNED,
                    onClose = function()
                        print("[Index story] close")
                    end,
                }),
            }),
        }),
    })
end

return mount.screen(React.createElement(Story))
