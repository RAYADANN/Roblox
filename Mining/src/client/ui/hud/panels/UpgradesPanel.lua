--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)
local Net = require(ReplicatedStorage:WaitForChild("Packages").Net)
local peek = Fusion.peek
local Constants = require(ReplicatedStorage:WaitForChild("shared").constants)

local ScopeFactory = require(script.Parent.Parent.ScopeFactory)
local HudStateModule = require(script.Parent.Parent.HudState)
local UpgradeMeta = require(script.Parent.Parent.UpgradeMeta)
local UpgRow = require(script.Parent.Parent.components.UpgRow)
local theme = require(script.Parent.Parent.theme)
local PanelScale = require(script.Parent.Parent.PanelScale)
local ViewportLayout = require(script.Parent.Parent.Parent.util.ViewportLayout)

local Children = Fusion.Children
local C = theme.C

local LIST_GAP = 8
local ROW_DESIGN_H = 62

local UpgradesPanel = {}

function UpgradesPanel.create(s: ScopeFactory.HudScope, state: HudStateModule.HudState)
    local layoutEpoch = s:Value(0)
    ViewportLayout.subscribe(function()
        layoutEpoch:set(peek(layoutEpoch) + 1)
    end, s)

    local rowHeight = s:Computed(function(use)
        use(layoutEpoch)
        return PanelScale.gsc(ROW_DESIGN_H)
    end)

    return s:New("ScrollingFrame")({
        Name = "Upgrades",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = PanelScale.scrollBar(),
        ScrollBarImageColor3 = C.panelBorder,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = s:Computed(function(use)
            return use(state.activeTab) == "upgrades"
        end),
        [Children] = {
            s:New("UIListLayout")({
                FillDirection = Enum.FillDirection.Vertical,
                Padding = PanelScale.pad(LIST_GAP),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            s:New("UIPadding")({
                PaddingLeft = PanelScale.pad(6),
                PaddingRight = PanelScale.pad(6),
                PaddingTop = PanelScale.pad(6),
                PaddingBottom = PanelScale.pad(6),
            }),
            -- Строки пересобираются только на ресайз (rowHeight). Не зависим от
            -- activeTab/upgrades/coins — уровень и стоимость живут внутри UpgRow.
            s:Computed(function(use)
                local rh = use(rowHeight)
                local rows = {}
                local layoutOrder = 0
                for _, id in ipairs(UpgradeMeta.ORDER) do
                    local cfg = Constants.UPGRADES[id]
                    if not cfg then
                        continue
                    end
                    layoutOrder += 1
                    local row = UpgRow.create(s, {
                        upgradeId = id,
                        rowHeight = rh,
                        coinsValue = state.coins,
                        upgradesValue = state.upgrades,
                        rebirthsValue = state.rebirths,
                        onBuy = function()
                            return Net:Invoke("BuyUpgrade", id)
                        end,
                    })
                    row.LayoutOrder = layoutOrder
                    rows[#rows + 1] = row
                end
                return rows
            end),
        },
    })
end

return UpgradesPanel
