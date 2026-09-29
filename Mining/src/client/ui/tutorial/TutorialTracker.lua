--!strict
-- Верхний баннер цели туториала.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UiAssets = require(ReplicatedStorage:WaitForChild("shared").data.UiAssets)
local TutorialLayout = require(script.Parent.TutorialLayout)
local UiScreen = require(script.Parent.Parent.util.UiScreen)

local TUTORIAL_GUI_NAME = "DeepDigger_Tutorial"
local GOLD = Color3.fromRGB(255, 214, 96)
local CYAN = Color3.fromRGB(120, 210, 255)
local GREEN = Color3.fromRGB(96, 230, 140)
local TEXT_MAIN = Color3.fromRGB(244, 248, 255)
local TEXT_SUB = Color3.fromRGB(156, 170, 210)
local BG_SLICE = Rect.new(36, 30, 476, 82)

local TutorialTracker = {}

export type Options = {
	title: string,
	description: string,
	goal: number?,
	icon: string?,
}

export type Handle = {
	update: (self: Handle, opts: Options) -> (),
	setProgress: (self: Handle, current: number, goal: number?) -> (),
	complete: (self: Handle) -> (),
	destroy: (self: Handle) -> (),
}

local function ensureGui(): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	return UiScreen.ensure(pg, TUTORIAL_GUI_NAME, "tutorial")
end

local function panelBgImage(): string
	local img = UiAssets.image("tutorial_objective_bg")
	if img ~= "" then
		return img
	end
	return ""
end

local function buildFrame(hasProgress: boolean): {
	root: Frame,
	icon: ImageLabel,
	title: TextLabel,
	description: TextLabel,
	progressBg: Frame,
	progressFill: Frame,
	progressText: TextLabel,
	checkmark: ImageLabel,
}
	local tm = TutorialLayout.trackerMetrics(hasProgress)
	local k = TutorialLayout.trackerScale(tm.designW)

	local root = Instance.new("Frame")
	root.Name = "TutorialTracker"
	root.Size = UDim2.fromOffset(tm.designW, tm.designH)
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Position = UDim2.new(0.5, 0, 0, TutorialLayout.trackerTopY())
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ZIndex = 9
	root.ClipsDescendants = true

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = k
	uiScale.Parent = root

	local bgImage = panelBgImage()
	if bgImage ~= "" then
		local bg = Instance.new("ImageLabel")
		bg.Name = "Bg"
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundTransparency = 1
		bg.Image = bgImage
		bg.ScaleType = Enum.ScaleType.Slice
		bg.SliceCenter = BG_SLICE
		bg.SliceScale = if TutorialLayout.isPhone() then 0.85 else 1
		bg.ZIndex = 1
		bg.Parent = root
	else
		root.BackgroundColor3 = Color3.fromRGB(12, 16, 30)
		root.BackgroundTransparency = 0.05
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, if TutorialLayout.isPhone() then 10 else 16)
		corner.Parent = root
		local stroke = Instance.new("UIStroke")
		stroke.Color = GOLD
		stroke.Thickness = 1.5
		stroke.Transparency = 0.2
		stroke.Parent = root
	end

	local iconSlot = Instance.new("Frame")
	iconSlot.Name = "IconSlot"
	iconSlot.Size = UDim2.fromOffset(tm.iconSlot, tm.iconSlot)
	iconSlot.Position = UDim2.fromOffset(tm.iconPad, tm.iconPad)
	iconSlot.BackgroundColor3 = Color3.fromRGB(20, 28, 48)
	iconSlot.BackgroundTransparency = 0.15
	iconSlot.BorderSizePixel = 0
	iconSlot.ZIndex = 3
	iconSlot.Parent = root

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, if TutorialLayout.isPhone() then 10 else 14)
	iconCorner.Parent = iconSlot

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = CYAN
	iconStroke.Thickness = 1.5
	iconStroke.Transparency = 0.35
	iconStroke.Parent = iconSlot

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(tm.iconSize, tm.iconSize)
	icon.Position = UDim2.new(0.5, -tm.iconSize / 2, 0.5, -tm.iconSize / 2)
	icon.BackgroundTransparency = 1
	icon.Image = UiAssets.image("tab_journal")
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 4
	icon.Parent = iconSlot

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -(tm.textX + 12), 0, tm.titleH)
	title.Position = UDim2.fromOffset(tm.textX, tm.titleY)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = tm.titleText
	title.TextColor3 = TEXT_SUB
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 3
	title.Parent = root

	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -(tm.textX + 12), 0, tm.descH)
	description.Position = UDim2.fromOffset(tm.textX, tm.descY)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.GothamBlack
	description.TextSize = tm.descText
	description.TextColor3 = TEXT_MAIN
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.TextWrapped = TutorialLayout.isPhone()
	description.TextTruncate = if TutorialLayout.isPhone() then Enum.TextTruncate.None else Enum.TextTruncate.AtEnd
	description.ZIndex = 3
	description.Parent = root

	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, -tm.iconPad * 2, 0, tm.progressH)
	progressBg.Position = UDim2.fromOffset(tm.iconPad, tm.progressY)
	progressBg.BackgroundColor3 = Color3.fromRGB(8, 10, 20)
	progressBg.BackgroundTransparency = 0.25
	progressBg.BorderSizePixel = 0
	progressBg.ZIndex = 3
	progressBg.Visible = false
	progressBg.Parent = root

	local pbgCorner = Instance.new("UICorner")
	pbgCorner.CornerRadius = UDim.new(1, 0)
	pbgCorner.Parent = progressBg

	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = GOLD
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 4
	progressFill.Parent = progressBg

	local pfillCorner = Instance.new("UICorner")
	pfillCorner.CornerRadius = UDim.new(1, 0)
	pfillCorner.Parent = progressFill

	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Size = UDim2.fromOffset(56, 14)
	progressText.AnchorPoint = Vector2.new(1, 1)
	progressText.Position = UDim2.new(1, -tm.iconPad, 0, tm.progressTextY)
	progressText.BackgroundTransparency = 1
	progressText.Font = Enum.Font.GothamBold
	progressText.TextSize = tm.progressTextSize
	progressText.TextColor3 = GOLD
	progressText.TextXAlignment = Enum.TextXAlignment.Right
	progressText.ZIndex = 5
	progressText.Visible = false
	progressText.Parent = root

	local checkmark = Instance.new("ImageLabel")
	checkmark.Name = "Check"
	checkmark.Size = UDim2.fromOffset(28, 28)
	checkmark.AnchorPoint = Vector2.new(1, 0.5)
	checkmark.Position = UDim2.new(1, -12, 0.5, 0)
	checkmark.BackgroundTransparency = 1
	checkmark.Image = UiAssets.image("icon_check")
	checkmark.ScaleType = Enum.ScaleType.Fit
	checkmark.ImageTransparency = 1
	checkmark.ZIndex = 6
	checkmark.Visible = false
	checkmark.Parent = root

	return {
		root = root,
		icon = icon,
		title = title,
		description = description,
		progressBg = progressBg,
		progressFill = progressFill,
		progressText = progressText,
		checkmark = checkmark,
	}
