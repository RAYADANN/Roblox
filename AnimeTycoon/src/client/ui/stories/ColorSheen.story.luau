--!strict
-- Hoarcekat: Roblox-popular color sheens + recolors for mutation/rarity.
-- Path: ReplicatedStorage.UI.stories.ColorSheen
-- S1–S8 motion · S9–S16 recolor (WhiteBand / Hue / Rainbow / Chrome / Candy…)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ColorSheenLogic =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("util").ColorSheenLogic)
local SheenCell = require(script.Parent.colorSheen.SheenCell)
local mount = require(script.Parent.mount)
local mutPalettes = require(script.Parent.mutationShine.palettes)
local rarPalettes = require(script.Parent.rarityShine.palettes)

type Sample = {
    id: string,
    sampleText: string,
    keys: { mutPalettes.Key },
    baseRotation: number,
    stroke: Color3,
}

local function pickMutation(id: string): Sample?
    for _, p in mutPalettes.all do
        if p.id == id then
            return {
                id = p.id,
                sampleText = p.displayName,
                keys = p.keys,
                baseRotation = p.baseRotation,
                stroke = p.stroke,
            }
        end
    end
    return nil
end

local function pickRarity(id: string): Sample?
    for _, p in rarPalettes.all do
        if p.id == id then
            return {
                id = p.id,
                sampleText = p.displayName,
                keys = p.keys,
                baseRotation = p.baseRotation,
                stroke = p.stroke,
            }
        end
    end
    return nil
end

local SAMPLES: { Sample } = {}
for _, id in { "golden", "galaxy", "diamond", "prismatic", "secret" } do
    local s = pickMutation(id)
    if s then
        table.insert(SAMPLES, s)
    end
end
for _, id in { "legendary", "mythic", "rare" } do
    local s = pickRarity(id)
    if s then
        table.insert(SAMPLES, s)
    end
end

local VARIANT_COUNT = ColorSheenLogic.variantCount()
local ROW_H = 52 + math.ceil(VARIANT_COUNT / 4) * 92

local function rowFor(sample: Sample, rowOrder: number): React.Node
    local cells: { [string]: React.Node } = {
        Layout = React.createElement("UIGridLayout", {
            CellSize = UDim2.fromOffset(148, 84),
            CellPadding = UDim2.fromOffset(8, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirectionMaxCells = 4,
        }),
    }
    for v = 1, VARIANT_COUNT do
        cells["S" .. v] = React.createElement(SheenCell, {
            sampleText = sample.sampleText,
            keys = sample.keys,
            baseRotation = sample.baseRotation,
            stroke = sample.stroke,
            variant = v,
            layoutOrder = v,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, ROW_H),
        BackgroundTransparency = 1,
        LayoutOrder = rowOrder,
    }, {
        Title = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Text = sample.sampleText .. "  (" .. sample.id .. ")",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(210, 218, 235),
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Grid = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, -26),
            Position = UDim2.fromOffset(0, 26),
            BackgroundTransparency = 1,
        }, cells),
    })
end

local function Story(): React.Node
    local rows: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 14),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for i, sample in SAMPLES do
        rows[sample.id] = rowFor(sample, i)
    end

    local canvasH = 70 + #SAMPLES * (ROW_H + 14)

    return React.createElement("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(10, 12, 18),
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.fromOffset(0, canvasH),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
    }, {
        Pad = React.createElement("UIPadding", {
            PaddingTop = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
        }),
        Intro = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundTransparency = 1,
            Text = "Roblox-popular text color FX — FredokaOne + black stroke.\nS1–S8 sheen/spin · S9 WhiteBand · S10 HueShift · S11 Rainbow solid · S12 DualFlash · S13 Chrome · S14 HotPulse · S15 Candy · S16 GoldBlink\nСкажи S# + mutation/rarity — залочим.",
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(170, 178, 200),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            LayoutOrder = 0,
        }),
        Body = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, #SAMPLES * (ROW_H + 14)),
            Position = UDim2.fromOffset(0, 58),
            BackgroundTransparency = 1,
        }, rows),
    })
end

return mount.screen(React.createElement(Story))
