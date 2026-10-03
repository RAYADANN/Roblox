-- Zap schema — AnimeTycoon network.
-- Generate: `zap net.zap`

opt server_output = "src/server/net/NetServer.luau"
opt client_output = "src/client/net/NetClient.luau"

event PlayerDataSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		coins: f64,
		rebirths: u32,
		base: u32,
		pad: u32,
		padTier: u32,
		luck: u32,
		cash: u32,
		time: u32,
		speed: u32,
		handUid: string.utf8,
		offersJson: string.utf8,
		slotsJson: string.utf8,
		inventoryJson: string.utf8,
		sellBoxCoins: f64,
		sellBoxDeposits: u32,
		sellCratesJson: string.utf8,
		indexFoundJson: string.utf8,
		rewardTrackStartedAt: f64,
		rewardClaimedJson: string.utf8,
		tutorialCompleted: boolean,
		boostOfferEndsAt: u32,
		ownsLuckyX2: boolean,
		ownsLuckyX4: boolean,
		ownsMoneyX2: boolean,
		pendingOfflineCoins: f64,
	},
}

-- World snapshot: all ramp slots (JSON) for every client.
event WorldRampSync = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		payloadJson: string.utf8,
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

funct RefreshOffers = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct BuyOfferIndex = {
	call: Async,
	args: (offerIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct PlaceContainer = {
	call: Async,
	args: (slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

-- Equip inventory item to hand (empty uid clears). Place uses current handUid.
funct SetHand = {
	call: Async,
	args: (uid: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct OpenContainer = {
	call: Async,
	args: (slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct PickupContainer = {
	call: Async,
	args: (slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct BuyUpgrade = {
	call: Async,
	args: (upgradeId: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		coins: f64?,
	},
}

funct BuyUpgradeRobux = {
	call: Async,
	args: (upgradeId: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

-- Level up the unpacked hero on this ramp slot. Cost is server-side.
funct LevelHero = {
	call: Async,
	args: (slotIndex: u8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		coins: f64?,
		level: u32?,
	},
}

funct ClaimTimedReward = {
	call: Async,
	args: (rewardId: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		coins: f64?,
		coinsGranted: f64?,
	},
}

funct CompleteTutorial = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct ResetTutorial = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

-- First view of right-rail Lucky/Money offers → start 24h window.
event BoostOfferSeen = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: boolean,
}

funct BuyBoostOffer = {
	call: Async,
	args: (offerId: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct ClaimOfflineEarnings = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
		coinsGranted: f64?,
	},
}

funct BuyOfflineDouble = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct BuyMegaPack = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct BuySkipAllRewards = {
	call: Async,
	args: (),
	rets: struct {
		success: boolean,
		error: string.utf8?,
	},
}

funct BuyCoinPack = {
	call: Async,
	args: (packId: string.utf8),
	rets: struct {
		success: boolean,
		error: string.utf8?,
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

-- Mini on conveyor (visual). Payout goes to SellBox on arrive, not pocket.
event MiniSpawned = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		-- f64: Roblox UserId can exceed u32 (2^32-1).
		ownerUserId: f64,
		slotIndex: u8,
		heroId: string.utf8,
		payout: f64,
		travelSec: f32,
	},
}
