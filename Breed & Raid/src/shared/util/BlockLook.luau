--!strict

-- Minecraft-style cube look per block id.

export type Look = {
	color: Color3,
	material: Enum.Material,
	transparency: number,
}

local LOOK: { [string]: Look } = {
	dirt = {
		color = Color3.fromRGB(121, 85, 58),
		material = Enum.Material.Ground,
		transparency = 0,
	},
	wood_planks = {
		color = Color3.fromRGB(162, 110, 55),
		material = Enum.Material.WoodPlanks,
		transparency = 0,
	},
	stone = {
		color = Color3.fromRGB(130, 130, 135),
		material = Enum.Material.Slate,
		transparency = 0,
	},
	spikes = {
		color = Color3.fromRGB(200, 70, 60),
		material = Enum.Material.Metal,
		transparency = 0,
	},
	nest_deco = {
		color = Color3.fromRGB(90, 170, 220),
		material = Enum.Material.Glass,
		transparency = 0.35,
	},
}

local BlockLook = {}

function BlockLook.get(blockId: string): Look
	return LOOK[blockId] or LOOK.dirt
end

function BlockLook.apply(part: BasePart, blockId: string)
	local look = BlockLook.get(blockId)
	part.Color = look.color
	part.Material = look.material
	part.Transparency = look.transparency
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = true
end

return BlockLook
