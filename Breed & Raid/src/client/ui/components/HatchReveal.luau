--!strict
-- Mythic hatch celebration — center modal, aura, confetti, tap to continue.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local MathFx = require(script.Parent.Parent.juice.MathFx)
local UiSound = require(script.Parent.Parent.juice.UiSound)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)

export type HatchPayload = {
	title: string,
	line: string,
	rarity: string?,
	oneIn: number?,
	token: number,
}

export type Props = {
	payload: HatchPayload?,
	onDone: () -> (),
}

local function accentFor(rarity: string?): Color3
	local r = string.lower(rarity or "")
	if r == "secret" then
		return Color3.fromRGB(255, 60, 100)
	elseif r == "mythic" then
		return Color3.fromRGB(200, 80, 255)
	elseif r == "epic" then
		return Color3.fromRGB(170, 90, 255)
	elseif r == "rare" then
		return Color3.fromRGB(80, 150, 255)
	end
	return theme.Colors.goldHi
end

local function HatchReveal(props: Props): React.Node
	local layout = useLayout()
	local payload = props.payload
	local scale, setScale = React.useState(0.35)
	local veil, setVeil = React.useState(1)
	local rootRef = React.useRef(nil :: Frame?)

	React.useEffect(function()
		if not payload then
			return
		end
		UiSound.play("hatch")
		setScale(0.35)
		setVeil(0.25)

		local scaleMotor = Flipper.SingleMotor.new(0.35, false)
		local veilMotor = Flipper.SingleMotor.new(0.25, false)
		local c1 = scaleMotor:onStep(setScale)
		local c2 = veilMotor:onStep(setVeil)
		scaleMotor:start()
		veilMotor:start()
		scaleMotor:setGoal(Flipper.Spring.new(1.12, MotionPresets.SPRING_BOUNCY))
		veilMotor:setGoal(Flipper.Spring.new(0.35, MotionPresets.SPRING_GENTLE))

		local accent = accentFor(payload.rarity)
		task.delay(0.08, function()
			local root = rootRef.current
			if root then
				MathFx.auraPulse(root, accent)
				MathFx.confetti(root, 32)
				MathFx.burstDots(root, accent, 14)
				MathFx.shockwave(root, accent, layout.px(260), 0.5)
			end
		end)
		task.delay(0.4, function()
			scaleMotor:setGoal(Flipper.Spring.new(1, MotionPresets.SPRING_SNAPPY))
			local root = rootRef.current
			if root then
				MathFx.confetti(root, 18)
			end
		end)

		-- Safety dismiss if player never taps
		local safety = task.delay(10, props.onDone)

		return function()
			task.cancel(safety)
			c1:disconnect()
			c2:disconnect()
			scaleMotor:destroy()
			veilMotor:destroy()
		end
	end, { if payload then payload.token else 0 })

	if not payload then
		return React.createElement(React.Fragment)
	end

	local accent = accentFor(payload.rarity)
	local rarityLabel = payload.rarity or "Rare"
	local oddsText = payload.line
	if string.find(oddsText, "·") then
		-- prefer dedicated odds if line still has extras
		oddsText = payload.line
	end

	return React.createElement("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(12, 6, 24),
		BackgroundTransparency = veil,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 100,
		Active = true,
		[React.Event.Activated] = props.onDone,
	}, {
		Card = React.createElement("Frame", {
			ref = rootRef,
			Size = UDim2.fromOffset(layout.px(420), layout.px(460)),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(28, 16, 48),
			BorderSizePixel = 0,
			ZIndex = 101,
		}, {
			Scale = React.createElement("UIScale", { Scale = scale }),
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.lg }),
			Stroke = React.createElement("UIStroke", {
				Color = accent,
				Thickness = 4,
				Transparency = 0.1,
			}),
			Glow = React.createElement("Frame", {
				Size = UDim2.fromOffset(layout.px(200), layout.px(200)),
				Position = UDim2.new(0.5, 0, 0.38, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = accent,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				ZIndex = 101,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
			}),
			Eyebrow = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(32), 0, layout.px(22)),
				Position = UDim2.fromOffset(layout.px(16), layout.px(18)),
				BackgroundTransparency = 1,
				Text = "You hatched...",
				TextSize = layout.text(16),
				Font = theme.Font.body,
				TextColor3 = Color3.fromRGB(240, 230, 255),
				ZIndex = 103,
			}),
			PetGlyph = React.createElement("TextLabel", {
				Size = UDim2.fromOffset(layout.px(120), layout.px(120)),
				Position = UDim2.new(0.5, 0, 0.38, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Text = "🐉",
				TextSize = layout.text(72),
				ZIndex = 103,
			}),
			Title = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(24), 0, layout.px(42)),
				Position = UDim2.new(0.5, 0, 0.58, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Text = string.upper(payload.title),
				TextSize = layout.text(28),
				Font = theme.Font.display,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextStrokeColor3 = accent,
				TextStrokeTransparency = 0.35,
				ZIndex = 103,
			}),
			Rarity = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(24), 0, layout.px(28)),
				Position = UDim2.new(0.5, 0, 0.68, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Text = rarityLabel,
				TextSize = layout.text(20),
				Font = theme.Font.title,
				TextColor3 = accent,
				ZIndex = 103,
			}),
			Odds = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(24), 0, layout.px(40)),
				Position = UDim2.new(0.5, 0, 0.76, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Text = oddsText,
				TextSize = layout.text(26),
				Font = theme.Font.heavy,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextStrokeTransparency = 0.5,
				ZIndex = 103,
			}),
			Hint = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(24), 0, layout.px(20)),
				Position = UDim2.new(0.5, 0, 1, -layout.px(36)),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Text = "Tap anywhere to continue!",
				TextSize = layout.text(14),
				Font = theme.Font.body,
				TextColor3 = Color3.fromRGB(220, 210, 240),
				ZIndex = 103,
			}),
		}),
	})
end

return HatchReveal
