--!strict
-- Ramp slots: place container, unpack tick, spawn minis, grant coins.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local ContainerLogic = require(ReplicatedStorage.shared.util.ContainerLogic)
local ContainerModule = require(ReplicatedStorage.shared.types.Container)
local ConveyorLogic = require(ReplicatedStorage.shared.util.ConveyorLogic)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local ProfileManager = require(script.Parent.ProfileManager)

type PlayerData = PlayerDataModule.PlayerData
type ContainerInstance = ContainerModule.ContainerInstance

export type PendingDelivery = {
    ownerUserId: number,
    slotIndex: number,
    amount: number,
    arriveAt: number,
    heroId: string,
}

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player) -> (),
    publishWorld: () -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
    fireMiniSpawned: (
        ownerUserId: number,
        slotIndex: number,
        heroId: string,
        payout: number,
        travelSec: number
    ) -> (),
}

local RampManager = {}
RampManager.__index = RampManager

type ProduceState = {
    lastProduceAt: number,
}

function RampManager.new(deps: Deps)
    return setmetatable({
        _deps = deps,
        _produce = {} :: { [string]: ProduceState }, -- key = userId_slot
        _pending = {} :: { PendingDelivery },
        _conn = nil :: RBXScriptConnection?,
    }, RampManager)
end

local function produceKey(userId: number, slotIndex: number): string
    return `{userId}_{slotIndex}`
end

local function findInventoryIndex(inventory: { ContainerInstance }, uid: string): number?
    for i, item in inventory do
        if item.uid == uid then
            return i
        end
    end
    return nil
end

function RampManager:place(player: Player, slotIndex: number): (boolean, string?)
    if typeof(slotIndex) ~= "number" then
        return false, "invalid_slot"
    end
    local idx = math.floor(slotIndex)
    if idx < 1 or idx > Constants.SLOT_COUNT then
        return false, "invalid_slot"
    end

    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local data = pm:get(player)
    if not data then
        return false, "no_profile"
    end

    local handUid = data.handUid
    if typeof(handUid) ~= "string" or handUid == "" then
        return false, "no_hand"
    end

    local failReason: string? = nil
    local ok = pm:mutate(player, function(d: PlayerData)
        if not d.slots then
            d.slots = PlayerDataModule.emptySlots()
        end
        if d.slots[idx] ~= nil then
            failReason = "slot_occupied"
            return
        end
        local invIdx = findInventoryIndex(d.inventory, d.handUid or "")
        if not invIdx then
            failReason = "hand_missing"
            return
        end
        local item = d.inventory[invIdx]
        table.remove(d.inventory, invIdx)
        item.placedAt = os.time()
        item.slotIndex = idx
        item.unpackProgress = 0
        item.unpacked = false
        item.incomeRate = ContainerLogic.incomePerMini(item.rarity, item.mutations)
        d.slots[idx] = item
        -- Equip next inventory item if any.
        if #d.inventory > 0 then
            d.handUid = d.inventory[1].uid
        else
            d.handUid = nil
        end
    end)

    if not ok then
        return false, "no_profile"
    end
    if failReason then
        return false, failReason
    end

    deps.syncHud(player)
    deps.publishWorld()
    deps.notify(player, "placed", tostring(idx))
    return true, nil
end

function RampManager:buildWorldPayload(): string
    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local Players = game:GetService("Players")
    local rows = {}
    for _, player in Players:GetPlayers() do
        local data = pm:get(player)
        if data and data.slots then
            for i = 1, Constants.SLOT_COUNT do
                local slot = data.slots[i]
                if slot then
                    table.insert(rows, {
                        ownerUserId = player.UserId,
                        slotIndex = slot.slotIndex or i,
                        uid = slot.uid,
                        templateId = slot.templateId,
                        boxModelName = slot.boxModelName,
                        rarity = slot.rarity,
                        heroId = slot.heroId,
                        displayName = slot.displayName,
                        unpackProgress = slot.unpackProgress,
                        unpacked = slot.unpacked,
                        mutations = slot.mutations,
                        mutationLabel = MutationLogic.formatLabel(slot.mutations or {}),
                        incomeRate = slot.incomeRate,
                    })
                end
            end
        end
    end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(rows)
    end)
    if ok and typeof(encoded) == "string" then
        return encoded
    end
    return "[]"
end

-- Per pad index: occupied / ready-to-open (any player on shared HeroPlace).
function RampManager:buildPromptStates(): { [number]: { occupied: boolean, ready: boolean } }
    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local Players = game:GetService("Players")
    local states: { [number]: { occupied: boolean, ready: boolean } } = {}
    for i = 1, Constants.SLOT_COUNT do
        states[i] = { occupied = false, ready = false }
    end
    for _, player in Players:GetPlayers() do
        local data = pm:get(player)
        if not data or not data.slots then
            continue
        end
        for i = 1, Constants.SLOT_COUNT do
            local slot = data.slots[i]
            if not slot then
                continue
            end
            local idx = slot.slotIndex or i
            if idx < 1 or idx > Constants.SLOT_COUNT then
                continue
            end
            local state = states[idx]
            state.occupied = true
            if not slot.unpacked and (tonumber(slot.unpackProgress) or 0) >= 0.999 then
                state.ready = true
            end
        end
    end
    return states
end

