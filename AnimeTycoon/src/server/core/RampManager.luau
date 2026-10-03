--!strict
-- Ramp slots: place container, unpack tick, spawn minis → SellBox deposit.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BoxVisualLogic = require(ReplicatedStorage.shared.util.BoxVisualLogic)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local ContainerLogic = require(ReplicatedStorage.shared.util.ContainerLogic)
local ContainerModule = require(ReplicatedStorage.shared.types.Container)
local ContainerPlacementLogic = require(ReplicatedStorage.shared.util.ContainerPlacementLogic)
local ConveyorLogic = require(ReplicatedStorage.shared.util.ConveyorLogic)
local HeroCatalog = require(ReplicatedStorage.shared.data.HeroCatalog)
local HeroLevelLogic = require(ReplicatedStorage.shared.util.HeroLevelLogic)
local IndexLogic = require(ReplicatedStorage.shared.util.IndexLogic)
local LimitedLogic = require(ReplicatedStorage.shared.util.LimitedLogic)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local ProfileManager = require(script.Parent.ProfileManager)
local SlotMap = require(ReplicatedStorage.shared.util.SlotMap)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)

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
    depositSellBox: (player: Player, amount: number) -> (),
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

    if not UpgradeLogic.isSlotUnlocked(data.upgrades, idx) then
        return false, "slot_locked"
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
        d.slots = SlotMap.normalize(d.slots)
        if SlotMap.get(d.slots, idx) ~= nil then
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
        local limitedOffer = LimitedLogic.offerFromTemplateId(item.templateId)
        if limitedOffer then
            LimitedLogic.syncContainerFromOffer(item, limitedOffer)
        end
        ContainerPlacementLogic.applyPlace(item, idx, os.time())
        if
            item.unpacked ~= true
            or typeof(item.incomeRate) ~= "number"
            or (item.incomeRate :: number) <= 0
        then
            item.incomeRate = ContainerLogic.incomePerMini(item.rarity, item.mutations)
        end
        HeroLevelLogic.syncIncome(item)
        SlotMap.set(d.slots, idx, item)
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
                local slot = SlotMap.get(data.slots, i)
                if slot then
                    local timeMult = UpgradeLogic.unpackTimeMultiplier(data.upgrades)
                    local placedAt = tonumber(slot.placedAt) or os.time()
                    local fast = slot.fastUnpack == true
                    local unpackEndsAt = if slot.unpacked
                        then 0
                        else ContainerLogic.unpackEndsAt(placedAt, slot.rarity, timeMult, fast)
                    local limitedOffer = LimitedLogic.offerFromTemplateId(slot.templateId)
                    if limitedOffer then
                        LimitedLogic.syncContainerFromOffer(slot, limitedOffer)
                    end
                    local muts = MutationLogic.normalizeStack(slot.mutations)
                    HeroLevelLogic.syncIncome(slot)
                    local level = HeroLevelLogic.normalize(slot.level)
                    local levelCost = 0
                    if slot.unpacked == true then
                        local base =
                            HeroLevelLogic.basePerMini(slot.rarity, slot.mutations, slot.baseIncome)
                        levelCost = HeroLevelLogic.upgradeCost(
                            base,
                            ContainerLogic.produceInterval(slot.rarity),
                            level
                        ) or 0
                    end
                    table.insert(rows, {
                        ownerUserId = player.UserId,
                        slotIndex = slot.slotIndex or i,
                        uid = slot.uid,
                        templateId = slot.templateId,
                        boxModelName = slot.boxModelName,
                        rarity = slot.rarity,
                        heroId = slot.heroId,
                        displayName = if slot.unpacked
                            then HeroCatalog.displayName(slot.displayName or slot.heroId or "")
                            else BoxVisualLogic.formatCaseDisplayName(slot.boxModelName or ""),
                        unpackProgress = slot.unpackProgress,
                        unpacked = slot.unpacked,
                        unpackEndsAt = unpackEndsAt,
                        mutations = muts,
                        mutationLabel = MutationLogic.formatLabel(muts),
                        incomeRate = slot.incomeRate,
                        level = level,
                        levelCost = levelCost,
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

-- Per-owner pad prompts: occupied / ready / packing / holding.
function RampManager:buildPromptStates(): {
    [number]: {
        [number]: {
            occupied: boolean,
            ready: boolean,
            packing: boolean,
            holding: boolean,
        },
    },
}
    local deps = (self :: any)._deps
    local pm = deps.profileManager
    local Players = game:GetService("Players")
    local byOwner: {
        [number]: {
            [number]: {
                occupied: boolean,
                ready: boolean,
                packing: boolean,
                holding: boolean,
            },
        },
    } =
        {}

    for _, player in Players:GetPlayers() do
        local data = pm:get(player)
        local states: {
            [number]: {
                occupied: boolean,
                ready: boolean,
                packing: boolean,
                holding: boolean,
            },
        } =
            {}
        for i = 1, Constants.SLOT_COUNT do
            states[i] = {
                occupied = false,
                ready = false,
                packing = false,
                holding = false,
            }
        end
        if data and data.slots then
            for i = 1, Constants.SLOT_COUNT do
                local slot = SlotMap.get(data.slots, i)
                if not slot then
                    continue
                end
                local idx = slot.slotIndex or i
                if idx < 1 or idx > Constants.SLOT_COUNT then
                    continue
                end
                local state = states[idx]
                state.occupied = true
                if slot.unpacked then
                    state.holding = true
                else
                    local progress = tonumber(slot.unpackProgress) or 0
                    if progress >= 0.999 then
                        state.ready = true
                    else
                        state.packing = true
                    end
                end
            end
        end
        byOwner[player.UserId] = states
    end
    return byOwner
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
            local timeMult = UpgradeLogic.unpackTimeMultiplier(d.upgrades)
            for i = 1, Constants.SLOT_COUNT do
                local slot = SlotMap.get(d.slots, i)
                if not slot or slot.unpacked or not slot.placedAt then
                    continue
                end
                local elapsed = math.max(0, now - slot.placedAt)
                local progress = ContainerLogic.unpackProgress(
                    elapsed,
                    slot.rarity,
                    timeMult,
                    slot.fastUnpack == true
                )
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
-- force=true: Robux skip — open while still packing.
function RampManager:open(player: Player, slotIndex: number, force: boolean?): (boolean, string?)
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
        mutations: { string },
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
        local slot = SlotMap.get(d.slots, idx)
        if not slot then
            failReason = "empty_slot"
            return
        end
        if slot.unpacked then
            failReason = "already_open"
            return
        end
        if force ~= true and (slot.unpackProgress or 0) < 1 then
            failReason = "not_ready"
            return
        end

        slot.unpacked = true
        slot.unpackProgress = 1
        -- Mutation only from purchase — never rolled on open.
        slot.mutations = MutationLogic.normalizeStack(slot.mutations)
        if slot.level == nil then
            slot.level = 1
        end
        HeroLevelLogic.syncIncome(slot)
        if d.indexFound == nil then
            d.indexFound = {}
        end
        local mutId: string? = if #slot.mutations > 0 then slot.mutations[1] else nil
        IndexLogic.addFound(d.indexFound, slot.heroId or "", mutId)
        local key = produceKey(player.UserId, slot.slotIndex or idx);
        (self :: any)._produce[key] = { lastProduceAt = os.clock() }

        reveal = {
            heroId = slot.heroId,
            displayName = HeroCatalog.displayName(slot.displayName or slot.heroId or ""),
            rarity = slot.rarity,
            mutations = table.clone(slot.mutations),
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
            mutations = reveal.mutations,
            mutationLabel = reveal.mutationLabel,
            slotIndex = reveal.slotIndex,
            incomeRate = reveal.incomeRate,
        })
    )
    return true, nil
