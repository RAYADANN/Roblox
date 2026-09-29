--!strict
-- Place / tick income+growth / react / sell / world publish.
-- Place uses the equipped inventory item (handUid).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AttentionLogic = require(ReplicatedStorage.shared.util.AttentionLogic)
local AuctionLogic = require(ReplicatedStorage.shared.util.AuctionLogic)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local ExhibitCatalog = require(ReplicatedStorage.shared.data.ExhibitCatalog)
local ExhibitLogic = require(ReplicatedStorage.shared.util.ExhibitLogic)
local ExhibitModule = require(ReplicatedStorage.shared.types.Exhibit)
local FavoriteLogic = require(ReplicatedStorage.shared.util.FavoriteLogic)
local MutationDatabase = require(ReplicatedStorage.shared.data.MutationDatabase)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local PlotManager = require(script.Parent.PlotManager)
local ProfileManager = require(script.Parent.ProfileManager)
local WorldCosmeticPublisher = require(script.Parent.WorldCosmeticPublisher)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)

type PlayerData = PlayerDataModule.PlayerData
type ExhibitInstance = ExhibitModule.ExhibitInstance
type HudSyncPayload = NetTypes.HudSyncPayload
type WorldExhibitPub = NetTypes.WorldExhibitPub

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    plotManager: PlotManager.PlotManager,
    syncHud: (player: Player, payload: HudSyncPayload?) -> (),
    publishWorld: (pubs: { WorldExhibitPub }) -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
}

local ExhibitManager = {}
ExhibitManager.__index = ExhibitManager

local function nowSec(): number
    return os.clock()
end

local function wallSec(): number
    return os.time()
end

local function ensureInventory(d: PlayerData)
    if not d.inventory then
        d.inventory = {}
    end
end

local function ensureFavorite(d: PlayerData)
    if not d.favoriteSlots then
        d.favoriteSlots = PlayerDataModule.emptyFavoriteSlots()
    end
    if typeof(d.favoriteBank) ~= "number" then
        d.favoriteBank = 0
    end
end

local function findInvIndex(d: PlayerData, uid: string): number?
    ensureInventory(d)
    for i, item in d.inventory do
        if item.uid == uid then
            return i
        end
    end
    return nil
end

local function takeFromInventory(d: PlayerData, uid: string): ExhibitInstance?
    local index = findInvIndex(d, uid)
    if index == nil then
        return nil
    end
    return table.remove(d.inventory, index :: number)
end

local function ensureMutations(ex: ExhibitInstance)
    if not ex.mutations then
        ex.mutations = {}
    end
    if typeof(ex.npcShunned) ~= "boolean" then
        ex.npcShunned = false
    end
    if typeof(ex.celebrateUntil) ~= "number" then
        ex.celebrateUntil = 0
    end
    if typeof(ex.celebrateKind) ~= "string" then
        ex.celebrateKind = ""
    end
end

local function startCelebrate(ex: ExhibitInstance, now: number, kind: string, durationSec: number)
    ex.celebrateUntil = now + durationSec
    ex.celebrateKind = kind
end

local function applyNamedMutation(ex: ExhibitInstance, mutationId: string, now: number): boolean
    ensureMutations(ex)
    if #ex.mutations >= MutationDatabase.MAX_STACKS then
        return false
    end
    for _, id in ex.mutations do
        if id == mutationId then
            return false
        end
    end
    table.insert(ex.mutations, mutationId)
    ex.mutated = true
    ex.mutationStacks = #ex.mutations
    startCelebrate(ex, now, "mutate", MutationDatabase.CELEBRATE_SEC)
    return true
end

function ExhibitManager.new(deps: Deps)
    return setmetatable({
        _deps = deps,
        _reactCooldown = {} :: { [string]: number },
        _accum = 0,
        _conn = nil :: RBXScriptConnection?,
    }, ExhibitManager)
end

