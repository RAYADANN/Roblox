--!strict
-- Pure gates for haptics. CI без Studio.

local Types = require(script.Parent.Types)

export type FxPriority = Types.FxPriority

local HapticLogic = {}

local PRIORITY_STRENGTH: { [FxPriority]: number } = {
	Low = 0.15,
	Medium = 0.35,
	High = 0.55,
	Critical = 0.85,
}

function HapticLogic.allows(enabled: boolean, reduceMotion: boolean): boolean
	return enabled and not reduceMotion
end

function HapticLogic.strength(priority: FxPriority, intensity: number?): number
	local base = PRIORITY_STRENGTH[priority] or 0.35
	return math.clamp(base * (intensity or 1), 0, 1)
end

function HapticLogic.profileStrength(profile: string?): number
	if profile == "Heavy" then
		return 0.85
	elseif profile == "Medium" then
		return 0.5
	elseif profile == "Light" then
		return 0.25
	end
	return 0.4
end

return HapticLogic
