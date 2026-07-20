--!strict
-- Короткий PointLight kick. На Low тире слой не вызывается.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type QualityBudget = QualityLogic.QualityBudget

export type LightConfig = {
	range: number?,
	brightness: number?,
	duration: number?,
}

local LightLayer = {}

function LightLayer.pulse(
	parent: Instance,
	cframe: CFrame,
	color: Color3,
	config: LightConfig,
	budget: QualityBudget
): Instance?
	if not budget.enableLights then
		return nil
	end

	local anchor = Instance.new("Part")
	anchor.Name = "VfxLightAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = cframe
	anchor.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = config.range or 14
	light.Brightness = (config.brightness or 2.5) * budget.lightBrightnessScale
	light.Parent = anchor

	local duration = config.duration or 0.28
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(light, info, { Brightness = 0 }):Play()
	Debris:AddItem(anchor, duration + 0.05)
	return anchor
end

return LightLayer
