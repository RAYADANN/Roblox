--!strict
-- Design tokens — единственный источник цветов, шрифтов, радиусов.
-- World / money look aligned with Tycoon (FredokaOne + yellow→lime Price gradient).

local Colors = {
    bg1 = Color3.fromRGB(8, 10, 18),
    bg2 = Color3.fromRGB(14, 17, 30),
    bg3 = Color3.fromRGB(22, 26, 44),
    bg4 = Color3.fromRGB(30, 36, 58),
    bgChip = Color3.fromRGB(16, 20, 36),
    dockBg = Color3.fromRGB(11, 13, 24),
    dockBorder = Color3.fromRGB(38, 46, 74),

    primary = Color3.fromRGB(82, 126, 255),
    primaryHi = Color3.fromRGB(112, 154, 255),

    gold = Color3.fromRGB(255, 212, 38),
    goldHi = Color3.fromRGB(255, 238, 130),

    sell = Color3.fromRGB(44, 210, 108),
    sellHi = Color3.fromRGB(70, 238, 136),

    panelBg = Color3.fromRGB(18, 22, 38),
    panelBody = Color3.fromRGB(22, 26, 44),

    textMain = Color3.fromRGB(228, 234, 255),
    textSub = Color3.fromRGB(148, 158, 195),
    textMuted = Color3.fromRGB(76, 88, 120),
    white = Color3.fromRGB(255, 255, 255),
    black = Color3.fromRGB(0, 0, 0),
    indexCard = Color3.fromRGB(255, 210, 120),

    outline = Color3.fromRGB(255, 255, 255),
    outlineDark = Color3.fromRGB(0, 0, 0),

    btnBg = Color3.fromRGB(36, 42, 68),
    tabActive = Color3.fromRGB(32, 38, 62),
    tabInactive = Color3.fromRGB(20, 24, 40),
    tabBorder = Color3.fromRGB(50, 58, 88),

    error = Color3.fromRGB(255, 100, 80),
    success = Color3.fromRGB(80, 220, 120),

    -- Tycoon MoneyButton / pad Price chrome
    moneyButtonStroke = Color3.fromRGB(226, 230, 181),
    worldCard = Color3.fromRGB(14, 16, 28),
    worldShadow = Color3.fromRGB(0, 0, 0),
    progressTrack = Color3.fromRGB(40, 44, 48),
}

-- Tycoon Buton25Rooms Price UIGradient — yellow → lime, rot 90.
local Gradients = {
    moneyButtonText = {
        rotation = 90,
        keypoints = {
            { t = 0, c = Color3.fromRGB(255, 255, 0) },
            { t = 0.337, c = Color3.fromRGB(245, 255, 0) },
            { t = 1, c = Color3.fromRGB(0, 255, 0) },
        },
    },
}

local Rarity = {
    common = Color3.fromRGB(180, 185, 200),
    uncommon = Color3.fromRGB(80, 200, 120),
    rare = Color3.fromRGB(80, 160, 255),
    epic = Color3.fromRGB(180, 100, 255),
    legendary = Color3.fromRGB(255, 180, 40),
    mythic = Color3.fromRGB(255, 80, 120),
}

local Font = {
    title = Enum.Font.GothamBold,
    body = Enum.Font.GothamMedium,
    heavy = Enum.Font.GothamBlack,
    display = Enum.Font.FredokaOne,
}

local Radius = {
    panel = UDim.new(0, 14),
    chip = UDim.new(0, 10),
    btn = UDim.new(0, 10),
    navBtn = UDim.new(0, 12),
    pill = UDim.new(1, 0),
    world = UDim.new(0, 14),
}

local Stroke = {
    thin = 1,
    medium = 1.5,
    thick = 2,
    moneyButton = 3,
    moneyButtonText = 0.14,
    world = 2.5,
    panel = 6,
    title = 6,
    body = 0.12,
}

local Icon = {
    tint = Color3.fromRGB(255, 255, 255),
    inactiveAlpha = 0.45,
}

-- Design-space константы (переводить через layout.px/text)
local Design = {
    MODAL_W = 600,
    MODAL_H = 450,
    HEADER_H = 56,
    ROW_H = 52,
    DOCK_H = 72,
    DOCK_BTN = 52,
    ICON_SM = 24,
    ICON_MD = 32,
    ICON_LG = 48,
    PAD_SM = 8,
    PAD_MD = 12,
    PAD_LG = 16,
}

local PromptKind = {
    restock = Colors.primary,
    buy = Colors.gold,
    auction = Colors.gold,
    favorite = Color3.fromRGB(255, 160, 70),
    react = Colors.primaryHi,
    collect = Colors.sell,
    default = Colors.textSub,
}

