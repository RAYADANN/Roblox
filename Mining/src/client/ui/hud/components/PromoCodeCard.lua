--!strict
-- PromoCodeCard — ввод и активация промокода (таб «Цели»).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local ScopeFactory = require(script.Parent.Parent.ScopeFactory)
local HudStateModule = require(script.Parent.Parent.HudState)
local theme = require(script.Parent.Parent.theme)
local PanelScale = require(script.Parent.Parent.PanelScale)
local PromoCodeActions = require(script.Parent.Parent.util.PromoCodeActions)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local C = theme.C
local ACCENT = theme.TAB_ACCENTS.goals
local sc = PanelScale.gsc
local text = PanelScale.text
local tsize = PanelScale.tsize

local PromoCodeCard = {}

function PromoCodeCard.create(s: ScopeFactory.HudScope, _state: HudStateModule.HudState, layoutOrder: number)
	local isBusy = s:Value(false)
	local codeDraft = ""

	return s:New("Frame")({
		Name = "PromoCodeCard",
		LayoutOrder = layoutOrder,
		Size = UDim2.new(1, 0, 0, sc(92)),
		BackgroundColor3 = C.btnBg,
		BorderSizePixel = 0,
		[Children] = {
			s:New("UICorner")({ CornerRadius = UDim.new(0, sc(8)) }),
			s:New("UIStroke")({ Color = ACCENT, Thickness = sc(1), Transparency = 0.5 }),
			s:New("TextLabel")({
				Size = UDim2.new(1, -sc(16), 0, sc(18)),
				Position = UDim2.new(0, sc(12), 0, sc(10)),
				BackgroundTransparency = 1,
				Text = L("modal.promo.cardTitle"),
				TextSize = text(11),
				Font = theme.FONT.title,
				TextColor3 = C.textSub,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2,
			}),
			s:New("TextBox")({
				Name = "CodeInput",
				Size = UDim2.new(1, -sc(128), 0, sc(36)),
				Position = UDim2.new(0, sc(12), 0, sc(38)),
				BackgroundColor3 = C.panelInner,
				BorderSizePixel = 0,
				ClearTextOnFocus = false,
				Font = Enum.Font.GothamBold,
				PlaceholderText = L("modal.promo.inputPlaceholder"),
				PlaceholderColor3 = C.textMuted,
				Text = "",
				TextColor3 = C.textMain,
				TextSize = tsize(14),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2,
				[Children] = {
					s:New("UICorner")({ CornerRadius = UDim.new(0, sc(8)) }),
					s:New("UIPadding")({
						PaddingLeft = UDim.new(0, sc(10)),
						PaddingRight = UDim.new(0, sc(10)),
					}),
				},
				[OnEvent("Changed")] = function(rbx: TextBox)
					codeDraft = rbx.Text
				end,
				[OnEvent("FocusLost")] = function(rbx: TextBox)
					codeDraft = rbx.Text
				end,
			}),
			s:New("TextButton")({
				Size = UDim2.new(0, sc(100), 0, sc(36)),
				Position = UDim2.new(1, -sc(112), 0, sc(38)),
				BackgroundColor3 = s:Computed(function(use)
					return if use(isBusy) then C.btnDisabled else ACCENT
				end),
				BorderSizePixel = 0,
				Text = L("modal.promo.activate"),
				TextSize = text(12),
				Font = Enum.Font.GothamBlack,
				TextColor3 = Color3.fromRGB(30, 20, 50),
				AutoButtonColor = false,
				ZIndex = 2,
				[Children] = {
					s:New("UICorner")({ CornerRadius = UDim.new(0, sc(8)) }),
				},
				[OnEvent("Activated")] = function()
					PromoCodeActions.tryRedeem(codeDraft, isBusy)
				end,
			}),
		},
	})
end

return PromoCodeCard
