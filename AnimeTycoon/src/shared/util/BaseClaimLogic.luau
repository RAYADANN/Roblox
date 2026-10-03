--!strict
-- Pure helpers for assigning Base1..BaseN to players.

local BaseClaimLogic = {}

--- First free base index in 1..baseCount, or nil if full.
function BaseClaimLogic.pickFreeIndex(occupied: { [number]: number }, baseCount: number): number?
    local n = math.max(0, math.floor(baseCount))
    for i = 1, n do
        if occupied[i] == nil then
            return i
        end
    end
    return nil
end

--- Remove player from occupied map (baseIndex → userId). Returns freed index or nil.
function BaseClaimLogic.releaseUser(occupied: { [number]: number }, userId: number): number?
    for index, uid in occupied do
        if uid == userId then
            occupied[index] = nil
            return index
        end
    end
    return nil
end

--- Index currently held by userId, or nil.
function BaseClaimLogic.indexForUser(occupied: { [number]: number }, userId: number): number?
    for index, uid in occupied do
        if uid == userId then
            return index
        end
    end
    return nil
end

return BaseClaimLogic
