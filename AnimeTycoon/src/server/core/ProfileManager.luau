--!strict

local ProfileStore = require(game:GetService("ServerScriptService").ServerPackages.ProfileStore)
local Players = game:GetService("Players")

local Constants = require(game:GetService("ReplicatedStorage").shared.data.Constants)
local IndexLogic = require(game:GetService("ReplicatedStorage").shared.util.IndexLogic)
local Logger = require(game:GetService("ReplicatedStorage").shared.util.Logger)
local OfflineEarningsLogic =
    require(game:GetService("ReplicatedStorage").shared.util.OfflineEarningsLogic)
local PlayerDataModule = require(game:GetService("ReplicatedStorage").shared.types.PlayerData)
local SlotMap = require(game:GetService("ReplicatedStorage").shared.util.SlotMap)

type PlayerData = PlayerDataModule.PlayerData
type Profile = any

export type ProfileManager = {
    get: (self: ProfileManager, player: Player) -> PlayerData?,
    mutate: (self: ProfileManager, player: Player, fn: (data: PlayerData) -> ()) -> boolean,
    resetProgress: (self: ProfileManager, player: Player) -> boolean,
    load: (self: ProfileManager, player: Player) -> PlayerData?,
    release: (self: ProfileManager, player: Player) -> (),
    onLoaded: (
        self: ProfileManager,
        listener: (player: Player, data: PlayerData) -> ()
    ) -> () -> (),
    start: (self: ProfileManager) -> (),
}

export type Deps = {}

local ProfileManager = {}
ProfileManager.__index = ProfileManager

function ProfileManager.new(_deps: Deps): ProfileManager
    local store = ProfileStore.New("AnimeTycoonPlayerData_v1", PlayerDataModule.TEMPLATE)
    return setmetatable({
        _store = store,
        _profiles = {} :: { [Player]: Profile },
        _loadedListeners = {} :: { (player: Player, data: PlayerData) -> () },
    }, ProfileManager) :: any
end

function ProfileManager:onLoaded(listener: (player: Player, data: PlayerData) -> ()): () -> ()
    local mgr = self :: any
    table.insert(mgr._loadedListeners, listener)
    return function()
        local i = table.find(mgr._loadedListeners, listener)
        if i then
            table.remove(mgr._loadedListeners, i)
        end
    end
end

function ProfileManager:get(player: Player): PlayerData?
    local mgr = self :: any
    local profile = mgr._profiles[player]
    if profile and profile:IsActive() then
        return profile.Data :: PlayerData
    end
    return nil
end

function ProfileManager:mutate(player: Player, fn: (data: PlayerData) -> ()): boolean
    local mgr = self :: any
    local profile = mgr._profiles[player]
    if not profile or not profile:IsActive() then
        return false
    end
    local data = profile.Data :: PlayerData
    fn(data)
    -- Keep ramp slots DataStore-safe (string keys, no sparse numeric holes).
    data.slots = SlotMap.normalize(data.slots)
    return true
end

--- Studio / FTUE debug: wipe progress back to template (keeps session).
function ProfileManager:resetProgress(player: Player): boolean
    return self:mutate(player, function(d: PlayerData)
        local t = PlayerDataModule.TEMPLATE
        d.coins = t.coins
        d.rebirths = 0
        d.upgrades = {}
        d.slots = PlayerDataModule.emptySlots()
        d.inventory = {}
        d.handUid = nil
        d.offers = {}
        d.offersGeneratedAt = 0
        d.firstSessionComplete = false
        d.tutorialCompleted = false
        d.firstContainerBought = false
        d.activeSellBox = { coins = 0, depositCount = 0 }
        d.sellCrates = {}
        d.indexFound = {}
        d.boostOfferSeenAt = 0
        d.ownsLuckyX2 = false
        d.ownsLuckyX4 = false
        d.ownsMoneyX2 = false
        d.lastSeenAt = 0
        d.pendingOfflineCoins = 0
    end)
end

function ProfileManager:load(player: Player): PlayerData?
    local mgr = self :: any
    local profile = mgr._store:StartSessionAsync(`{player.UserId}`, {
        Cancel = function()
            return player.Parent ~= Players
        end,
    })

    if profile == nil then
        player:Kick("Profile load failed — please rejoin")
        return nil
    end

    profile:AddUserId(player.UserId)
    profile:Reconcile()

    profile.OnSessionEnd:Connect(function()
        mgr._profiles[player] = nil
        player:Kick("Session ended — please rejoin")
    end)

    if player.Parent ~= Players then
        profile:EndSession()
        return nil
    end

    mgr._profiles[player] = profile
    local data = profile.Data :: PlayerData
    if data.upgrades == nil then
        data.upgrades = {}
    end
    data.slots = SlotMap.normalize(data.slots)
    if data.indexFound == nil then
        data.indexFound = {}
    end
    if typeof(data.lastSeenAt) ~= "number" then
        data.lastSeenAt = 0
    end
    if typeof(data.pendingOfflineCoins) ~= "number" then
        data.pendingOfflineCoins = 0
    end
    IndexLogic.backfillFromOwned(data.indexFound, SlotMap.toList(data.slots), data.inventory)

    -- Accrue offline earnings before lastSeenAt advances.
    OfflineEarningsLogic.settleOnJoin(data, os.time())

    -- Veterans (pre-FTUE saves): skip tutorial if they already have progress.
    if data.tutorialCompleted ~= true then
        local hasProgress = (data.rebirths or 0) > 0
            or (data.coins or 0) ~= Constants.START_COINS
            or SlotMap.hasAny(data.slots)
            or #(data.inventory or {}) > 0
            or #(data.sellCrates or {}) > 0
        if hasProgress then
            data.tutorialCompleted = true
        end
    end

    Logger.info("ProfileManager", `loaded {player.Name}`)

    for _, listener in mgr._loadedListeners do
        task.spawn(listener, player, data)
    end

    return data
end

function ProfileManager:release(player: Player)
    local mgr = self :: any
    local profile = mgr._profiles[player]
    if profile then
        -- Stamp leave time for offline accrual on next join.
        if profile:IsActive() then
            local data = profile.Data :: PlayerData
            data.lastSeenAt = os.time()
            data.slots = SlotMap.normalize(data.slots)
        end
        profile:EndSession()
        mgr._profiles[player] = nil
    end
end

function ProfileManager:start()
    local mgr = self :: any
    Players.PlayerAdded:Connect(function(player)
        mgr:load(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        mgr:release(player)
    end)
    for _, player in Players:GetPlayers() do
        task.spawn(function()
            mgr:load(player)
        end)
    end
    game:BindToClose(function()
        for player, profile in mgr._profiles do
            if profile:IsActive() then
                local data = profile.Data :: PlayerData
                data.lastSeenAt = os.time()
                data.slots = SlotMap.normalize(data.slots)
            end
            profile:EndSession()
            mgr._profiles[player] = nil
        end
    end)
end

return ProfileManager
