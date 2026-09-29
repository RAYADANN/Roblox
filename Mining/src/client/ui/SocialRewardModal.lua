--!strict

-- Модал бесплатной соц-награды (группа + избранное).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local peek = Fusion.peek

local HudStateModule = require(script.Parent.hud.HudState)
local theme = require(script.Parent.hud.theme)
local UiIcon = require(script.Parent.hud.components.UiIcon)
local HudModalChrome = require(script.Parent.hud.components.HudModalChrome)
local RewardPreviewRow = require(script.Parent.hud.components.RewardPreviewRow)
local SocialRewardStepRow = require(script.Parent.hud.components.SocialRewardStepRow)
local SocialRewardActions = require(script.Parent.hud.util.SocialRewardActions)
local EngagementTracker = require(script.Parent.util.EngagementTracker)
local ViewportLayout = require(script.Parent.util.ViewportLayout)
local UiScreen = require(script.Parent.util.UiScreen)
local SoundManager = require(script.Parent.Parent.core.SoundManager)
local Constants = require(ReplicatedStorage:WaitForChild("shared").constants)
local Loc = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local C = theme.C
local ACCENT = theme.TAB_ACCENTS.shop
local PAD = 18
local ROW_GAP = 8

local MODAL_GUI_NAME = "DeepDigger_SocialRewardModal"
local FADE_IN = 0.18
local FADE_OUT = 0.15
local DESIGN_W = 440
local DESIGN_H = 460

local L = {
	TITLE = 1,
	SUBTITLE = 2,
	REWARDS = 3,
	PROGRESS = 4,
	STEP_GROUP = 5,
	STEP_FAV = 6,
	CLAIM_HINT = 7,
	PAD_BEFORE_CLAIM = 8,
	BTN_CLAIM = 9,
}

local SocialRewardModal = {}

export type Options = {
	scope: any,
	state: HudStateModule.HudState,
	onClose: (() -> ())?,
}

export type Handle = { close: (self: Handle) -> () }

local _activeHandle: Handle? = nil

local function ensureGui(): ScreenGui?
	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	return UiScreen.ensure(pg, MODAL_GUI_NAME, "modal")
end

-- Тело модалки свёрстано в дизайн-пикселях (см. HudModalChrome.contentScale).
local function modalBody(
	s: any,
	state: HudStateModule.HudState,
	rewards: RewardPreviewRow.RewardTable,
	isBusy: any,
	onClaimSuccess: () -> ()
)
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

	return s:New("Frame")({
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 4,
		[Children] = {
			s:New("UIPadding")({
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 14),
				PaddingLeft = UDim.new(0, PAD),
				PaddingRight = UDim.new(0, PAD),
			}),
			s:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, ROW_GAP),
			}),
			UiIcon.titleRow(s, {
				source = "icon_social_reward",
				text = Loc("modal.social.title"),
				textSize = 20,
				font = Enum.Font.GothamBlack,
				textColor = C.gold,
				size = UDim2.new(1, -64, 0, 32),
				iconSize = 26,
				zIndex = 4,
				layoutOrder = L.TITLE,
			}),
			s:New("TextLabel")({
				LayoutOrder = L.SUBTITLE,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = Loc("modal.social.subtitle"),
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				TextColor3 = C.textLabel,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 4,
			}),
			RewardPreviewRow.create(s, {
				rewards = rewards,
				layoutOrder = L.REWARDS,
			}),
			s:New("TextLabel")({
				LayoutOrder = L.PROGRESS,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = s:Computed(function(use)
					return Loc("modal.social.progress", {
						done = use(progressDone),
						total = 2,
					})
				end),
				TextSize = 13,
				Font = Enum.Font.GothamBlack,
				TextColor3 = C.gold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 4,
			}),
			SocialRewardStepRow.create(s, {
				layoutOrder = L.STEP_GROUP,
				labelDone = Loc("modal.social.stepGroupDone"),
				labelPending = Loc("modal.social.stepGroupPending"),
				actionLabel = Loc("modal.social.actionJoin"),
				done = inGroup,
				disabled = isBusy,
				textSize = 12,
				onAction = function()
					SoundManager.play("ui_click")
					SocialRewardActions.promptGroup(isBusy)
				end,
			}),
			SocialRewardStepRow.create(s, {
				layoutOrder = L.STEP_FAV,
				labelDone = Loc("modal.social.stepFavoriteDone"),
				labelPending = Loc("modal.social.stepFavoritePending"),
				actionLabel = Loc("modal.social.actionFavorite"),
				done = favoriteDone,
				disabled = isBusy,
				textSize = 12,
				onAction = function()
					SoundManager.play("ui_click")
					SocialRewardActions.promptFavorite(isBusy)
				end,
			}),
			s:New("TextLabel")({
				LayoutOrder = L.CLAIM_HINT,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = s:Computed(function(use)
					return if use(canClaim)
						then Loc("modal.social.claimReady")
						else Loc("modal.social.claimHint")
				end),
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextColor3 = s:Computed(function(use)
					return if use(canClaim) then C.sell else C.textSub
				end),
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 4,
			}),
			s:New("Frame")({
				LayoutOrder = L.PAD_BEFORE_CLAIM,
				Size = UDim2.new(1, 0, 0, 4),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			}),
			s:New("TextButton")({
				LayoutOrder = L.BTN_CLAIM,
				Size = UDim2.new(1, 0, 0, 46),
				BackgroundColor3 = s:Computed(function(use)
					return if use(canClaim) then C.gold else C.btnDisabled
				end),
				BackgroundTransparency = s:Computed(function(use)
					return if use(canClaim) then 0 else 0.25
				end),
				BorderSizePixel = 0,
				Text = Loc("modal.social.claim"),
				TextSize = 15,
				Font = Enum.Font.GothamBlack,
				TextColor3 = Color3.fromRGB(40, 25, 0),
				AutoButtonColor = false,
				Active = s:Computed(function(use)
					return use(canClaim) and not use(isBusy)
				end),
				ZIndex = 4,
				[Children] = {
					s:New("UICorner")({ CornerRadius = UDim.new(0, 10) }),
					s:New("UIStroke")({ Color = C.goldHi, Thickness = 1, Transparency = 0.35 }),
				},
				[OnEvent("Activated")] = function()
					SoundManager.play("ui_click")
					SocialRewardActions.tryClaim(isBusy, function(success)
						if success then
							onClaimSuccess()
						end
					end)
				end,
			}),
		},
	})
