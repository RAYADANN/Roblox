--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local CombatConfig = require(shared.data.CombatConfig)
local BaseBuilder = require(script.Parent.BaseBuilder)

export type LightService = {
	attachToBlock: (self: LightService, block: BasePart, tier: number) -> (),
	detachFromBlock: (self: LightService, block: BasePart) -> (),
	getLampFearAt: (self: LightService, plot: BaseBuilder.BasePlot, worldPos: Vector3) -> number,
	getSlowAt: (self: LightService, plot: BaseBuilder.BasePlot, worldPos: Vector3) -> number,
	-- legacy aliases used by MonsterService
	getLampFearPerSec: (self: LightService, plot: BaseBuilder.BasePlot, worldPos: Vector3) -> number,
	getLightSlowFactor: (self: LightService, plot: BaseBuilder.BasePlot, worldPos: Vector3) -> number,
	destroy: (self: LightService) -> (),
}

local LightService = {}
LightService.__index = LightService

function LightService.new(): LightService
	return setmetatable({
		_lamps = {} :: { [BasePart]: { tier: number, light: PointLight } },
	}, LightService)
end

function LightService:attachToBlock(block: BasePart, tier: number)
	self:detachFromBlock(block)
	local light = Instance.new("PointLight")
	light.Brightness = if tier >= 2 then 2.2 else 1.4
	light.Range = if tier >= 2 then CombatConfig.Light.lampT2Radius else CombatConfig.Light.lampRadius
	light.Color = Color3.fromRGB(255, 230, 160)
	light.Parent = block
	self._lamps[block] = { tier = tier, light = light }
end

function LightService:detachFromBlock(block: BasePart)
	local entry = self._lamps[block]
	if entry then
		entry.light:Destroy()
		self._lamps[block] = nil
	end
end

function LightService:getLampFearAt(plot: BaseBuilder.BasePlot, worldPos: Vector3): number
	local best = 0
	for block, entry in self._lamps do
		if block.Parent == plot.model then
			local radius = if entry.tier >= 2 then CombatConfig.Light.lampT2Radius else CombatConfig.Light.lampRadius
			local fear = if entry.tier >= 2 then CombatConfig.Light.lampT2FearPerSec else CombatConfig.Light.lampFearPerSec
			if (block.Position - worldPos).Magnitude <= radius then
				best = math.max(best, fear)
			end
		end
	end
	return best
end

function LightService:getSlowAt(plot: BaseBuilder.BasePlot, worldPos: Vector3): number
	if self:getLampFearAt(plot, worldPos) > 0 then
		return 0.5
	end
	return 1
end

function LightService:getLampFearPerSec(plot: BaseBuilder.BasePlot, worldPos: Vector3): number
	return self:getLampFearAt(plot, worldPos)
end

function LightService:getLightSlowFactor(plot: BaseBuilder.BasePlot, worldPos: Vector3): number
	return self:getSlowAt(plot, worldPos)
end

function LightService:destroy()
	for block in self._lamps do
		self:detachFromBlock(block)
	end
end

return LightService
