--!strict
-- Боттом-центр диалог наставника с typewriter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local UiAssets = require(ReplicatedStorage:WaitForChild("shared").data.UiAssets)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t
local TutorialLayout = require(script.Parent.TutorialLayout)
local UiScreen = require(script.Parent.Parent.util.UiScreen)

local TUTORIAL_GUI_NAME = "DeepDigger_Tutorial"
local TYPE_SPEED_CHARS_PER_SEC = 42

local KIND_COLORS = {
	intro = Color3.fromRGB(255, 210, 50),
	task = Color3.fromRGB(80, 200, 255),
	success = Color3.fromRGB(100, 220, 100),
	finale = Color3.fromRGB(220, 120, 255),
}
local DEFAULT_COLOR = KIND_COLORS.intro

local TutorialDialog = {}

export type Options = {
	speaker: string,
	name: string,
	text: string,
	kind: string?,
	onAdvance: (() -> ())?,
	onSkip: (() -> ())?,
	hideAdvanceButton: boolean?,
	skipTypewriter: boolean?,
}

export type Handle = {
	update: (self: Handle, opts: Options) -> (),
	destroy: (self: Handle) -> (),
}

local function ensureGui(): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	return UiScreen.ensure(pg, TUTORIAL_GUI_NAME, "tutorial")
end

local function colorFor(kind: string?): Color3
	if kind and KIND_COLORS[kind] then
		return KIND_COLORS[kind]
	end
	return DEFAULT_COLOR
end

local function measureTextHeight(textLabel: TextLabel, fullText: string, width: number): number
	local minH = if TutorialLayout.isPhone()
		then TutorialLayout.px(TutorialLayout.scaledDesign(28))
		else TutorialLayout.px(44)
	local bounds = TextService:GetTextSize(
		fullText,
		textLabel.TextSize,
		textLabel.Font,
		Vector2.new(math.max(1, width), 10000)
	)
	return math.max(minH, math.ceil(bounds.Y) + TutorialLayout.px(4))
end

local function reflowDialog(parts: {
	root: Frame,
	textLabel: TextLabel,
	advanceBtn: TextButton,
}, fullText: string?)
	local m = TutorialLayout.dialogMetrics()
	local text = fullText or parts.textLabel.Text
	local textW = m.width - m.sideInset
	local textH = measureTextHeight(parts.textLabel, text, textW)
	parts.textLabel.Size = UDim2.new(1, -m.sideInset, 0, textH)

	local footerH = if parts.advanceBtn.Visible then m.footerAdvance else m.footerSkipOnly
	local padTop = m.avatarPad
	local totalH = math.max(
		m.minH,
		padTop + m.nameH + TutorialLayout.px(4) + textH + footerH
	)
	totalH = math.min(totalH, m.maxH)

	parts.root.Size = UDim2.fromOffset(m.width, totalH)
	parts.root.Position = UDim2.new(0.5, 0, 1, TutorialLayout.dialogRestY())
end

