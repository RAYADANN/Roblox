--!strict
-- Модальное окно подтверждения ребёрта (anti-misclick 0.3с).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local peek = Fusion.peek

local theme = require(script.Parent.Parent.theme)
local ViewportLayout = require(script.Parent.Parent.Parent.util.ViewportLayout)
local UiScreen = require(script.Parent.Parent.Parent.util.UiScreen)
local UiIcon = require(script.Parent.Parent.components.UiIcon)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t
local C = theme.C

local MODAL_GUI_NAME = "DeepDigger_RebirthModal"
local ANTI_MISCLICK_DELAY = 0.3
local FADE_IN = 0.18
local FADE_OUT = 0.12

-- Design-space (как DailyRewardModal): контент в фиксированных px, масштаб через UIScale.
local DESIGN_W = 420
local PAD = 16
local HEADER_H = 40
local BODY_H = 168
local FOOTER_H = 48
local GAP = 10
local DESIGN_H = PAD + HEADER_H + GAP + BODY_H + GAP + FOOTER_H + PAD

local RebirthConfirmModal = {}

export type Options = {
	scope: any,
	title: string,
	body: string,
	confirmText: string?,
	cancelText: string?,
	confirm: () -> (),
	onClose: (() -> ())?,
}

export type Handle = {
	close: (self: Handle) -> (),
}

local _activeHandle: Handle? = nil

local function ensureGui(): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	return UiScreen.ensure(pg, MODAL_GUI_NAME, "modal")
end

