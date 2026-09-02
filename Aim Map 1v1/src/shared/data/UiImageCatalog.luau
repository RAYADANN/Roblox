--!strict
-- Locked UI image rbxassetids (Studio MCP upload of assets/ui).

export type CombatImages = {
    hitmarkerBody: string,
    hitmarkerHead: string,
    damageDir: string,
    killRing: string,
    killIcon: string,
}

export type SkinImages = {
    usp_default: string,
    usp_slate: string,
    usp_crimson: string,
    usp_neon: string,
    usp_ember: string,
    usp_void: string,
    usp_frost: string,
    usp_jade: string,
    usp_solar: string,
    usp_obsidian: string,
    usp_azure: string,
    usp_rose: string,
    usp_copper: string,
    usp_cobalt: string,
    usp_toxin: string,
    usp_plasma: string,
    usp_ivory: string,
    usp_graphite: string,
    usp_amber: string,
    usp_nova: string,
}

export type HudIconKey =
    "inventory"
    | "shop"
    | "settings"
    | "sensitivity"
    | "crosshair"
    | "rematch"
    | "vsBot"
    | "invite"
    | "health"
    | "ammo"
    | "coins"
    | "diamonds"
    | "robux"
    | "flex"
    | "win"
    | "defeat"
    | "close"
    | "level"
    | "luck"
    | "pistol"

export type RankKey = "iron" | "bronze" | "silver" | "gold" | "platinum" | "diamond" | "elite"

export type CaseKey = "standard" | "rare" | "epic" | "legendary" | "mythic" | "open" | "master"

export type ShopPlateKey = "blue" | "sky" | "green" | "purple" | "gold" | "orange"

export type ShopItemKey =
    "x2Coins"
    | "x2Diamonds"
    | "x2Luck"
    | "coinsSmall"
    | "coinsMedium"
    | "coinsBig"
    | "diamondsSmall"
    | "diamondsMedium"
    | "diamondsBig"

export type ShopItemDef = {
    image: string,
    nativeWidth: number,
    nativeHeight: number,
}

local UiImageCatalog = {}

UiImageCatalog.combat = {
    hitmarkerBody = "rbxassetid://139885055386985",
    hitmarkerHead = "rbxassetid://100039292895912",
    damageDir = "rbxassetid://116669273647796",
    killRing = "rbxassetid://113386266501596",
    killIcon = "rbxassetid://128738184961434",
} :: CombatImages

UiImageCatalog.skins = {
    usp_default = "rbxassetid://0",
    usp_slate = "rbxassetid://0",
    usp_crimson = "rbxassetid://0",
    usp_neon = "rbxassetid://0",
    usp_ember = "rbxassetid://0",
    usp_void = "rbxassetid://0",
    usp_frost = "rbxassetid://0",
    usp_jade = "rbxassetid://0",
    usp_solar = "rbxassetid://0",
    usp_obsidian = "rbxassetid://0",
    usp_azure = "rbxassetid://0",
    usp_rose = "rbxassetid://0",
    usp_copper = "rbxassetid://0",
    usp_cobalt = "rbxassetid://0",
    usp_toxin = "rbxassetid://0",
    usp_plasma = "rbxassetid://0",
    usp_ivory = "rbxassetid://0",
    usp_graphite = "rbxassetid://0",
    usp_amber = "rbxassetid://0",
    usp_nova = "rbxassetid://0",
} :: SkinImages

