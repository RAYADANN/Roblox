--!strict
-- Pure: move containers between inventory and ramp slots.

local ContainerPlacementLogic = {}

export type Placeable = {
    placedAt: number?,
    slotIndex: number?,
    unpackProgress: number,
    unpacked: boolean,
    incomeRate: number?,
}

--- Lift from ramp → inventory/hand. Keeps hero/unpack state.
function ContainerPlacementLogic.toInventory(item: Placeable)
    item.placedAt = nil
    item.slotIndex = nil
    -- unpacked / unpackProgress / incomeRate stay (re-place as hero or resume box).
end

--- Put from hand onto a slot.
--- Already-unpacked heroes stay open; sealed boxes restart unpack.
function ContainerPlacementLogic.applyPlace(item: Placeable, slotIndex: number, now: number)
    item.placedAt = now
    item.slotIndex = slotIndex
    if item.unpacked == true then
        item.unpackProgress = 1
        -- incomeRate already set from first open
    else
        item.unpackProgress = 0
        item.unpacked = false
    end
end

function ContainerPlacementLogic.canPickup(
    unpacked: boolean,
    inventoryCount: number,
    inventoryMax: number
): (boolean, string?)
    if not unpacked then
        return false, "not_unpacked"
    end
    if inventoryCount >= inventoryMax then
        return false, "inventory_full"
    end
    return true, nil
end

return ContainerPlacementLogic