local function buildFrame(): {
	root: Frame,
	avatar: ImageLabel,
	avatarRing: UIStroke,
	nameLabel: TextLabel,
	textLabel: TextLabel,
	advanceBtn: TextButton,
	skipBtn: TextButton,
	stroke: UIStroke,
	contentClick: TextButton,
}
	local m = TutorialLayout.dialogMetrics()
	local phone = TutorialLayout.isPhone()

	local root = Instance.new("Frame")
	root.Name = "TutorialDialog"
	root.Size = UDim2.fromOffset(m.width, m.minH)
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.new(0.5, 0, 1, 200)
	root.BackgroundColor3 = Color3.fromRGB(14, 14, 28)
	root.BackgroundTransparency = 0.08
	root.BorderSizePixel = 0
	root.ZIndex = 10
	root.Active = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, m.corner)
	corner.Parent = root

	local stroke = Instance.new("UIStroke")
	stroke.Color = DEFAULT_COLOR
	stroke.Thickness = math.max(1, TutorialLayout.px(2))
	stroke.Transparency = 0.1
	stroke.Parent = root

	local contentClick = Instance.new("TextButton")
	contentClick.Name = "ContentClick"
	contentClick.Size = UDim2.fromScale(1, 1)
	contentClick.BackgroundTransparency = 1
	contentClick.Text = ""
	contentClick.AutoButtonColor = false
	contentClick.ZIndex = 11
	contentClick.Parent = root

	local avatarFrame = Instance.new("Frame")
	avatarFrame.Size = UDim2.fromOffset(m.avatarSize, m.avatarSize)
	avatarFrame.Position = UDim2.fromOffset(m.avatarPad, m.avatarPad)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 50)
	avatarFrame.BorderSizePixel = 0
	avatarFrame.ZIndex = 12
	avatarFrame.Active = false
	avatarFrame.Parent = root

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatarFrame

	local avatarRing = Instance.new("UIStroke")
	avatarRing.Color = DEFAULT_COLOR
	avatarRing.Thickness = math.max(1, TutorialLayout.px(2))
	avatarRing.Parent = avatarFrame

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.fromScale(1, 1)
	avatar.BackgroundTransparency = 1
	avatar.Image = UiAssets.image("upg_pickaxe")
	avatar.ScaleType = Enum.ScaleType.Fit
	avatar.ZIndex = 13
	avatar.Parent = avatarFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -m.sideInset, 0, m.nameH)
	nameLabel.Position = UDim2.fromOffset(m.textColX, m.avatarPad)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextSize = m.nameText
	nameLabel.TextColor3 = DEFAULT_COLOR
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 12
	nameLabel.Parent = root

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -m.sideInset, 0, TutorialLayout.px(28))
	textLabel.Position = UDim2.fromOffset(m.textColX, m.avatarPad + m.nameH + TutorialLayout.px(2))
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = m.bodyText
	textLabel.TextColor3 = Color3.fromRGB(232, 230, 220)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.TextWrapped = true
	textLabel.RichText = true
	textLabel.LineHeight = if phone then 1.02 else 1.05
	textLabel.ZIndex = 12
	textLabel.Parent = root

	local advanceBtn = Instance.new("TextButton")
	advanceBtn.Size = UDim2.fromOffset(
		TutorialLayout.px(TutorialLayout.scaledDesign(if phone then 100 else 140)),
		TutorialLayout.px(TutorialLayout.scaledDesign(if phone then 24 else 30))
	)
	advanceBtn.AnchorPoint = Vector2.new(1, 1)
	advanceBtn.Position = UDim2.new(1, -m.skipSize - TutorialLayout.px(10), 1, -TutorialLayout.px(6))
	advanceBtn.BackgroundColor3 = DEFAULT_COLOR
	advanceBtn.BorderSizePixel = 0
	advanceBtn.Text = L("tutorial.dialog.advance")
	advanceBtn.Font = Enum.Font.GothamBold
	advanceBtn.TextSize = TutorialLayout.textPx(TutorialLayout.scaledDesign(if phone then 11 else 14))
	advanceBtn.TextColor3 = Color3.fromRGB(20, 20, 36)
	advanceBtn.ZIndex = 14
	advanceBtn.Parent = root

	local advBtnCorner = Instance.new("UICorner")
	advBtnCorner.CornerRadius = UDim.new(0, TutorialLayout.px(6))
	advBtnCorner.Parent = advanceBtn

	local skipBtn = Instance.new("TextButton")
	skipBtn.Size = UDim2.fromOffset(m.skipSize, m.skipSize)
	if phone then
		skipBtn.AnchorPoint = Vector2.new(1, 0)
		skipBtn.Position = UDim2.new(1, -TutorialLayout.px(6), 0, TutorialLayout.px(6))
	else
		skipBtn.AnchorPoint = Vector2.new(1, 1)
		skipBtn.Position = UDim2.new(1, -TutorialLayout.px(10), 1, -TutorialLayout.px(8))
	end
	skipBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
	skipBtn.BackgroundTransparency = 0.15
	skipBtn.BorderSizePixel = 0
	skipBtn.Text = "X"
	skipBtn.Font = Enum.Font.GothamBold
	skipBtn.TextSize = TutorialLayout.textPx(TutorialLayout.scaledDesign(if phone then 14 else 16))
	skipBtn.TextColor3 = Color3.fromRGB(220, 180, 180)
	skipBtn.ZIndex = 15
	skipBtn.Parent = root

	local skipBtnCorner = Instance.new("UICorner")
	skipBtnCorner.CornerRadius = UDim.new(0, TutorialLayout.px(6))
	skipBtnCorner.Parent = skipBtn

	local skipBtnStroke = Instance.new("UIStroke")
	skipBtnStroke.Color = Color3.fromRGB(180, 80, 80)
	skipBtnStroke.Thickness = 1
	skipBtnStroke.Transparency = 0.3
	skipBtnStroke.Parent = skipBtn

	return {
		root = root,
		avatar = avatar,
		avatarRing = avatarRing,
		nameLabel = nameLabel,
		textLabel = textLabel,
		advanceBtn = advanceBtn,
		skipBtn = skipBtn,
		stroke = stroke,
		contentClick = contentClick,
	}
end

