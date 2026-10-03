--!strict
-- Box mesh = stand level + random palette. Rarity does NOT pick the mesh.
-- Templates live under ReplicatedStorage.GameAssets.Boxes / 1|2|3.
-- Display names = Italian Brainrot; mesh asset names stay as authored.

export type BoxShapeId = "1" | "2" | "3"

local PALETTES: { [BoxShapeId]: { string } } = {
    ["1"] = {
        "Box1_Sapphire",
        "Box1_Emerald",
        "Box1_Ruby",
        "Box1_Topaz",
        "Box1_RoseQuartz",
        "Box1_Obsidian",
        "Box1_Sunset",
        "Box1_MintIce",
        "Box1_Lavender",
        "Box1_BloodAmber",
    },
    ["2"] = {
        "BoxLVL2_Sapphire",
        "BoxLVL2_Emerald",
        "BoxLVL2_Ruby",
        "BoxLVL2_Topaz",
        "BoxLVL2_RoseQuartz",
        "BoxLVL2_Obsidian",
        "BoxLVL2_Sunset",
        "BoxLVL2_MintIce",
        "BoxLVL2_Lavender",
        "BoxLVL2_BloodAmber",
    },
    ["3"] = {
        "Diamond_Sapphire",
        "Diamond_Emerald",
        "Diamond_Ruby",
        "Diamond_Topaz",
        "Diamond_RoseQuartz",
        "Diamond_Obsidian",
        "Diamond_Sunset",
        "Diamond_MintIce",
        "Diamond_Lavender",
        "Diamond_BloodAmber",
    },
}

--- Stand / shape tier (internal / upgrade status). Not used as case DisplayName.
local TIER_DISPLAY: { [BoxShapeId]: string } = {
    ["1"] = "Scatolino Tralala",
    ["2"] = "Cassa Bombardini",
    ["3"] = "Forziere Saturnita",
}

--- Palette suffix (after last `_`) → case DisplayName (single name only).
local PALETTE_DISPLAY: { [string]: string } = {
    Sapphire = "Blu Blu Mareini",
    Emerald = "Verdi Pistacchio",
    Ruby = "Rossini Pepperoni",
    Topaz = "Oro Formaggino",
    RoseQuartz = "Rosa Ballerina",
    Obsidian = "Nero Cappuccino",
    Sunset = "Arancio Tramonto",
    MintIce = "Menta Gelato",
    Lavender = "Lilla Lullaby",
    BloodAmber = "Sangre Ambra",
}

local BoxVisualDatabase = {}

--- Luck upgrade level → box shape (mesh tier). Also drives rarity bias via UpgradeLogic.luckBias.
function BoxVisualDatabase.standLevelFromLuck(luckLevel: number): number
    local L = math.max(0, math.floor(luckLevel))
    if L >= 6 then
        return 3
    end
    if L >= 3 then
        return 2
    end
    return 1
end

--- Stand upgrade level → box shape folder under GameAssets.Boxes.
function BoxVisualDatabase.shapeForStandLevel(standLevel: number): BoxShapeId
    local lvl = math.floor(standLevel)
    if lvl <= 1 then
        return "1"
    end
    if lvl == 2 then
        return "2"
    end
    return "3" -- 3 and 4 share Boxes/3
end

function BoxVisualDatabase.palettes(shape: BoxShapeId): { string }
    return PALETTES[shape]
end

function BoxVisualDatabase.allShapes(): { BoxShapeId }
    return { "1", "2", "3" }
end

function BoxVisualDatabase.tierDisplayName(shape: BoxShapeId): string
    return TIER_DISPLAY[shape] or "Scatolino Tralala"
end

function BoxVisualDatabase.paletteKeyFromModelName(boxModelName: string): string?
    local key = string.match(boxModelName, "_(%w+)$")
    return key
end

function BoxVisualDatabase.paletteDisplayName(paletteKey: string): string
    return PALETTE_DISPLAY[paletteKey] or paletteKey
end

--- Case DisplayName = palette only (e.g. "Menta Gelato"). Mesh tier is visual-only.
function BoxVisualDatabase.formatCaseDisplayName(boxModelName: string, _standLevel: number?): string
    local key = BoxVisualDatabase.paletteKeyFromModelName(boxModelName)
    if key then
        return BoxVisualDatabase.paletteDisplayName(key)
    end
    return "Menta Gelato"
end

function BoxVisualDatabase.shapeFromModelName(boxModelName: string): BoxShapeId
    if
        string.find(boxModelName, "BoxLVL2", 1, true) or string.find(boxModelName, "LVL2", 1, true)
    then
        return "2"
    end
    if string.find(boxModelName, "Diamond_", 1, true) then
        return "3"
    end
    return "1"
end

return BoxVisualDatabase
