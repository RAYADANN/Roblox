--!strict
-- Промокод + соц-награда под счётчиком инвентаря (правый верх).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local ScopeFactory = require(script.Parent.Parent.ScopeFactory)
local HudStateModule = require(script.Parent.Parent.HudState)
local DailyRewardButton = require(script.Parent.DailyRewardButton)
local PromoCodeButton = require(script.Parent.PromoCodeButton)
local SocialRewardButton = require(script.Parent.SocialRewardButton)
local ViewportLayout = require(script.Parent.Parent.Parent.util.ViewportLayout)

local Children = Fusion.Children
local peek = Fusion.peek

local TopRightActionRow = {}

export type CreateOpts = {
	onOpenDaily: () -> (),
}

function TopRightActionRow.create(
	s: ScopeFactory.HudScope,
	state: HudStateModule.HudState,
	opts: CreateOpts
)
	local layoutEpoch = s:Value(0)
	ViewportLayout.subscribe(function()
		layoutEpoch:set(peek(layoutEpoch) + 1)
	end, s)

	local rowSize = s:Computed(function(use)
		use(layoutEpoch)
		local btnSz = ViewportLayout.chromePx(40)
		local gap = ViewportLayout.chromePx(6)
		return UDim2.fromOffset(btnSz * 3 + gap * 2, btnSz)
	end)

	local rowPos = s:Computed(function(use)
		use(layoutEpoch)
		local _, invH = ViewportLayout.inventoryChipSize()
		local gap = ViewportLayout.chromePx(4)
		-- AnchorPoint (1,0): правый край совпадает с правым краем InventoryWidget.
		return UDim2.new(1, -ViewportLayout.sidePad(), 0, ViewportLayout.topHudY() + invH + gap)
	end)

	local gapPx = s:Computed(function(use)
		use(layoutEpoch)
		return ViewportLayout.chromePx(6)
	end)

	return s:New("Frame")({
		Name = "TopRightActionRow",
		Size = rowSize,
		Position = rowPos,
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 8,
		[Children] = {
			s:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = s:Computed(function(use)
					return UDim.new(0, use(gapPx))
				end),
			}),
			DailyRewardButton.create(s, state, { layoutOrder = 0, onOpen = opts.onOpenDaily }),
			PromoCodeButton.create(s, state, { layoutOrder = 1 }),
			SocialRewardButton.create(s, state, { layoutOrder = 2 }),
		},
	})
end

return TopRightActionRow
