--!strict
-- Достижения: прыжки, падение, покупки (покупки — через ShopManager).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementLogic = require(ReplicatedStorage.shared.util.AchievementLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local ProfileManager = require(script.Parent.ProfileManager)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

type HudSyncPayload = NetTypes.HudSyncPayload

export type Deps = {
	profileManager: ProfileManager.ProfileManager,
	syncHud: (player: Player, payload: HudSyncPayload?) -> (),
	onAchievement: (player: Player, id: string) -> (),
}

local AchievementManager = {}
AchievementManager.__index = AchievementManager

function AchievementManager.new(deps: Deps)
	return setmetatable({
		_deps = deps,
		_conns = {} :: { [Player]: { RBXScriptConnection } },
		_started = false,
	}, AchievementManager)
end

function AchievementManager:_unlock(player: Player, id: string)
	local data = self._deps.profileManager:get(player)
	if not data then
		return
	end
	local achievements = data.achievements :: { [string]: boolean }
	if achievements[id] then
		return
	end

	local ok = self._deps.profileManager:mutate(player, function(d)
		local ach = d.achievements :: { [string]: boolean }
		if ach[id] then
			return
		end
		ach[id] = true
	end)
	if ok then
		self._deps.syncHud(player, nil)
		self._deps.onAchievement(player, id)
	end
end

function AchievementManager:_onJump(player: Player)
	local unlocked = false
	local ok = self._deps.profileManager:mutate(player, function(d)
		if d.achievements.jumpFiveTimes then
			return
		end
		d.jumpCount += 1
		if AchievementLogic.shouldUnlockJumpFive(d.jumpCount) then
			d.achievements.jumpFiveTimes = true
			unlocked = true
		end
	end)
	if ok then
		self._deps.syncHud(player, nil)
		if unlocked then
			self._deps.onAchievement(player, "jumpFiveTimes")
		end
	end
end

function AchievementManager:_bindCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp or not hrp:IsA("BasePart") then
		return
	end

	local conns = self._conns[player]
	if not conns then
		conns = {}
		self._conns[player] = conns
	end

	table.insert(
		conns,
		humanoid.StateChanged:Connect(function(_old, new)
			if new == Enum.HumanoidStateType.Jumping then
				self:_onJump(player)
			end
		end)
	)

	-- Падение за карту: Y ниже порога (throttle ~4 Hz)
	local acc = 0
	table.insert(
		conns,
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			acc += dt
			if acc < 0.25 then
				return
			end
			acc = 0
			if not character.Parent or not hrp.Parent then
				return
			end
			if AchievementLogic.shouldUnlockFall(hrp.Position.Y) then
				self:_unlock(player, "fallOffMap")
			end
		end)
	)
end

function AchievementManager:_clear(player: Player)
	local conns = self._conns[player]
	if conns then
		for _, c in conns do
			c:Disconnect()
		end
		self._conns[player] = nil
	end
end

function AchievementManager:_hookPlayer(player: Player)
	self._conns[player] = {}

	player.CharacterAdded:Connect(function(character)
		local old = self._conns[player]
		if old then
			for _, c in old do
				c:Disconnect()
			end
		end
		self._conns[player] = {}
		self:_bindCharacter(player, character)
	end)

	if player.Character then
		self:_bindCharacter(player, player.Character)
	end
end

function AchievementManager:start()
	if self._started then
		return
	end
	self._started = true

	Players.PlayerAdded:Connect(function(player)
		self:_hookPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:_clear(player)
	end)
	for _, player in Players:GetPlayers() do
		self:_hookPlayer(player)
	end

	Logger.info("AchievementManager", "started")
end

return AchievementManager
