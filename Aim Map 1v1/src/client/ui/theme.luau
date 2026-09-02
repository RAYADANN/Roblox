--!strict
-- Design tokens — единственный источник цветов, шрифтов, радиусов.
-- Art/UI shared roles: assets/ui/PALETTE.md (держи в sync).

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
    -- Icon/brand chrome (see PALETTE.md)
    sky = Color3.fromRGB(62, 165, 232),
    skyHi = Color3.fromRGB(115, 199, 255),
    deepBlue = Color3.fromRGB(0, 96, 174),
    navyOutline = Color3.fromRGB(0, 13, 40),
    silver = Color3.fromRGB(197, 205, 213),
    steel = Color3.fromRGB(139, 149, 163),

    gold = Color3.fromRGB(255, 212, 38),
    goldHi = Color3.fromRGB(255, 238, 130),
    goldArt = Color3.fromRGB(230, 182, 62),
    bronze = Color3.fromRGB(181, 120, 71),
    bronzeDeep = Color3.fromRGB(122, 74, 47),

    sell = Color3.fromRGB(44, 210, 108),
    sellHi = Color3.fromRGB(70, 238, 136),

    panelBg = Color3.fromRGB(18, 22, 38),
    panelBody = Color3.fromRGB(22, 26, 44),

    textMain = Color3.fromRGB(228, 234, 255),
    textSub = Color3.fromRGB(148, 158, 195),
    textMuted = Color3.fromRGB(76, 88, 120),
    white = Color3.fromRGB(255, 255, 255),
    black = Color3.fromRGB(0, 0, 0),

    outline = Color3.fromRGB(255, 255, 255),
    outlineDark = Color3.fromRGB(0, 0, 0),

    btnBg = Color3.fromRGB(36, 42, 68),
    tabActive = Color3.fromRGB(32, 38, 62),
    tabInactive = Color3.fromRGB(20, 24, 40),
    tabBorder = Color3.fromRGB(50, 58, 88),

    error = Color3.fromRGB(255, 100, 80),
    success = Color3.fromRGB(80, 220, 120),
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
    -- SimPop chrome labels (UI Templates)
    display = Enum.Font.FredokaOne,
}

local Radius = {
    panel = UDim.new(0, 14),
    chip = UDim.new(0, 10),
    btn = UDim.new(0, 10),
    navBtn = UDim.new(0, 12),
    pill = UDim.new(1, 0),
}

local Stroke = {
    thin = 1,
    medium = 1.5,
    thick = 2,
    simPop = 3,
    text = 3,
    slot = 8,
    panel = 10,
    title = 7,
}

-- SimPop layout tokens (UI Templates)
local Space = {
    xs = 12,
    sm = 8,
    md = 12,
    lg = 16,
    xl = 24,
}

local SimPop = {
    cornerScale = 0.08,
    slotCorner = 0.07,
    hudIcon = 88,
    hudIconGap = 10,
    panelStroke = 10,
    titleStroke = 7,
    selectedStroke = Color3.fromRGB(255, 140, 32),
    selectedShadow = Color3.fromRGB(160, 64, 8),
}

