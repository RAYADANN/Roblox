--!strict
-- Эталон: сервер публикует компактное состояние на Player attribute,
-- все клиенты decode и рисуют (петы, aura, trail — то, что видят другие).
-- НЕ для прогресса (монеты, инвентарь) — только HudPayload через Zap.

export type Slot = {
    id: string,
}

local ATTRIBUTE = "RS_WorldCosmetic"

local function encode(slots: { Slot }): string
    if #slots == 0 then
        return "[]"
    end
    local parts = table.create(#slots)
    for i, slot in slots do
        parts[i] = slot.id
    end
    return table.concat(parts, ",")
end

local function decode(raw: unknown): { Slot }
    if typeof(raw) ~= "string" or raw == "" or raw == "[]" then
        return {}
    end
    local slots = {}
    for token in string.gmatch(raw, "[^,]+") do
        local trimmed = string.match(token, "^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            table.insert(slots, { id = trimmed })
        end
    end
    return slots
end

return {
    ATTRIBUTE = ATTRIBUTE,
    encode = encode,
    decode = decode,
}