end

local function applyOptions(state: any, opts: Options)
	local parts = state.parts
	parts.title.Text = string.upper(opts.title or "")
	parts.description.Text = opts.description or ""
	local iconKey = opts.icon or "tab_journal"
	local resolved = UiAssets.resolve(iconKey)
	parts.icon.Image = if resolved ~= "" then resolved else UiAssets.image("tab_journal")

	if opts.goal and opts.goal > 0 then
		state.goal = opts.goal
		state.current = math.min(state.current or 0, opts.goal)
		parts.progressBg.Visible = true
		parts.progressText.Visible = true
		parts.progressFill.Size = UDim2.fromScale(state.current / opts.goal, 1)
		parts.progressText.Text = string.format("%d / %d", state.current, opts.goal)
	else
		state.goal = nil
		parts.progressBg.Visible = false
		parts.progressText.Visible = false
	end
end

function TutorialTracker.show(opts: Options): Handle
	local gui = ensureGui()
	local hasProgress = opts.goal ~= nil and (opts.goal :: number) > 0
	local parts = buildFrame(hasProgress)
	parts.root.Parent = gui

	local state: any = {
		parts = parts,
		destroyed = false,
		completed = false,
		current = 0,
		goal = nil,
	}

	local restY = TutorialLayout.trackerTopY()
	parts.root.Position = UDim2.new(0.5, 0, 0, -80)
	TweenService:Create(
		parts.root,
		TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, restY) }
	):Play()

	applyOptions(state, opts)

	local handle: Handle = {} :: any

	function handle:update(newOpts: Options)
		if state.destroyed then
			return
		end
		applyOptions(state, newOpts)
	end

	function handle:setProgress(current: number, goal: number?)
		if state.destroyed or state.completed then
			return
		end
		if goal then
			state.goal = goal
		end
		state.current = math.max(0, math.min(current, state.goal or current))
		local g = state.goal
		if g and g > 0 then
			parts.progressBg.Visible = true
			parts.progressText.Visible = true
			TweenService:Create(
				parts.progressFill,
				TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.fromScale(state.current / g, 1) }
			):Play()
			parts.progressText.Text = string.format("%d / %d", state.current, g)
		end
	end

	function handle:complete()
		if state.destroyed or state.completed then
			return
		end
		state.completed = true
		if state.goal and state.goal > 0 then
			TweenService:Create(
				parts.progressFill,
				TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.fromScale(1, 1), BackgroundColor3 = GREEN }
			):Play()
			parts.progressText.Text = string.format("%d / %d", state.goal, state.goal)
			parts.progressText.TextColor3 = GREEN
		end
		parts.title.TextColor3 = GREEN
		parts.checkmark.Visible = true
		parts.checkmark.ImageTransparency = 1
		parts.checkmark.Size = UDim2.fromOffset(14, 14)
		TweenService:Create(
			parts.checkmark,
			TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(28, 28), ImageTransparency = 0 }
		):Play()
		task.delay(1.2, function()
			if not state.destroyed then
				handle:destroy()
			end
		end)
	end

	function handle:destroy()
		if state.destroyed then
			return
		end
		state.destroyed = true
		local root = parts.root
		local slideOut = TweenService:Create(
			root,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -80) }
		)
		slideOut:Play()
		slideOut.Completed:Connect(function()
			if root.Parent then
				root:Destroy()
			end
		end)
	end

	return handle
end

return TutorialTracker