-- Inventory: Scale shell (fills fitted canvas) + Scale grid cells.
-- HUD: all Scale fractions of the 1920×1080 canvas (no Offset layout).
local Layout = {
    hud = {
        padX = 0.018,
        padY = 0.02,
        topH = 0.12,
        statusH = 0.3,
        scoreH = 0.55,
        railW = 0.055,
        railH = 0.42,
        iconGap = 0.04,
        bottomLeftW = 0.28,
        bottomLeftH = 0.16,
        hpRowH = 0.38,
        hpIconW = 0.12,
        metaH = 0.18,
        ctaW = 0.42,
        ctaH = 0.075,
        ctaBtnW = 0.42,
        ctaSensW = 0.32,
        ctaGap = 0.03,
        bottomPad = 0.025,
        iconInRail = 1,
    },
    inventory = {
        -- Centered modal; tabs + close hang outside the white panel.
        size = UDim2.fromScale(0.78, 0.74),
        position = UDim2.fromScale(0.52, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        tabW = 0.12,
        -- Tall enough for two square tabs (width-driven aspect) + gap.
        tabStackH = 0.52,
        tabGap = 0.08,
        -- Gap between tab column and white panel edge.
        tabInset = 0.025,
        panelCornerScale = 0.04,
        titlePadX = 0.0004,
        titleIconScale = 0.22,
        titleIconGap = 0.004,
        titleHeightScale = 0.12,
        closeScale = 0.165,
        -- Scroll fills nearly the whole white panel (title sits on the edge).
        scrollFill = 0.98,
        grid = {
            columns = 4,
            rowsVisible = 2,
            padScale = 0.03,
            gapScale = 0.025,
            -- Extra space between rows (vs column gap).
            rowGapScale = 0.05,
            -- Card height vs base row math (scroll if content exceeds viewport).
            cellHeightMul = 1.4,
        },
    },
    -- Same shell as inventory; tune `offer*` to change card proportions.
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
        -- Offer card height as fraction of the scroll viewport height.
        offerH = 0.6,
        offerGap = 0.04,
        -- Product cards under case offers (Items assets).
        productCols = 3,
        productGap = 0.03,
        boostGap = 0.03,
        product = {
            titleW = 0.7,
            titleH = 0.22,
            titlePadX = 0.06,
            titlePadY = 0.04,
            -- Single buy button (same price+Robux cluster as case offers).
            buyPriceH = 0.72,
            buyContentScale = 1.35,
            buyCenterGap = 0,
            buyRobuxH = 0.92,
            -- Portrait packs.
            packBuyW = 0.78,
            packBuyH = 0.16,
            packBuyX = 0.92,
            packBuyY = 0.94,
            -- Half-row X2 Coins / X2 Diamonds.
            boostBuyW = 0.42,
            boostBuyH = 0.42,
            boostBuyX = 0.94,
            boostBuyY = 0.88,
            -- Full-width X2 Luck.
            bannerBuyW = 0.28,
            bannerBuyH = 0.48,
            bannerBuyX = 0.96,
            bannerBuyY = 0.88,
        },
        -- Inner element sizes (×1.5). Positions left as-is; tweak in theme if needed.
        offer = {
            titleW = 0.7,
            titleH = 0.3,
            titlePadX = 0.,
            titlePadY = -0.1,
            caseW = 0.72,
            caseH = 1.2,
            -- Negative X pulls art past the left edge of the plate.
            caseX = -0.3,
            caseY = 0.56,
            -- Vertical bob (scale of offer card height).
            caseBobAmp = 0.028,
            caseBobHz = 0.65,
            dropsW = 0.8,
            dropsH = 0.46 * 1.5,
            dropsX = 0.25,
            dropsY = 0.2,
            dropGap = 0.03 * 1.5,
            dropCardH = 0.8,
            dropNameH = 0.4,
            buysW = 0.58,
            buysH = 0.2,
            buysX = 1.05,
            -- Lower = closer to / past the bottom of the plate.
            buysY = 1.06,
            buyGap = 0.05,
            buyW = 0.45,
            -- Qty badge (scale of button; can sit past the corner).
            buyQtyW = 0.34,
            buyQtyH = 0.3,
            buyQtyX = 1.1,
            buyQtyY = -0.35,
            buyQtyScale = 2,
            -- Price+Robux row (height = scale of button; width hugs content, centered).
            buyPriceH = 0.72,
            buyContentScale = 1.45,
            -- Half-gap from center pivot (price right / icon left). 0 = touching at center.
            buyCenterGap = 0,
            buyRobuxH = 0.92,
        },
    },
}

local Icon = {
    tint = Color3.fromRGB(255, 255, 255),
    inactiveAlpha = 0.45,
}

-- Design-space @ 1920×1080 (DesignRoot + UIScale). Use raw numbers in components.
local Design = {
    MODAL_W = 900,
    MODAL_H = 675,
    HEADER_H = 84,
    ROW_H = 78,
    DOCK_H = 108,
    DOCK_BTN = 78,
    ICON_SM = 36,
    ICON_MD = 48,
    ICON_LG = 72,
    PAD_SM = 12,
    PAD_MD = 18,
    PAD_LG = 24,
    TOUCH_MIN = 44,
}

return {
    Colors = Colors,
    Rarity = Rarity,
    Font = Font,
    Radius = Radius,
    Stroke = Stroke,
    Space = Space,
    SimPop = SimPop,
    Layout = Layout,
    Icon = Icon,
    Design = Design,
}