function RebirthConfirmModal.show(opts: Options): Handle
	if _activeHandle then
		_activeHandle:close()
	end

	local s = opts.scope:innerScope()
	local gui = ensureGui()

	for _, child in ipairs(gui:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local enabled = s:Value(false)
	local hoveredConfirm = s:Value(false)
	local hoveredCancel = s:Value(false)

	local handle: any = { _closed = false }
	_activeHandle = handle
	local escConn: RBXScriptConnection? = nil
	local layoutCleanup: (() -> ())? = nil
	local backdrop: Frame

	local confirmText = opts.confirmText or L("modal.rebirth.confirm")
	local cancelText = opts.cancelText or L("modal.rebirth.cancel")

	local layoutEpoch = s:Value(0)
	layoutCleanup = ViewportLayout.subscribe(function()
		layoutEpoch:set(peek(layoutEpoch) + 1)
	end, s)

	local fitScale = s:Computed(function(use)
		use(layoutEpoch)
		local deskMax = if ViewportLayout.tier() == "desktop" then 1.35 else 1.0
		return ViewportLayout.fitModalScale(DESIGN_W, DESIGN_H, deskMax)
	end)

	local modalSize = s:Computed(function(use)
		local k = use(fitScale)
		return UDim2.fromOffset(
			math.floor(DESIGN_W * k + 0.5),
			math.floor(DESIGN_H * k + 0.5)
		)
	end)

	local modalPos = s:Computed(function(use)
		local k = use(fitScale)
		return UDim2.new(0.5, 0, 0, ViewportLayout.modalCenterY(math.floor(DESIGN_H * k + 0.5)))
	end)

	local function doClose()
		if handle._closed then
			return
		end
		handle._closed = true
		if _activeHandle == handle then
			_activeHandle = nil
		end
		if escConn then
			escConn:Disconnect()
			escConn = nil
		end
		if layoutCleanup then
			layoutCleanup()
			layoutCleanup = nil
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
		else
			pcall(function()
				Fusion.doCleanup(s)
			end)
		end
		if opts.onClose then
			pcall(opts.onClose)
		end
	end

	handle.close = function()
		doClose()
	end

	backdrop = s:New("Frame")({
		Name = "Backdrop",
		Size = UiScreen.backdropSize(),
		Position = UiScreen.backdropPosition(),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
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
				ZIndex = 1,
				[OnEvent("Activated")] = doClose,
			}),
			s:New("Frame")({
				Name = "Modal",
				Size = modalSize,
				Position = modalPos,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = C.panelBg,
				BorderSizePixel = 0,
				Active = true,
				ClipsDescendants = false,
				ZIndex = 2,
				[Children] = {
					s:New("UICorner")({ CornerRadius = UDim.new(0, 12) }),
					s:New("UIStroke")({ Color = C.gold, Thickness = 2, Transparency = 0.1 }),
					s:New("Frame")({
						Name = "Content",
						Size = UDim2.fromOffset(DESIGN_W, DESIGN_H),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						ZIndex = 3,
						[Children] = {
							s:New("UIScale")({ Scale = fitScale }),
							s:New("UIPadding")({
								PaddingTop = UDim.new(0, PAD),
								PaddingBottom = UDim.new(0, PAD),
								PaddingLeft = UDim.new(0, PAD),
								PaddingRight = UDim.new(0, PAD),
							}),
							s:New("UIListLayout")({
								FillDirection = Enum.FillDirection.Vertical,
								Padding = UDim.new(0, GAP),
								SortOrder = Enum.SortOrder.LayoutOrder,
							}),
							UiIcon.titleRow(s, {
								source = "tab_rebirth",
								text = opts.title,
								textSize = 20,
								font = Enum.Font.GothamBlack,
								textColor = C.gold,
								size = UDim2.new(1, 0, 0, HEADER_H),
								iconSize = 22,
								zIndex = 5,
								layoutOrder = 1,
							}),
							s:New("TextLabel")({
								Name = "Body",
								LayoutOrder = 2,
								Size = UDim2.new(1, 0, 0, BODY_H),
								BackgroundTransparency = 1,
								Text = opts.body,
								TextSize = 14,
								Font = Enum.Font.Gotham,
								TextColor3 = C.textMain,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextYAlignment = Enum.TextYAlignment.Top,
								TextWrapped = true,
								RichText = true,
								ZIndex = 5,
							}),
							s:New("Frame")({
								Name = "Footer",
								LayoutOrder = 3,
								Size = UDim2.new(1, 0, 0, FOOTER_H),
								BackgroundTransparency = 1,
								ZIndex = 5,
								[Children] = {
									s:New("UIListLayout")({
										FillDirection = Enum.FillDirection.Horizontal,
										Padding = UDim.new(0, 10),
										SortOrder = Enum.SortOrder.LayoutOrder,
										VerticalAlignment = Enum.VerticalAlignment.Center,
									}),
									s:New("TextButton")({
										Name = "CancelButton",
										LayoutOrder = 1,
										Size = UDim2.new(0.34, 0, 0, FOOTER_H),
										BackgroundColor3 = s:Computed(function(use)
											return use(hoveredCancel) and C.btnHover or C.btnBg
										end),
										BorderSizePixel = 0,
										Text = cancelText,
										TextSize = 15,
										Font = Enum.Font.GothamBold,
										TextColor3 = C.textMain,
										AutoButtonColor = false,
										ZIndex = 6,
										[Children] = {
											s:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
											s:New("UIStroke")({ Color = C.btnBorder, Thickness = 1.5, Transparency = 0.4 }),
										},
										[OnEvent("MouseEnter")] = function()
											hoveredCancel:set(true)
										end,
										[OnEvent("MouseLeave")] = function()
											hoveredCancel:set(false)
										end,
										[OnEvent("Activated")] = doClose,
									}),
									s:New("TextButton")({
										Name = "ConfirmButton",
										LayoutOrder = 2,
										Size = UDim2.new(0.66, -10, 0, FOOTER_H),
										BackgroundColor3 = s:Computed(function(use)
											if not use(enabled) then
												return C.btnDisabled
											end
											return use(hoveredConfirm) and Color3.fromRGB(220, 180, 30) or C.gold
										end),
										BorderSizePixel = 0,
										Text = s:Computed(function(use)
											if not use(enabled) then
												return "..."
											end
											return confirmText
										end),
										TextSize = 16,
										Font = Enum.Font.GothamBlack,
										TextColor3 = s:Computed(function(use)
											return if use(enabled)
												then Color3.fromRGB(40, 25, 0)
												else C.textMuted
										end),
										AutoButtonColor = false,
										ZIndex = 6,
										[Children] = {
											s:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
											s:New("UIStroke")({
												Color = s:Computed(function(use)
													return use(enabled) and Color3.fromRGB(255, 240, 150) or C.btnBorder
												end),
												Thickness = 2,
												Transparency = 0.2,
											}),
										},
										[OnEvent("MouseEnter")] = function()
											hoveredConfirm:set(true)
										end,
										[OnEvent("MouseLeave")] = function()
											hoveredConfirm:set(false)
										end,
										[OnEvent("Activated")] = function()
											if handle._closed or not peek(enabled) then
												return
											end
											doClose()
											local ok, err = pcall(opts.confirm)
											if not ok then
												warn("[RebirthConfirmModal] confirm failed:", err)
											end
										end,
									}),
								},
							}),
						},
					}),
				},
			}),
		},
	})

	TweenService:Create(backdrop, TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 0.45,
	}):Play()

	task.delay(ANTI_MISCLICK_DELAY, function()
		if not handle._closed then
			enabled:set(true)
		end
	end)

	escConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			doClose()
		end
	end)

	return handle :: Handle
end

return RebirthConfirmModal
