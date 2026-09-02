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
	onLoaded: (self: ProfileManager, listener: (player: Player, data: PlayerData) -> ()) -> () -> (),
	start: (self: ProfileManager) -> (),
}

export type Deps = {}

local ProfileManager = {}
ProfileManager.__index = ProfileManager

function ProfileManager.new(_deps: Deps): ProfileManager
	local store = ProfileStore.New("ScripterTest_v1", PlayerDataModule.TEMPLATE)
	return setmetatable({
		_store = store,
		_profiles = {} :: { [Player]: Profile },
		_loadedListeners = {} :: { (player: Player, data: PlayerData) -> () },
	}, ProfileManager) :: any
end

function ProfileManager:onLoaded(listener: (player: Player, data: PlayerData) -> ()): () -> ()
	local self = self :: any
	table.insert(self._loadedListeners, listener)
	return function()
		local i = table.find(self._loadedListeners, listener)
		if i then
			table.remove(self._loadedListeners, i)
		end
	end
end

function ProfileManager:get(player: Player): PlayerData?
	local self = self :: any
	local profile = self._profiles[player]
	if profile and profile:IsActive() then
		return profile.Data :: PlayerData
	end
	return nil
end

function ProfileManager:mutate(player: Player, fn: (data: PlayerData) -> ()): boolean
	local self = self :: any
	local profile = self._profiles[player]
	if not profile or not profile:IsActive() then
		return false
	end
	fn(profile.Data :: PlayerData)
	return true
end

function ProfileManager:load(player: Player): PlayerData?
	local self = self :: any
	local profile = self._store:StartSessionAsync(`{player.UserId}`, {
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
		self._profiles[player] = nil
		player:Kick("Session ended — please rejoin")
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return nil
	end

	self._profiles[player] = profile
	local data = profile.Data :: PlayerData
	Logger.info("ProfileManager", `loaded {player.Name}`)

	for _, listener in self._loadedListeners do
		task.spawn(listener, player, data)
	end

	return data
end

function ProfileManager:release(player: Player)
	local self = self :: any
	local profile = self._profiles[player]
	if profile then
		profile:EndSession()
		self._profiles[player] = nil
	end
end

function ProfileManager:start()
	local self = self :: any
	Players.PlayerAdded:Connect(function(player)
		self:load(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:release(player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:load(player)
		end)
	end
	game:BindToClose(function()
		for player, profile in self._profiles do
			profile:EndSession()
			self._profiles[player] = nil
		end
	end)
end

return ProfileManager
