--!strict

local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BreedConfig = require(ReplicatedStorage.shared.data.BreedConfig)
local BreedLogic = require(ReplicatedStorage.shared.util.BreedLogic)
local FormatOneIn = require(ReplicatedStorage.shared.util.FormatOneIn)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local WorldUi = require(ReplicatedStorage.shared.ui.WorldUi)
local Remotes = require(ReplicatedStorage.shared.net.Remotes)
local SessionService = require(script.Parent.SessionService)
local BaseService = require(script.Parent.BaseService)
local CreatureService = require(script.Parent.CreatureService)
local RateLimiter = require(script.Parent.util.RateLimiter)

export type Deps = {
	sessionService: SessionService.SessionService,
	baseService: BaseService.BaseService,
	creatureService: CreatureService.CreatureService,
	remotes: Remotes.RemotesApi,
	syncHud: (player: Player) -> (),
	notify: (player: Player, kind: string, payload: string) -> (),
}

local BreedService = {}
BreedService.__index = BreedService

export type BreedService = typeof(setmetatable(
	{} :: {
		_deps: Deps,
		_limit: RateLimiter.RateLimiter,
		_conn: RBXScriptConnection?,
		_promptConn: RBXScriptConnection?,
		_remoteConns: { RBXScriptConnection },
	},
	BreedService
))

function BreedService.new(deps: Deps): BreedService
	return setmetatable({
		_deps = deps,
		_limit = RateLimiter.new(4, 1),
		_conn = nil,
		_promptConn = nil,
		_remoteConns = {},
	}, BreedService)
end

