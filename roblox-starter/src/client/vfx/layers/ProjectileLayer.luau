--!strict
-- Снаряд A→B: якорь летит, trail/beam опционально. callback onArrive.

local RunService = game:GetService("RunService")
local TrailLayer = require(script.Parent.TrailLayer)
local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type QualityBudget = QualityLogic.QualityBudget

export type ProjectileConfig = {
	speed: number?,
	color: Color3,
	withTrail: boolean?,
	onArrive: (() -> ())?,
}

export type ProjectileHandle = {
	stop: (self: ProjectileHandle) -> (),
}

local ProjectileLayer = {}

function ProjectileLayer.fire(
	parent: Instance,
	from: CFrame,
	to: CFrame,
	config: ProjectileConfig,
	budget: QualityBudget
): ProjectileHandle
	local speed = config.speed or 80
	local anchor = Instance.new("Part")
	anchor.Name = "VfxProjectile"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Material = Enum.Material.Neon
	anchor.Color = config.color
	anchor.Size = Vector3.new(0.6, 0.6, 1.8)
	anchor.CFrame = CFrame.lookAt(from.Position, to.Position)
	anchor.Parent = parent

	if config.withTrail ~= false then
		TrailLayer.attach(anchor, config.color, { lifetime = 0.35, width0 = 1.4 }, budget)
	end

	local start = from.Position
	local goal = to.Position
	local dist = (goal - start).Magnitude
	local duration = if speed > 0 then dist / speed else 0.01
	local elapsed = 0
	local stopped = false
	local conn: RBXScriptConnection?

	conn = RunService.Heartbeat:Connect(function(dt)
		if stopped then
			return
		end
		elapsed += dt
		local t = math.clamp(elapsed / duration, 0, 1)
		local pos = start:Lerp(goal, t)
		anchor.CFrame = CFrame.lookAt(pos, pos + (goal - start))
		if t >= 1 then
			stopped = true
			if conn then
				conn:Disconnect()
			end
			anchor:Destroy()
			if config.onArrive then
				config.onArrive()
			end
		end
	end)

	return {
		stop = function(_)
			if stopped then
				return
			end
			stopped = true
			if conn then
				conn:Disconnect()
			end
			anchor:Destroy()
		end,
	}
end

return ProjectileLayer
