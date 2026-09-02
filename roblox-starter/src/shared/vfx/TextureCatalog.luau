--!strict
-- Texture IDs for VFX flipbooks. Updated after Studio upload.

export type TextureEntry = {
	id: string,
	layout: string,
	fpsMin: number,
	fpsMax: number,
	mode: string,
}

local TextureCatalog = {
	NeonBurst = {
		id = "rbxassetid://117687641569968",
		layout = "Grid4x4",
		fpsMin = 18,
		fpsMax = 24,
		mode = "OneShot",
	} :: TextureEntry,
	SmokePuff = {
		id = "rbxassetid://131840252392616",
		layout = "Grid4x4",
		fpsMin = 12,
		fpsMax = 16,
		mode = "OneShot",
	} :: TextureEntry,
	SparkBurst = {
		id = "rbxassetid://137306757060329",
		layout = "Grid4x4",
		fpsMin = 20,
		fpsMax = 28,
		mode = "OneShot",
	} :: TextureEntry,
	EmberTrail = {
		id = "rbxassetid://76717224586863",
		layout = "Grid4x4",
		fpsMin = 14,
		fpsMax = 18,
		mode = "OneShot",
	} :: TextureEntry,
	FireBlast = {
		id = "rbxassetid://120555546418811",
		layout = "Grid4x4",
		fpsMin = 16,
		fpsMax = 22,
		mode = "OneShot",
	} :: TextureEntry,
	PlasmaCore = {
		id = "rbxassetid://94676924593597",
		layout = "Grid4x4",
		fpsMin = 18,
		fpsMax = 26,
		mode = "OneShot",
	} :: TextureEntry,
	DebrisShard = {
		id = "rbxassetid://104193816389856",
		layout = "Grid4x4",
		fpsMin = 12,
		fpsMax = 18,
		mode = "OneShot",
	} :: TextureEntry,
	ShockRing = {
		id = "rbxassetid://90630847782786",
		layout = "Grid4x4",
		fpsMin = 14,
		fpsMax = 20,
		mode = "OneShot",
	} :: TextureEntry,
	EnergyArc = {
		id = "rbxassetid://78567159003746",
		layout = "Grid4x4",
		fpsMin = 20,
		fpsMax = 28,
		mode = "OneShot",
	} :: TextureEntry,
}

return TextureCatalog
