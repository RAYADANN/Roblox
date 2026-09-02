--!strict
-- SimPop Block — rarity card chrome for inventory / shop / cases.

export type SimPopBlockTone = "blue" | "green" | "purple" | "orange" | "red"

export type ChromeDef = {
    background: string,
    ASPECT: number,
    shineWidth: number,
    nativeWidth: number,
    nativeHeight: number,
}

local SHINE_W = 356
local SHINE_H = 493
local SHINE_ASPECT = SHINE_W / SHINE_H

local function chrome(width: number, height: number, background: string): ChromeDef
    return {
        background = background,
        ASPECT = width / height,
        shineWidth = SHINE_W / width,
        nativeWidth = width,
        nativeHeight = height,
    }
end

local Block = {
    shine = "rbxassetid://128087905347748",
    SHINE_ASPECT = SHINE_ASPECT,
    blue = chrome(320, 439, "rbxassetid://126866800396510"),
    green = chrome(320, 439, "rbxassetid://107795526086183"),
    orange = chrome(320, 439, "rbxassetid://93480964723864"),
    red = chrome(320, 439, "rbxassetid://119027139368496"),
    purple = chrome(320, 439, "rbxassetid://76429261757683"),
    --- Frame-only chrome (no fill) — shop drop tiles; tint via ImageColor3.
    frame = chrome(320, 439, "rbxassetid://119027139368496"),
}

-- Long shop plates (cases / offers) — purple set for cases + shop.
-- Shine band is a fraction of plate WIDTH (not the tall-block 356×493 metrics).
local LONG_SHINE_WIDTH = 0.22

local function longChrome(width: number, height: number, background: string): ChromeDef
    return {
        background = background,
        ASPECT = width / height,
        shineWidth = LONG_SHINE_WIDTH,
        nativeWidth = width,
        nativeHeight = height,
    }
end

local LongBlock = {
    shine = "rbxassetid://128150293974822",
    blue = longChrome(640, 220, "rbxassetid://123858447548753"),
    green = longChrome(640, 220, "rbxassetid://103736968726447"),
    orange = longChrome(640, 220, "rbxassetid://125708359415380"),
    red = longChrome(640, 220, "rbxassetid://125938563552603"),
    purple = longChrome(640, 220, "rbxassetid://132741952329002"),
    purpleDiamond = longChrome(640, 220, "rbxassetid://97697114296754"),
    purpleVertical = longChrome(220, 640, "rbxassetid://86684267156881"),
}

local TONES: { SimPopBlockTone } = { "blue", "green", "purple", "orange", "red" }

return {
    Block = Block,
    LongBlock = LongBlock,
    TONES = TONES,
    SHINE_ASPECT = SHINE_ASPECT,
}
