--!strict

export type RollPreview = {
	kind: string, -- "creature" | "block"
	templateId: string,
	displayName: string,
	oneIn: number,
	rarity: string,
	buyCost: number,
	mps: number?,
	grantQty: number?,
}

export type IncubateJob = {
	parentAId: string,
	parentBId: string,
	startedAt: number,
	endsAt: number,
	spedUp: boolean,
	expectedOneIn: number,
}

export type Placeable = {
	id: string,
	blockId: string,
	x: number,
	y: number, -- cell layer 0..
	z: number,
}

local Creature = require(script.Parent.Creature)

export type CreatureInstance = Creature.CreatureInstance

export type SessionData = {
	cash: number,
	buffer: number,
	plotId: number?,
	nestsUnlocked: number,
	creatures: { [string]: CreatureInstance },
	blockInventory: { [string]: number },
	placeables: { Placeable },
	luckCreature: number,
	luckBreed: number,
	starterGranted: boolean,
	creaturePreview: RollPreview?,
	blockPreview: RollPreview?,
	incubateJob: IncubateJob?,
	lockUntil: number,
	timesLockedToday: number,
	joinedAt: number,
}

export type HudCreature = {
	id: string,
	displayName: string,
	oneIn: number,
	rarity: string,
	mps: number,
	nestId: string?,
	isHybrid: boolean,
}

export type HudPayload = {
	cash: number,
	buffer: number,
	mps: number,
	plotId: number?,
	creaturePreview: RollPreview?,
	blockPreview: RollPreview?,
	incubate: {
		startedAt: number,
		endsAt: number,
		expectedOneIn: number,
		spedUp: boolean,
	}?,
	lockUntil: number,
	creatures: { HudCreature },
	dirt: number,
	spikes: number,
	blocks: { [string]: number },
	notify: string?,
}

return {}
