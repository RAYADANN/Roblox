--!strict
-- Fullscreen juice layer: buy gold flash + collect ring host.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local MathFx = require(script.Parent.Parent.juice.MathFx)
local UiSound = require(script.Parent.Parent.juice.UiSound)
local Formatters = require(script.Parent.Parent.util.Formatters)

export type Props = {
	buyToken: number,
	collectToken: number,
	collectAmount: number,
}

local function JuiceLayer(props: Props): React.Node
	local layout = useLayout()
	local hostRef = React.useRef(nil :: Frame?)
	local collectRef = React.useRef(nil :: Frame?)
	local floatText, setFloatText = React.useState(nil :: string?)

	React.useEffect(function()
		if props.buyToken <= 0 then
			return
		end
		UiSound.play("buy")
		local host = hostRef.current
		if host then
			MathFx.goldFlash(host)
			MathFx.burstDots(host, theme.Colors.gold, 6)
		end
	end, { props.buyToken })

	React.useEffect(function()
		if props.collectToken <= 0 then
			return
		end
		UiSound.play("collect")
		local host = collectRef.current
		if host then
			MathFx.shockwave(host, theme.Colors.sellHi, layout.px(160), 0.42)
			MathFx.burstDots(host, theme.Colors.sell, 8)
		end
		setFloatText(`+{Formatters.shortNumber(props.collectAmount)}`)
		local t = task.delay(0.95, function()
			setFloatText(nil)
		end)
		return function()
			task.cancel(t)
		end
	end, { props.collectToken })

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 40,
		Active = false,
	}, {
		Host = React.createElement("Frame", {
			ref = hostRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 41,
		}),
		CollectHost = React.createElement("Frame", {
			ref = collectRef,
			Size = UDim2.fromOffset(layout.px(72), layout.px(72)),
			Position = UDim2.fromOffset(
				layout.safeLeft + layout.gap(10),
				layout.safeTop + layout.px(theme.Design.CHIP_H) + layout.gap(16) + layout.touch(theme.Design.NAV_BTN) * 3 + layout.gap(40)
			),
			BackgroundTransparency = 1,
			ZIndex = 42,
		}, {
			Float = if floatText
				then React.createElement("TextLabel", {
					Size = UDim2.fromOffset(layout.px(120), layout.px(28)),
					Position = UDim2.new(0.5, 0, 0, -layout.px(28)),
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
					Text = floatText,
					TextSize = layout.text(18),
					Font = theme.Font.heavy,
					TextColor3 = theme.Colors.sellHi,
					ZIndex = 43,
				})
				else nil,
		}),
	})
end

return JuiceLayer
