--!strict
-- Предупреждение: кирка слишком слабая для каменного слоя (depth >= 50).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local Constants = require(ReplicatedStorage:WaitForChild("shared").constants)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local ScopeFactory = require(script.Parent.Parent.ScopeFactory)
local HudStateModule = require(script.Parent.Parent.HudState)
local theme = require(script.Parent.Parent.theme)
local Notification = require(script.Parent.Parent.Parent.Notification)
local ViewportLayout = require(script.Parent.Parent.Parent.util.ViewportLayout)
local UiMotion = require(script.Parent.Parent.Parent.util.UiMotion)

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local peek = Fusion.peek

local C = theme.C
local WARN = Color3.fromRGB(255, 160, 60)

export type CreateOpts = {
	onUpgradeClick: () -> (),
}

local StoneLayerWarning = {}

local _toastShownThisSession = false

local function pickaxeLevel(upgrades: any): number
	if typeof(upgrades) ~= "table" then
		return 1
	end
	local pick = upgrades.pickaxe
	if typeof(pick) == "table" and typeof(pick.level) == "number" then
		return pick.level
	end
	return 1
end

function StoneLayerWarning.create(
	s: ScopeFactory.HudScope,
	state: HudStateModule.HudState,
	opts: CreateOpts
)
	local layoutEpoch = s:Value(0)
	ViewportLayout.subscribe(function()
		layoutEpoch:set(peek(layoutEpoch) + 1)
	end, s)

	local dismissed = s:Value(false)

	local needsWarning = s:Computed(function(use)
		local depth = use(state.depth) or 0
		local pick = pickaxeLevel(use(state.upgrades))
		return depth >= 50 and pick < Constants.STONE_PICKAXE_MIN_LEVEL
	end)

	local visible = s:Computed(function(use)
		return use(needsWarning) and not use(dismissed)
	end)

	local bannerH = s:Computed(function(use)
		use(layoutEpoch)
		return ViewportLayout.chromePx(28)
	end)

	local banner = s:New("Frame")({
		Name = "StoneLayerWarning",
		Size = s:Computed(function(use)
			use(layoutEpoch)
			local w, _ = ViewportLayout.coinChipSize()
			return UDim2.fromOffset(w, use(bannerH))
		end),
		BackgroundColor3 = Color3.fromRGB(48, 32, 8),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		Visible = visible,
		[Children] = {
			s:New("UICorner")({ CornerRadius = theme.RADIUS.chip }),
			s:New("UIStroke")({ Color = WARN, Thickness = theme.STROKE.medium, Transparency = 0.25 }),
			s:New("TextLabel")({
				Size = UDim2.new(1, -ViewportLayout.chromePx(82), 1, 0),
				Position = UDim2.fromOffset(ViewportLayout.chromePx(8), 0),
				BackgroundTransparency = 1,
				Text = s:Computed(function(_use)
					return L("component.stoneWarning.banner", { level = Constants.STONE_PICKAXE_MIN_LEVEL })
				end),
				TextSize = s:Computed(function(use)
					use(layoutEpoch)
					return math.max(10, ViewportLayout.chromePx(11))
				end),
				Font = theme.FONT.body,
				TextColor3 = WARN,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			s:New("TextButton")({
				Name = "UpgradeBtn",
				Size = UDim2.fromOffset(ViewportLayout.chromePx(52), ViewportLayout.chromePx(22)),
				Position = UDim2.new(1, -ViewportLayout.chromePx(58), 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = WARN,
				BackgroundTransparency = 0.15,
				BorderSizePixel = 0,
				Font = theme.FONT.label,
				Text = L("component.stoneWarning.action"),
				TextColor3 = C.textMain,
				TextSize = s:Computed(function(use)
					use(layoutEpoch)
					return math.max(9, ViewportLayout.chromePx(10))
				end),
				[Children] = {
					s:New("UICorner")({ CornerRadius = UDim.new(0, ViewportLayout.chromePx(6)) }),
				},
				[OnEvent "Activated"] = function()
					opts.onUpgradeClick()
				end,
			}),
			s:New("TextButton")({
				Name = "Dismiss",
				Size = UDim2.fromOffset(ViewportLayout.chromePx(18), ViewportLayout.chromePx(18)),
				Position = UDim2.new(1, -ViewportLayout.chromePx(6), 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "×",
				TextColor3 = C.textSub,
				TextSize = 16,
				[OnEvent "Activated"] = function()
					dismissed:set(true)
				end,
			}),
		},
	})

	UiMotion.defer(s, banner, function()
		UiMotion.watch(s, function()
			return peek(state.layerId)
		end, function(layerId, prev)
			if layerId == "stone" and prev ~= "stone" then
				dismissed:set(false)
			end
		end)
		UiMotion.watch(s, function()
			return peek(visible)
		end, function(isVisible, wasVisible)
			if isVisible and not wasVisible and not _toastShownThisSession then
				_toastShownThisSession = true
				Notification.show({
					text = L("component.stoneWarning.toast", { level = Constants.STONE_PICKAXE_MIN_LEVEL }),
					icon = "icon_warning",
					color = WARN,
					duration = 4,
				})
			end
		end)
		return nil
	end)

	return banner
end

return StoneLayerWarning