-- Tycoon FarmHud + Index layout (screen / DesignRoot Scale @ 1920×1080).
local Layout = {
    farm = {
        -- Balance chip: bottom-left safe inset.
        balancePadX = 0.02,
        balancePadBottom = 0.025,
        -- Frame 7 (2) @ 1920×1080: 443×112 px balance bar
        balanceBarPxW = 443,
        balanceBarPxH = 112,
        balanceW = 443 / 1920,
        balanceH = 112 / 1080,
        balanceIconLeftPx = 14,
        balanceIconSizePx = 132,
        balanceIconTextGapPx = 12,
        balanceTextRightPx = 20,
        indexBtnPadRight = 0.02,
        indexBtnPadTop = 0.02,
        indexBtn = 96 / 1080,
        shopBtnPadRight = 0.02,
        shopBtnPadTop = 0.02 + (96 / 1080) + 0.015,
        shopBtn = 96 / 1080,
        rebirthBtnPadRight = 0.02,
        rebirthBtnPadTop = 0.02 + (96 / 1080) * 2 + 0.015 * 2,
        rebirthBtn = 96 / 1080,
    },
    -- Bottom-center inventory hotbar (screen Scale @ 1920×1080, like farm HUD).
    inventory = {
        padBottom = 0.012,
        slotH = 88 / 1080,
        selectedScale = 1.28,
        -- List padding as fraction of bar width (full screen width host).
        gapScale = 14 / 1920,
        cornerScale = 0.18,
        -- Border stroke: ScaledSize (not FixedSize px — fat on phone).
        strokeScale = 0.055,
        iconPad = 0.12,
        -- Fractions of base slot height (added into barH when hotkeys shown).
        keyH = 0.32,
        keyGap = 0.06,
    },
    -- Figma Rebirth board @ 1920×1080, scaled 1.5× (Tycoon landscape size).
    rebirth = {
        size = UDim2.fromScale(1027 * 1.5 / 1920, 552 * 1.5 / 1080),
        position = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        panelCornerScale = 20 / 552,
        titlePadX = 0.01,
        titleIconScale = 0.12 * 1.2,
        titleHeightScale = 64 / 552,
        closeScale = 0.125,
        -- Body starts sooner so "You will receive" sits higher under the title.
        contentTop = 0.07,
        contentBottom = 0.025,
        contentPadX = 0.028,
        listPad = 0.005,
        receiveH = 0.13,
        receiveMaxText = 112,
        perkRowH = 0.54 / 1.2,
        perkGap = 0.014,
        perkAspect = 0.78,
        perkLabelH = 0.24,
        perkLabelMaxText = 56,
        perkIconScale = 0.56 * 1.2,
        perkIconY = 0.6,
        perkIconBobAmp = 0.018,
        perkIconBobHz = 0.75,
        perkCornerScale = 0.1,
        perkProgressGap = 0.02,
        reqLabelH = 0.07,
        progressH = 0.075 * 1.2,
        progressCornerScale = 0.16,
        progressButtonGap = 0.04,
        buttonRowH = 0.112 * 1.1,
        rebirthButtonW = 0.52 / 1.2,
        skipButtonW = 0.3,
        skipButtonH = 1 / 1.1,
        buttonGap = 0.04,
        buttonCornerScale = 0.14,
        shineWidth = 0.28,
    },
    -- Index panel @ 1920×1080 (egg tabs = top-right horizontal strip).
    index = {
        size = UDim2.fromScale(1027 * 1.5 / 1920, 552 * 1.5 / 1080),
        position = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        panelCornerScale = 20 / 552,
        titlePadX = 0.01,
        titleIconScale = 0.12 * 1.2,
        titleHeightScale = 64 / 552,
        closeScale = 0.125,
        -- Horizontal egg strip (left of close); ScrollFrame later when many eggs.
        eggStripW = 0.42,
        eggStripH = 0.14,
        eggStripPadRight = 0.02,
        eggGap = 0.02,
        eggHitScale = 1,
        contentTop = 0.12,
        contentBottom = 0.04,
        contentPadX = 0.03,
        scrollBarThickness = 6,
        cardCornerScale = 0.08,
        cardStroke = 5,
        shineWidth = 0.28,
        countW = 0.52,
        countH = 0.12,
        countPad = 0.035,
        countIconW = 0.38,
        nameH = 0.13,
        namePad = 0.035,
        grid = {
            columns = 4,
            rowsVisible = 2,
            padScale = 0.02,
            gapScale = 0.018,
            rowGapScale = 0.04,
            cellHeightMul = 1,
        },
    },
    -- Aim Map Shop shell (DesignRoot @ 1920×1080).
    shop = {
        size = UDim2.fromScale(0.8, 0.76),
        position = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        panelCornerScale = 0.04,
        titlePadX = 0.0004,
        titleIconScale = 0.22,
        titleHeightScale = 0.12,
        closeScale = 0.165,
        scrollFill = 0.98,
        contentPad = 0.035,
        sectionGap = 0.04,
        productCols = 3,
        productGap = 0.03,
        product = {
            titleW = 0.72,
            titleH = 0.14,
            titlePadX = 0.06,
            titlePadY = 0.035,
            subtitleH = 0.1,
            -- Long banners: larger title + short blurb under it.
            bannerTitleH = 0.28,
            bannerDescH = 0.22,
            bannerDescPadY = 0.32,
            -- Buy chip (smaller than first pass).
            buyPriceH = 0.78,
            buyContentScale = 1,
            buyCenterGap = 0.04,
            buyRobuxH = 0.85,
            buyStroke = 3,
            -- Packs: less wide, taller chip.
            packBuyW = 0.58,
            packBuyH = 0.145,
            packBuyX = 0.5,
            packBuyY = 0.94,
            -- Banners: longer, shorter chip.
            bannerBuyW = 0.26,
            bannerBuyH = 0.34,
            bannerBuyX = 0.96,
            bannerBuyY = 0.88,
            -- Floating hero (coin / luck) over plate — left of center on banners.
            packHeroW = 0.72,
            packHeroH = 0.55,
            packHeroY = 0.48,
            bannerHeroW = 0.34,
            bannerHeroH = 1.05,
            bannerHeroX = 0.34,
            bannerHeroY = 0.48,
            heroBobAmp = 0.02,
            heroBobHz = 0.7,
        },
    },
}

return {
    Colors = Colors,
    Gradients = Gradients,
    Rarity = Rarity,
    Font = Font,
    Radius = Radius,
    Stroke = Stroke,
    Icon = Icon,
    Design = Design,
    PromptKind = PromptKind,
    Layout = Layout,
}
