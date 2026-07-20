--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local PlotSlots = require(shared.data.PlotSlots)
local Remotes = require(shared.net.Remotes)
local BaseBuilder = require(script.Parent.BaseBuilder)

export type BaseService = {
	getPlotForPlayer: (self: BaseService, player: Player) -> BaseBuilder.BasePlot?,
	getPlotByIndex: (self: BaseService, index: number) -> BaseBuilder.BasePlot?,
	getOwner: (self: BaseService, plot: BaseBuilder.BasePlot) -> Player?,
	isLocked: (self: BaseService, plot: BaseBuilder.BasePlot) -> boolean,
	ensureClaim: (self: BaseService, player: Player) -> (),
	requestToggleLock: (self: BaseService, player: Player) -> (),
	syncPlot: (self: BaseService, player: Player) -> (),
	bindEconomy: (self: BaseService, economy: any) -> (),
	destroy: (self: BaseService) -> (),
}

local BaseService = {}
BaseService.__index = BaseService

function BaseService.new(): BaseService
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	folder.Parent = Workspace

	local hub, rollMachine = BaseBuilder.createHub(Workspace)
	local plots: { BaseBuilder.BasePlot } = {}
	for i, center in PlotSlots.World.plotCenters do
		table.insert(plots, BaseBuilder.createPlot(CFrame.new(center), i, folder))
	end

	local self = setmetatable({
		_folder = folder,
		_hub = hub,
		_rollMachine = rollMachine,
		_plots = plots,
		_ownerToPlot = {} :: { [number]: number },
		_economy = nil :: any,
		_lockCooldownUntil = {} :: { [number]: number },
		_conns = {} :: { RBXScriptConnection },
	}, BaseService)

	table.insert(
		self._conns,
		Players.PlayerAdded:Connect(function(player)
			self:_claimPlot(player)
		end)
	)
	table.insert(
		self._conns,
		Players.PlayerRemoving:Connect(function(player)
			self:_releasePlot(player)
		end)
	)
	for _, player in Players:GetPlayers() do
		self:_claimPlot(player)
	end

	table.insert(
		self._conns,
		Remotes.ToggleLock.OnServerEvent:Connect(function(player: Player)
			self:requestToggleLock(player)
		end)
	)

	return self
end

function BaseService:requestToggleLock(player: Player)
	local plot = self:getPlotForPlayer(player)
	if not plot then
		return
	end
	if self:isLocked(plot) then
		plot.lockedUntil = 0
		self:syncPlot(player)
		Remotes.Toast:FireClient(player, "Unlocked")
		return
	end
	local cd = self._lockCooldownUntil[player.UserId] or 0
	if os.clock() < cd then
		Remotes.Toast:FireClient(player, "Lock cooling down")
		return
	end
	local CombatConfig = require(shared.data.CombatConfig)
	plot.lockedUntil = os.clock() + CombatConfig.Steal.lockDurationSec
	self._lockCooldownUntil[player.UserId] = os.clock() + CombatConfig.Steal.lockCooldownSec
	self:syncPlot(player)
	Remotes.Toast:FireClient(player, "Base locked (players only)")
end

function BaseService:bindEconomy(economy: any)
	self._economy = economy
end

function BaseService:ensureClaim(player: Player)
	self:_claimPlot(player)
end

function BaseService:_claimPlot(player: Player)
	if self._ownerToPlot[player.UserId] then
		return
	end
	for _, plot in self._plots do
		if plot.ownerUserId == nil then
			plot.ownerUserId = player.UserId
			self._ownerToPlot[player.UserId] = plot.index
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			player:SetAttribute("PlotIndex", plot.index)
			self:syncPlot(player)
			return
		end
	end
	Remotes.Toast:FireClient(player, "No free plots")
end

function BaseService:_releasePlot(player: Player)
	local index = self._ownerToPlot[player.UserId]
	if not index then
		return
	end
	local plot = self._plots[index]
	if plot then
		plot.ownerUserId = nil
		plot.lockedUntil = 0
		plot.model:SetAttribute("OwnerUserId", nil)
	end
	self._ownerToPlot[player.UserId] = nil
end

function BaseService:getPlotForPlayer(player: Player): BaseBuilder.BasePlot?
	local index = self._ownerToPlot[player.UserId] or player:GetAttribute("PlotIndex")
	if typeof(index) ~= "number" then
		return nil
	end
	return self._plots[index]
end

function BaseService:getPlotByIndex(index: number): BaseBuilder.BasePlot?
	return self._plots[index]
end

function BaseService:getOwner(plot: BaseBuilder.BasePlot): Player?
	if not plot.ownerUserId then
		return nil
	end
	return Players:GetPlayerByUserId(plot.ownerUserId)
end

function BaseService:isLocked(plot: BaseBuilder.BasePlot): boolean
	return os.clock() < plot.lockedUntil
end

function BaseService:getRollMachine(): BasePart
	return self._rollMachine
end

function BaseService:syncPlot(player: Player)
	local plot = self:getPlotForPlayer(player)
	if not plot then
		return
	end
	Remotes.PlotStateSync:FireClient(player, {
		plotIndex = plot.index,
		locked = self:isLocked(plot),
		lockedRemaining = math.max(0, plot.lockedUntil - os.clock()),
		blockCount = plot.blockCount,
	})
end

function BaseService:destroy()
	for _, conn in self._conns do
		conn:Disconnect()
	end
	for _, plot in self._plots do
		plot:destroy()
	end
	self._hub:Destroy()
	self._folder:Destroy()
end

return BaseService
