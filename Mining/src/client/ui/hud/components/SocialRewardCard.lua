--!strict
-- SocialRewardCard — бесплатная награда за группу + избранное (таб «Магазин»).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local ScopeFactory = require(script.Parent.Parent.ScopeFactory)
local HudStateModule = require(script.Parent.Parent.HudState)
local theme = require(script.Parent.Parent.theme)
local PanelScale = require(script.Parent.Parent.PanelScale)
local SocialRewardStepRow = require(script.Parent.SocialRewardStepRow)
local SocialRewardActions = require(script.Parent.Parent.util.SocialRewardActions)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local C = theme.C
local ACCENT = theme.TAB_ACCENTS.shop
local sc = PanelScale.gsc
local text = PanelScale.text

local SocialRewardCard = {}

function SocialRewardCard.create(s: ScopeFactory.HudScope, state: HudStateModule.HudState, layoutOrder: number)
	local isBusy = s:Value(false)
	local inGroup = s:Computed(function(use)
		local social = use(state.socialReward) or {}
		return social.inGroup == true
	end)
	local favoriteDone = s:Computed(function(use)
		local social = use(state.socialReward) or {}
		return social.favoriteConfirmed == true
	end)
	local canClaim = s:Computed(function(use)
		local social = use(state.socialReward) or {}
		return social.canClaim == true
	end)
	local progressDone = s:Computed(function(use)
		local done = 0
		if use(inGroup) then
			done += 1
		end
		if use(favoriteDone) then
			done += 1
		end
		return done
	end)

	local card = s:New("Frame")({
		Name = "SocialRewardCard",
		LayoutOrder = layoutOrder,
		Size = UDim2.new(1, -sc(8), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.btnBg,
		BorderSizePixel = 0,
		Visible = s:Computed(function(use)
			local social = use(state.socialReward) or {}
			return social.claimed ~= true
		end),
		[Children] = {
			s:New("UICorner")({ CornerRadius = UDim.new(0, sc(10)) }),
			s:New("UIStroke")({ Color = ACCENT, Thickness = sc(1.5), Transparency = 0.35 }),
			s:New("UIPadding")({
				PaddingTop = PanelScale.pad(10),
				PaddingBottom = PanelScale.pad(10),
				PaddingLeft = PanelScale.pad(12),
				PaddingRight = PanelScale.pad(12),
			}),
			s:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Vertical,
				Padding = PanelScale.pad(8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			s:New("TextLabel")({
				LayoutOrder = 0,
				Size = UDim2.new(1, 0, 0, sc(20)),
				BackgroundTransparency = 1,
				Text = L("modal.social.cardTitle"),
				TextSize = text(14),
				Font = Enum.Font.GothamBlack,
				TextColor3 = C.gold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2,
			}),
			s:New("TextLabel")({
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = SocialRewardActions.rewardSummary(),
				TextSize = text(12),
				Font = Enum.Font.GothamBold,
				TextColor3 = C.textLabel,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2,
			}),
			s:New("TextLabel")({
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, sc(16)),
				BackgroundTransparency = 1,
				Text = s:Computed(function(use)
					return L("modal.social.progress", {
						done = use(progressDone),
						total = 2,
					})
				end),
				TextSize = text(11),
				Font = Enum.Font.GothamBlack,
				TextColor3 = C.gold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2,
			}),
			SocialRewardStepRow.create(s, {
				layoutOrder = 3,
				labelDone = L("modal.social.stepGroupDone"),
				labelPending = L("modal.social.stepGroupPending"),
				actionLabel = L("modal.social.actionJoin"),
				done = inGroup,
				disabled = isBusy,
				sc = sc,
				textSize = text(10),
				zIndex = 2,
				onAction = function()
					SocialRewardActions.promptGroup(isBusy)
				end,
			}),
			SocialRewardStepRow.create(s, {
				layoutOrder = 4,
				labelDone = L("modal.social.stepFavoriteDone"),
				labelPending = L("modal.social.stepFavoritePending"),
				actionLabel = L("modal.social.actionFavorite"),
				done = favoriteDone,
				disabled = isBusy,
				sc = sc,
				textSize = text(10),
				zIndex = 2,
				onAction = function()
					SocialRewardActions.promptFavorite(isBusy)
				end,
			}),
			s:New("TextButton")({
				LayoutOrder = 5,
				Size = UDim2.new(1, 0, 0, sc(38)),
				BackgroundColor3 = s:Computed(function(use)
					return if use(canClaim) then C.gold else C.btnDisabled
				end),
				BackgroundTransparency = s:Computed(function(use)
					return if use(canClaim) then 0 else 0.3
				end),
				BorderSizePixel = 0,
				Text = L("modal.social.claim"),
				TextSize = text(13),
				Font = Enum.Font.GothamBlack,
				TextColor3 = Color3.fromRGB(40, 25, 0),
				AutoButtonColor = false,
				Active = s:Computed(function(use)
					return use(canClaim) and not use(isBusy)
				end),
				ZIndex = 2,
				[Children] = {
					s:New("UICorner")({ CornerRadius = UDim.new(0, sc(8)) }),
				},
				[OnEvent("Activated")] = function()
					SocialRewardActions.tryClaim(isBusy)
				end,
			}),
		},
	})

	SocialRewardActions.ensureStatusFresh()
	return card
end

return SocialRewardCard
