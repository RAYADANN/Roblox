--!strict

export type CyclePhase = "Day" | "Dusk" | "Night" | "Dawn"

--[[
	PROVE_FAST = true → short cycle for Studio iterate.
	Set false before external playtest (GDD §12 ship timings).
]]
local PROVE_FAST = true

local FAST = {
	daySec = 45,
	duskSec = 10,
	nightSec = 40,
	dawnSec = 8,
}

local SHIP = {
	daySec = 220,
	duskSec = 15,
	nightSec = 100,
	dawnSec = 10,
}

local timings = if PROVE_FAST then FAST else SHIP

local CycleConfig = {
	PROVE_FAST = PROVE_FAST,
	daySec = timings.daySec,
	duskSec = timings.duskSec,
	nightSec = timings.nightSec,
	dawnSec = timings.dawnSec,
	dawnAllSavedBonus = 25,
}

function CycleConfig.durationFor(phase: CyclePhase): number
	if phase == "Day" then
		return CycleConfig.daySec
	elseif phase == "Dusk" then
		return CycleConfig.duskSec
	elseif phase == "Night" then
		return CycleConfig.nightSec
	end
	return CycleConfig.dawnSec
end

function CycleConfig.nextPhase(phase: CyclePhase): CyclePhase
	if phase == "Day" then
		return "Dusk"
	elseif phase == "Dusk" then
		return "Night"
	elseif phase == "Night" then
		return "Dawn"
	end
	return "Day"
end

return CycleConfig
