--!strict
-- Pure floor/slot ordering for DummyItems layout (6 floors × 6).

local Constants
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
else
    Constants = require("../data/Constants")
end

export type MarkerSortKey = {
    floor: number,
    x: number,
    z: number,
    name: string,
}

local SlotLayoutLogic = {}

--- Floor_01 / Floor1 / Floor_1 → 1
function SlotLayoutLogic.floorIndexFromName(name: string): number?
    local n = string.match(name, "^Floor_0*(%d+)$") or string.match(name, "^Floor(%d+)$")
    if n == nil then
        return nil
    end
    return tonumber(n)
end

function SlotLayoutLogic.expectedSlotCount(): number
    return Constants.SLOT_FLOORS * Constants.SLOTS_PER_FLOOR
end

function SlotLayoutLogic.compareKeys(a: MarkerSortKey, b: MarkerSortKey): boolean
    if a.floor ~= b.floor then
        return a.floor < b.floor
    end
    if math.abs(a.x - b.x) > 0.05 then
        return a.x < b.x
    end
    if math.abs(a.z - b.z) > 0.05 then
        return a.z < b.z
    end
    return a.name < b.name
end

function SlotLayoutLogic.floorFolderName(floorIndex: number): string
    return string.format("Floor_%02d", floorIndex)
end

return SlotLayoutLogic
