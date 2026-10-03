--!strict
-- Ramp slots as string-keyed map for DataStore (no sparse numeric arrays).

local Constants
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
else
    Constants = require("../data/Constants")
end

export type SlotTable = { [string]: any }

local SlotMap = {}

function SlotMap.key(slotIndex: number): string
    return tostring(math.floor(slotIndex))
end

function SlotMap.empty(): SlotTable
    return {}
end

function SlotMap.get(slots: SlotTable?, slotIndex: number): any?
    if slots == nil then
        return nil
    end
    local idx = math.floor(slotIndex)
    if idx < 1 or idx > Constants.SLOT_COUNT then
        return nil
    end
    local byStr = slots[SlotMap.key(idx)]
    if byStr ~= nil then
        return byStr
    end
    -- Legacy numeric-array profiles (pre SlotMap).
    return (slots :: any)[idx]
end

function SlotMap.set(slots: SlotTable, slotIndex: number, item: any?)
    local idx = math.floor(slotIndex)
    if idx < 1 or idx > Constants.SLOT_COUNT then
        return
    end
    local k = SlotMap.key(idx)
    if item == nil then
        slots[k] = nil;
        (slots :: any)[idx] = nil
    else
        if typeof(item) == "table" then
            item.slotIndex = idx
        end
        slots[k] = item;
        (slots :: any)[idx] = nil
    end
end

--- Rewrite any legacy numeric / mixed form into string keys only.
function SlotMap.normalize(raw: any): SlotTable
    local out = SlotMap.empty()
    if typeof(raw) ~= "table" then
        return out
    end
    local seen: { [number]: boolean } = {}
    for key, value in raw :: { [any]: any } do
        if typeof(value) ~= "table" then
            continue
        end
        local idx: number? = nil
        if typeof(key) == "string" then
            idx = tonumber(key)
        elseif typeof(key) == "number" then
            idx = key
        end
        if idx == nil and typeof(value.slotIndex) == "number" then
            idx = value.slotIndex
        end
        if idx == nil then
            continue
        end
        local i = math.floor(idx)
        if i < 1 or i > Constants.SLOT_COUNT or seen[i] then
            continue
        end
        seen[i] = true
        value.slotIndex = i
        out[SlotMap.key(i)] = value
    end
    return out
end

function SlotMap.hasAny(slots: SlotTable?): boolean
    if slots == nil then
        return false
    end
    for i = 1, Constants.SLOT_COUNT do
        if SlotMap.get(slots, i) ~= nil then
            return true
        end
    end
    return false
end

--- Dense list of occupied slot payloads (for income / iteration helpers).
function SlotMap.toList(slots: SlotTable?): { any }
    local list = {}
    if slots == nil then
        return list
    end
    for i = 1, Constants.SLOT_COUNT do
        local slot = SlotMap.get(slots, i)
        if slot ~= nil then
            table.insert(list, slot)
        end
    end
    return list
end

return SlotMap
