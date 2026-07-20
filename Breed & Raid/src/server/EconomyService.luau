--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local EconomyConfig = require(ReplicatedStorage.shared.data.EconomyConfig)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local WorldUi = require(ReplicatedStorage.shared.ui.WorldUi)
local SessionService = require(script.Parent.SessionService)
local BaseService = require(script.Parent.BaseService)
local RateLimiter = require(script.Parent.util.RateLimiter)
local Remotes = require(ReplicatedStorage.shared.net.Remotes)

export type Deps = {
	sessionService: SessionService.SessionService,
	baseService: BaseService.BaseService,
	remotes: Remotes.RemotesApi,
	syncHud: (player: Player) -> (),
}

local EconomyService = {}
EconomyService.__index = EconomyService

export type EconomyService = typeof(setmetatable(
	{} :: {
		_deps: Deps,
		_accum: number,
		_conn: RBXScriptConnection?,
		_remoteConn: RBXScriptConnection?,
		_promptConn: RBXScriptConnection?,
		_limiter: RateLimiter.RateLimiter,
		_lastHudAt: { [number]: number },
	},
	EconomyService
))

function EconomyService.new(deps: Deps): EconomyService
	return setmetatable({
		_deps = deps,
		_accum = 0,
		_conn = nil,
		_remoteConn = nil,
		_promptConn = nil,
		_limiter = RateLimiter.new(4, 1),
		_lastHudAt = {},
	}, EconomyService)
end

function EconomyService:start()
	self._conn = RunService.Heartbeat:Connect(function(dt)
		self._accum += dt
		while self._accum >= EconomyConfig.mpsTickSec do
			self._accum -= EconomyConfig.mpsTickSec
			self:_tick()
		end
	end)

	self._remoteConn = self._deps.remotes.RequestCollect.OnServerEvent:Connect(function(player)
		self:collect(player)
	end)

	self._promptConn = ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt.Name ~= "CollectPrompt" then
			return
		end
		local plot = self._deps.baseService:getPlotForPlayer(player)
		if not plot or prompt.Parent ~= plot.collectPart then
			return
		end
		self:collect(player)
	end)
end

function EconomyService:_tick()
	local sessions = self._deps.sessionService
	local Players = game:GetService("Players")
	for _, player in Players:GetPlayers() do
		local data = sessions:get(player)
		if data then
			local mps = sessions:sumNestMps(player)
			if mps > 0 then
				data.buffer += math.floor(mps)
				self:_updateBufferBillboard(player, data.buffer)
				-- Billboard/prompt every tick; full HUD less often to avoid React flicker
				local now = os.clock()
				local last = self._lastHudAt[player.UserId] or 0
				if now - last >= 0.85 then
					self._lastHudAt[player.UserId] = now
					self._deps.syncHud(player)
				end
			end
		end
	end
end

function EconomyService:_updateBufferBillboard(player: Player, buffer: number)
	local plot = self._deps.baseService:getPlotForPlayer(player)
	if not plot then
		return
	end
	local gui = plot.collectPart:FindFirstChild("BufferBillboard")
	if not gui then
		return
	end
	local label = WorldUi.findLabel(gui, "BufferLabel")
	if label then
		local amount = math.floor(buffer)
		label.Text = if amount > 0 then `${amount}` else "$0"
	end
	local prompt = plot.collectPart:FindFirstChild("CollectPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		local amount = math.floor(buffer)
		prompt.ObjectText = if amount > 0 then `${amount} ready` else "Cash ready"
	end
end

function EconomyService:collect(player: Player): boolean
	if not self._limiter:allow(player) then
		return false
	end
	local data = self._deps.sessionService:get(player)
	if not data then
		return false
	end
	if data.buffer <= 0 then
		return false
	end
	local amount = math.floor(data.buffer)
	data.cash += amount
	data.buffer = 0
	self:_updateBufferBillboard(player, 0)
	self._deps.syncHud(player)
	self._deps.remotes.Notify:FireClient(player, {
		kind = "collect",
		payload = tostring(amount),
	})
	Logger.debug("EconomyService", `{player.Name} collected {amount}`)
	return true
end

function EconomyService:clearLimiter(player: Player)
	self._limiter:clear(player)
end

function EconomyService:trySpend(player: Player, cost: number): boolean
	local data = self._deps.sessionService:get(player)
	if not data or data.cash < cost then
		return false
	end
	data.cash -= cost
	self._deps.syncHud(player)
	return true
end

function EconomyService:destroy()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	if self._remoteConn then
		self._remoteConn:Disconnect()
		self._remoteConn = nil
	end
	if self._promptConn then
		self._promptConn:Disconnect()
		self._promptConn = nil
	end
end

return EconomyService
