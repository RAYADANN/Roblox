--!strict
-- UI textures (rbxassetid). Prefer ReplicatedStorage.GameAssets when present.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Money / MoneyBarBg match Tycoon FarmHud. Index set uploaded via Studio MCP.
local IconCatalog = {
    Money = "rbxassetid://125816211208962", -- Icons/coin.png
    MoneyBarBg = "rbxassetid://73084442227357", -- BalanceBarBg (Tycoon parity)
    Cash = "rbxassetid://103276037408620", -- icon_cash.png

    Index = "rbxassetid://71451735020065", -- icon_book
    Close = "rbxassetid://134613001279150", -- Tycoon close (no square backdrop)
    Shop = "rbxassetid://126486574263219", -- shop.png (transparent bg)
    Shine = "rbxassetid://139702564707796", -- Tycoon shine sweep
    ItemBackGround = "rbxassetid://113499236763653",
    Robux = "rbxassetid://11560341132",
    ShopCoin = "rbxassetid://125816211208962", -- Icons/coin.png (same as Money)

    EggDomestic = "rbxassetid://120993629326311",
    EggForest = "rbxassetid://109922405110000",
    EggIce = "rbxassetid://87055209027249",
    EggVolcano = "rbxassetid://130975262311414",

    CardStandart = "rbxassetid://136218249605781", -- StandartInventory
    CardGreen = "rbxassetid://119569074693410", -- GreenInventory
    CardIce = "rbxassetid://124611391549998", -- IceInventory
    CardFire = "rbxassetid://139127210298107", -- FireInventory

    ShopLuck = "rbxassetid://106944410283389",
    ShopGold = "rbxassetid://122536320201935",
    ShopGoldPack = "rbxassetid://112780447733682",
    ShopBuyGreen = "rbxassetid://75897180357837",
    ShopBuyYellow = "rbxassetid://131262464003878",
    LuckIcon = "rbxassetid://128671656783079", -- icon_luck.png

    CoinsSmall = "rbxassetid://135359317693370",
    CoinsMedium = "rbxassetid://76639187260355",
    CoinsLarge = "rbxassetid://80855350938623",
    CoinsPouch = "rbxassetid://112538366207811",
    CoinsChest = "rbxassetid://116998164297908",

    -- Rebirth modal (Icons + eggs → Studio MCP upload).
    Rebirth = "rbxassetid://123222845152715", -- icon_rebirth-Photoroom
    ProgressLine = "rbxassetid://121607259775944",
    RebirthButton = "rbxassetid://130984557118327", -- ShowRoom/RebirthButton
    SkipButton = "rbxassetid://104093201532326", -- ShowRoom/SkipButton
    NewEgg = "rbxassetid://87055209027249", -- eggs/egg_ice
    NewMutation = "rbxassetid://98111313048774", -- icon_mutation_add_outlined
    XCoins = "rbxassetid://125816211208962", -- coin.png
    AddIncubator = "rbxassetid://139022147690347", -- icon_arrow_up_outlined
    FavoritePlace = "rbxassetid://126236793918836", -- icon_plus_cyan
}

function IconCatalog.resolveImage(catalogId: string, gameAssetName: string?): string
    if gameAssetName then
        local assets = ReplicatedStorage:FindFirstChild("GameAssets")
        local ref = assets and assets:FindFirstChild(gameAssetName)
        if ref then
            if ref:IsA("ImageLabel") or ref:IsA("ImageButton") then
                local image = ref.Image
                if image ~= "" then
                    return image
                end
            elseif ref:IsA("Decal") then
                local texture = ref.Texture
                if texture ~= "" then
                    return texture
                end
            end
        end
    end
    if catalogId ~= "" then
        return catalogId
    end
    return ""
end

local KEY_LOOKUP: { [string]: string } = {
    EggDomestic = IconCatalog.EggDomestic,
    EggForest = IconCatalog.EggForest,
    EggIce = IconCatalog.EggIce,
    EggVolcano = IconCatalog.EggVolcano,
    CardStandart = IconCatalog.CardStandart,
    CardGreen = IconCatalog.CardGreen,
    CardIce = IconCatalog.CardIce,
    CardFire = IconCatalog.CardFire,
    ShopLuck = IconCatalog.ShopLuck,
    ShopGold = IconCatalog.ShopGold,
    ShopGoldPack = IconCatalog.ShopGoldPack,
    LuckIcon = IconCatalog.LuckIcon,
    Money = IconCatalog.Money,
    ShopCoin = IconCatalog.ShopCoin,
    CoinsSmall = IconCatalog.CoinsSmall,
    CoinsMedium = IconCatalog.CoinsMedium,
    CoinsLarge = IconCatalog.CoinsLarge,
    CoinsPouch = IconCatalog.CoinsPouch,
    CoinsChest = IconCatalog.CoinsChest,
    NewEgg = IconCatalog.NewEgg,
    NewMutation = IconCatalog.NewMutation,
    XCoins = IconCatalog.XCoins,
    AddIncubator = IconCatalog.AddIncubator,
    FavoritePlace = IconCatalog.FavoritePlace,
}

function IconCatalog.byKey(key: string): string
    return KEY_LOOKUP[key] or ""
end

return IconCatalog