function BreedService:_setTimer(player: Player, text: string)
	local plot = self._deps.baseService:getPlotForPlayer(player)
	if not plot then
		return
	end
	local gui = plot.incubatorPart:FindFirstChild("IncubateBillboard")
	if not gui then
		return
	end
	local label = WorldUi.findLabel(gui, "TimerLabel")
	if label then
		label.Text = text
	end
	local prompt = plot.incubatorPart:FindFirstChild("IncubatorPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		if text == "Ready" then
			prompt.ObjectText = "Fuse two pets"
		else
			prompt.ObjectText = text
		end
	end
end

function BreedService:startBreed(player: Player, parentAId: string, parentBId: string): boolean
	if not self._limit:allow(player) then
		return false
	end
	if typeof(parentAId) ~= "string" or typeof(parentBId) ~= "string" or parentAId == parentBId then
		return false
	end
	local data = self._deps.sessionService:get(player)
	if not data or data.incubateJob then
		self._deps.notify(player, "error", "Incubator busy")
		return false
	end
	local a = data.creatures[parentAId]
	local b = data.creatures[parentBId]
	if not a or not b then
		return false
	end
	if a.ownerUserId ~= player.UserId or b.ownerUserId ~= player.UserId then
		return false
	end

	a.nestId = nil
	b.nestId = nil
	local now = os.time()
	local expected = a.oneIn * b.oneIn
	data.incubateJob = {
		parentAId = parentAId,
		parentBId = parentBId,
		startedAt = now,
		endsAt = now + BreedConfig.incubateSec,
		spedUp = false,
		expectedOneIn = expected,
	}
	self._deps.creatureService:refreshPlayer(player)
	self:_setTimer(player, `Breed… {BreedConfig.incubateSec}s`)
	self._deps.syncHud(player)
	self._deps.notify(player, "breed", `Expected ~ {FormatOneIn(expected)}`)
	return true
end

function BreedService:cancelBreed(player: Player): boolean
	local data = self._deps.sessionService:get(player)
	if not data or not data.incubateJob then
		return false
	end
	local job = data.incubateJob
	local a = data.creatures[job.parentAId]
	local b = data.creatures[job.parentBId]
	if not a or not b then
		data.incubateJob = nil
		return false
	end
	local fee = BreedLogic.cancelFee(a, b)
	if data.cash < fee then
		self._deps.notify(player, "error", `Need ${fee} to cancel`)
		return false
	end
	data.cash -= fee
	data.incubateJob = nil
	self:_setTimer(player, "Ready")
	self._deps.syncHud(player)
	self._deps.notify(player, "breed", "Breed cancelled")
	return true
end

function BreedService:softSpeed(player: Player): boolean
	local data = self._deps.sessionService:get(player)
	if not data or not data.incubateJob or data.incubateJob.spedUp then
		return false
	end
	local job = data.incubateJob
	local now = os.time()
	local cost = BreedLogic.softSpeedCost(job.startedAt, now)
	if data.cash < cost then
		self._deps.notify(player, "error", `Need ${cost}`)
		return false
	end
	data.cash -= cost
	local remaining = math.max(0, job.endsAt - now)
	job.endsAt = now + math.ceil(remaining / 2)
	job.spedUp = true
	self._deps.syncHud(player)
	self._deps.notify(player, "breed", "Sped up!")
	return true
end

function BreedService:_resolve(player: Player)
	local data = self._deps.sessionService:get(player)
	if not data or not data.incubateJob then
		return
	end
	local job = data.incubateJob
	local a = data.creatures[job.parentAId]
	local b = data.creatures[job.parentBId]
	data.incubateJob = nil
	if not a or not b then
		self:_setTimer(player, "Ready")
		self._deps.syncHud(player)
		return
	end

	local outcome = BreedLogic.rollOutcome(data.luckBreed)
	if outcome == "success" then
		local childOneIn = BreedLogic.rollChildOneIn(a, b, data.luckBreed)
		local hybrid = BreedLogic.buildHybrid(a, b, childOneIn)
		data.creatures[a.id] = nil
		data.creatures[b.id] = nil
		hybrid.nestId = self._deps.sessionService:findEmptyNest(player)
		data.creatures[hybrid.id] = hybrid
		self._deps.creatureService:refreshPlayer(player)
		self:_setTimer(player, `HATched!\n{FormatOneIn(hybrid.oneIn)}`)
		self._deps.notify(
			player,
			"hatch",
			`{hybrid.displayName} · {FormatOneIn(hybrid.oneIn)} · {hybrid.rarity} · {hybrid.oneIn}`
		)
		Logger.info("BreedService", `{player.Name} hatched {FormatOneIn(hybrid.oneIn)}`)
	elseif outcome == "fail" then
		self:_setTimer(player, "Failed")
		self._deps.notify(player, "breed", "Breed failed")
	else
		data.creatures[a.id] = nil
		data.creatures[b.id] = nil
		self._deps.creatureService:refreshPlayer(player)
		self:_setTimer(player, "Burned!")
		self._deps.notify(player, "breed", "Burned!")
	end
	self._deps.syncHud(player)
	task.delay(3, function()
		local d = self._deps.sessionService:get(player)
		if d and not d.incubateJob then
			self:_setTimer(player, "Ready")
		end
	end)
end

function BreedService:_tick()
	local now = os.time()
	local Players = game:GetService("Players")
	for _, player in Players:GetPlayers() do
		local data = self._deps.sessionService:get(player)
		if data and data.incubateJob then
			local left = data.incubateJob.endsAt - now
			if left <= 0 then
				self:_resolve(player)
			else
				self:_setTimer(player, `{left}s · ~{FormatOneIn(data.incubateJob.expectedOneIn)}`)
			end
		end
	end
end

function BreedService:start()
	local accum = 0
	self._conn = RunService.Heartbeat:Connect(function(dt)
		accum += dt
		if accum < 0.5 then
			return
		end
		accum = 0
		self:_tick()
	end)

	table.insert(self._remoteConns, self._deps.remotes.RequestStartBreed.OnServerEvent:Connect(function(player, a, b)
		if typeof(a) == "string" and typeof(b) == "string" then
			self:startBreed(player, a, b)
		end
	end))
	table.insert(self._remoteConns, self._deps.remotes.RequestCancelBreed.OnServerEvent:Connect(function(player)
		self:cancelBreed(player)
	end))
	table.insert(self._remoteConns, self._deps.remotes.RequestSoftSpeedBreed.OnServerEvent:Connect(function(player)
		self:softSpeed(player)
	end))

	self._promptConn = ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt.Name ~= "IncubatorPrompt" then
			return
		end
		local plot = self._deps.baseService:getPlotForPlayer(player)
		if not plot or prompt.Parent ~= plot.incubatorPart then
			return
		end
		-- Client opens breed UI; server just nudges HUD
		self._deps.syncHud(player)
		self._deps.notify(player, "breed_ui", "open")
	end)
end

function BreedService:destroy()
	if self._conn then
		self._conn:Disconnect()
	end
	if self._promptConn then
		self._promptConn:Disconnect()
	end
	for _, c in self._remoteConns do
		c:Disconnect()
	end
end

return BreedService
