--!strict
-- Чип очков — стиль currencyChip из UI Templates.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.Parent.ImageIds)
local theme = require(script.Parent.Parent.theme)
local useSpringValue = require(script.Parent.Parent.hooks.useSpringValue)
local springs = require(script.Parent.Parent.hooks.springs)

export type Props = {
	amount: number,
}

local function PointsChip(props: Props): React.Node
	local display, setDisplay = useSpringValue(props.amount, springs.soft)

	React.useEffect(function()
		setDisplay(props.amount, springs.soft)
	end, { props.amount })

	return React.createElement("Frame", {
		Name = "PointsChip",
		Size = UDim2.fromOffset(220, 56),
		BackgroundColor3 = Color3.fromRGB(20, 20, 24),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Colors.black,
			Thickness = 3,
		}),
		Icon = React.createElement("ImageLabel", {
			Size = UDim2.fromOffset(44, 44),
			Position = UDim2.new(0, 8, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = ImageIds.Hud.coins,
			ScaleType = Enum.ScaleType.Fit,
		}),
		Amount = React.createElement("TextLabel", {
			Size = UDim2.new(1, -64, 1, 0),
			Position = UDim2.fromOffset(56, 0),
			BackgroundTransparency = 1,
			Text = tostring(math.floor(display + 0.5)),
			Font = theme.Font.display,
			TextScaled = true,
			TextColor3 = theme.Colors.white,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			Pad = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 12),
			}),
			Outline = React.createElement("UIStroke", {
				Color = theme.Colors.black,
				Thickness = theme.Stroke.text,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			}),
		}),
	})
end

return PointsChip
