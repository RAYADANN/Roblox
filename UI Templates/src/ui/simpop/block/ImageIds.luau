--!strict
-- SimPop Block — card chrome for shop / inventory grids.

export type SimPopBlockTone = "blue" | "green" | "orange" | "red"

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
    shine = "rbxassetid://128087905347748", -- Blocks/Shine.png
    SHINE_ASPECT = SHINE_ASPECT,
    blue = chrome(320, 439, "rbxassetid://126866800396510"), -- Blocks/Blue.png
    green = chrome(320, 439, "rbxassetid://107795526086183"), -- Blocks/Green.png
    orange = chrome(320, 439, "rbxassetid://93480964723864"), -- Blocks/Orange.png
    red = chrome(320, 439, "rbxassetid://119027139368496"), -- Blocks/Red.png
}

local TONES: { SimPopBlockTone } = { "blue", "green", "orange", "red" }

return {
    Block = Block,
    TONES = TONES,
    SHINE_ASPECT = SHINE_ASPECT,
}
