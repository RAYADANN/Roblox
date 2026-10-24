--!strict
-- Boot: DI, сервисы, сеть. Без бизнес-логики.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DevCommands = require(script.core.DevCommands)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local ProfileManager = require(script.core.ProfileManager)
local RateLimiter = require(script.util.RateLimiter)
local Zap = require(script.net.NetServer)

local CarryService = require(script.game.CarryService)
local GiantService = require(script.game.GiantService)
local HoardService = require(script.game.HoardService)
local MovementService = require(script.game.MovementService)
local NoiseService = require(script.game.NoiseService)
local PillowService = require(script.game.PillowService)
local PlotService = require(script.game.PlotService)
local Scene = require(script.game.Scene)

local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)

Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

-- Общее состояние великана для клиентов: атрибуты Noise, Phase, GazeYaw, EyePosition.
local giantState = Instance.new("Configuration")
giantState.Name = "GiantState"
giantState.Parent = ReplicatedStorage

local scene = Scene.resolve()
local profiles = ProfileManager.new({})

local function notify(player: Player, kind: string, text: string)
    Zap.Notify.Fire(player, { kind = kind, payload = text })
end
local function feedAll(kind: string, text: string)
    Zap.Notify.FireAll({ kind = kind, payload = text })
end
local function feed(text: string)
    feedAll("feed", text)
end

-- Сервисы ссылаются друг на друга; объявляем заранее, связываем после создания.
local noise: any
local carry: any
local giant: any

local movement = MovementService.new({
    giant = scene.giant,
    onLanded = function(player)
        local root = player.Character
            and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if root and noise then
            noise:add(GiantConfig.LANDING_NOISE, root.Position)
        end
    end,
    onSpeedViolation = function(player)
        if carry then
            carry:drop(player)
        end
        Logger.warn("AntiCheat", `{player.Name}: превышение скорости, откат`)
    end,
})

noise = NoiseService.new({ state = giantState, movement = movement })

carry = CarryService.new({
    scene = scene,
    movement = movement,
    noise = noise,
    notify = notify,
    feed = feed,
    fireRagdoll = function(player, velocity, duration)
        Zap.Ragdoll.Fire(player, { velocity = velocity, duration = duration })
    end,
})

local hoard = HoardService.new({ carry = carry, feed = feed })
local plots = PlotService.new({
    plots = scene.plots,
    carry = carry,
    hoard = hoard,
    movement = movement,
    profiles = profiles,
    notify = notify,
    feed = feed,
    syncCoins = function(player, coins, income)
        Zap.PlayerDataSync.Fire(player, { coins = coins, incomePerSec = income })
    end,
})
giant = GiantService.new({
    state = giantState,
    scene = scene,
    noise = noise,
    movement = movement,
    carry = carry,
    feedAll = feedAll,
})
carry._deps.plots = plots
carry._deps.hoard = hoard
carry._deps.onTeddyGrabbed = function(player: Player)
    feed(`{player.DisplayName} grabbed Grumble's Teddy!`)
    giant:wake(player)
end

local pillow = PillowService.new({ carry = carry, noise = noise, movement = movement })

-- Сеть -----------------------------------------------------------------------

local sneakLimiter = RateLimiter.new(6, 1)
Zap.SetSneak.SetCallback(function(player, enabled)
    if typeof(enabled) ~= "boolean" or not sneakLimiter:allow(player) then
        return
    end
    movement:setSneak(player, enabled)
end)

local dropLimiter = RateLimiter.new(3, 1)
Zap.DropItem.SetCallback(function(player, _)
    if dropLimiter:allow(player) then
        carry:drop(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    sneakLimiter:clear(player)
    dropLimiter:clear(player)
end)

profiles:onLoaded(function(player, data)
    Zap.PlayerDataSync.Fire(player, { coins = data.Coins, incomePerSec = 0 })
end)

DevCommands.start({
    mutateCoins = function(player, delta)
        return profiles:mutate(player, function(d)
            d.Coins += delta
        end)
    end,
    setNoise = function(value)
        noise:set(value)
    end,
})

-- Старт -----------------------------------------------------------------------

movement:start()
noise:start()
carry:start()
hoard:start()
plots:start()
giant:start()
pillow:start()
profiles:start()

Logger.info("server", "boot complete")
