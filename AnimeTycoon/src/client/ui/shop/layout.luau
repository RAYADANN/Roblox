--!strict
-- Единственный источник размеров: значения из StarterGui.ScreenGui (Scale).

local SG = {
    stage = {
        size = UDim2.fromScale(0.8, 0.8),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
    },
    window = {
        size = UDim2.fromScale(0.7, 0.9),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        aspect = (1280 * 0.7) / (720 * 0.9),
    },
    title = {
        size = UDim2.fromScale(1, 0.12),
        pos = UDim2.fromScale(0.5, 0.06),
        anchor = Vector2.new(0.5, 0.5),
    },
    content = {
        top = 0.1,
        bottom = 0,
    },
    titleShadow = {
        size = UDim2.fromScale(0.6, 1),
        pos = UDim2.fromScale(0.43, 0.5),
        anchor = Vector2.new(0.5, 0.5),
    },
    titleText = {
        size = UDim2.fromScale(0.6, 1),
        pos = UDim2.fromScale(0.43, 0.4),
        anchor = Vector2.new(0.5, 0.5),
    },
    close = {
        size = UDim2.fromScale(0.075, 0.8),
        pos = UDim2.fromScale(0.95, 0.48),
        anchor = Vector2.new(0.5, 0.5),
    },
    -- Доли от Title/Header (квадрат через AspectRatio)
    icon = {
        size = UDim2.fromScale(2, 2),
        pos = UDim2.fromScale(0.08, 0.35),
        anchor = Vector2.new(0.5, 0.5),
    },

    luck = {
        size = UDim2.fromScale(0.48, 0.45 / 0.62),
        leftPos = UDim2.fromScale(0.25, 0.5),
        rightPos = UDim2.fromScale(0.75, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        icon = {
            size = UDim2.fromScale(0.5, 0.75),
            pos = UDim2.fromScale(0.23, 0.6),
            anchor = Vector2.new(0.5, 0.5),
        },
        title = {
            size = UDim2.fromScale(1, 0.3),
            pos = UDim2.fromScale(0.5, 0.12),
            anchor = Vector2.new(0.5, 0.5),
        },
        desc = {
            size = UDim2.fromScale(0.5, 0.4),
            pos = UDim2.fromScale(0.75, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
        mult = {
            size = UDim2.fromScale(0.2, 0.3),
            pos = UDim2.fromScale(0.23, 0.55),
            anchor = Vector2.new(0.5, 0.5),
        },
        buy = {
            size = UDim2.fromScale(0.4, 0.25),
            pos = UDim2.fromScale(0.6, 0.85),
            anchor = Vector2.new(0.5, 0.5),
        },
        gift = {
            size = UDim2.fromScale(0.15, 0.25),
            pos = UDim2.fromScale(0.9, 0.85),
            anchor = Vector2.new(0.5, 0.5),
        },
    },

    money = {
        size = UDim2.fromScale(0.28, 0.55 / 0.62),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        rowX = { 0.2, 0.5, 0.8 },
        rowY = 0.5,
        icon = {
            size = UDim2.fromScale(0.6, 0.6),
            pos = UDim2.fromScale(0.5, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
        value = {
            size = UDim2.fromScale(1, 0.2),
            pos = UDim2.fromScale(0.5, 0.1),
            anchor = Vector2.new(0.5, 0.5),
        },
        buy = {
            size = UDim2.fromScale(0.6, 0.2),
            pos = UDim2.fromScale(0.37, 0.88),
            anchor = Vector2.new(0.5, 0.5),
        },
        gift = {
            size = UDim2.fromScale(0.24, 0.2),
            pos = UDim2.fromScale(0.84, 0.88),
            anchor = Vector2.new(0.5, 0.5),
        },
    },

    -- SpecialPack (GamePass) — ширина 0.98; высота как у Luck, чтобы gap к Boosts = Boosts→Cash
    specialPack = {
        size = UDim2.fromScale(0.98, 0.45 / 0.62),
        pos = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        icon1 = {
            size = UDim2.fromScale(0.2, 0.8),
            pos = UDim2.fromScale(0.1, 0.35),
            anchor = Vector2.new(0.5, 0.5),
        },
        icon2 = {
            size = UDim2.fromScale(0.2, 0.8),
            pos = UDim2.fromScale(0.23, 0.62),
            anchor = Vector2.new(0.5, 0.5),
        },
        icon3 = {
            size = UDim2.fromScale(0.2, 0.8),
            pos = UDim2.fromScale(0.37, 0.35),
            anchor = Vector2.new(0.5, 0.5),
        },
        title = {
            size = UDim2.fromScale(0.5, 0.5),
            pos = UDim2.fromScale(0.75, 0.18),
            anchor = Vector2.new(0.5, 0.5),
        },
        desc = {
            size = UDim2.fromScale(0.5, 0.3),
            pos = UDim2.fromScale(0.75, 0.5),
            anchor = Vector2.new(0.5, 0.5),
        },
        buy = {
            size = UDim2.fromScale(0.3, 0.35),
            pos = UDim2.fromScale(0.7, 0.8),
            anchor = Vector2.new(0.5, 0.5),
        },
        gift = {
            size = UDim2.fromScale(0.1, 0.35),
            pos = UDim2.fromScale(0.92, 0.8),
            anchor = Vector2.new(0.5, 0.5),
        },
    },

    -- Отдельная строка НАД контентом секции (внутри блока, не через list gap)
    sectionLabel = {
        height = 0.1,
        size = UDim2.fromScale(0.55, 0.95),
        -- Y в долях Heading: меньше = выше. cashPos — только секция Cash (карточки выше)
        pos = UDim2.fromScale(0.5, 1),
        cashPos = UDim2.fromScale(0.5, 0.6),
        zIndex = 20,
        contentGap = -0.1,
    },

    section = {
        height = 0.6,
        gap = 0.02,
        -- запас снизу (доля высоты Scroll) после AbsoluteContentSize
        bottomPad = 0.1,
    },
}

return SG
