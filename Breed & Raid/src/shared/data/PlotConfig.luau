--!strict

local PlotConfig = {
	maxPlayers = 6,
	provePlotCount = 2,
	hubSize = Vector2.new(24, 20),
	yardSize = Vector2.new(40, 40),
	cellSize = 4,
	junctionDepth = 4,
	startNests = 4,
	maxNests = 8,
	plotGap = 20,
	raidPathWidth = 6,
	nestPedestalHeight = 3,
	nestSnapLift = 1,
	safeZoneRadius = 8,
	fallYOffset = 40,
	petZoneMargin = 4,
	petWanderMinSec = 2,
	petWanderMaxSec = 4.5,
	petMoveSpeed = 6,

	nestOffsets = {
		N1 = Vector2.new(-12, -8),
		N2 = Vector2.new(-4, -8),
		N3 = Vector2.new(4, -8),
		N4 = Vector2.new(12, -8),
		N5 = Vector2.new(-12, 4),
		N6 = Vector2.new(-4, 4),
		N7 = Vector2.new(4, 4),
		N8 = Vector2.new(12, 4),
	},

	hubObjects = {
		spawn = Vector3.new(0, 0, 8),
		creatureRoll = Vector3.new(-6, 0, 4),
		blockRoll = Vector3.new(6, 0, 4),
		collect = Vector3.new(0, 0, 2),
		lockPad = Vector3.new(-8, 0, 0),
		incubator = Vector3.new(8, 0, 0),
	},
}

return PlotConfig
