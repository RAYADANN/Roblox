--!strict
-- Boot: DI wire only. No business logic.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local Remotes = require(ReplicatedStorage.shared.net.Remotes)

local SessionService = require(script.SessionService)
local BaseService = require(script.BaseService)
local EconomyService = require(script.EconomyService)
local CreatureService = require(script.CreatureService)
local RollService = require(script.RollService)
local BreedService = require(script.BreedService)
local StealService = require(script.StealService)
local BuildService = require(script.BuildService)
local TrapService = require(script.TrapService)

Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

local remotes = Remotes.init()
local sessionService = SessionService.new({})

local creatureService: CreatureService.CreatureService
local economyService: EconomyService.EconomyService
local rollService: RollService.RollService
local breedService: BreedService.BreedService
local stealService: StealService.StealService
local buildService: BuildService.BuildService
local trapService: TrapService.TrapService

local function syncHud(player: Player)
	local payload = sessionService:buildHud(player)
	if payload then
		remotes.HudSync:FireClient(player, payload)
	end
end

local function notify(player: Player, kind: string, payload: string)
	remotes.Notify:FireClient(player, { kind = kind, payload = payload })
end

local baseService = BaseService.new({
	sessionService = sessionService,
	onClaimed = function(player, plot)
		creatureService:onClaimed(player, plot)
		rollService:onClaimed(player)
		stealService:onClaimed(player)
		syncHud(player)
	end,
})

creatureService = CreatureService.new({
	sessionService = sessionService,
	baseService = baseService,
})

economyService = EconomyService.new({
	sessionService = sessionService,
	baseService = baseService,
	remotes = remotes,
	syncHud = syncHud,
})

rollService = RollService.new({
	sessionService = sessionService,
	baseService = baseService,
	creatureService = creatureService,
	remotes = remotes,
	syncHud = syncHud,
	notify = notify,
})

breedService = BreedService.new({
	sessionService = sessionService,
	baseService = baseService,
	creatureService = creatureService,
	remotes = remotes,
	syncHud = syncHud,
	notify = notify,
})

trapService = TrapService.new({
	baseService = baseService,
})

stealService = StealService.new({
	sessionService = sessionService,
	baseService = baseService,
	creatureService = creatureService,
	remotes = remotes,
	syncHud = syncHud,
	notify = notify,
	getTrapMult = function(player)
		return trapService:getSlowMult(player)
	end,
})

buildService = BuildService.new({
	sessionService = sessionService,
	baseService = baseService,
	remotes = remotes,
	syncHud = syncHud,
	notify = notify,
})

baseService:start()
economyService:start()
rollService:start()
breedService:start()
stealService:start()
buildService:start()

Players.PlayerRemoving:Connect(function(player)
	economyService:clearLimiter(player)
end)

Logger.info("server", "boot complete")
