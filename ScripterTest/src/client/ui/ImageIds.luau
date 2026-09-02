--!strict
-- Roblox image asset IDs for UI chrome (PNG from Figma / Studio uploads).

local ASPECT = 231 / 61

-- tone → shine → rbxassetid
local Action = {
	buy = {
		linear = "rbxassetid://83073575662178", -- LinearGreenButton
		radial = "rbxassetid://96601193641494", -- RadialGreenButton
		diamond = "rbxassetid://111950019824754", -- DiamondGreenButton
	},
	equip = {
		linear = "rbxassetid://80681732652621", -- LinearBlueButton
		radial = "rbxassetid://119410166014425", -- RadialBlueButton
		diamond = "rbxassetid://113783580035303", -- DiamondBlueButton
	},
	close = {
		linear = "rbxassetid://80454495048876", -- LinearGreyButton
		radial = "rbxassetid://115559988984652", -- RadialGreyButton
		diamond = "rbxassetid://126666795537875", -- DiamondGreyButton
	},
}

-- sim-pop transparent icons (uploaded in Studio)
local Hud = {
	-- primary (01–27)
	shop = "rbxassetid://111764037452324", -- 01
	inventory = "rbxassetid://140078696393067", -- 02
	bypass = "rbxassetid://93969114736132", -- 03
	coins = "rbxassetid://86076047430576", -- 06
	gems = "rbxassetid://109853215761174", -- 07
	eggs = "rbxassetid://80247548316256", -- 08
	rebirth = "rbxassetid://133866802977785", -- 09
	boosts = "rbxassetid://121885952774000", -- 10
	settings = "rbxassetid://81209855033635", -- 11
	daily = "rbxassetid://105740378107075", -- 12
	spin = "rbxassetid://105731039194247", -- 13
	trade = "rbxassetid://136157394689283", -- 14
	codes = "rbxassetid://136980300947271", -- 15
	close = "rbxassetid://132233226642479", -- 16
	back = "rbxassetid://112452388848720", -- 17
	confirm = "rbxassetid://72975356741029", -- 18
	cancel = "rbxassetid://107928363180554", -- 19
	premium = "rbxassetid://116736389384589", -- 21
	info = "rbxassetid://82626097809054", -- 22
	quests = "rbxassetid://111351707482111", -- 25
	achievements = "rbxassetid://110775774735925", -- 26
	leaderboard = "rbxassetid://75232222378137", -- 27
	-- secondary / activity (28–45)
	index = "rbxassetid://80914264943826", -- 28
	stats = "rbxassetid://111037567603012", -- 29
	teleport = "rbxassetid://110550956846210", -- 30
	zones = "rbxassetid://82673135512842", -- 31
	robuxShop = "rbxassetid://114500404693881", -- 32
	offers = "rbxassetid://74345165735507", -- 33
	bundles = "rbxassetid://96715775234977", -- 34
	gift = "rbxassetid://87870545757468", -- 35
	friends = "rbxassetid://113971112786202", -- 36
	party = "rbxassetid://103489854321120", -- 37
	chat = "rbxassetid://139314608198279", -- 38
	mail = "rbxassetid://74945038755106", -- 39
	afk = "rbxassetid://129494377271259", -- 40
	play = "rbxassetid://140319313673761", -- 41
	skills = "rbxassetid://107922841965928", -- 43
	boss = "rbxassetid://137242411558698", -- 44
	dungeon = "rbxassetid://129155492735798", -- 45
}

export type HudIcon =
	"shop"
	| "inventory"
	| "bypass"
	| "coins"
	| "gems"
	| "eggs"
	| "rebirth"
	| "boosts"
	| "settings"
	| "daily"
	| "spin"
	| "trade"
	| "codes"
	| "close"
	| "back"
	| "confirm"
	| "cancel"
	| "premium"
	| "info"
	| "quests"
	| "achievements"
	| "leaderboard"
	| "index"
	| "stats"
	| "teleport"
	| "zones"
	| "robuxShop"
	| "offers"
	| "bundles"
	| "gift"
	| "friends"
	| "party"
	| "chat"
	| "mail"
	| "afk"
	| "play"
	| "skills"
	| "boss"
	| "dungeon"

return {
	Action = Action,
	Hud = Hud,
	ASPECT = ASPECT,
	-- Back-compat alias
	greenLinear = Action.buy.linear,
}
