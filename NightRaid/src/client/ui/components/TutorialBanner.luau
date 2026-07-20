--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
	step: number,
}

local TEXTS = {
	[1] = "Hub: Block Roll (+100) · Pet Roll → yard",
	[2] = "Build/Take tools · place on grass grid · Collect All",
	[3] = "E steal · Bat breaks walls · Lock",
	[4] = "Dusk → shine RMB/F",
}

local function TutorialBanner(props: Props): React.ReactElement<any, any>?
	local layout = useLayout()
	local text = TEXTS[props.step]
	if not text then
		return nil
	end

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(layout.px(400), layout.px(48)),
		Position = UDim2.new(0.5, 0, 0.16, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = theme.Colors.bg2,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Colors.gold,
			Thickness = theme.Stroke.medium,
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = text,
			TextSize = layout.text(14),
			Font = theme.Font.title,
			TextColor3 = theme.Colors.goldHi,
		}),
	})
end

return TutorialBanner