function ExhibitManager:selectHand(player: Player, itemUid: string): (boolean, string?)
    if typeof(itemUid) ~= "string" or itemUid == "" then
        return false, "invalid_uid"
    end
    local data = self._deps.profileManager:get(player)
    if not data then
        return false, "no_profile"
    end
    ensureInventory(data)
    if findInvIndex(data, itemUid) == nil then
        return false, "not_in_inventory"
    end
    local ok = self._deps.profileManager:mutate(player, function(d: PlayerData)
        if findInvIndex(d, itemUid) == nil then
            return
        end
        d.handUid = itemUid
    end)
    if not ok then
        return false, "mutate_failed"
    end
    self:_afterChange(player)
    return true, nil
end

function ExhibitManager:place(player: Player, slotIndex: number): (boolean, string?)
    if not ExhibitLogic.isValidSlot(slotIndex) then
        return false, "invalid_slot"
    end
    local plot = self._deps.plotManager:getByPlayer(player)
    if not plot then
        return false, "no_plot"
    end
    local data = self._deps.profileManager:get(player)
    if not data then
        return false, "no_profile"
    end
    ensureInventory(data)
    local handUid = data.handUid
    if not handUid or handUid == "" then
        return false, "no_hand"
    end
    if findInvIndex(data, handUid) == nil then
        return false, "no_hand"
    end
    if data.slots[slotIndex] ~= nil then
        return false, "slot_occupied"
    end

    local ok = self._deps.profileManager:mutate(player, function(d: PlayerData)
        ensureInventory(d)
        local uid = d.handUid
        if not uid or d.slots[slotIndex] ~= nil then
            return
        end
        local ex = takeFromInventory(d, uid)
        if not ex then
            d.handUid = nil
            return
        end
        d.handUid = nil
        -- Auto-equip next inventory item if any.
        if #d.inventory > 0 then
            d.handUid = d.inventory[1].uid
        end
        ex.placedAt = wallSec()
        ex.slotIndex = slotIndex
        ex.evolveProgress = 0
        ex.evolved = false
        -- Keep egg starting mutations; growth can still add more stacks.
        ensureMutations(ex)
        ex.mutationStacks = #ex.mutations
        ex.mutated = #ex.mutations > 0
        ex.celebrateUntil = 0
        ex.celebrateKind = ""
        local npcBase, shunned = ExhibitLogic.rollCrowd(ex.rarity, math.random(), math.random())
        ex.npcBase = npcBase
        ex.npcShunned = shunned
        ex.animId = ExhibitLogic.pickAnim(math.random())
        ex.attention = 0
        ex.incomeRate = ExhibitLogic.incomeAt(ex.rarity, 0, 0)
        d.slots[slotIndex] = ex
        d.plotId = plot.id
    end)
    if not ok then
        return false, "mutate_failed"
    end
    self:_afterChange(player)
    return true, nil
end

function ExhibitManager:removeToInventory(player: Player, slotIndex: number): (boolean, string?)
    if not ExhibitLogic.isValidSlot(slotIndex) then
        return false, "invalid_slot"
    end
    local data = self._deps.profileManager:get(player)
    if not data then
        return false, "no_profile"
    end
    ensureInventory(data)
    if data.slots[slotIndex] == nil then
        return false, "empty_slot"
    end
    if #data.inventory >= Constants.INVENTORY_MAX then
        return false, "inventory_full"
    end
    local ok = self._deps.profileManager:mutate(player, function(d: PlayerData)
        ensureInventory(d)
        if d.slots[slotIndex] == nil or #d.inventory >= Constants.INVENTORY_MAX then
            return
        end
        local ex = d.slots[slotIndex] :: ExhibitInstance
        d.slots[slotIndex] = nil
        ex.placedAt = nil
        ex.slotIndex = nil
        table.insert(d.inventory, ex)
        if d.handUid == nil or d.handUid == "" then
            d.handUid = ex.uid
        end
    end)
    if not ok then
        return false, "mutate_failed"
    end
    self:_afterChange(player)
    return true, nil
end

-- Back-compat alias used by Zap RemoveExhibit.
function ExhibitManager:removeToHand(player: Player, slotIndex: number): (boolean, string?)
    return self:removeToInventory(player, slotIndex)
end

