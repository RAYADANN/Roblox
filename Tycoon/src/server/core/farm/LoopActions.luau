--!strict
-- Core loop pads: buy, merge, deposit, cash, upgrades, group, rebirth, reset.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectCashFxLogic = require(ReplicatedStorage.shared.util.CollectCashFxLogic)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local FarmLogic = require(ReplicatedStorage.shared.util.FarmLogic)
local IndexLogic = require(ReplicatedStorage.shared.util.IndexLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local RebirthLogic = require(ReplicatedStorage.shared.util.RebirthLogic)
local WorldFarmFactory = require(script.Parent.Parent.WorldFarmFactory)

local Types = require(script.Parent.Types)

type FarmHost = Types.FarmHost

local LoopActions = {}

function LoopActions.tryBuy(self: FarmHost, player: Player, qty: number)
    local session = self._sessions[player]
    local data = self:_data(player)
    if session == nil or data == nil then
        return
    end
    local ok, err = FarmLogic.canBuy(
        data.units,
        qty,
        data.coins,
        data.buyCount,
        #session.slots,
        data.productionLevel
    )
    if not ok then
        print(
            `[Farm] buy fail {err} | coins={data.coins} cost={FarmLogic.batchCost(
                data.buyCount,
                qty
            )} units={#data.units}/{#session.slots}`
        )
        self._deps.notify(player, "farm_error", err or "cannot_buy")
        return
    end
    local cost = FarmLogic.batchCost(data.buyCount, qty)
    local maxSlots = #session.slots
    local productionLevel = data.productionLevel
    local didAutoMerge = false
    self._deps.profileManager:mutate(player, function(d)
        d.coins -= cost
        d.buyCount += qty
        local nextUnits = FarmLogic.applyBuy(d.units, qty, productionLevel)
        local auto = FarmLogic.autoMergeIfFull(nextUnits, maxSlots)
        if auto then
            d.units = auto
            didAutoMerge = true
        else
            d.units = nextUnits
        end
        d.indexMaxTier = IndexLogic.rememberTiers(d.indexMaxTier, d.units)
    end)
    data = self:_data(player)
    if data then
        self:_syncUnits(session, data)
    end
    self:_sync(player)
    self._deps.notify(player, "farm_ok", "bought")
    if didAutoMerge then
        self._deps.notify(player, "farm_ok", "merged")
    end
end

function LoopActions.tryMerge(self: FarmHost, player: Player)
    local session = self._sessions[player]
    local data = self:_data(player)
    if session == nil or data == nil then
        return
    end
    local merged = FarmLogic.mergeAll(data.units)
    if merged == nil then
        self._deps.notify(player, "farm_error", "need_three")
        return
    end
    self._deps.profileManager:mutate(player, function(d)
        local nextUnits = FarmLogic.mergeAll(d.units)
        if nextUnits then
            d.units = nextUnits
            d.indexMaxTier = IndexLogic.rememberTiers(d.indexMaxTier, d.units)
        end
    end)
    data = self:_data(player)
    if data then
        self:_syncUnits(session, data)
    end
    self:_sync(player)
    self._deps.notify(player, "farm_ok", "merged")
end

function LoopActions.tryDeposit(self: FarmHost, player: Player)
    local data = self:_data(player)
    if data == nil then
        return
    end
    local added = FarmLogic.depositAmount(data.backpackEggs, self._deps.getMultiplier())
    if added <= 0 then
        self._deps.notify(player, "farm_error", "empty_backpack")
        print(`[Farm] deposit empty | items=0 player={player.Name}`)
        return
    end
    print(`[Farm] deposit {data.backpackEggs} items → queue +{added} player={player.Name}`)
    self._deps.profileManager:mutate(player, function(d)
        d.shopQueue += FarmLogic.depositAmount(d.backpackEggs, self._deps.getMultiplier())
        d.backpackEggs = 0
    end)
    self:_sync(player)
    self:_logItems(player, "after deposit")
    self._deps.notify(player, "farm_ok", "deposited")
end

function LoopActions.tryCollectCash(self: FarmHost, player: Player)
    local session = self._sessions[player]
    local data = self:_data(player)
    if data == nil then
        return
    end
    if data.pendingCash <= 0 then
        self._deps.notify(player, "farm_error", "no_cash")
        Logger.info("Farm", `collect cash empty player={player.Name}`)
        return
    end
    local gained = data.pendingCash
    self._deps.profileManager:mutate(player, function(d)
        d.coins += d.pendingCash
        d.pendingCash = 0
    end)
    self:_sync(player)
    self._deps.notify(player, "farm_ok", "collected")
    Logger.info("Farm", `collect cash +{gained} player={player.Name}`)

    local coinCount = CollectCashFxLogic.coinCount(gained)
    if coinCount > 0 and session then
        local padModel = session.pads.CollectCash
        local padPart = if padModel then WorldFarmFactory.findPadPart(padModel) else nil
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local from = if padPart then padPart.Position else nil
        local to = if root and root:IsA("BasePart") then root.Position else from
        if from and to then
            self._deps.playVfx(player, "CollectCashCoins", coinCount, from, to)
        end
    end
end

function LoopActions.tryUpgradeProcess(self: FarmHost, player: Player)
    local data = self:_data(player)
    if data == nil then
        return
    end
    local cost = FarmLogic.processUpgradeCost(data.processLevel)
    if data.coins < cost then
        self._deps.notify(player, "farm_error", "no_coins")
        return
    end
    self._deps.profileManager:mutate(player, function(d)
        d.coins -= cost
        d.processLevel += 1
    end)
    self:_sync(player)
    self._deps.notify(player, "farm_ok", "process")
end

function LoopActions.tryUpgradeProduction(self: FarmHost, player: Player)
    local data = self:_data(player)
    if data == nil then
        return
    end
    local ok, err = FarmLogic.canUpgradeProduction(
        data.productionLevel,
        data.rebirths,
        data.buyCount,
        data.coins
    )
    if not ok then
        self._deps.notify(player, "farm_error", err or "cannot_buy")
        return
    end
    local cost = FarmLogic.productionUpgradeCost(data.productionLevel)
    self._deps.profileManager:mutate(player, function(d)
        d.coins -= cost
        d.productionLevel += 1
    end)
    self:_sync(player)
    self._deps.notify(player, "farm_ok", "production")
end

function LoopActions.tryGroupReward(self: FarmHost, player: Player)
    local data = self:_data(player)
    if data == nil then
        return
    end
    local now = os.time()
    if
        data.groupRewardAt > 0
        and now - data.groupRewardAt < Constants.GROUP_REWARD_COOLDOWN_SEC
    then
        self._deps.notify(player, "farm_error", "cooldown")
        return
    end
    self._deps.profileManager:mutate(player, function(d)
        d.coins += Constants.GROUP_REWARD
        d.groupRewardAt = now
    end)
    self:_sync(player)
    self._deps.notify(player, "farm_ok", "group")
end

function LoopActions.tryRebirth(self: FarmHost, player: Player): NetTypes.RebirthResult
    local session = self._sessions[player]
    local data = self:_data(player)
    if session == nil or data == nil then
        return { success = false, error = "no_profile" }
    end
    if not RebirthLogic.canAfford(data.coins, data.rebirths) then
        self._deps.notify(player, "farm_error", "no_coins")
        return { success = false, error = "no_coins" }
    end

    if session.pendingEggs > 0 or session.pendingLucky > 0 then
        self:_flushBag(player, session)
    end

    local ok = self._deps.profileManager:mutate(player, function(d)
        RebirthLogic.apply(d)
    end)
    if not ok then
        return { success = false, error = "no_profile" }
    end

    for _, drop in session.drops do
        if drop.Parent ~= nil then
            drop:Destroy()
        end
    end
    table.clear(session.drops)
    session.pendingEggs = 0
    session.pendingLucky = 0
    session.bagFlushQueued = false

    data = self:_data(player)
    if data == nil then
        return { success = false, error = "no_profile" }
    end
    self:_syncUnits(session, data)
    self:_sync(player)
    self._deps.notify(player, "farm_ok", "rebirthed")
    Logger.info("FarmManager", `rebirth {player.Name} -> {data.rebirths}`)
    return { success = true, error = nil, rebirths = data.rebirths }
end

function LoopActions.resetToStart(self: FarmHost, player: Player): boolean
    local session = self._sessions[player]
    if session == nil then
        return false
    end

    session.pendingEggs = 0
    session.pendingLucky = 0
    session.bagFlushQueued = false

    local ok = self._deps.profileManager:mutate(player, function(d)
        PlayerDataModule.applyTemplate(d)
        d.lastSeenAt = os.time()
    end)
    if not ok then
        return false
    end

    for _, drop in session.drops do
        if drop.Parent ~= nil then
            drop:Destroy()
        end
    end
    table.clear(session.drops)
    table.clear(session.nextLay)

    local data = self:_data(player)
    if data == nil then
        return false
    end
    self:_syncUnits(session, data)
    self:_sync(player)
    self:refreshExclusiveHeart(player)
    self:_logItems(player, "reset")
    Logger.info("FarmManager", `reset {player.Name}`)
    return true
end

return LoopActions