function RampManager:_tickUnpack(now: number)
    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local Players = game:GetService("Players")
    local dirtyPlayers: { [Player]: boolean } = {}

    for _, player in Players:GetPlayers() do
        local data = pm:get(player)
        if not data or not data.slots then
            continue
        end
        local changed = false
        pm:mutate(player, function(d: PlayerData)
            for i = 1, Constants.SLOT_COUNT do
                local slot = d.slots[i]
                if not slot or slot.unpacked or not slot.placedAt then
                    continue
                end
                local elapsed = math.max(0, now - slot.placedAt)
                local progress = ContainerLogic.unpackProgress(elapsed, slot.rarity)
                if progress >= 1 then
                    if slot.unpackProgress < 1 then
                        slot.unpackProgress = 1
                        changed = true
                    end
                elseif math.abs(progress - slot.unpackProgress) > 0.01 then
                    slot.unpackProgress = progress
                    changed = true
                end
            end
        end)
        if changed then
            dirtyPlayers[player] = true
        end
    end

    local anyDirty = false
    for player in dirtyPlayers do
        anyDirty = true
        deps.syncHud(player)
    end
    if anyDirty then
        deps.publishWorld()
    end
end

-- Player confirms Open on a ready (progress=1) container.
function RampManager:open(player: Player, slotIndex: number): (boolean, string?)
    if typeof(slotIndex) ~= "number" then
        return false, "invalid_slot"
    end
    local idx = math.floor(slotIndex)
    if idx < 1 or idx > Constants.SLOT_COUNT then
        return false, "invalid_slot"
    end

    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local data = pm:get(player)
    if not data then
        return false, "no_profile"
    end

    local failReason: string? = nil
    local reveal: {
        heroId: string,
        displayName: string,
        rarity: string,
        mutationLabel: string,
        slotIndex: number,
        incomeRate: number,
    }? =
        nil

    local ok = pm:mutate(player, function(d: PlayerData)
        if not d.slots then
            failReason = "empty_slot"
            return
        end
        local slot = d.slots[idx]
        if not slot then
            failReason = "empty_slot"
            return
        end
        if slot.unpacked then
            failReason = "already_open"
            return
        end
        if (slot.unpackProgress or 0) < 1 then
            failReason = "not_ready"
            return
        end

        slot.unpacked = true
        slot.unpackProgress = 1
        local extra = MutationLogic.rollUnpackMutation(
            slot.rarity,
            slot.mutations,
            math.random(),
            math.random()
        )
        if extra then
            table.insert(slot.mutations, extra)
        end
        slot.incomeRate = ContainerLogic.incomePerMini(slot.rarity, slot.mutations)
        local key = produceKey(player.UserId, slot.slotIndex or idx);
        (self :: any)._produce[key] = { lastProduceAt = os.clock() }

        reveal = {
            heroId = slot.heroId,
            displayName = slot.displayName,
            rarity = slot.rarity,
            mutationLabel = MutationLogic.formatLabel(slot.mutations),
            slotIndex = slot.slotIndex or idx,
            incomeRate = slot.incomeRate,
        }
    end)

    if not ok then
        return false, "no_profile"
    end
    if failReason then
        return false, failReason
    end
    if not reveal then
        return false, "open_failed"
    end

    deps.syncHud(player)
    deps.publishWorld()
    deps.notify(
        player,
        "unpacked",
        HttpService:JSONEncode({
            heroId = reveal.heroId,
            displayName = reveal.displayName,
            rarity = reveal.rarity,
            mutationLabel = reveal.mutationLabel,
            slotIndex = reveal.slotIndex,
            incomeRate = reveal.incomeRate,
        })
    )
    return true, nil
end

function RampManager:_tickProduce(now: number)
    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local Players = game:GetService("Players")
    local selfAny = self :: any

    for _, player in Players:GetPlayers() do
        local data = pm:get(player)
        if not data or not data.slots then
            continue
        end
        for i = 1, Constants.SLOT_COUNT do
            local slot = data.slots[i]
            if not slot or not slot.unpacked then
                continue
            end
            local slotIndex = slot.slotIndex or i
            local key = produceKey(player.UserId, slotIndex)
            local state = selfAny._produce[key]
            if not state then
                selfAny._produce[key] = { lastProduceAt = now }
                state = selfAny._produce[key]
            end
            local interval = ContainerLogic.produceInterval(slot.rarity)
            if now - state.lastProduceAt < interval then
                continue
            end
            state.lastProduceAt = now
            local payout = ContainerLogic.incomePerMini(slot.rarity, slot.mutations)
            local travel = ConveyorLogic.travelDuration(slotIndex)
            table.insert(selfAny._pending, {
                ownerUserId = player.UserId,
                slotIndex = slotIndex,
                amount = payout,
                arriveAt = now + travel,
                heroId = slot.heroId,
            })
            deps.fireMiniSpawned(player.UserId, slotIndex, slot.heroId, payout, travel)
        end
    end
end

function RampManager:_tickDeliveries(now: number)
    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local Players = game:GetService("Players")
    local selfAny = self :: any
    local remaining: { PendingDelivery } = {}
    local credited: { [number]: number } = {}

    for _, delivery in selfAny._pending do
        if now < delivery.arriveAt then
            table.insert(remaining, delivery)
            continue
        end
        credited[delivery.ownerUserId] = (credited[delivery.ownerUserId] or 0) + delivery.amount
    end
    selfAny._pending = remaining

    for userId, amount in credited do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            pm:mutate(player, function(d: PlayerData)
                d.coins += amount
            end)
            deps.syncHud(player)
            deps.notify(player, "income", tostring(math.floor(amount + 0.5)))
        end
    end
end

function RampManager:start()
    local selfAny = self :: any
    if selfAny._conn then
        return
    end
    local accum = 0
    selfAny._conn = RunService.Heartbeat:Connect(function(dt)
        accum += dt
        if accum < 0.25 then
            return
        end
        accum = 0
        local now = os.clock()
        -- unpack uses wall clock via placedAt=os.time(); use os.time for unpack
        self:_tickUnpack(os.time())
        self:_tickProduce(now)
        self:_tickDeliveries(now)
    end)
end

return RampManager
