--!strict
-- Hoarcekat: locked mutation shine picks.
-- Path: ReplicatedStorage.UI.stories.MutationShine
-- sync: normal none · secret S5 · galaxy S2 · diamond S4 · prismatic legacy V3 · golden S5

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ShineCell = require(script.Parent.mutationShine.ShineCell)
local mount = require(script.Parent.mount)
local palettes = require(script.Parent.mutationShine.palettes)

local MutationShineDatabase =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("data").MutationShineDatabase)

local function Story(): React.Node
    local cells: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }

    for i, def in MutationShineDatabase.all() do
        local palette = nil
        for _, p in palettes.all do
            if p.id == def.id then
                palette = p
                break
            end
        end
        if palette then
            cells[def.id] = React.createElement(ShineCell, {
                palette = palette,
                variant = def.variant,
                legacyMutationV = def.legacyMutationV,
                layoutOrder = i,
            })
        end
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(10, 12, 18),
        BorderSizePixel = 0,
    }, {
        Pad = React.createElement("UIPadding", {
            PaddingTop = UDim.new(0, 16),
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16),
        }),
        Intro = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            Text = "Locked: normal none · secret S5 · galaxy S2 · diamond S4 · prismatic legacy V3 · golden S5",
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(170, 178, 200),
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Row = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 90),
            Position = UDim2.fromOffset(0, 44),
            BackgroundTransparency = 1,
        }, cells),
    })
end

return mount.screen(React.createElement(Story))
