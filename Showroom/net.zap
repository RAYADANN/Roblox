-- Zap schema — Showroom network.
-- Generate: `zap net.zap`

opt server_output = "src/server/net/NetServer.luau"
opt client_output = "src/client/net/NetClient.luau"

event PlayerDataSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		coins: f64,
		plotId: u8,
		favoriteBank: f64,
		handUid: string.utf8,
		handName: string.utf8,
		offersJson: string.utf8,
		slotsJson: string.utf8,
		inventoryJson: string.utf8,
	},
}

-- World snapshot for all clients (exhibits on plots).
event WorldExhibitsSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		payloadJson: string.utf8,
	},
}

funct PickOffer = {
	call: Async,
	args: (offerUid: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct PickOfferIndex = {
	call: Async,
	args: (offerIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct RequestHudSync = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct PlaceExhibit = {
	call: Async,
	args: (slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct RemoveExhibit = {
	call: Async,
	args: (slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct SellExhibit = {
	call: Async,
	args: (slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		coins: f64?,
	},
}

funct MoveToFavorite = {
	call: Async,
	args: (slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct CollectFavoriteBank = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		coins: f64?,
	},
}

funct ReactExhibit = {
	call: Async,
	args: (ownerUserId: u32, slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct RefreshOffers = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct SelectHand = {
	call: Async,
	args: (itemUid: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct StartAuction = {
	call: Async,
	args: (slotIndex: u8, fromFavorite: boolean),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct ConfirmAuctionSell = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		coins: f64?,
	},
}

funct RerunAuction = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

event AuctionSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		phase: string.utf8,
		displayName: string.utf8,
		rarity: string.utf8,
		sizeId: string.utf8,
		sizeLabel: string.utf8,
		mutationLabel: string.utf8,
		mutationCount: u8,
		currentBid: f64,
		maxBid: f64,
		remainingSec: f32,
		runsUsed: u8,
		maxRuns: u8,
		nextCommission: f64,
		lastBuyer: string.utf8,
		bidsJson: string.utf8,
		colorR: u8,
		colorG: u8,
		colorB: u8,
		scale: f32,
	},
}

event Notify = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		kind: string.utf8,
		payload: string.utf8,
	},
}

event PlayVfx = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		effectId: string.utf8,
		intensity: f32,
		pos: Vector3?,
		from: Vector3?,
		to: Vector3?,
	},
}
