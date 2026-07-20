--!strict

export type Genes = {
	primaryColor: { number },
	secondaryColor: { number },
	faceId: string,
	accHead: string?,
	accBack: string?,
	scale: number,
	auraId: string,
}

export type CreatureInstance = {
	id: string,
	templateId: string?,
	speciesId: string,
	displayName: string,
	ownerUserId: number,
	oneIn: number,
	rarity: string,
	mps: number,
	isHybrid: boolean,
	generation: number,
	genes: Genes,
	nestId: string?,
	lockedUntil: number?,
	bornAt: number,
}

return {}
