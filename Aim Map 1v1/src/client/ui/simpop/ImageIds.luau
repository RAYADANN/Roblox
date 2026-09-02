--!strict
-- SimPop chrome asset IDs (shared with UI Templates).

export type SimPopTone = "blue" | "green" | "orange" | "red" | "purple"
export type SimPopOrientation = "horizontal" | "vertical"

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

local SimPop = {
    shine = "rbxassetid://139702564707796",
    blue = {
        horizontal = chrome(330, 106, "rbxassetid://107871837824196"),
        vertical = chrome(320, 101, "rbxassetid://81631036339000"),
    },
    green = {
        horizontal = chrome(320, 101, "rbxassetid://79221494642851"),
        vertical = chrome(320, 101, "rbxassetid://71103140926641"),
    },
    orange = {
        horizontal = chrome(320, 101, "rbxassetid://75616206605098"),
        vertical = chrome(320, 101, "rbxassetid://83832338667341"),
    },
    red = {
        horizontal = chrome(320, 101, "rbxassetid://103534869197531"),
        vertical = chrome(320, 101, "rbxassetid://93973473704176"),
    },
    purple = {
        horizontal = chrome(320, 101, "rbxassetid://137249165128650"),
        vertical = chrome(320, 101, "rbxassetid://77215885644005"),
    },
}

local TONES: { SimPopTone } = { "blue", "green", "orange", "red", "purple" }
local ORIENTATIONS: { SimPopOrientation } = { "horizontal", "vertical" }

return {
    SimPop = SimPop,
    TONES = TONES,
    ORIENTATIONS = ORIENTATIONS,
}