end

function SocialRewardModal.show(opts: Options): Handle?
	if _activeHandle then
		return _activeHandle
	end

	SocialRewardActions.ensureStatusFresh()
	EngagementTracker.trackModal("social")

	local parentScope = opts.scope
	local s = parentScope:innerScope()
	local state = opts.state
	local gui = ensureGui()
	if not gui then
		return nil
	end

	for _, child in ipairs(gui:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local isBusy = s:Value(false)
	local handle: any = { _closed = false }
	_activeHandle = handle
	local escConn: RBXScriptConnection? = nil
	local backdrop: Frame

	local function doClose()
		if handle._closed then
			return
		end
		handle._closed = true
		_activeHandle = nil
		if escConn then
			escConn:Disconnect()
			escConn = nil
		end
		if backdrop then
			TweenService:Create(backdrop, TweenInfo.new(FADE_OUT, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1,
			}):Play()
			task.delay(FADE_OUT + 0.05, function()
				if backdrop and backdrop.Parent then
					backdrop:Destroy()
				end
				pcall(function()
					Fusion.doCleanup(s)
				end)
			end)
		end
		if opts.onClose then
			pcall(opts.onClose)
		end
	end

	handle.close = function()
		doClose()
	end

	local layoutEpoch = s:Value(0)
	ViewportLayout.subscribe(function()
		layoutEpoch:set(peek(layoutEpoch) + 1)
	end, s)

	local fitScale = s:Computed(function(use)
		use(layoutEpoch)
		local deskMax = if ViewportLayout.tier() == "desktop" then 1.7 else 1.0
		return ViewportLayout.fitModalScale(DESIGN_W, DESIGN_H, deskMax)
	end)

	local modalSize = s:Computed(function(use)
		use(layoutEpoch)
		local k = use(fitScale)
		return UDim2.fromOffset(math.floor(DESIGN_W * k + 0.5), math.floor(DESIGN_H * k + 0.5))
	end)

	local modalPos = s:Computed(function(use)
		use(layoutEpoch)
		local k = use(fitScale)
		return UDim2.new(0.5, 0, 0, ViewportLayout.modalCenterY(math.floor(DESIGN_H * k + 0.5)))
	end)

	local backdropSize = s:Computed(function(use)
		use(layoutEpoch)
		return UiScreen.backdropSize()
	end)

	local backdropPos = s:Computed(function(use)
		use(layoutEpoch)
		return UiScreen.backdropPosition()
	end)

	local rewards = ((Constants.SOCIAL_REWARD or {}).rewards or {}) :: RewardPreviewRow.RewardTable

	backdrop = s:New("Frame")({
		Name = "Backdrop",
		Size = backdropSize,
		Position = backdropPos,
		BackgroundColor3 = C.backdrop,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = gui,
		Active = true,
		ZIndex = 1,
		[Children] = {
			s:New("TextButton")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				[OnEvent("Activated")] = doClose,
			}),
			HudModalChrome.shell(s, {
				accent = ACCENT,
				gradientTop = Color3.fromRGB(36, 28, 58),
				size = modalSize,
				position = modalPos,
				onClose = doClose,
				designSize = Vector2.new(DESIGN_W, DESIGN_H),
				contentScale = fitScale,
				children = {
					modalBody(s, state, rewards, isBusy, doClose),
				},
			}),
		},
	})

	TweenService:Create(backdrop, TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 0.45,
	}):Play()

	escConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			doClose()
		end
	end)

	return handle
end

return SocialRewardModal
