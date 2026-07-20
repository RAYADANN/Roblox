--!strict

local MonsterConfig = {
	fearSeconds = 3.5,
	speed = 12,
	speedInLight = 6,
	grabCarrySec = 10,
	spawnOffset = Vector3.new(0, 3, 18),
}

local LightConfig = {
	coneDeg = 35,
	range = 28,
	lampRadius = 14,
	lampFearPerSec = 0.15,
	lampT2Radius = 20,
	lampT2FearPerSec = 0.28,
	batteryDrainPerSec = 0.12,
	batteryRechargeDayPerSec = 0.2,
	batteryRechargeOtherPerSec = 0.03,
}

local StealConfig = {
	carryWalkSpeed = 10,
	batCooldownSec = 1.2,
	batKnockbackStuds = 18,
	lockDurationSec = 25,
	lockCooldownSec = 45,
	stealRange = 8,
	batRange = 10,
}

return {
	Monster = MonsterConfig,
	Light = LightConfig,
	Steal = StealConfig,
}
