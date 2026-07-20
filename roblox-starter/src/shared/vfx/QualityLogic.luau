--!strict
-- Pure: тиры, бюджеты, distance soft-LOD. CI без Studio.

local Types = require(script.Parent.Types)

export type QualityTier = Types.QualityTier
export type QualityBudget = Types.QualityBudget
export type DeviceHints = Types.DeviceHints
export type FxPriority = Types.FxPriority
export type EffectKind = Types.EffectKind

local QualityLogic = {}

local BUDGETS: { [QualityTier]: QualityBudget } = {
	Low = {
		tier = "Low",
		particleScale = 0.3,
		maxEmitCount = 10,
		maxConcurrent = 3,
		enableLights = false,
		enableBeams = false,
		enableScreenFX = false,
		enableCameraShake = false,
		enableShockwave = true,
		enableTrails = false,
		enableLoops = false,
		maxDistance = 60,
		lightBrightnessScale = 0,
		layerMinPriority = "Medium",
	},
	Medium = {
		tier = "Medium",
		particleScale = 0.6,
		maxEmitCount = 24,
		maxConcurrent = 7,
		enableLights = true,
		enableBeams = true,
		enableScreenFX = true,
		enableCameraShake = true,
		enableShockwave = true,
		enableTrails = true,
		enableLoops = true,
		maxDistance = 100,
		lightBrightnessScale = 0.65,
		layerMinPriority = "Low",
	},
	High = {
		tier = "High",
		particleScale = 1,
		maxEmitCount = 48,
		maxConcurrent = 14,
		enableLights = true,
		enableBeams = true,
		enableScreenFX = true,
		enableCameraShake = true,
		enableShockwave = true,
		enableTrails = true,
		enableLoops = true,
		maxDistance = 160,
		lightBrightnessScale = 1,
		layerMinPriority = "Low",
	},
	Ultra = {
		tier = "Ultra",
		particleScale = 1.3,
		maxEmitCount = 80,
		maxConcurrent = 22,
		enableLights = true,
		enableBeams = true,
		enableScreenFX = true,
		enableCameraShake = true,
		enableShockwave = true,
		enableTrails = true,
		enableLoops = true,
		maxDistance = 240,
		lightBrightnessScale = 1.2,
		layerMinPriority = "Low",
	},
}

local TIER_ORDER: { QualityTier } = { "Low", "Medium", "High", "Ultra" }

local function tierIndex(tier: QualityTier): number
	return Types.TIER_RANK[tier] or 1
end

local function clampTier(tier: QualityTier, minTier: QualityTier, maxTier: QualityTier): QualityTier
	local i = math.clamp(tierIndex(tier), tierIndex(minTier), tierIndex(maxTier))
	return TIER_ORDER[i]
end

function QualityLogic.baseTier(hints: DeviceHints): QualityTier
	if hints.reduceMotion then
		return "Low"
	end

	local q = hints.savedQualityLevel
	if hints.touchEnabled then
		if q == 0 then
			return "Medium"
		elseif q <= 3 then
			return "Low"
		elseif q <= 6 then
			return "Medium"
		else
			return "High"
		end
	end

	if q == 0 then
		return "High"
	elseif q <= 3 then
		return "Medium"
	elseif q <= 7 then
		return "High"
	else
		return "Ultra"
	end
end

function QualityLogic.adaptTier(base: QualityTier, averageFps: number?): QualityTier
	if averageFps == nil then
		return base
	end
	local fps = averageFps
	if fps < 26 then
		return clampTier(base, "Low", "Low")
	elseif fps < 32 then
		return clampTier(base, "Low", "Medium")
	elseif fps < 42 then
		return clampTier(base, "Low", "High")
	elseif fps >= 55 then
		return base
	end
	return clampTier(base, "Low", base)
end

function QualityLogic.resolveTier(hints: DeviceHints): QualityTier
	return QualityLogic.adaptTier(QualityLogic.baseTier(hints), hints.averageFps)
end

function QualityLogic.budgetFor(tier: QualityTier): QualityBudget
	return BUDGETS[tier]
end

function QualityLogic.resolveBudget(hints: DeviceHints): QualityBudget
	return QualityLogic.budgetFor(QualityLogic.resolveTier(hints))
end

function QualityLogic.scaleEmit(count: number, budget: QualityBudget, distanceScale: number?): number
	local d = distanceScale or 1
	local scaled = math.floor(count * budget.particleScale * d + 0.5)
	return math.clamp(scaled, 0, budget.maxEmitCount)
end

--- Soft-LOD: ближе maxDistance частицы/интенсивность падают, не hard-cut.
function QualityLogic.distanceScale(distance: number, maxDistance: number): number
	if maxDistance <= 0 then
		return 1
	end
	local t = distance / maxDistance
	if t >= 1 then
		return 0
	end
	if t <= 0.5 then
		return 1
	end
	-- 0.5..1 → 1..0.25
	local u = (t - 0.5) / 0.5
	return 1 - u * 0.75
end

function QualityLogic.allowsPriority(priority: FxPriority, budget: QualityBudget): boolean
	return Types.PRIORITY_RANK[priority] >= Types.PRIORITY_RANK[budget.layerMinPriority]
end

function QualityLogic.allowsMinTier(minTier: QualityTier?, budget: QualityBudget): boolean
	if minTier == nil then
		return true
	end
	return tierIndex(budget.tier) >= tierIndex(minTier)
end

function QualityLogic.allowsKind(kind: EffectKind, budget: QualityBudget): boolean
	if kind == "Loop" or kind == "Attached" then
		return budget.enableLoops
	end
	return true
end

return QualityLogic
