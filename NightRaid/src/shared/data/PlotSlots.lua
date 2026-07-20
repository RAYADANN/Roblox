--!strict

export type SlotType = "Wall" | "Pedestal" | "Lamp"

export type SlotDef = {
	id: string,
	slotType: SlotType,
	offset: Vector3,
	defaultTier: string?, -- Wood for walls; nil for empty lamp
}

export type WorldLayout = {
	plotCenters: { Vector3 },
	rollMachine: Vector3,
	gapStuds: number,
	plotSize: number,
}

local PlotSlots = {
	World = {
		plotCenters = {
			Vector3.new(-28, 0, 0),
			Vector3.new(28, 0, 0),
		},
		rollMachine = Vector3.new(0, 2, 0),
		gapStuds = 16,
		plotSize = 40,
	} :: WorldLayout,

	Slots = {
		{
			id = "wall_back",
			slotType = "Wall",
			offset = Vector3.new(0, 4, -20),
			defaultTier = "Wood",
		},
		{
			id = "wall_left",
			slotType = "Wall",
			offset = Vector3.new(-20, 4, 0),
			defaultTier = "Wood",
		},
		{
			id = "wall_right",
			slotType = "Wall",
			offset = Vector3.new(20, 4, 0),
			defaultTier = "Wood",
		},
		{
			id = "pedestal_1",
			slotType = "Pedestal",
			offset = Vector3.new(-6, 1.5, -4),
		},
		{
			id = "pedestal_2",
			slotType = "Pedestal",
			offset = Vector3.new(6, 1.5, -4),
		},
		{
			id = "lamp_1",
			slotType = "Lamp",
			offset = Vector3.new(-10, 3, 2),
		},
		{
			id = "lamp_2",
			slotType = "Lamp",
			offset = Vector3.new(0, 3, -10),
		},
		{
			id = "lamp_3",
			slotType = "Lamp",
			offset = Vector3.new(10, 3, 2),
		},
	} :: { SlotDef },

	Costs = {
		wallMetal = 40,
		lampT1 = 30,
		lampT2 = 80,
	},

	ShopPadOffset = Vector3.new(10, 1, 6),
}

return PlotSlots
