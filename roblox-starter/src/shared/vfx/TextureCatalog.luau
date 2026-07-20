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
}

return TextureCatalog
