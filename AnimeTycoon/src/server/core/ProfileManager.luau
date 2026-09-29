--!strict

local ProfileStore = require(game:GetService("ServerScriptService").ServerPackages.ProfileStore)
local Players = game:GetService("Players")

local Logger = require(game:GetService("ReplicatedStorage").shared.util.Logger)
local PlayerDataModule = require(game:GetService("ReplicatedStorage").shared.types.PlayerData)

type PlayerData = PlayerDataModule.PlayerData
type Profile = any

export type ProfileManager = {
    get: (self: ProfileManager, player: Player) -> PlayerData?,
    mutate: (self: ProfileManager, player: Player, fn: (data: PlayerData) -> ()) -> boolean,
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
    fn(profile.Data :: PlayerData)
    return true
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
            profile:EndSession()
            mgr._profiles[player] = nil
        end
    end)
end

return ProfileManager
