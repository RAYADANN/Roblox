--!strict
-- Custom ProximityPrompt: кнопка = default Roblox, текст = theme (одинаковый размер, без фона).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

export type PromptView = {
	keyText: string,
	objectText: string,
	actionText: string,
	adornee: BasePart?,
	inputType: Enum.ProximityPromptInputType?,
}

export type Props = {
	prompt: PromptView?,
}

local BackgroundColor = Color3.new(0.07, 0.07, 0.07)
local ContentColor = Color3.new(1, 1, 1)
local KEY_SINGLE = "rbxasset://textures/ui/Controls/key_single.png"
local TOUCH_TAP = "rbxasset://textures/ui/Controls/TouchTapIcon.png"

local CIRCLE = 72
local KEY_IMG = 42
local KEY_TEXT = 22
local LABEL_SIZE = 28
local LABEL_STROKE = theme.Stroke.title
local BILLBOARD = UDim2.fromOffset(420, 100)

local function themedLabel(props: {
	text: string,
	layoutOrder: number,
}): React.Node
	return React.createElement("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = props.text,
		Font = theme.Font.display,
		TextSize = LABEL_SIZE,
		TextColor3 = theme.Colors.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		Outline = React.createElement("UIStroke", {
			Color = theme.Colors.black,
			Thickness = LABEL_STROKE,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}),
	})
end

local function DefaultKeyButton(props: {
	keyText: string,
	inputType: Enum.ProximityPromptInputType?,
}): React.Node
	local inputType = props.inputType or Enum.ProximityPromptInputType.Keyboard

	local children: { [string]: React.Node } = {
		RoundFrame = React.createElement("Frame", {
			Name = "RoundFrame",
			Size = UDim2.fromOffset(CIRCLE, CIRCLE),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = BackgroundColor,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0.5, 0),
			}),
		}),
	}

	if inputType == Enum.ProximityPromptInputType.Touch then
		children.ButtonImage = React.createElement("ImageLabel", {
			Name = "ButtonImage",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(38, 46),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Image = TOUCH_TAP,
		})
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		children.ButtonImage = React.createElement("ImageLabel", {
			Name = "ButtonImage",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(36, 36),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Image = UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonX),
		})
	else
		children.ButtonImage = React.createElement("ImageLabel", {
			Name = "ButtonImage",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(KEY_IMG, math.floor(KEY_IMG * 30 / 28)),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Image = KEY_SINGLE,
		})
		children.ButtonText = React.createElement("TextLabel", {
			Name = "ButtonText",
			AutoLocalize = false,
			Position = UDim2.fromOffset(0, -1),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = KEY_TEXT,
			TextColor3 = ContentColor,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = props.keyText,
		})
	end

	return React.createElement("Frame", {
		Name = "InputFrame",
		Size = UDim2.fromOffset(CIRCLE, CIRCLE),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, children)
end

local function PromptContent(prompt: PromptView): React.Node
	return React.createElement("Frame", {
		Name = "PromptFrame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Input = React.createElement(DefaultKeyButton, {
			keyText = prompt.keyText,
			inputType = prompt.inputType,
		}),
		Texts = React.createElement("Frame", {
			Name = "TextFrame",
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 2,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Object = if prompt.objectText ~= ""
				then themedLabel({
					text = prompt.objectText,
					layoutOrder = 1,
				})
				else nil,
			Action = if prompt.actionText ~= ""
				then themedLabel({
					text = prompt.actionText,
					layoutOrder = 2,
				})
				else nil,
		}),
	})
end

local function ProximityPromptUI(props: Props): React.Node
	local prompt = props.prompt
	if not prompt then
		return nil
	end

	local content = PromptContent(prompt)

	if prompt.adornee then
		return React.createElement("BillboardGui", {
			Name = "ProximityPromptUI",
			Adornee = prompt.adornee,
			Size = BILLBOARD,
			AlwaysOnTop = true,
			MaxDistance = 40,
			Active = false,
			LightInfluence = 0,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			Content = content,
		})
	end

	return React.createElement("Frame", {
		Name = "ProximityPromptUI",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = BILLBOARD,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 40,
	}, {
		Content = content,
	})
end

return ProximityPromptUI
