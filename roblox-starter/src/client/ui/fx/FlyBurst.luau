--!strict
-- Generic "fly icons from A → B" burst. Skin via texture/color/count (coins, gems, XP…).

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")

local theme = require(script.Parent.Parent.theme)
local FxOverlay = require(script.Parent.FxOverlay)
local SettingsManager = require(script.Parent.Parent.Parent.core.SettingsManager)

export type FlyBurstOptions = {
	from: Vector2,
	to: Vector2,
	count: number?,
	--- rbxassetid://… or omit for solid circle
	texture: string?,
	color: Color3?,
	sizePx: number?,
	duration: number?,
	spreadPx: number?,
	stagger: number?,
	maxCount: number?,
}

local FlyBurst = {}

local function toScale(abs: Vector2): UDim2
	local cam = workspace.CurrentCamera
	local inset = GuiService:GetGuiInset()
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	return UDim2.fromScale(abs.X / vp.X, (abs.Y - inset.Y) / math.max(1, vp.Y))
end

local function clampCount(requested: number, maxCount: number?): number
	local cap = maxCount or 24
	if SettingsManager.isReduceMotion() then
		cap = math.min(cap, 3)
	end
	return math.clamp(math.floor(requested + 0.5), 1, cap)
end

function FlyBurst.play(opts: FlyBurstOptions)
	local layer = FxOverlay.getLayer()
	local count = clampCount(opts.count or 12, opts.maxCount)
	local sizePx = opts.sizePx or 18
	local duration = opts.duration or 0.55
	local spread = opts.spreadPx or 36
	local stagger = opts.stagger or 0.028
	local color = opts.color or theme.Colors.primaryHi

	for i = 1, count do
		local delay = (i - 1) * stagger
		task.delay(delay, function()
			if layer.Parent == nil then
				return
			end
			local angle = (i / count) * math.pi * 2 + (i % 3) * 0.4
			local ox = math.cos(angle) * spread * (0.35 + (i % 5) * 0.12)
			local oy = math.sin(angle) * spread * (0.35 + (i % 4) * 0.1)
			local start = opts.from + Vector2.new(ox, oy)

			local bit = Instance.new("ImageLabel")
			bit.Name = "FlyBit"
			bit.BackgroundTransparency = if opts.texture then 1 else 0.15
			bit.BackgroundColor3 = color
			bit.Image = opts.texture or ""
			bit.ImageColor3 = color
			bit.AnchorPoint = Vector2.new(0.5, 0.5)
			bit.Position = toScale(start)
			bit.Size = UDim2.fromOffset(sizePx, sizePx)
			bit.ZIndex = 15
			bit.BorderSizePixel = 0
			if not opts.texture then
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(1, 0)
				corner.Parent = bit
			end
			bit.Parent = layer

			local arc = TweenInfo.new(duration * 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local land = TweenInfo.new(duration * 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local mid = start:Lerp(opts.to, 0.45) + Vector2.new(0, -28 - (i % 3) * 6)
			TweenService:Create(bit, arc, {
				Position = toScale(mid),
				Size = UDim2.fromOffset(sizePx * 1.15, sizePx * 1.15),
			}):Play()
			task.delay(duration * 0.45, function()
				if bit.Parent == nil then
					return
				end
				TweenService:Create(bit, land, {
					Position = toScale(opts.to),
					Size = UDim2.fromOffset(sizePx * 0.55, sizePx * 0.55),
					ImageTransparency = 0.35,
					BackgroundTransparency = 1,
				}):Play()
			end)
			Debris:AddItem(bit, duration + delay + 0.1)
		end)
	end
end

return FlyBurst
