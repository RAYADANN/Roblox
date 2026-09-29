--!strict
-- Карточка предпросмотра ребёрта: множитель и две колонки «сохранится / сбросится».

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local ScopeFactory = require(script.Parent.Parent.ScopeFactory)
local HudStateModule = require(script.Parent.Parent.HudState)
local theme = require(script.Parent.Parent.theme)
local PanelScale = require(script.Parent.Parent.PanelScale)
local UiIcon = require(script.Parent.UiIcon)
local RebirthLogic = require(ReplicatedStorage:WaitForChild("shared").util.RebirthLogic)
local Constants = require(ReplicatedStorage:WaitForChild("shared").constants)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local Children = Fusion.Children
local C = theme.C
local sc = PanelScale.gsc
local text = PanelScale.text

local RebirthPreviewCard = {}

local KEEP_ITEMS = {
	"panel.rebirth.previewKeep.rebirths",
	"panel.rebirth.previewKeep.stats",
	"panel.rebirth.previewKeep.depth",
	"panel.rebirth.previewKeep.tutorial",
}

local RESET_ITEMS = {
	"panel.rebirth.previewReset.coins",
	"panel.rebirth.previewReset.inventory",
	"panel.rebirth.previewReset.upgrades",
}

local function bulletColumn(
	s: ScopeFactory.HudScope,
	title: string,
	titleColor: Color3,
	iconKey: string,
	lines: { string }
): Instance
	local rows: { Instance } = {}
	for _, key in ipairs(lines) do
		table.insert(rows, s:New("Frame")({
			Size = UDim2.new(1, 0, 0, sc(20)),
			BackgroundTransparency = 1,
			[Children] = {
				UiIcon.create(s, {
					source = iconKey,
					size = UDim2.fromOffset(sc(12), sc(12)),
					position = UDim2.new(0, 0, 0.5, -sc(6)),
				}),
				s:New("TextLabel")({
					Size = UDim2.new(1, -sc(16), 1, 0),
					Position = UDim2.new(0, sc(16), 0, 0),
					BackgroundTransparency = 1,
					Text = L(key),
					TextSize = text(11),
					Font = Enum.Font.Gotham,
					TextColor3 = C.textSub,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
				}),
			},
		}))
	end

	return s:New("Frame")({
		Size = UDim2.new(0.5, -sc(4), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		[Children] = {
			s:New("TextLabel")({
				Size = UDim2.new(1, 0, 0, sc(18)),
				BackgroundTransparency = 1,
				Text = title,
				TextSize = text(12),
				Font = Enum.Font.GothamBold,
				TextColor3 = titleColor,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			s:New("Frame")({
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, sc(22)),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				[Children] = {
					s:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Vertical,
						Padding = UDim.new(0, sc(4)),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					table.unpack(rows),
				},
			}),
		},
	})
end

function RebirthPreviewCard.create(s: ScopeFactory.HudScope, state: HudStateModule.HudState): Instance
	local invPerRebirth = (Constants.REBIRTH and Constants.REBIRTH.inventorySlotsPerRebirth) or 0

	return s:New("Frame")({
		Name = "RebirthPreviewCard",
		Size = UDim2.new(1, -sc(8), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.btnBg,
		BorderSizePixel = 0,
		[Children] = {
			s:New("UICorner")({ CornerRadius = UDim.new(0, sc(8)) }),
			s:New("UIStroke")({ Color = C.gold, Thickness = sc(1), Transparency = 0.55 }),
			s:New("UIPadding")({
				PaddingTop = UDim.new(0, sc(10)),
				PaddingBottom = UDim.new(0, sc(10)),
				PaddingLeft = UDim.new(0, sc(12)),
				PaddingRight = UDim.new(0, sc(12)),
			}),
			s:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, sc(8)),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			s:New("TextLabel")({
				Size = UDim2.new(1, 0, 0, sc(16)),
				BackgroundTransparency = 1,
				Text = L("panel.rebirth.previewTitle"),
				TextSize = text(12),
				Font = Enum.Font.GothamBold,
				TextColor3 = C.textLabel,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			s:New("Frame")({
				Size = UDim2.new(1, 0, 0, sc(36)),
				BackgroundTransparency = 1,
				[Children] = {
					s:New("TextLabel")({
						Size = UDim2.new(0.45, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = s:Computed(function(use)
							local mult = use(state.rebirthMultiplier) or 1
							return RebirthLogic.formatMultiplier(mult)
						end),
						TextSize = text(24),
						Font = Enum.Font.GothamBlack,
						TextColor3 = C.textMuted,
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
					s:New("TextLabel")({
						Size = UDim2.new(0.1, 0, 1, 0),
						Position = UDim2.new(0.45, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = "→",
						TextSize = text(22),
						Font = Enum.Font.GothamBlack,
						TextColor3 = C.gold,
						TextXAlignment = Enum.TextXAlignment.Center,
					}),
					s:New("TextLabel")({
						Size = UDim2.new(0.45, 0, 1, 0),
						Position = UDim2.new(0.55, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = s:Computed(function(use)
							local rebirths = use(state.rebirths) or 0
							return RebirthLogic.formatMultiplier(RebirthLogic.valueMultiplier(rebirths + 1))
						end),
						TextSize = text(24),
						Font = Enum.Font.GothamBlack,
						TextColor3 = C.gold,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
				},
			}),
			s:New("Frame")({
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				[Children] = {
					s:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, sc(8)),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					bulletColumn(s, L("panel.rebirth.previewKeepTitle"), Color3.fromRGB(150, 255, 150), "icon_check", KEEP_ITEMS),
					bulletColumn(s, L("panel.rebirth.previewResetTitle"), Color3.fromRGB(255, 140, 90), "icon_close", RESET_ITEMS),
				},
			}),
			if invPerRebirth > 0
				then s:New("TextLabel")({
					Size = UDim2.new(1, 0, 0, sc(18)),
					BackgroundTransparency = 1,
					Text = s:Computed(function(use)
						return L("panel.rebirth.previewUnlock", { slots = invPerRebirth })
					end),
					TextSize = text(11),
					Font = Enum.Font.GothamBold,
					TextColor3 = Color3.fromRGB(120, 200, 255),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
				})
				else nil,
			s:New("TextLabel")({
				Size = UDim2.new(1, 0, 0, sc(18)),
				BackgroundTransparency = 1,
				Text = s:Computed(function(use)
					local current = use(state.rebirths) or 0
					local nextT = RebirthLogic.nextPickaxeBonusThreshold(current)
					if not nextT then
						return L("panel.rebirth.allBonuses")
					end
					return L("panel.rebirth.nextBonus", { threshold = nextT, remaining = nextT - current })
				end),
				TextSize = text(11),
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(120, 200, 255),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
			}),
		},
	})
end

return RebirthPreviewCard