function ExhibitManager:sell(player: Player, slotIndex: number): (boolean, string?, number?)
    -- Instant sell removed from UI; keep server path for DevCommands / fallback.
    if not ExhibitLogic.isValidSlot(slotIndex) then
        return false, "invalid_slot", nil
    end
    local data = self._deps.profileManager:get(player)
    if not data or data.slots[slotIndex] == nil then
        return false, "empty_slot", nil
    end
    local ex = data.slots[slotIndex] :: ExhibitInstance
    local progress = ex.evolveProgress
    if ex.placedAt and not ex.evolved then
        progress = ExhibitLogic.progress(wallSec() - ex.placedAt, ex.rarity)
    end
    local price =
        ExhibitLogic.sellPrice(ex.rarity, progress, ex.mutated, ex.baseIncome, ex.mutationStacks)
    local ok = self._deps.profileManager:mutate(player, function(d: PlayerData)
        if d.slots[slotIndex] == nil then
            return
        end
        d.slots[slotIndex] = nil
        d.coins += price
    end)
    if not ok then
        return false, "mutate_failed", nil
    end
    self._deps.notify(player, "sold", tostring(price))
    self:_afterChange(player)
    return true, nil, price
end

function ExhibitManager:moveToFavorite(player: Player, slotIndex: number): (boolean, string?)
    if not ExhibitLogic.isValidSlot(slotIndex) then
        return false, "invalid_slot"
    end
    local data = self._deps.profileManager:get(player)
    if not data then
        return false, "no_profile"
    end
    ensureFavorite(data)
    local ex = data.slots[slotIndex]
    if not ex then
        return false, "empty_slot"
    end
    if not ex.evolved then
        return false, "not_grown"
    end
    if data.auctionHold ~= nil then
        return false, "auction_busy"
    end
    if FavoriteLogic.firstEmpty(data.favoriteSlots) == nil then
        return false, "favorite_full"
    end

    local ok = self._deps.profileManager:mutate(player, function(d: PlayerData)
        ensureFavorite(d)
        local slotEx = d.slots[slotIndex]
        if not slotEx or not slotEx.evolved then
            return
        end
        local favIndex = FavoriteLogic.firstEmpty(d.favoriteSlots)
        if favIndex == nil then
            return
        end
        d.slots[slotIndex] = nil
        slotEx.placedAt = wallSec()
        slotEx.slotIndex = favIndex
        d.favoriteSlots[favIndex] = slotEx
    end)
    if not ok then
        return false, "mutate_failed"
    end
    self._deps.notify(player, "favorite", "Placed on Favorite")
    self:_afterChange(player)
    return true, nil
end

function ExhibitManager:collectFavoriteBank(player: Player): (boolean, string?, number?)
    local data = self._deps.profileManager:get(player)
    if not data then
        return false, "no_profile", nil
    end
    ensureFavorite(data)
    local amount = math.floor(data.favoriteBank + 0.5)
    if amount <= 0 then
        return false, "empty_bank", nil
    end
    local ok = self._deps.profileManager:mutate(player, function(d: PlayerData)
        ensureFavorite(d)
        local payout = math.floor(d.favoriteBank + 0.5)
        if payout <= 0 then
            return
        end
        d.coins += payout
        d.favoriteBank = 0
    end)
    if not ok then
        return false, "mutate_failed", nil
    end
    self._deps.notify(player, "collect", tostring(amount))
    self:_afterChange(player)
    return true, nil, amount
end

function ExhibitManager:react(
    reactor: Player,
    ownerUserId: number,
    slotIndex: number
): (boolean, string?)
    if reactor.UserId == ownerUserId then
        return false, "self_react"
    end
    if not ExhibitLogic.isValidSlot(slotIndex) then
        return false, "invalid_slot"
    end
    local key = `{reactor.UserId}:{ownerUserId}:{slotIndex}`
    local last = self._reactCooldown[key] or 0
    if nowSec() - last < AttentionLogic.cooldownSec() then
        return false, "cooldown"
    end
    local owner: Player? = nil
    for _, p in Players:GetPlayers() do
        if p.UserId == ownerUserId then
            owner = p
            break
        end
    end
    if not owner then
        return false, "owner_offline"
    end
    local data = self._deps.profileManager:get(owner)
    if not data or data.slots[slotIndex] == nil then
        return false, "empty_slot"
    end
    local ok = self._deps.profileManager:mutate(owner, function(d: PlayerData)
        local ex = d.slots[slotIndex]
        if not ex then
            return
        end
        ex.attention = AttentionLogic.applyReact(ex.attention)
    end)
    if not ok then
        return false, "mutate_failed"
    end
    self._reactCooldown[key] = nowSec()
    self:_afterChange(owner)
    self._deps.notify(owner, "react", reactor.Name)
    return true, nil
