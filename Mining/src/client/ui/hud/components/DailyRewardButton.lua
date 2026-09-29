--!strict
-- Кнопка ежедневной награды (правый верх).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local ScopeFactory = require(script.Parent.Parent.ScopeFactory)
local HudStateModule = require(script.Parent.Parent.HudState)
local theme = require(script.Parent.Parent.theme)
local ChromeIconButton = require(script.Parent.ChromeIconButton)
local ViewportLayout = require(script.Parent.Parent.Parent.util.ViewportLayout)

local peek = Fusion.peek

export type CreateOpts = {
	layoutOrder: number?,
	onOpen: () -> (),
}

local DailyRewardButton = {}

function DailyRewardButton.create(
	s: ScopeFactory.HudScope,
	state: HudStateModule.HudState,
	opts: CreateOpts
)
	local layoutEpoch = s:Value(0)
	ViewportLayout.subscribe(function()
		layoutEpoch:set(peek(layoutEpoch) + 1)
	end, s)

	local visible = s:Computed(function(use)
		return use(state.dailyCanClaim) == true
	end)

	local size = s:Computed(function(use)
		use(layoutEpoch)
		local btnSz = ViewportLayout.chromePx(40)
		return UDim2.fromOffset(btnSz, btnSz)
	end)

	return ChromeIconButton.create(s, {
		name = "DailyRewardButton",
		iconKey = "icon_gift",
		accent = theme.C.gold,
		size = size,
		layoutOrder = opts.layoutOrder,
		visible = visible,
		showPulse = visible,
		showBadge = visible,
		tooltip = L("component.daily.claim"),
		onActivated = opts.onOpen,
		zIndex = 8,
	})
end

return DailyRewardButton
