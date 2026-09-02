--!strict
-- Design tokens — hybrid layout (Scale + Offset), no magic numbers in components.
--
-- Scale  → окно к экрану, доли внутри панели.
-- Offset → только токены: hit-target, ячейка сетки, pad/gap, stroke, scrollbar.
-- Aspect → квадраты (close / slot).
-- В UI не писать голые 48/12 — theme.Layout / Space / Stroke.

export type Shine = "linear" | "radial" | "diamond"
export type ActionTone = "buy" | "equip" | "close"
export type SlotRarity = "purple" | "gold" | "blue" | "orange" | "green" | "red"
export type BarTone = "teal" | "orange"

export type GradientStop = {
    pos: number,
    color: Color3,
    alpha: number,
}

export type GradientDef = {
    stops: { GradientStop },
    rotation: number,
}

local function rgb(r: number, g: number, b: number): Color3
    return Color3.fromRGB(r, g, b)
end

local Colors = {
    bg = rgb(28, 28, 34),
    panel = rgb(255, 255, 255),
    panelAlt = rgb(210, 210, 214),
    slotEmpty = rgb(90, 90, 94),
    divider = rgb(40, 40, 44),
    white = rgb(255, 255, 255),
    black = rgb(0, 0, 0),
    stroke = rgb(2, 2, 2),
    text = rgb(255, 253, 253),
    buy = rgb(106, 255, 17),
    equip = rgb(5, 123, 255),
    close = rgb(112, 112, 112),
    closeXLight = rgb(249, 170, 170),
    closeX = rgb(255, 41, 41),
    countWarm = rgb(240, 148, 94),
    countLight = rgb(254, 244, 244),
}

local Font = {
    display = Enum.Font.FredokaOne,
}

-- UICorner scale (relative to parent min axis)
local Radius = {
    button = 0.08,
    closeX = 0.08,
    slot = 0.07,
    panel = 0.035,
}

-- UIStroke Thickness — engine only accepts pixels.
local Stroke = {
    button = 3,
    closeX = 8,
    slot = 4,
    bar = 3,
    text = 3,
    title = 7,
    panel = 10,
    divider = 3,
}

-- Spacing: Offset px tokens + Scale aliases for galleries.
local Space = {
    xs = 4,
    sm = 8,
    md = 12,
    lg = 16,
    xl = 24,
    xxl = 32,
    -- Scale (legacy gallery / section lists)
    pad = 0.03,
    gap = 0.015,
    sectionGap = 0.035,
}

-- Inventory / window chrome — tune proportions here only.
local Layout = {
    window = {
        size = UDim2.fromScale(0.9, 0.62),
        position = UDim2.fromScale(0.5, 0.52),
        anchor = Vector2.new(0.5, 0.5),
        minWidthPx = 280,
        minHeightPx = 240,
        maxWidthPx = 900,
        maxHeightPx = 700,
    },
    -- Title on top edge (half outside). Width Scale, height fixed band.
    title = {
        size = UDim2.new(0.5, 0, 0, 44),
        position = UDim2.fromScale(0.04, 0),
        anchor = Vector2.new(0, 0.5),
    },
    -- Close: Scale + clamp (stable on phone and desktop).
    close = {
        scale = 0.1,
        minPx = 36,
        maxPx = 52,
        position = UDim2.fromScale(0.985, 0),
        anchor = Vector2.new(1, 0.5),
    },
    body = {
        size = UDim2.new(1, 0, 1, -8),
        position = UDim2.fromOffset(0, 8),
    },
    -- Cell px computed from AbsoluteWidth; these are clamps / fallbacks.
    grid = {
        cellPx = 112,
        minCellPx = 72,
        maxCellPx = 128,
        gapPx = 10,
        columns = 4,
        padPx = 14,
    },
    scrollbarPx = 6,
}

-- UIShadow defaults (drop shadow under parent GuiObject)
export type ShadowDef = {
    blurRadius: UDim,
    offset: UDim2,
    spread: UDim2,
    color: Color3,
    transparency: number,
    zIndex: number,
}

local Shadow = {
    -- Bright light halo (dark bg). Note: Transparency 1 = invisible.
    button = {
        blurRadius = UDim.new(0, 28),
        offset = UDim2.fromOffset(0, 10),
        spread = UDim2.fromOffset(8, 8),
        color = rgb(11, 218, 73),
        transparency = 0.05,
        zIndex = -1,
    } :: ShadowDef,
    closeX = {
        blurRadius = UDim.new(0, 24),
        offset = UDim2.fromOffset(0, 8),
        spread = UDim2.fromOffset(6, 6),
        color = rgb(255, 160, 160),
        transparency = 0.05,
        zIndex = -1,
    } :: ShadowDef,
}