-- Transparent Photoroom masters (icons/) + ammo/invite (already alpha).
UiImageCatalog.hud = {
    inventory = "rbxassetid://83617179259459",
    shop = "rbxassetid://103157722038435",
    settings = "rbxassetid://93565981815340",
    sensitivity = "rbxassetid://71145325184119",
    crosshair = "rbxassetid://126938707637224",
    rematch = "rbxassetid://127820487762562",
    vsBot = "rbxassetid://92257340922172",
    invite = "rbxassetid://100508962110540",
    health = "rbxassetid://124089462625862",
    ammo = "rbxassetid://130745796970934",
    coins = "rbxassetid://75791121977935",
    diamonds = "rbxassetid://129151873694686",
    robux = "rbxassetid://11560341132",
    flex = "rbxassetid://129562189183660",
    win = "rbxassetid://129868164525799",
    defeat = "rbxassetid://125335751046464",
    close = "rbxassetid://135314650267827",
    level = "rbxassetid://94251758863909",
    luck = "rbxassetid://100344450795493",
    pistol = "rbxassetid://81617728315070",
} :: { [HudIconKey]: string }

UiImageCatalog.ranks = {
    iron = "rbxassetid://87201932065339",
    bronze = "rbxassetid://76987972541105",
    silver = "rbxassetid://77727457047763",
    gold = "rbxassetid://131630255922358",
    platinum = "rbxassetid://74277086962282",
    diamond = "rbxassetid://78724920699458",
    elite = "rbxassetid://126027984620585",
} :: { [RankKey]: string }

-- Cases: always Photoroom (true alpha). Non-Photoroom case_rare/standard PNGs bake a white square — do not wire.
UiImageCatalog.cases = {
    standard = "rbxassetid://85136891669866", -- case_master-Photoroom
    master = "rbxassetid://85136891669866",
    rare = "rbxassetid://85136891669866", -- same blue master; no rare-Photoroom yet
    epic = "rbxassetid://110039956554113",
    legendary = "rbxassetid://131905612887026",
    mythic = "rbxassetid://93898561690717",
    open = "rbxassetid://87246561752834",
} :: { [CaseKey]: string }

-- Portrait shop product cards (assets/ui/shop_plates/shop_plate_small_*).
UiImageCatalog.shopPlates = {
    blue = "rbxassetid://120063557727906",
    sky = "rbxassetid://85620519500575",
    green = "rbxassetid://122232849591903",
    purple = "rbxassetid://80743185672470",
    gold = "rbxassetid://78870972899905",
    orange = "rbxassetid://76288194016047",
} :: { [ShopPlateKey]: string }

-- Shop currency / boost cards (assets/ui/Items).
UiImageCatalog.shopItems = {
    x2Coins = {
        image = "rbxassetid://81032816159509",
        nativeWidth = 489,
        nativeHeight = 178,
    },
    x2Diamonds = {
        image = "rbxassetid://107452139685030",
        nativeWidth = 498,
        nativeHeight = 183,
    },
    x2Luck = {
        image = "rbxassetid://92655416316793",
        nativeWidth = 937,
        nativeHeight = 201,
    },
    coinsSmall = {
        image = "rbxassetid://127417966059969",
        nativeWidth = 284,
        nativeHeight = 368,
    },
    coinsMedium = {
        image = "rbxassetid://125336407386808",
        nativeWidth = 284,
        nativeHeight = 368,
    },
    coinsBig = {
        image = "rbxassetid://116620602693380",
        nativeWidth = 284,
        nativeHeight = 368,
    },
    diamondsSmall = {
        image = "rbxassetid://119275588122909",
        nativeWidth = 271,
        nativeHeight = 372,
    },
    diamondsMedium = {
        image = "rbxassetid://109014746709126",
        nativeWidth = 271,
        nativeHeight = 371,
    },
    diamondsBig = {
        image = "rbxassetid://100596317740120",
        nativeWidth = 271,
        nativeHeight = 372,
    },
} :: { [ShopItemKey]: ShopItemDef }

function UiImageCatalog.hudIcon(key: HudIconKey): string
    return UiImageCatalog.hud[key]
end

function UiImageCatalog.shopPlate(key: ShopPlateKey): string
    return UiImageCatalog.shopPlates[key]
end

function UiImageCatalog.shopItem(key: ShopItemKey): ShopItemDef
    return UiImageCatalog.shopItems[key]
end

return UiImageCatalog
