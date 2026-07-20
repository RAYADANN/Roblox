--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotConfig = require(ReplicatedStorage.shared.data.PlotConfig)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local PlotBuilder = require(script.Parent.PlotBuilder)
local SessionService = require(script.Parent.SessionService)

type PlotModel = PlotBuilder.PlotModel

export type Deps = {
	sessionService: SessionService.SessionService,
	onClaimed: ((player: Player, plot: PlotModel) -> ())?,
	onReleased: ((player: Player, plotId: number) -> ())?,
}

local BaseService = {}
BaseService.__index = BaseService

export type BaseService = typeof(setmetatable(
	{} :: {
		_deps: Deps,
		_plots: { PlotModel },
		_byPlayer: { [Player]: number },
		_connections: { RBXScriptConnection },
	},
	BaseService
))

function BaseService.new(deps: Deps): BaseService
	local self = setmetatable({
		_deps = deps,
		_plots = {},
		_byPlayer = {},
		_connections = {},
	}, BaseService)
	return self
end

function BaseService:start()
	local count = math.min(PlotConfig.provePlotCount, PlotConfig.maxPlayers)
	self._plots = PlotBuilder.buildWorld(count)
	Logger.info("BaseService", `built {count} plots`)

	table.insert(
		self._connections,
		Players.PlayerAdded:Connect(function(player)
			self:claim(player)
		end)
	)
	table.insert(
		self._connections,
		Players.PlayerRemoving:Connect(function(player)
			self:release(player)
		end)
	)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:claim(player)
		end)
	end
end

function BaseService:getPlot(plotId: number): PlotModel?
	return self._plots[plotId]
end

function BaseService:getPlotForPlayer(player: Player): PlotModel?
	local id = self._byPlayer[player]
	if not id then
		return nil
	end
	return self._plots[id]
end

function BaseService:claim(player: Player): PlotModel?
	if self._byPlayer[player] then
		return self._plots[self._byPlayer[player]]
	end

	local free: PlotModel? = nil
	for _, plot in self._plots do
		if plot.ownerUserId == nil then
			free = plot
			break
		end
	end
	if not free then
		Logger.warn("BaseService", `no free plot for {player.Name}`)
		return nil
	end

	free.ownerUserId = player.UserId
	free.model:SetAttribute("OwnerUserId", player.UserId)
	self._byPlayer[player] = free.id

	local session = self._deps.sessionService:get(player) or self._deps.sessionService:create(player)
	session.plotId = free.id
	self._deps.sessionService:grantStarter(player)

	local function teleport(character: Model)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if hrp and hrp:IsA("BasePart") then
			hrp.CFrame = free.spawnCFrame
		end
	end

	if player.Character then
		teleport(player.Character)
	end
	table.insert(
		self._connections,
		player.CharacterAdded:Connect(function(character)
			if self._byPlayer[player] == free.id then
				teleport(character)
			end
		end)
	)

	if self._deps.onClaimed then
		self._deps.onClaimed(player, free)
	end

	Logger.info("BaseService", `{player.Name} claimed plot {free.id}`)
	return free
end

function BaseService:release(player: Player)
	local plotId = self._byPlayer[player]
	if not plotId then
		return
	end
	local plot = self._plots[plotId]
	if plot then
		plot.ownerUserId = nil
		plot.model:SetAttribute("OwnerUserId", nil)
	end
	self._byPlayer[player] = nil
	self._deps.sessionService:remove(player)
	if self._deps.onReleased then
		self._deps.onReleased(player, plotId)
	end
end

function BaseService:destroy()
	for _, conn in self._connections do
		conn:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._byPlayer)
end

return BaseService
