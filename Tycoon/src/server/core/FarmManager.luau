--!strict
-- Server authority for the farm loop. Logic lives in core/farm/* submodules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local FarmLogic = require(ReplicatedStorage.shared.util.FarmLogic)
local IndexLogic = require(ReplicatedStorage.shared.util.IndexLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local PadLogic = require(ReplicatedStorage.shared.util.PadLogic)
local PadVisuals = require(script.Parent.PadVisuals)
local StandHeartVisuals = require(script.Parent.StandHeartVisuals)
local WorldFarmFactory = require(script.Parent.WorldFarmFactory)

local LoopActions = require(script.Parent.farm.LoopActions)
local Monetization = require(script.Parent.farm.Monetization)
local PadLabels = require(script.Parent.farm.PadLabels)
local Types = require(script.Parent.farm.Types)
local WorldRuntime = require(script.Parent.farm.WorldRuntime)

export type Deps = Types.Deps
export type Session = Types.Session
type PlayerData = Types.PlayerData

export type FarmManager = {
    bindPlayer: (self: FarmManager, player: Player) -> (),
    unbindPlayer: (self: FarmManager, player: Player) -> (),
    canActivatePad: (self: FarmManager, player: Player, action: string) -> boolean,
    handlePad: (self: FarmManager, player: Player, action: string) -> (),
    tryRebirth: (self: FarmManager, player: Player) -> NetTypes.RebirthResult,
    resetToStart: (self: FarmManager, player: Player) -> boolean,
    slotCount: (self: FarmManager, player: Player) -> number?,
    grantGamepass: (
        self: FarmManager,
        player: Player,
        gamepassId: number,
        fromPurchase: boolean?
    ) -> boolean,
    grantFinishNow: (self: FarmManager, player: Player, purchaseId: string) -> boolean,
    grantExclusiveHeart: (self: FarmManager, player: Player, purchaseId: string) -> boolean,
    grantExclusiveRebirth: (self: FarmManager, player: Player, purchaseId: string) -> boolean,
    clearExclusiveHeart: (self: FarmManager, player: Player) -> boolean,
    clearExclusiveOffers: (self: FarmManager, player: Player) -> boolean,
    clearGamepasses: (self: FarmManager, player: Player) -> boolean,
    refreshPads: (self: FarmManager, player: Player) -> (),
    tick: (self: FarmManager, dt: number) -> (),
    start: (self: FarmManager) -> (),
}

local FarmManager = {}
FarmManager.__index = FarmManager

local function attach(source: { [string]: any })
    for name, fn in source do
        if typeof(fn) == "function" then
            (FarmManager :: any)[name] = fn
        end
    end
end

attach(PadLabels)
attach(WorldRuntime)
attach(LoopActions)
attach(Monetization)

function FarmManager.new(deps: Deps)
    return setmetatable({
        _deps = deps,
        _sessions = {} :: { [Player]: Session },
    }, FarmManager)
end

function FarmManager:_data(player: Player): PlayerData?
    return self._deps.profileManager:get(player)
end

function FarmManager:slotCount(player: Player): number?
    local session = self._sessions[player]
    if session == nil then
        return nil
    end
    return #session.slots
end

function FarmManager:_sync(player: Player)
    self._deps.syncHud(player, nil)
    self:_refreshLabels(player)
end

function FarmManager:refreshPads(player: Player)
    self:_refreshLabels(player)
end

function FarmManager:_logItems(player: Player, reason: string)
    local data = self:_data(player)
    if data == nil then
        return
    end
    print(`[Farm] {reason} | items={data.backpackEggs} coins={data.coins} queue={data.shopQueue}`)
end

function FarmManager:bindPlayer(player: Player)
    if self._sessions[player] then
        return
    end
    local plot = self._deps.plotRegistry:assign(player)
    if plot == nil then
        player:Kick("No free farm plot")
        return
    end

    local template, slots = WorldFarmFactory.preparePlot(plot.island)

    local session: Session = {
        player = player,
        plot = plot,
        template = template,
        slots = slots,
        unitsFolder = WorldFarmFactory.ensureFolder(plot.island, "FarmUnits"),
        dropsFolder = WorldFarmFactory.ensureFolder(plot.island, "FarmDrops"),
        unitModels = {},
        drops = {},
        nextLay = {},
        pads = WorldFarmFactory.padModels(plot.island),
        collectTip = WorldFarmFactory.findCollectTip(plot.island),
        pendingEggs = 0,
        pendingLucky = 0,
        bagFlushQueued = false,
    }
    self._sessions[player] = session
    PadVisuals.snapshotPads(session.pads)

    local data = self:_data(player)
    if data then
        if data.lastSeenAt > 0 then
            local elapsed = os.time() - data.lastSeenAt
            local eggs =
                FarmLogic.offlineEggs(data.units, elapsed, data.productionLevel, data.doubleItems)
            if eggs > 0 then
                self._deps.profileManager:mutate(player, function(d)
                    d.backpackEggs += eggs
                    d.lastSeenAt = os.time()
                end)
            end
        else
            self._deps.profileManager:mutate(player, function(d)
                d.lastSeenAt = os.time()
            end)
        end
        data = self:_data(player)
        if data then
            self._deps.profileManager:mutate(player, function(d)
                d.units = FarmLogic.sortUnitsDesc(d.units)
                d.indexMaxTier = IndexLogic.rememberTiers(d.indexMaxTier, d.units)
            end)
            data = self:_data(player)
            if data then
                self:_syncUnits(session, data)
            end
        end
    end

    task.spawn(function()
        self._deps.plotRegistry:teleport(player, plot)
    end)
    self:_sync(player)
    task.spawn(function()
        self:reconcileGamepasses(player)
    end)
    self:refreshExclusiveHeart(player)
    self:_logItems(player, "bound")
    Logger.info("FarmManager", `bound {player.Name} plot={plot.id}`)
end

function FarmManager:unbindPlayer(player: Player)
    local session = self._sessions[player]
    if session == nil then
        return
    end
    if session.pendingEggs > 0 or session.pendingLucky > 0 then
        self:_flushBag(player, session)
    end
    for _, model in session.pads do
        PadVisuals.clearCache(model)
    end
    -- Restore Stand defaults so the next plot owner does not inherit Heart Skin.
    StandHeartVisuals.apply(session.plot.island, false)
    self._deps.profileManager:mutate(player, function(d)
        d.lastSeenAt = os.time()
    end)
    session.unitsFolder:ClearAllChildren()
    session.dropsFolder:ClearAllChildren()
    self._sessions[player] = nil
    self._deps.plotRegistry:release(player)
end

function FarmManager:canActivatePad(player: Player, action: string): boolean
    if action ~= "Merge" then
        return true
    end
    local data = self:_data(player)
    return data ~= nil and PadLogic.mergeReady(data.units)
end

function FarmManager:handlePad(player: Player, action: string)
    print(`[Farm] pad {action} player={player.Name}`)
    if action == "Buy1" then
        self:tryBuy(player, 1)
    elseif action == "Buy5" then
        self:tryBuy(player, 5)
    elseif action == "Buy25" then
        self:tryBuy(player, 25)
    elseif action == "Buy100" then
        self:tryBuy(player, 100)
    elseif action == "Merge" then
        self:tryMerge(player)
    elseif action == "Deposit" then
        self:tryDeposit(player)
    elseif action == "CollectCash" then
        self:tryCollectCash(player)
    elseif action == "UpgradeProcess" then
        self:tryUpgradeProcess(player)
    elseif action == "UpgradeProduction" then
        self:tryUpgradeProduction(player)
    elseif
        action == "AutoCollectEggs"
        or action == "AutoCollectCash"
        or action == "DoubleItems"
    then
        self:tryGamepassPad(player, action)
    elseif action == "FinishNow" then
        self:tryFinishNow(player)
    elseif action == "GroupReward" then
        self:tryGroupReward(player)
    end
end

function FarmManager:tick(dt: number)
    local now = os.clock()
    for player, session in self._sessions do
        local data = self:_data(player)
        if data == nil then
            continue
        end

        if data.shopQueue > 0 then
            local converted, rest = FarmLogic.processTick(
                data.shopQueue,
                FarmLogic.processPerSec(data.processLevel),
                dt
            )
            if converted > 0 then
                local cash = FarmLogic.cashFromEggs(converted, data.rebirths)
                self._deps.profileManager:mutate(player, function(d)
                    d.shopQueue = rest
                    d.pendingCash += cash
                    if d.autoCollectCash then
                        d.coins += d.pendingCash
                        d.pendingCash = 0
                    end
                end)
                self:_sync(player)
            end
        elseif data.autoCollectCash and data.pendingCash > 0 then
            self:tryCollectCash(player)
        end

        data = self:_data(player)
        if data == nil then
            continue
        end

        for i, tier in data.units do
            local due = session.nextLay[i]
            if due == nil then
                session.nextLay[i] = now + FarmLogic.layIntervalSec(tier, data.productionLevel)
            elseif now >= due then
                local kind = FarmLogic.rollDropKind(tier, math.random())
                local value = FarmLogic.dropValue(kind, data.doubleItems, tier)
                self:_spawnDrop(session, i, kind, value)
                session.nextLay[i] = now + FarmLogic.layIntervalSec(tier, data.productionLevel)
            end
        end
    end
end

function FarmManager:start()
    WorldFarmFactory.publishHeroCatalog()
    task.spawn(function()
        local acc = 0
        while true do
            local dt = task.wait(0.25)
            self:tick(dt)
            acc += dt
            if acc >= 15 then
                acc = 0
                for player in self._sessions do
                    self._deps.profileManager:mutate(player, function(d)
                        d.lastSeenAt = os.time()
                    end)
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(Constants.DROP_PICKUP_INTERVAL_SEC)
            for player, session in self._sessions do
                self:_pickupNear(player, session)
            end
        end
    end)
end

return FarmManager