local ActionGradients: { [ActionTone]: { [Shine]: GradientDef } } = {
    buy = {
        linear = {
            rotation = 90,
            stops = {
                { pos = 0, color = Colors.white, alpha = 1 },
                { pos = 0.27, color = Colors.buy, alpha = 1 },
                { pos = 1, color = Colors.buy, alpha = 1 },
            },
        },
        radial = {
            rotation = 90,
            stops = {
                { pos = 0, color = Colors.white, alpha = 1 },
                { pos = 0.45, color = Colors.buy, alpha = 1 },
                { pos = 1, color = rgb(70, 200, 10), alpha = 1 },
            },
        },
        diamond = {
            rotation = 45,
            stops = {
                { pos = 0, color = Colors.white, alpha = 1 },
                { pos = 0.5, color = Colors.buy, alpha = 1 },
                { pos = 1, color = rgb(70, 200, 10), alpha = 1 },
            },
        },
    },
    equip = {
        linear = {
            rotation = 90,
            stops = {
                { pos = 0, color = Colors.white, alpha = 1 },
                { pos = 0.27, color = Colors.equip, alpha = 1 },
                { pos = 1, color = Colors.equip, alpha = 1 },
            },
        },
        radial = {
            rotation = 90,
            stops = {
                { pos = 0, color = Colors.white, alpha = 1 },
                { pos = 0.45, color = Colors.equip, alpha = 1 },
                { pos = 1, color = rgb(4, 90, 200), alpha = 1 },
            },
        },
        diamond = {
            rotation = 45,
            stops = {
                { pos = 0, color = Colors.white, alpha = 1 },
                { pos = 0.5, color = Colors.equip, alpha = 1 },
                { pos = 1, color = rgb(4, 90, 200), alpha = 1 },
            },
        },
    },
    close = {
        linear = {
            rotation = 90,
            stops = {
                { pos = 0, color = Colors.white, alpha = 1 },
                { pos = 0.27, color = Colors.close, alpha = 1 },
                { pos = 1, color = Colors.close, alpha = 1 },
            },
        },
        radial = {
            rotation = 90,
            stops = {
                { pos = 0, color = Colors.white, alpha = 1 },
                { pos = 0.45, color = Colors.close, alpha = 1 },
                { pos = 1, color = rgb(80, 80, 80), alpha = 1 },
            },
        },
        diamond = {
            rotation = 45,
            stops = {
                { pos = 0, color = Colors.white, alpha = 1 },
                { pos = 0.5, color = Colors.close, alpha = 1 },
                { pos = 1, color = rgb(80, 80, 80), alpha = 1 },
            },
        },
    },
}

local CloseXGradients: { [Shine]: GradientDef } = {
    linear = {
        rotation = 90,
        stops = {
            { pos = 0, color = Colors.closeXLight, alpha = 1 },
            { pos = 0.27, color = Colors.closeX, alpha = 1 },
            { pos = 1, color = Colors.closeX, alpha = 1 },
        },
    },
    radial = {
        rotation = 90,
        stops = {
            { pos = 0, color = Colors.closeXLight, alpha = 1 },
            { pos = 1, color = Colors.closeX, alpha = 1 },
        },
    },
    diamond = {
        rotation = 45,
        stops = {
            { pos = 0, color = Colors.closeXLight, alpha = 1 },
            { pos = 0.5, color = Colors.closeX, alpha = 1 },
            { pos = 1, color = rgb(200, 20, 20), alpha = 1 },
        },
    },
}

local SlotGradients: { [SlotRarity]: GradientDef } = {
    purple = {
        rotation = 90,
        stops = {
            { pos = 0, color = Colors.white, alpha = 1 },
            { pos = 0.4, color = rgb(148, 88, 255), alpha = 1 },
            { pos = 1, color = rgb(94, 2, 254), alpha = 1 },
        },
    },
    gold = {
        rotation = 90,
        stops = {
            { pos = 0, color = Colors.white, alpha = 1 },
            { pos = 0.4, color = rgb(255, 223, 118), alpha = 1 },
            { pos = 1, color = rgb(254, 193, 19), alpha = 1 },
        },
    },
    blue = {
        rotation = 90,
        stops = {
            { pos = 0, color = Colors.white, alpha = 1 },
            { pos = 0.4, color = rgb(100, 120, 255), alpha = 1 },
            { pos = 1, color = rgb(19, 40, 255), alpha = 1 },
        },
    },
    orange = {
        rotation = 90,
        stops = {
            { pos = 0, color = Colors.white, alpha = 1 },
            { pos = 0.4, color = rgb(255, 133, 61), alpha = 1 },
            { pos = 1, color = rgb(242, 84, 0), alpha = 1 },
        },
    },
    green = {
        rotation = 90,
        stops = {
            { pos = 0, color = Colors.white, alpha = 1 },
            { pos = 0.4, color = rgb(97, 255, 61), alpha = 1 },
            { pos = 1, color = rgb(46, 255, 0), alpha = 1 },
        },
    },
    red = {
        rotation = 90,
        stops = {
            { pos = 0, color = Colors.white, alpha = 1 },
            { pos = 0.4, color = rgb(255, 67, 61), alpha = 1 },
            { pos = 1, color = rgb(255, 8, 0), alpha = 1 },
        },
    },
}

local BarGradients: { [BarTone]: GradientDef } = {
    teal = {
        rotation = 0,
        stops = {
            { pos = 0, color = rgb(0, 242, 196), alpha = 1 },
            { pos = 1, color = rgb(26, 2, 166), alpha = 1 },
        },
    },
    orange = {
        rotation = 0,
        stops = {
            { pos = 0, color = rgb(255, 162, 0), alpha = 1 },
            { pos = 1, color = rgb(0, 7, 2), alpha = 1 },
        },
    },
}

local ActionLabels: { [ActionTone]: string } = {
    buy = "BUY",
    equip = "EQUIP",
    close = "CLOSE",
}

return {
    Colors = Colors,
    Font = Font,
    Radius = Radius,
    Stroke = Stroke,
    Space = Space,
    Layout = Layout,
    Shadow = Shadow,
    ActionGradients = ActionGradients,
    CloseXGradients = CloseXGradients,
    SlotGradients = SlotGradients,
    BarGradients = BarGradients,
    ActionLabels = ActionLabels,
}
