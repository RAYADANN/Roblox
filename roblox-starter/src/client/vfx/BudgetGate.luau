--!strict
-- Лимит одновременных FX + distance cull. Без этого телефоны греются.

local Types = require(game:GetService("ReplicatedStorage").shared.vfx.Types)
local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type QualityBudget = QualityLogic.QualityBudget
export type FxPriority = Types.FxPriority

export type BudgetGate = {
	tryAcquire: (self: BudgetGate, priority: FxPriority, budget: QualityBudget) -> boolean,
	release: (self: BudgetGate) -> (),
	activeCount: (self: BudgetGate) -> number,
	droppedCount: (self: BudgetGate) -> number,
	resetDropped: (self: BudgetGate) -> (),
	shouldCull: (
		self: BudgetGate,
		worldPos: Vector3,
		cameraPos: Vector3,
		budget: QualityBudget
	) -> boolean,
	destroy: (self: BudgetGate) -> (),
}

local BudgetGate = {}
BudgetGate.__index = BudgetGate

function BudgetGate.new(): BudgetGate
	local self = setmetatable({
		_active = 0,
		_dropped = 0,
		_destroyed = false,
	}, BudgetGate)
	return (self :: any) :: BudgetGate
end

function BudgetGate:tryAcquire(priority: FxPriority, budget: QualityBudget): boolean
	if self._destroyed then
		return false
	end
	if not QualityLogic.allowsPriority(priority, budget) then
		self._dropped += 1
		return false
	end
	if self._active >= budget.maxConcurrent then
		if priority ~= "Critical" then
			self._dropped += 1
			return false
		end
	end
	self._active += 1
	return true
end

function BudgetGate:release()
	if self._active > 0 then
		self._active -= 1
	end
end

function BudgetGate:activeCount(): number
	return self._active
end

function BudgetGate:droppedCount(): number
	return self._dropped
end

function BudgetGate:resetDropped()
	self._dropped = 0
end

function BudgetGate:shouldCull(worldPos: Vector3, cameraPos: Vector3, budget: QualityBudget): boolean
	local maxDist = budget.maxDistance
	local delta = worldPos - cameraPos
	return delta:Dot(delta) > (maxDist * maxDist)
end

function BudgetGate:destroy()
	self._destroyed = true
	self._active = 0
end

return BudgetGate
