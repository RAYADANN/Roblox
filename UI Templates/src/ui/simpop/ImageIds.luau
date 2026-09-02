--!strict
-- SimPop style — Roblox image asset IDs (PNG chrome + shine strip).

export type SimPopTone = "blue" | "green" | "orange" | "red"
export type SimPopOrientation = "horizontal" | "vertical"

-- Legacy: horizontal / vertical = blue orientation aliases
export type SimPopVariant = SimPopOrientation

export type ChromeDef = {
    background: string,
    ASPECT: number,
    shineWidth: number,
    nativeWidth: number,
    nativeHeight: number,
}

local SHINE_STRIP_W = 92

local function chrome(width: number, height: number, background: string): ChromeDef
    return {
        background = background,
        ASPECT = width / height,
        shineWidth = SHINE_STRIP_W / width,
        nativeWidth = width,
        nativeHeight = height,
    }
end

local SIM_POP_SHINE = "rbxassetid://139702564707796" -- Shine.png

local SimPop = {
    shine = SIM_POP_SHINE,
    blue = {
        horizontal = chrome(330, 106, "rbxassetid://107871837824196"), -- BlueButton.png
        vertical = chrome(320, 101, "rbxassetid://81631036339000"), -- BlueButtonVertival.png
    },
    green = {
        horizontal = chrome(320, 101, "rbxassetid://79221494642851"), -- Green.png
        vertical = chrome(320, 101, "rbxassetid://71103140926641"), -- GreenVertical.png
    },
    orange = {
        horizontal = chrome(320, 101, "rbxassetid://75616206605098"), -- Orange.png
        vertical = chrome(320, 101, "rbxassetid://83832338667341"), -- OrangeVertical.png
    },
    red = {
        horizontal = chrome(320, 101, "rbxassetid://103534869197531"), -- Red.png
        vertical = chrome(320, 101, "rbxassetid://93973473704176"), -- RedVertical.png
    },
}

-- Back-compat alias (blue horizontal)
local BlueButton = {
    background = SimPop.blue.horizontal.background,
    shine = SimPop.shine,
    ASPECT = SimPop.blue.horizontal.ASPECT,
}

local TONES: { SimPopTone } = { "blue", "green", "orange", "red" }
local ORIENTATIONS: { SimPopOrientation } = { "horizontal", "vertical" }

return {
    SimPop = SimPop,
    BlueButton = BlueButton,
    TONES = TONES,
    ORIENTATIONS = ORIENTATIONS,
}
