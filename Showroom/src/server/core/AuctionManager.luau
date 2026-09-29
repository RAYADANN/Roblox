--!strict
-- Automatic auction for grown exhibits. Removes from income stand while held.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AuctionLogic = require(ReplicatedStorage.shared.util.AuctionLogic)
local ExhibitCatalog = require(ReplicatedStorage.shared.data.ExhibitCatalog)
local ExhibitLogic = require(ReplicatedStorage.shared.util.ExhibitLogic)
local ExhibitModule = require(ReplicatedStorage.shared.types.Exhibit)
local FavoriteLogic = require(ReplicatedStorage.shared.util.FavoriteLogic)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local PlotManager = require(script.Parent.PlotManager)
local ProfileManager = require(script.Parent.ProfileManager)

type PlayerData = PlayerDataModule.PlayerData
type ExhibitInstance = ExhibitModule.ExhibitInstance
type AuctionHold = PlayerDataModule.AuctionHold
type BidStep = AuctionLogic.BidStep
type WorldExhibitPub = NetTypes.WorldExhibitPub

export type AuctionSyncPayload = {
    phase: string,
    displayName: string,
    rarity: string,
    sizeId: string,
    sizeLabel: string,
    mutationLabel: string,
    mutationCount: number,
    currentBid: number,
    maxBid: number,
    remainingSec: number,
    runsUsed: number,
    maxRuns: number,
    nextCommission: number,
    lastBuyer: string,
    bidsJson: string,
    colorR: number,
    colorG: number,
    colorB: number,
    scale: number,
}

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    plotManager: PlotManager.PlotManager,
    syncHud: (player: Player) -> (),
    publishWorld: () -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
    fireAuctionSync: (player: Player, payload: AuctionSyncPayload) -> (),
}

type LiveSession = {
    bids: { BidStep },
    startedAt: number,
    endsAt: number,
    revealedIndex: number,
    currentBid: number,
    lastBuyer: string,
}

export type AuctionManager = {
    start: (
        self: AuctionManager,
        player: Player,
        slotIndex: number,
        fromFavorite: boolean?
    ) -> (boolean, string?),
    confirmSell: (self: AuctionManager, player: Player) -> (boolean, string?, number?),
    rerun: (self: AuctionManager, player: Player) -> (boolean, string?),
    onProfileLoaded: (self: AuctionManager, player: Player) -> (),
    clearPlayer: (self: AuctionManager, player: Player) -> (),
    startTicking: (self: AuctionManager) -> (),
    appendAuctionPubs: (self: AuctionManager, pubs: { WorldExhibitPub }) -> (),
}

local AuctionManager = {}
AuctionManager.__index = AuctionManager

local function wallSec(): number
    return os.clock()
end

local function ensureRebirths(d: PlayerData)
    if typeof(d.rebirths) ~= "number" then
        d.rebirths = 0
    end
end

local function emptySync(): AuctionSyncPayload
    return {
        phase = "none",
        displayName = "",
        rarity = "",
        sizeId = "medium",
        sizeLabel = "",
        mutationLabel = "",
        mutationCount = 0,
        currentBid = 0,
        maxBid = 0,
        remainingSec = 0,
        runsUsed = 0,
        maxRuns = AuctionLogic.maxRuns(),
        nextCommission = 0,
        lastBuyer = "",
        bidsJson = "[]",
        colorR = 100,
        colorG = 100,
        colorB = 100,
        scale = 1,
    }
end

