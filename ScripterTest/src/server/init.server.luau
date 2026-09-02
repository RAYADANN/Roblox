--!strict
-- Boot: DI, менеджеры, сеть. Без бизнес-логики.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local ProfileManager = require(script.core.ProfileManager)
local CoinManager = require(script.core.CoinManager)
local ShopManager = require(script.core.ShopManager)
local TeleportManager = require(script.core.TeleportManager)
local AchievementManager = require(script.core.AchievementManager)
local Zap = require(script.net.NetServer)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)

Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

local profileManager = ProfileManager.new({})

local function syncHud(player: Player, payload: NetTypes.HudSyncPayload?)
	local data = profileManager:get(player)
	if not data then
		return
	end
	local hud = if payload then payload else buildHudPayload.fromPlayerData(data)
	Zap.PlayerDataSync.Fire(player, NetTypes.toZapSync(hud))
end

local function notify(player: Player, kind: string, payload: string)
	Zap.Notify.Fire(player, { kind = kind, payload = payload })
end

local function onAchievement(player: Player, id: string)
	Zap.AchievementUnlocked.Fire(player, { id = id })
	notify(player, "achievement", id)
end

local shopManager = ShopManager.new({
	profileManager = profileManager,
	syncHud = syncHud,
	notify = notify,
	onAchievement = onAchievement,
})

local coinManager = CoinManager.new({
	profileManager = profileManager,
	syncHud = syncHud,
	onCoinCollected = function(player, worldPos, isRed)
		Zap.CoinCollected.Fire(player, {
			x = worldPos.X,
			y = worldPos.Y,
			z = worldPos.Z,
			isRed = isRed,
		})
	end,
})

local achievementManager = AchievementManager.new({
	profileManager = profileManager,
	syncHud = syncHud,
	onAchievement = onAchievement,
})

local teleportManager = TeleportManager.new()

profileManager:onLoaded(function(player, data)
	syncHud(player, buildHudPayload.fromPlayerData(data))
	shopManager:restorePlayerVisuals(player)
	if not data.firstSessionComplete then
		profileManager:mutate(player, function(d)
			d.firstSessionComplete = true
		end)
	end
end)

profileManager:start()
shopManager:start()
coinManager:start()
achievementManager:start()
teleportManager:start()

Logger.info("server", "boot complete")