end

function ExhibitManager:_afterChange(player: Player)
    self._deps.syncHud(player, nil)
    self:publishAll()
    WorldCosmeticPublisher.syncHeldEgg(player, self._deps.profileManager:get(player))
end

function ExhibitManager:buildWorldPubs(): { WorldExhibitPub }
    local pubs: { WorldExhibitPub } = {}
    local now = wallSec()
    for _, player in Players:GetPlayers() do
        local data = self._deps.profileManager:get(player)
        local plot = self._deps.plotManager:getByPlayer(player)
        if data and plot then
            for i = 1, ExhibitCatalog.SLOT_COUNT do
                local ex = data.slots[i]
                if ex then
                    local progress = ex.evolveProgress
                    if ex.placedAt and not ex.evolved then
                        progress = ExhibitLogic.progress(now - ex.placedAt, ex.rarity)
                    elseif ex.evolved then
                        progress = 1
                    end
                    local duration = ExhibitLogic.evolveDuration(ex.rarity)
                    local remaining = 0
                    if not ex.evolved and progress < 1 then
                        remaining = math.max(0, duration * (1 - progress))
                    end
                    local template = ExhibitCatalog.byId[ex.templateId]
                    ensureMutations(ex)
                    local npcBase = if typeof(ex.npcBase) == "number" then ex.npcBase else 0
                    local animId = ex.animId
                    if typeof(animId) ~= "string" or animId == "" then
                        animId = "spin"
                    end
                    local stacks = #ex.mutations
                    local mutationLabel = MutationLogic.formatLabel(ex.mutations)
                    local celebrateUntil = ex.celebrateUntil or 0
                    local celebrateKind = ex.celebrateKind or ""
                    table.insert(pubs, {
                        ownerUserId = player.UserId,
                        plotId = plot.id,
                        slotIndex = i,
                        uid = ex.uid,
                        templateId = ex.templateId,
                        rarity = ex.rarity,
                        displayName = ex.displayName,
                        progress = progress,
                        remainingSec = remaining,
                        evolveDurationSec = duration,
                        incomeRate = ExhibitLogic.incomeAt(ex.rarity, progress, ex.attention),
                        highlightT = ExhibitLogic.highlightTransparency(progress, ex.evolved),
                        npcTarget = ExhibitLogic.npcTargetCount(npcBase, progress, ex.evolved),
                        evolved = ex.evolved,
                        mutated = ex.mutated or stacks > 0,
                        mutationStacks = stacks,
                        mutationLabel = mutationLabel,
                        celebrateUntil = celebrateUntil,
                        celebrateKind = celebrateKind,
                        animId = animId,
                        sellPrice = ExhibitLogic.sellPrice(
                            ex.rarity,
                            progress,
                            ex.mutated or stacks > 0,
                            ex.baseIncome,
                            stacks
                        ),
                        auctionValue = AuctionLogic.targetValue(
                            ex.rarity,
                            ex.sizeId or "medium",
                            stacks,
                            data.rebirths or 0
                        ),
                        scale = ExhibitLogic.visualScale(
                            progress,
                            ex.mutated or stacks > 0,
                            ex.sizeId or "medium",
                            ex.mutations
                        ),
                        sizeId = ex.sizeId or "medium",
                        colorRgb = if template then template.colorRgb else { 100, 100, 100 },
                        auctioning = false,
                        auctionPhase = "",
                        auctionBidsJson = "[]",
                        auctionCurrentBid = 0,
                        auctionBidderCount = 0,
                        isFavorite = false,
                    })
                end
            end

            ensureFavorite(data)
            for i = 1, FavoriteLogic.slotCount() do
                local ex = data.favoriteSlots[i]
                if ex then
                    ensureMutations(ex)
                    local template = ExhibitCatalog.byId[ex.templateId]
                    local stacks = #ex.mutations
                    local npcBase = if typeof(ex.npcBase) == "number" then ex.npcBase else 0
                    local animId = if typeof(ex.animId) == "string" and ex.animId ~= ""
                        then ex.animId
                        else "spin"
                    local rate = ExhibitLogic.incomeAt(ex.rarity, 1, ex.attention)
                    local sizeId = ex.sizeId or "medium"
                    table.insert(pubs, {
                        ownerUserId = player.UserId,
                        plotId = plot.id,
                        slotIndex = i,
                        uid = ex.uid,
                        templateId = ex.templateId,
                        rarity = ex.rarity,
                        displayName = ex.displayName,
                        progress = 1,
                        remainingSec = 0,
                        evolveDurationSec = ExhibitLogic.evolveDuration(ex.rarity),
                        incomeRate = rate,
                        highlightT = ExhibitLogic.highlightTransparency(1, true),
                        npcTarget = ExhibitLogic.npcTargetCount(npcBase, 1, true),
                        evolved = true,
                        mutated = ex.mutated or stacks > 0,
                        mutationStacks = stacks,
                        mutationLabel = MutationLogic.formatLabel(ex.mutations),
                        celebrateUntil = ex.celebrateUntil or 0,
                        celebrateKind = ex.celebrateKind or "",
                        animId = animId,
                        sellPrice = ExhibitLogic.sellPrice(
                            ex.rarity,
                            1,
                            ex.mutated or stacks > 0,
                            ex.baseIncome,
                            stacks
                        ),
                        auctionValue = AuctionLogic.targetValue(
                            ex.rarity,
                            sizeId,
                            stacks,
                            data.rebirths or 0
                        ),
                        scale = ExhibitLogic.visualScale(1, stacks > 0, sizeId, ex.mutations),
                        sizeId = sizeId,
                        colorRgb = if template then template.colorRgb else { 100, 100, 100 },
                        auctioning = false,
                        auctionPhase = "",
                        auctionBidsJson = "[]",
                        auctionCurrentBid = 0,
                        auctionBidderCount = 0,
                        isFavorite = true,
                    })
                end
            end
        end
    end
    return pubs
