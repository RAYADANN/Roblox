--!strict
-- Boot: DI, менеджеры, сеть. Без бизнес-логики.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local ProfileManager = require(script.core.ProfileManager)
local EconomyManager = require(script.core.EconomyManager)
local MonetizationManager = require(script.core.MonetizationManager)
local DevCommands = require(script.core.DevCommands)
local GameAnalytics = require(script.core.GameAnalytics)
local VfxBroadcaster = require(script.core.VfxBroadcaster)
local Zap = require(script.net.NetServer)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)

local RunService = game:GetService("RunService")
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

local economyManager = EconomyManager.new({
	profileManager = profileManager,
	syncHud = syncHud,
	notify = function(player, kind, pl)
		Zap.Notify.Fire(player, { kind = kind, payload = pl })
	end,
})

Zap.BuyUpgrade.SetCallback(function(player, upgradeId)
	return economyManager:buyUpgrade(player, upgradeId)
end)

profileManager:onLoaded(function(player, data)
	syncHud(player, buildHudPayload.fromPlayerData(data))
	GameAnalytics.log(player, "session_start", 1)
	if not data.firstSessionComplete then
		profileManager:mutate(player, function(d)
			d.firstSessionComplete = true
		end)
		GameAnalytics.log(player, "first_action", 1)
	end
end)

MonetizationManager.new({
	grantProduct = function(player, _productId)
		local ok = profileManager:mutate(player, function(d)
			d.coins += 500
		end)
		if ok then
			syncHud(player, nil)
		end
		return ok
	end,
}):start()

DevCommands.start({
	mutateCoins = function(player, delta)
		local ok = profileManager:mutate(player, function(d)
			d.coins += delta
		end)
		if ok then
			syncHud(player, nil)
		end
		return ok
	end,
})

profileManager:start()

-- Studio / soft-launch demo: periodically fire networked cast→bolt→impact from VfxLab pads.
if RunService:IsStudio() then
	task.spawn(function()
		while true do
			task.wait(4.5)
			local lab = workspace:FindFirstChild("VfxLab")
			if lab then
				local fromPart = lab:FindFirstChild("ProjectileStart")
				local toPart = lab:FindFirstChild("ProjectileEnd")
				if fromPart and fromPart:IsA("BasePart") and toPart and toPart:IsA("BasePart") then
					VfxBroadcaster.castBoltImpact(fromPart.Position, toPart.Position, 1.1)
				end
			end
		end
	end)
end

Logger.info("server", "boot complete")