end

--- Robux / Studio skip: open while still packing.
function RampManager:skipUnpack(player: Player, slotIndex: number): (boolean, string?)
    if typeof(slotIndex) ~= "number" then
        return false, "invalid_slot"
    end
    local idx = math.floor(slotIndex)
    if idx < 1 or idx > Constants.SLOT_COUNT then
        return false, "invalid_slot"
    end
    local deps = (self :: any)._deps
    local data = deps.profileManager:get(player)
    if not data or not data.slots then
        return false, "no_profile"
    end
    local slot = SlotMap.get(data.slots, idx)
    if not slot then
        return false, "empty_slot"
    end
    if slot.unpacked then
        return false, "already_open"
    end
    -- Already ready → normal open; still packing → force.
    if (slot.unpackProgress or 0) >= 0.999 then
        return self:open(player, idx, false)
    end
    return self:open(player, idx, true)
end

--- Pick up an unpacked hero → inventory + hand (can Place elsewhere).
function RampManager:pickup(player: Player, slotIndex: number): (boolean, string?)
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

    local slot = data.slots and SlotMap.get(data.slots, idx)
    if not slot then
        return false, "empty_slot"
    end
    local invCount = if data.inventory then #data.inventory else 0
    local can, why =
        ContainerPlacementLogic.canPickup(slot.unpacked == true, invCount, Constants.INVENTORY_MAX)
    if not can then
        return false, why
    end

    local failReason: string? = nil
    local pickedUid: string? = nil
    local ok = pm:mutate(player, function(d: PlayerData)
        if not d.slots then
            failReason = "empty_slot"
            return
        end
        local s = SlotMap.get(d.slots, idx)
        if not s then
            failReason = "empty_slot"
            return
        end
        local count = if d.inventory then #d.inventory else 0
        local allowed, reason =
            ContainerPlacementLogic.canPickup(s.unpacked == true, count, Constants.INVENTORY_MAX)
        if not allowed then
            failReason = reason
            return
        end
        if not d.inventory then
            d.inventory = {}
        end
        ContainerPlacementLogic.toInventory(s)
        table.insert(d.inventory, s)
        d.handUid = s.uid
        pickedUid = s.uid
        SlotMap.set(d.slots, idx, nil)
    end)

    if not ok then
        return false, "no_profile"
    end
    if failReason then
        return false, failReason
    end

    -- Stop producing / in-flight minis for this pad.
    local selfAny = self :: any
    local key = produceKey(player.UserId, idx)
    selfAny._produce[key] = nil
    local remaining: { PendingDelivery } = {}
    for _, delivery in selfAny._pending do
        if delivery.ownerUserId == player.UserId and delivery.slotIndex == idx then
            continue
        end
        table.insert(remaining, delivery)
    end
    selfAny._pending = remaining

    deps.syncHud(player)
    deps.publishWorld()
    deps.notify(player, "picked_up", pickedUid or tostring(idx))
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
            local slot = SlotMap.get(data.slots, i)
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
            HeroLevelLogic.syncIncome(slot)
            local payout = slot.incomeRate
            if typeof(payout) ~= "number" or (payout :: number) <= 0 then
                payout = ContainerLogic.incomePerMini(slot.rarity, slot.mutations)
            end
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
        if player and deps.depositSellBox then
            deps.depositSellBox(player, amount)
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
