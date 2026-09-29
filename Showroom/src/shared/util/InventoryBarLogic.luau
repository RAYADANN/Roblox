--!strict
-- Pure helpers for bottom inventory hotbar (icon + hotkey labels).

local InventoryBarLogic = {}

local RARITY_EGG: { [string]: string } = {
    common = "EggDomestic",
    uncommon = "EggForest",
    rare = "EggIce",
    epic = "EggVolcano",
    legendary = "EggVolcano",
}

local KEYCODE_NAMES = {
    "One",
    "Two",
    "Three",
    "Four",
    "Five",
    "Six",
    "Seven",
    "Eight",
    "Nine",
}

function InventoryBarLogic.eggIconKey(rarity: string): string
    return RARITY_EGG[rarity] or "EggDomestic"
end

--- Keyboard label for slot index (1-based). 1..9 → "1".."9", 10 → "0", else nil.
function InventoryBarLogic.hotkeyLabel(index: number): string?
    local i = math.floor(index)
    if i < 1 or i > 10 then
        return nil
    end
    if i == 10 then
        return "0"
    end
    return tostring(i)
end

--- Enum.KeyCode name for slot index (One..Nine, Zero).
function InventoryBarLogic.hotkeyKeyCodeName(index: number): string?
    local i = math.floor(index)
    if i < 1 or i > 10 then
        return nil
    end
    if i == 10 then
        return "Zero"
    end
    return KEYCODE_NAMES[i]
end

return InventoryBarLogic