local function buildSync(hold: AuctionHold, live: LiveSession?): AuctionSyncPayload
    local ex = hold.exhibit
    local mutations = ex.mutations or {}
    local mutCount = #mutations
    local template = ExhibitCatalog.byId[ex.templateId]
    local rgb = if template then template.colorRgb else { 100, 100, 100 }
    local sizeId = ex.sizeId or "medium"
    local revealed: { BidStep } = {}
    local currentBid = hold.lastMaxBid
    local lastBuyer = ""
    local remaining = 0
    if live then
        currentBid = live.currentBid
        lastBuyer = live.lastBuyer
        remaining = AuctionLogic.remainingSec(live.endsAt, wallSec())
        for i = 1, live.revealedIndex do
            table.insert(revealed, live.bids[i])
        end
    elseif hold.phase == "finished" then
        currentBid = hold.lastMaxBid
        remaining = 0
    end

    local nextCommission = AuctionLogic.commissionForNextRun(hold.runsCompleted, hold.lastMaxBid)
    return {
        phase = hold.phase,
        displayName = ex.displayName,
        rarity = ex.rarity,
        sizeId = sizeId,
        sizeLabel = AuctionLogic.sizeLabel(sizeId),
        mutationLabel = MutationLogic.formatLabel(mutations),
        mutationCount = mutCount,
        currentBid = currentBid,
        maxBid = hold.lastMaxBid,
        remainingSec = remaining,
        runsUsed = hold.runsCompleted,
        maxRuns = AuctionLogic.maxRuns(),
        nextCommission = nextCommission,
        lastBuyer = lastBuyer,
        bidsJson = HttpService:JSONEncode(revealed),
        colorR = rgb[1] or 100,
        colorG = rgb[2] or 100,
        colorB = rgb[3] or 100,
        scale = ExhibitLogic.visualScale(1, mutCount > 0, sizeId, mutations),
    }
end

function AuctionManager.new(deps: Deps): AuctionManager
    local self = setmetatable({
        _deps = deps,
        _live = {} :: { [number]: LiveSession },
        _conn = nil :: RBXScriptConnection?,
    }, AuctionManager)
    return (self :: any) :: AuctionManager
end

function AuctionManager:_syncPlayer(player: Player)
    local data = self._deps.profileManager:get(player)
    if not data or not data.auctionHold then
        self._deps.fireAuctionSync(player, emptySync())
        return
    end
    ensureRebirths(data)
    local live = self._live[player.UserId]
    self._deps.fireAuctionSync(player, buildSync(data.auctionHold, live))
end