end

function ExhibitManager:publishAll()
    local pubs = self:buildWorldPubs()
    self._deps.publishWorld(pubs)
    local occupied: { [number]: boolean } = {}
    for _, pub in pubs do
        if not pub.isFavorite then
            occupied[pub.slotIndex] = true
        end
    end
    self._deps.plotManager:syncStandFx(occupied)
end

function ExhibitManager:_tickPlayer(player: Player, dt: number)
    local data = self._deps.profileManager:get(player)
    if not data then
        return
    end
    local now = wallSec()
    local changed = false
    local mutatedNotify: string? = nil
    local evolvedNotify: string? = nil
    self._deps.profileManager:mutate(player, function(d: PlayerData)
        for i = 1, ExhibitCatalog.SLOT_COUNT do
            local ex = d.slots[i]
            if ex and ex.placedAt then
                ensureMutations(ex)
                if typeof(ex.npcBase) ~= "number" then
                    local npcBase, shunned =
                        ExhibitLogic.rollCrowd(ex.rarity, math.random(), math.random())
                    ex.npcBase = npcBase
                    ex.npcShunned = shunned
                    changed = true
                end
                if typeof(ex.animId) ~= "string" or ex.animId == "" then
                    ex.animId = ExhibitLogic.pickAnim(math.random())
                    changed = true
                end

                local progress = if ex.evolved
                    then 1
                    else ExhibitLogic.progress(now - ex.placedAt, ex.rarity)
                local npcTarget = ExhibitLogic.npcTargetCount(ex.npcBase, progress, ex.evolved)
                local prevAtt = ex.attention
                ex.attention = AttentionLogic.npcDrip(ex.attention, npcTarget, dt)
                if ex.attention ~= prevAtt then
                    changed = true
                end
                local rate = ExhibitLogic.incomeAt(ex.rarity, progress, ex.attention)
                if ex.incomeRate ~= rate or ex.evolveProgress ~= progress then
                    changed = true
                end
                ex.incomeRate = rate
                ex.evolveProgress = progress
                -- No pocket income while growing. Passive income only on Favorite stands.
                if not ex.evolved and progress < 1 then
                    if ex.npcShunned or ex.npcBase <= 0 then
                        if
                            MutationLogic.rollLonelyDuringGrowth(
                                ex.rarity,
                                dt,
                                MutationLogic.hasLonely(ex.mutations),
                                math.random()
                            )
                        then
                            local lonelyId = MutationLogic.pickLonelyId(ex.mutations, math.random())
                            if lonelyId and applyNamedMutation(ex, lonelyId, now) then
                                mutatedNotify = MutationLogic.formatLabel(ex.mutations)
                                changed = true
                            end
                        end
                    end

                    if
                        MutationLogic.rollDuringGrowth(
                            ex.rarity,
                            dt,
                            #ex.mutations > 0,
                            math.random()
                        )
                    then
                        local growthId = MutationLogic.pickGrowthId(ex.mutations, math.random())
                        if growthId and applyNamedMutation(ex, growthId, now) then
                            mutatedNotify = MutationLogic.formatLabel(ex.mutations)
                            changed = true
                        end
                    end
                end

                if not ex.evolved and progress >= 1 then
                    ex.evolved = true
                    ex.evolveProgress = 1
                    if
                        #ex.mutations == 0 and MutationLogic.shouldMutate(ex.rarity, math.random())
                    then
                        local growthId = MutationLogic.pickGrowthId(ex.mutations, math.random())
                        if growthId and applyNamedMutation(ex, growthId, now) then
                            mutatedNotify = MutationLogic.formatLabel(ex.mutations)
                        end
                    end
                    -- Evolve is the rare spectacle — NPCs rush here.
                    startCelebrate(ex, now, "evolve", MutationDatabase.EVOLVE_CELEBRATE_SEC)
                    evolvedNotify = ex.displayName
                    changed = true
                end
            end
        end
        ensureFavorite(d)
        local bankGain = 0
        for i = 1, FavoriteLogic.slotCount() do
            local fav = d.favoriteSlots[i]
            if fav then
                ensureMutations(fav)
                if typeof(fav.npcBase) ~= "number" then
                    local npcBase, shunned =
                        ExhibitLogic.rollCrowd(fav.rarity, math.random(), math.random())
                    fav.npcBase = npcBase
                    fav.npcShunned = shunned
                end
                local npcTarget = ExhibitLogic.npcTargetCount(fav.npcBase, 1, true)
                fav.attention = AttentionLogic.npcDrip(fav.attention, npcTarget, dt)
                local rate = ExhibitLogic.incomeAt(fav.rarity, 1, fav.attention)
                fav.incomeRate = rate
                bankGain += rate * dt
            end
        end
        if bankGain > 0 then
            d.favoriteBank += bankGain
            changed = true
        end
    end)
    if evolvedNotify then
        self._deps.notify(player, "evolved", evolvedNotify)
    end
    if mutatedNotify then
        self._deps.notify(player, "mutated", mutatedNotify)
    end
    if changed then
        self._deps.syncHud(
            player,
            buildHudPayload.fromPlayerData(self._deps.profileManager:get(player) :: PlayerData, now)
        )
    end
end

function ExhibitManager:start()
    local selfAny = self :: any
    if selfAny._conn then
        return
    end
    selfAny._conn = RunService.Heartbeat:Connect(function(dt)
        selfAny._accum += dt
        local tickSec = ExhibitCatalog.INCOME_TICK_SEC
        if selfAny._accum < tickSec then
            return
        end
        local step = selfAny._accum
        selfAny._accum = 0
        for _, player in Players:GetPlayers() do
            self:_tickPlayer(player, step)
        end
        self:publishAll()
    end)
end

function ExhibitManager:stop()
    local selfAny = self :: any
    if selfAny._conn then
        selfAny._conn:Disconnect()
        selfAny._conn = nil
    end
end

return ExhibitManager
