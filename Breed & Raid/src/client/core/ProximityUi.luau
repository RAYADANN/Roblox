--!strict
-- Toybox Premium custom ProximityPrompt UI.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldUi = require(ReplicatedStorage.shared.ui.WorldUi)
local ThemeColors = require(ReplicatedStorage.shared.ui.ThemeColors)
local UiScreen = require(script.Parent.Parent.ui.util.UiScreen)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local C = ThemeColors.Colors

local screen = UiScreen.ensure(playerGui, "BreedRaidPrompts", "toast")
local active: { [ProximityPrompt]: BillboardGui } = {}

local function keyLabel(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "TAP"
	end
	local ok, name = pcall(function()
		return UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
	end)
	if ok and name and name ~= "" then
		return string.upper(name)
	end
	return "E"
end

local function destroyUi(prompt: ProximityPrompt)
	local gui = active[prompt]
	if gui then
		gui:Destroy()
		active[prompt] = nil
	end
end

local function showUi(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	destroyUi(prompt)
	local adornee = prompt.Parent
	if not adornee or (not adornee:IsA("BasePart") and not adornee:IsA("Attachment")) then
		return
	end

	local kindAttr = prompt:GetAttribute("UiKind")
	local kind = if typeof(kindAttr) == "string" then kindAttr else nil
	local accent = WorldUi.promptAccent(kind)
	local isTouch = inputType == Enum.ProximityPromptInputType.Touch
	local promptWidth = if isTouch then 268 else 250
	local promptHeight = if isTouch then 96 else 88
	local keyWidth = if isTouch then 72 else 54
	local connections: { RBXScriptConnection } = {}

	local gui = Instance.new("BillboardGui")
	gui.Name = "CustomPrompt"
	gui.Size = UDim2.fromOffset(promptWidth, promptHeight)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = prompt.MaxActivationDistance + 8
	gui.LightInfluence = 0
	gui.Adornee = adornee
	gui.Parent = screen

	local card, content = WorldUi.makeCardFrame(gui, UDim2.fromScale(1, 1), accent)
	card.BackgroundTransparency = 0
	-- Prompt uses absolute children on card; clear content list usage
	content:Destroy()

	local key = Instance.new("TextButton")
	key.Name = "Key"
	key.Size = UDim2.fromOffset(keyWidth, if isTouch then 58 else 54)
	key.Position = UDim2.new(0, 18, 0.5, -4)
	key.AnchorPoint = Vector2.new(0, 0.5)
	key.BackgroundColor3 = accent
	key.BorderSizePixel = 0
	key.AutoButtonColor = false
	key.Active = isTouch
	key.Text = ""
	key.ZIndex = 3
	key.Parent = card
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(0, 18)
	kc.Parent = key
	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color = C.outline
	keyStroke.Thickness = 3
	keyStroke.Parent = key
	local kl = Instance.new("TextLabel")
	kl.BackgroundTransparency = 1
	kl.Size = UDim2.fromScale(1, 1)
	kl.Font = Enum.Font.GothamBlack
	kl.TextSize = if isTouch then 17 else 21
	local lum = accent.R * 0.299 + accent.G * 0.587 + accent.B * 0.114
	kl.TextColor3 = if lum > 0.55 then C.textDark else C.white
	kl.Text = keyLabel(prompt, inputType)
	kl.ZIndex = 4
	kl.Parent = key

	local textLeft = 18 + keyWidth + 14
	local action = Instance.new("TextLabel")
	action.BackgroundTransparency = 1
	action.Position = UDim2.fromOffset(textLeft, 14)
	action.Size = UDim2.new(1, -(textLeft + 14), 0, 24)
	action.Font = Enum.Font.GothamBlack
	action.TextSize = if isTouch then 18 else 17
	action.TextColor3 = accent
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.TextTruncate = Enum.TextTruncate.AtEnd
	action.Text = prompt.ActionText
	action.ZIndex = 3
	action.Parent = card

	local object = Instance.new("TextLabel")
	object.BackgroundTransparency = 1
	object.Position = UDim2.fromOffset(textLeft, 40)
	object.Size = UDim2.new(1, -(textLeft + 14), 0, 18)
	object.Font = Enum.Font.GothamMedium
	object.TextSize = 12
	object.TextColor3 = C.textSub
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.TextTruncate = Enum.TextTruncate.AtEnd
	object.Text = prompt.ObjectText
	object.ZIndex = 3
	object.Parent = card

	local barBg = Instance.new("Frame")
	barBg.Name = "HoldBg"
	barBg.Size = UDim2.new(1, -32, 0, 9)
	barBg.Position = UDim2.new(0, 16, 1, -16)
	barBg.BackgroundColor3 = C.bg4
	barBg.BorderSizePixel = 0
	barBg.Visible = prompt.HoldDuration > 0
	barBg.ZIndex = 3
	barBg.Parent = card
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barBg
	local bar = Instance.new("Frame")
	bar.Name = "HoldFill"
	bar.Size = UDim2.fromScale(0, 1)
	bar.BackgroundColor3 = accent
	bar.BorderSizePixel = 0
	bar.Parent = barBg
	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(1, 0)
	barFillCorner.Parent = bar

	local scale = Instance.new("UIScale")
	scale.Scale = 0.9
	scale.Parent = card
	TweenService:Create(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	if isTouch then
		table.insert(
			connections,
			key.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					prompt:InputHoldBegin()
				end
			end)
		)
		table.insert(
			connections,
			key.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					prompt:InputHoldEnd()
				end
			end)
		)
	end
	if prompt.HoldDuration > 0 then
		table.insert(
			connections,
			prompt.PromptButtonHoldBegan:Connect(function()
				bar.Size = UDim2.fromScale(0, 1)
				TweenService:Create(
					bar,
					TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear),
					{ Size = UDim2.fromScale(1, 1) }
				):Play()
			end)
		)
		table.insert(
			connections,
			prompt.PromptButtonHoldEnded:Connect(function()
				TweenService:Create(bar, TweenInfo.new(0.1), { Size = UDim2.fromScale(0, 1) }):Play()
			end)
		)
	end
	table.insert(
		connections,
		prompt:GetPropertyChangedSignal("ObjectText"):Connect(function()
			object.Text = prompt.ObjectText
		end)
	)
	table.insert(
		connections,
		prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
			action.Text = prompt.ActionText
		end)
	)
	gui.Destroying:Connect(function()
		for _, conn in connections do
			conn:Disconnect()
		end
	end)

	active[prompt] = gui
end

local ProximityUi = {}
local started = false

function ProximityUi.start()
	if started then
		return
	end
	started = true
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return
		end
		showUi(prompt, inputType)
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		destroyUi(prompt)
	end)
end

return ProximityUi