function AuctionManager:appendAuctionPubs(pubs: { WorldExhibitPub })
    for _, player in Players:GetPlayers() do
        local data = self._deps.profileManager:get(player)
        local plot = self._deps.plotManager:getByPlayer(player)
        if data and data.auctionHold and plot then
            local hold = data.auctionHold
            local ex = hold.exhibit
            local mutations = ex.mutations or {}
            local mutCount = #mutations
            local template = ExhibitCatalog.byId[ex.templateId]
            local sizeId = ex.sizeId or "medium"
            local live = self._live[player.UserId]
            local revealed: { BidStep } = {}
            local currentBid = hold.lastMaxBid
            if live then
                currentBid = live.currentBid
                for i = 1, live.revealedIndex do
                    table.insert(revealed, live.bids[i])
                end
            elseif hold.phase == "finished" or hold.phase == "sold" then
                if typeof(hold.lastBidsJson) == "string" and hold.lastBidsJson ~= "" then
                    local ok, decoded = pcall(function()
                        return HttpService:JSONDecode(hold.lastBidsJson :: string)
                    end)
                    if ok and typeof(decoded) == "table" then
                        revealed = decoded :: { BidStep }
                    end
                end
                if #revealed == 0 and hold.lastMaxBid > 0 then
                    table.insert(revealed, {
                        buyerName = "Winner",
                        amount = hold.lastMaxBid,
                    })
                end
                currentBid = hold.lastMaxBid
            end

            local bidTotal = if live
                then #live.bids
                else math.max(hold.bidderCount or #revealed, #revealed, 3)
            local npcTarget = 0 -- regular crowd off; dedicated auction bidders on client

            table.insert(pubs, {
                ownerUserId = player.UserId,
                plotId = plot.id,
                slotIndex = hold.originSlot,
                uid = ex.uid,
                templateId = ex.templateId,
                rarity = ex.rarity,
                displayName = ex.displayName,
                progress = 1,
                remainingSec = 0,
                evolveDurationSec = ExhibitLogic.evolveDuration(ex.rarity),
                incomeRate = 0,
                highlightT = ExhibitLogic.highlightTransparency(1, true),
                npcTarget = npcTarget,
                evolved = true,
                mutated = mutCount > 0,
                mutationStacks = mutCount,
                mutationLabel = MutationLogic.formatLabel(mutations),
                celebrateUntil = 0,
                celebrateKind = "",
                animId = if typeof(ex.animId) == "string" and ex.animId ~= ""
                    then ex.animId
                    else "spin",
                sellPrice = hold.lastMaxBid,
                auctionValue = hold.lastMaxBid,
                scale = ExhibitLogic.visualScale(1, mutCount > 0, sizeId, mutations),
                sizeId = sizeId,
                colorRgb = if template then template.colorRgb else { 100, 100, 100 },
                auctioning = true,
                auctionPhase = hold.phase,
                auctionBidsJson = HttpService:JSONEncode(revealed),
                auctionCurrentBid = currentBid,
                auctionBidderCount = bidTotal,
                isFavorite = hold.fromFavorite == true,
            })
        end
    end
end

function AuctionManager:_startLive(player: Player, hold: AuctionHold, rebirths: number)
    local ex = hold.exhibit
    local mutations = ex.mutations or {}
    local mutCount = #mutations
    local target = AuctionLogic.targetValue(ex.rarity, ex.sizeId, mutCount, rebirths)
    local count = AuctionLogic.bidCount(ex.rarity, ex.sizeId, mutCount)
    local seed = (player.UserId * 1009 + math.floor(wallSec() * 1000) + hold.runsCompleted * 17)
        % 2147483647
    local bids = AuctionLogic.generateBids(target, count, seed)
    local now = wallSec()
    local duration = AuctionLogic.durationSec()
    self._live[player.UserId] = {
        bids = bids,
        startedAt = now,
        endsAt = now + duration,
        revealedIndex = 0,
        currentBid = 0,
        lastBuyer = "",
    }
    hold.phase = "running"
    hold.lastMaxBid = bids[#bids].amount
    hold.bidderCount = #bids
end

function AuctionManager:_finishRun(player: Player, data: PlayerData, live: LiveSession)
    local hold = data.auctionHold
    if not hold then
        return
    end
    local finalBid = live.bids[#live.bids].amount
    hold.lastMaxBid = finalBid
    hold.bidderCount = #live.bids
    hold.lastBidsJson = HttpService:JSONEncode(live.bids)
    hold.runsCompleted += 1
    hold.phase = "finished"
    self._live[player.UserId] = nil
    self._deps.notify(player, "auction_done", tostring(finalBid))
end

function AuctionManager:start(
    player: Player,
    slotIndex: number,
    fromFavorite: boolean?
): (boolean, string?)
    local fromFav = fromFavorite == true
    if fromFav then
        if not FavoriteLogic.isValidSlot(slotIndex) then
            return false, "invalid_slot"
        end
    elseif not ExhibitLogic.isValidSlot(slotIndex) then
        return false, "invalid_slot"
    end
    local data = self._deps.profileManager:get(player)
    if not data then
        return false, "no_profile"
    end
    if data.auctionHold ~= nil then
        return false, "auction_busy"
    end

    if fromFav then
        if not data.favoriteSlots then
            return false, "empty_slot"
        end
        local ex = data.favoriteSlots[slotIndex]
        if not ex then
            return false, "empty_slot"
        end
        if not ex.evolved then
            return false, "not_grown"
        end
    else
        local ex = data.slots[slotIndex]
        if not ex then
            return false, "empty_slot"
        end
        if not ex.evolved then
            return false, "not_grown"
        end
    end

    local ok = self._deps.profileManager:mutate(player, function(d: PlayerData)
        if d.auctionHold ~= nil then
            return
        end
        local slotEx: ExhibitInstance?
        if fromFav then
            if not d.favoriteSlots then
                return
            end
            slotEx = d.favoriteSlots[slotIndex]
            if not slotEx or not slotEx.evolved then
                return
            end
            d.favoriteSlots[slotIndex] = nil
        else
            slotEx = d.slots[slotIndex]
            if not slotEx or not slotEx.evolved then
                return
            end
            d.slots[slotIndex] = nil
        end
        local taken = slotEx :: ExhibitInstance
        ensureRebirths(d)
        taken.placedAt = nil
        taken.slotIndex = nil
        d.auctionHold = {
            exhibit = taken,
            runsCompleted = 0,
            phase = "running",
            lastMaxBid = 0,
            originSlot = slotIndex,
            fromFavorite = fromFav,
            bidderCount = 0,
        }
    end)
    if not ok then
        return false, "mutate_failed"
    end

    data = self._deps.profileManager:get(player)
    if not data or not data.auctionHold then
        return false, "mutate_failed"
    end
    ensureRebirths(data)
    self:_startLive(player, data.auctionHold, data.rebirths)
    -- Persist lastMaxBid seed target for reconnect.
    self._deps.profileManager:mutate(player, function(d: PlayerData)
        if d.auctionHold then
            d.auctionHold.lastMaxBid = data.auctionHold.lastMaxBid
            d.auctionHold.phase = "running"
            d.auctionHold.fromFavorite = fromFav
        end
    end)

    self._deps.syncHud(player)
    self._deps.publishWorld()
    self:_syncPlayer(player)
    self._deps.notify(player, "auction_start", data.auctionHold.exhibit.displayName)
    return true, nil
end

function AuctionManager:confirmSell(player: Player): (boolean, string?, number?)
    local data = self._deps.profileManager:get(player)
    if not data or not data.auctionHold then
        return false, "no_auction", nil
    end
    if data.auctionHold.phase ~= "finished" then
        return false, "auction_running", nil
    end
    local payout = data.auctionHold.lastMaxBid
    local ok = self._deps.profileManager:mutate(player, function(d: PlayerData)
        if not d.auctionHold or d.auctionHold.phase ~= "finished" then
            return
        end
        d.coins += d.auctionHold.lastMaxBid
        d.auctionHold.phase = "sold"
    end)
    if not ok then
        return false, "mutate_failed", nil
    end
    self._live[player.UserId] = nil
    self._deps.notify(player, "sold", tostring(payout))
    self._deps.syncHud(player)
    self._deps.publishWorld()
    self._deps.fireAuctionSync(player, emptySync())

    task.delay(2.8, function()
        if not player.Parent then
            return
        end
        self._deps.profileManager:mutate(player, function(d: PlayerData)
            if d.auctionHold and d.auctionHold.phase == "sold" then
                d.auctionHold = nil
            end
        end)
        self._deps.publishWorld()
        self._deps.fireAuctionSync(player, emptySync())
    end)

    return true, nil, payout
end

function AuctionManager:rerun(player: Player): (boolean, string?)
    local data = self._deps.profileManager:get(player)
    if not data or not data.auctionHold then
        return false, "no_auction"
    end
    if data.auctionHold.phase ~= "finished" then
        return false, "auction_running"
    end
    if not AuctionLogic.canStartRun(data.auctionHold.runsCompleted) then
        return false, "max_auctions"
    end
    ensureRebirths(data)
    local fee = AuctionLogic.commissionForNextRun(
        data.auctionHold.runsCompleted,
        data.auctionHold.lastMaxBid
    )
    if data.coins < fee then
        return false, "need_coins"
    end

    local ok = self._deps.profileManager:mutate(player, function(d: PlayerData)
        if not d.auctionHold or d.auctionHold.phase ~= "finished" then
            return
        end
        if not AuctionLogic.canStartRun(d.auctionHold.runsCompleted) then
            return
        end
        local c =
            AuctionLogic.commissionForNextRun(d.auctionHold.runsCompleted, d.auctionHold.lastMaxBid)
        if d.coins < c then
            return
        end
        d.coins -= c
        d.auctionHold.phase = "running"
    end)
    if not ok then
        return false, "mutate_failed"
    end

    data = self._deps.profileManager:get(player)
    if not data or not data.auctionHold then
        return false, "mutate_failed"
    end
    ensureRebirths(data)
    self:_startLive(player, data.auctionHold, data.rebirths)
    self._deps.profileManager:mutate(player, function(d: PlayerData)
        if d.auctionHold then
            d.auctionHold.lastMaxBid = data.auctionHold.lastMaxBid
            d.auctionHold.phase = "running"
        end
    end)

    self._deps.syncHud(player)
    self._deps.publishWorld()
    self:_syncPlayer(player)
    if fee > 0 then
        self._deps.notify(player, "auction_fee", tostring(fee))
    end
    return true, nil
end

function AuctionManager:onProfileLoaded(player: Player)
    local data = self._deps.profileManager:get(player)
    if not data or not data.auctionHold then
        self._deps.fireAuctionSync(player, emptySync())
        return
    end
    ensureRebirths(data)
    -- Mid-run reconnect: settle immediately so player can sell / rerun.
    if data.auctionHold.phase == "running" then
        local ex = data.auctionHold.exhibit
        local mutCount = #(ex.mutations or {})
        local target = AuctionLogic.targetValue(ex.rarity, ex.sizeId, mutCount, data.rebirths)
        self._deps.profileManager:mutate(player, function(d: PlayerData)
            if d.auctionHold and d.auctionHold.phase == "running" then
                if d.auctionHold.lastMaxBid <= 0 then
                    d.auctionHold.lastMaxBid = target
                end
                d.auctionHold.runsCompleted += 1
                d.auctionHold.phase = "finished"
            end
        end)
    end
    self:_syncPlayer(player)
end

function AuctionManager:clearPlayer(player: Player)
    self._live[player.UserId] = nil
end

function AuctionManager:_tick()
    local now = wallSec()
    for _, player in Players:GetPlayers() do
        local live = self._live[player.UserId]
        if live then
            local data = self._deps.profileManager:get(player)
            if not data or not data.auctionHold or data.auctionHold.phase ~= "running" then
                self._live[player.UserId] = nil
            else
                local elapsed = now - live.startedAt
                local duration = live.endsAt - live.startedAt
                local idx, step = AuctionLogic.bidAtElapsed(live.bids, elapsed, duration)
                local changed = false
                if step and idx > live.revealedIndex then
                    live.revealedIndex = idx
                    live.currentBid = step.amount
                    live.lastBuyer = step.buyerName
                    changed = true
                end

                if now >= live.endsAt then
                    self:_finishRun(player, data, live)
                    self._deps.profileManager:mutate(player, function(d: PlayerData)
                        if d.auctionHold then
                            d.auctionHold.phase = "finished"
                            d.auctionHold.lastMaxBid = data.auctionHold.lastMaxBid
                            d.auctionHold.runsCompleted = data.auctionHold.runsCompleted
                            d.auctionHold.bidderCount = data.auctionHold.bidderCount
                            d.auctionHold.lastBidsJson = data.auctionHold.lastBidsJson
                        end
                    end)
                    self:_syncPlayer(player)
                    self._deps.publishWorld()
                elseif changed then
                    self:_syncPlayer(player)
                    self._deps.publishWorld()
                end
            end
        end
    end
end

function AuctionManager:startTicking()
    if self._conn then
        return
    end
    self._conn = RunService.Heartbeat:Connect(function()
        self:_tick()
    end)
end

return AuctionManager
