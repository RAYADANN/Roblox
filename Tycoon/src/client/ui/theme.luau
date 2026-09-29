--!strict
-- Design tokens — единственный источник цветов, шрифтов, радиусов.

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

    indexCard = Color3.fromRGB(78, 38, 122),

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
    -- Affordable pad / billboard buy button (PadVisuals green).
    padGreen = Color3.fromRGB(0, 152, 0),
    success = Color3.fromRGB(0, 152, 0),

    -- MoneyButton chrome (assets/GameAssets/MoneyButton.png)
    moneyButtonStroke = Color3.fromRGB(226, 230, 181),
    progressTrack = Color3.fromRGB(40, 44, 48),
}

-- Buton25Rooms Price UIGradient (Studio BillboardGui) — yellow → lime, rot 90.
local Gradients = {
    moneyButtonText = {
        rotation = 90,
        keypoints = {
            { t = 0, c = Color3.fromRGB(255, 255, 0) },
            { t = 0.337, c = Color3.fromRGB(245, 255, 0) },
            { t = 1, c = Color3.fromRGB(0, 255, 0) },
        },
    },
    -- Pad BillboardGui Price (TagName row) — yellow → orange → black, rot 90.
    billboardPrice = {
        rotation = 90,
        keypoints = {
            { t = 0, c = Color3.fromRGB(255, 170, 0) },
            { t = 0.642, c = Color3.fromRGB(244, 163, 0) },
            { t = 1, c = Color3.fromRGB(0, 0, 0) },
        },
    },
    -- Exclusive offer title — hot pink → magenta.
    exclusiveTitle = {
        rotation = 0,
        keypoints = {
            { t = 0, c = Color3.fromRGB(255, 120, 200) },
            { t = 0.5, c = Color3.fromRGB(255, 70, 170) },
            { t = 1, c = Color3.fromRGB(220, 40, 140) },
        },
    },
    -- Exclusive rebirth pack title — billboard orange.
    exclusiveTitleOrange = {
        rotation = 90,
        keypoints = {
            { t = 0, c = Color3.fromRGB(255, 170, 0) },
            { t = 0.642, c = Color3.fromRGB(244, 163, 0) },
            { t = 1, c = Color3.fromRGB(0, 0, 0) },
        },
    },
    -- Exclusive offer countdown — red.
    exclusiveTimer = {
        rotation = 0,
        keypoints = {
            { t = 0, c = Color3.fromRGB(255, 90, 90) },
            { t = 0.5, c = Color3.fromRGB(255, 40, 40) },
            { t = 1, c = Color3.fromRGB(200, 20, 20) },
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
    btn = UDim.new(0, 8),
    navBtn = UDim.new(0, 12),
    pill = UDim.new(0.2, 0),
}

local Stroke = {
    thin = 1,
    medium = 1.5,
    thick = 2,
    moneyButton = 3,
    moneyButtonText = 0.14,
    panel = 10,
    title = 7,
    body = 0.12,
}

local Icon = {
    tint = Color3.fromRGB(255, 255, 255),
    inactiveAlpha = 0.45,
}

-- Design-space @ 1920×1080 (DesignRoot + UIScale). Use Scale fractions of the canvas.
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

local Layout = {
    farm = {
        chipW = 0.2,
        chipH = 0.075,
        -- Balance chip: bottom-left safe inset (CoreUISafeInsets on GameUI ScreenGui).
        balancePadX = 0.02,
        balancePadBottom = 0.025,
        -- Icon rail: right side vertical column (Index above Rebirth).
        -- Sized for two ~square icons + gap (matches former grid cell ~0.08×0.15 screen).
        railPadX = 0.9,
        railW = 0.08,
        railH = 0.34,
        stackW = 0.22,
        stackH = 0.28,
        rowH = 0.22,
        gap = 0.04,
        -- Frame 7 (2) @ 1920×1080: 443×112 px balance bar (design px → bar fractions in FarmHud)
        balanceBarPxW = 443,
        balanceBarPxH = 112,
        balanceW = 443 / 1920,
        balanceH = 112 / 1080,
        balanceIconLeftPx = 14,
        balanceIconSizePx = 132,
        balanceIconTextGapPx = 12,
        balanceTextRightPx = 20,
        -- Rebirth cash mult label on the right of the balance bar (e.g. "x10").
        balanceMultW = 0.22,
        balanceMultRightPx = 18,
        -- Money offer pills: mid-left stack (above balance chip). Design 320×135 @ 1920×1080 (1.5× height of 90).
        moneyOfferPadX = 0.025,
        moneyOfferCenterY = 0.46,
        moneyOfferW = 320 / 1920,
        moneyOfferBtnH = 135 / 1080,
        moneyOfferGap = 24 / 1080,
        moneyOfferAspect = 320 / 135,
        moneyOfferShineWidth = 0.28,
        -- Label height fraction inside pill (same idea as BalanceChip Amount 0.85).
        moneyOfferTextH = 0.85,
        -- Bottom-center bag (ItemsCount.png 275²). Design 300² @ 1920×1080.
        -- Pink score plate on the art: y 149–202 / 275 → center 0.64, height ~0.19.
        itemsCountPx = 300,
        itemsCountW = 300 / 1920,
        itemsCountH = 300 / 1080,
        itemsCountPadBottom = 0.02,
        itemsCountTextW = 0.58,
        itemsCountTextH = 0.18,
        itemsCountTextY = 0.64,
        -- Playtest: open FTUE overlay.
        tutorialTestPadX = 0.02,
        tutorialTestPadY = 0.02,
        tutorialTestW = 0.1,
        tutorialTestH = 0.045,
        -- Exclusive offers: above Index on the right rail (anchor bottom-center).
        exclusivePadX = 0.9,
        exclusivePadY = 0.32,
        exclusiveW = 0.2,
        exclusiveH = 0.28,
        exclusiveSpinScale = 1.15,
        exclusiveSlotsH = 0.92,
        exclusiveSlotW = 0.85,
        exclusiveSlotGap = 0.04,
        -- Title / price / Robux ~2× prior sizes; timer sits under title.
        exclusiveTitleH = 0.2,
        exclusiveTitleY = 0.1,
        exclusiveTimerH = 0.2,
        exclusiveTimerY = 0.26,
        exclusivePlatformH = 0.7,
        exclusivePlatformY = 0.2,
        exclusivePriceH = 0.25,
        exclusivePriceY = 0.74,
    },
    tutorial = {
        cardW = 0.42,
        cardH = 0.26,
        cardY = 0.78,
        cardCornerScale = 0.08,
        focusCornerScale = 0.08,
        focusHalfW = 0.13,
        focusHalfH = 0.09,
        arrowW = 0.09,
        arrowH = 0.12,
        -- Offset from focus hole (on-screen: above hole; off-screen: toward target).
        arrowOut = 0.08,
        arrowBob = 0.018,
        padX = 0.05,
        titleY = 0.08,
        titleH = 0.2,
        bodyY = 0.32,
        bodyH = 0.32,
        btnH = 0.18,
        btnPadY = 0.08,
        skipW = 0.22,
        nextW = 0.28,
        btnCornerScale = 0.22,
    },
    -- Figma Rebirth 1027×552 @ 1920×1080, scaled 1.5× on the design canvas.
    rebirth = {
        size = UDim2.fromScale(1027 * 1.5 / 1920, 552 * 1.5 / 1080),
        position = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        panelCornerScale = 20 / 552,
        titlePadX = 0.01,
        titleIconScale = 0.12,
        titleTextX = 0.045,
        titleHeightScale = 64 / 552,
        closeScale = 0.125,
        contentTop = 0.1,
        contentBottom = 0.045,
        contentPadX = 150.5 / 1027,
        listPad = 0.016,
        rewardLabelInCardH = 0.22,
        rewardCardW = 344 / 726,
        rewardCardH = 0.48,
        rewardCardAspect = 344 / 212,
        rewardCoinScale = 0.62,
        rewardCoinY = 0.58,
        rewardCoinBobPx = 12,
        reqLabelH = 0.08,
        progressH = 0.13,
        progressCornerScale = 0.16,
        progressButtonGap = 0.07,
        buttonRowH = 0.17,
        buttonW = 320 / 726,
        buttonGap = 86 / 726,
        buttonCornerScale = 0.14,
        shineWidth = 0.28,
    },
    -- Same Rebirth board; Index grid scroll matches Aim Map Inventory/Shop pattern.
    index = {
        size = UDim2.fromScale(1027 * 1.5 / 1920, 552 * 1.5 / 1080),
        position = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        panelCornerScale = 20 / 552,
        titlePadX = 0.01,
        titleIconScale = 0.12,
        titleHeightScale = 64 / 552,
        closeScale = 0.125,
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
            -- ~1.5× taller vs base 2-row fit (Aim Map inventory cellHeightMul).
            cellHeightMul = 1.5,
        },
    },
}

-- Spacing (matches UI Templates theme.Space — SimPopChrome shadow offset uses xs).
local Space = {
    xs = 12,
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
    Layout = Layout,
    Space = Space,
}