local function startTypewriter(state: any, fullText: string)
	if state.typeConn then
		state.typeConn:Disconnect()
		state.typeConn = nil
	end
	state.fullText = fullText
	state.typedChars = 0
	state.textLabel.Text = ""
	state.startTime = os.clock()
	state.typeConn = RunService.Heartbeat:Connect(function()
		if not state.fullText then
			if state.typeConn then
				state.typeConn:Disconnect()
			end
			return
		end
		local elapsed = os.clock() - state.startTime
		local total = #state.fullText
		local target = math.min(total, math.floor(elapsed * TYPE_SPEED_CHARS_PER_SEC))
		if target > state.typedChars then
			state.typedChars = target
			local cut = utf8.offset(state.fullText, target + 1)
			if cut then
				state.textLabel.Text = string.sub(state.fullText, 1, cut - 1)
			else
				state.textLabel.Text = state.fullText
				state.typedChars = total
			end
			reflowDialog(state.parts, state.fullText)
		end
		if state.typedChars >= total then
			if state.typeConn then
				state.typeConn:Disconnect()
			end
			state.typeConn = nil
			state.textLabel.Text = state.fullText
			reflowDialog(state.parts, state.fullText)
		end
	end)
end

local function finishTypewriter(state: any)
	if state.typeConn then
		state.typeConn:Disconnect()
		state.typeConn = nil
	end
	if state.fullText then
		state.textLabel.Text = state.fullText
		state.typedChars = #state.fullText
		reflowDialog(state.parts, state.fullText)
	end
end

local function applyColor(parts: any, color: Color3)
	parts.stroke.Color = color
	parts.avatarRing.Color = color
	parts.nameLabel.TextColor3 = color
	parts.advanceBtn.BackgroundColor3 = color
end

local function applyOptions(state: any, opts: Options)
	local parts = state.parts
	parts.avatar.Image = UiAssets.resolve(opts.speaker) ~= "" and UiAssets.resolve(opts.speaker)
		or UiAssets.image("upg_pickaxe")
	parts.nameLabel.Text = opts.name or ""

	local color = colorFor(opts.kind)
	applyColor(parts, color)

	local newText = opts.text or ""
	if newText ~= state.fullText then
		if opts.skipTypewriter then
			state.fullText = newText
			finishTypewriter(state)
		else
			reflowDialog(parts, newText)
			startTypewriter(state, newText)
		end
	end

	parts.advanceBtn.Visible = not (opts.hideAdvanceButton == true)
	reflowDialog(parts, state.fullText)

	state.onAdvance = opts.onAdvance
	state.onSkip = opts.onSkip
end

function TutorialDialog.show(opts: Options): Handle
	local gui = ensureGui()
	for _, child in ipairs(gui:GetChildren()) do
		if child:IsA("Frame") and child.Name == "TutorialDialog" then
			child:Destroy()
		end
	end

	local parts = buildFrame()
	parts.root.Parent = gui

	local state: any = {
		parts = parts,
		destroyed = false,
		typeConn = nil,
		fullText = nil,
		typedChars = 0,
		startTime = 0,
		onAdvance = opts.onAdvance,
		onSkip = opts.onSkip,
		textLabel = parts.textLabel,
		connections = {},
	}

	local m = TutorialLayout.dialogMetrics()
	parts.root.Size = UDim2.fromOffset(m.width, m.minH)
	parts.root.Position = UDim2.new(0.5, 0, 1, 200)
	TweenService:Create(
		parts.root,
		TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 1, TutorialLayout.dialogRestY()) }
	):Play()

	applyOptions(state, opts)

	table.insert(state.connections, parts.contentClick.Activated:Connect(function()
		if state.typeConn then
			finishTypewriter(state)
		end
	end))

	table.insert(state.connections, parts.advanceBtn.Activated:Connect(function()
		if state.destroyed then
			return
		end
		if state.typeConn then
			finishTypewriter(state)
			return
		end
		if state.onAdvance then
			state.onAdvance()
		end
	end))

	table.insert(state.connections, parts.skipBtn.Activated:Connect(function()
		if state.destroyed then
			return
		end
		if state.onSkip then
			state.onSkip()
		end
	end))

	local handle: Handle = {} :: any
	function handle:update(newOpts: Options)
		if state.destroyed then
			return
		end
		applyOptions(state, newOpts)
	end
	function handle:destroy()
		if state.destroyed then
			return
		end
		state.destroyed = true
		if state.typeConn then
			state.typeConn:Disconnect()
			state.typeConn = nil
		end
		for _, c in ipairs(state.connections) do
			c:Disconnect()
		end
		local root = parts.root
		local slideOut = TweenService:Create(
			root,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 1, 200), BackgroundTransparency = 1 }
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

return TutorialDialog
