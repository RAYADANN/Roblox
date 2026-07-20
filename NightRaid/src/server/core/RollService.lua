--!strict

--[[
	Per-plot dual Roll: Block + Pet.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local PetDatabase = require(shared.data.PetDatabase)
local BlockDatabase = require(shared.data.BlockDatabase)
local Remotes = require(shared.net.Remotes)
local BaseBuilder = require(script.Parent.BaseBuilder)

type EconomyLike = {
	trySpend: (self: any, player: Player, amount: number) -> boolean,
	buyRolledBlock: (self: any, player: Player, blockId: string, buyCost: number) -> boolean,
	buyRolledPet: (self: any, player: Player, petId: string, buyCost: number) -> boolean,
	collectAll: (self: any, player: Player) -> number,
}

type BaseLike = {
	getPlotForPlayer: (self: any, player: Player) -> BaseBuilder.BasePlot?,
	getPlotByIndex: (self: any, index: number) -> BaseBuilder.BasePlot?,
	requestToggleLock: (self: any, player: Player) -> (),
}

type Pending = {
	kind: "block" | "pet",
	id: string,
	buyCost: number,
}

export type RollService = {
	destroy: (self: RollService) -> (),
}

local RollService = {}
RollService.__index = RollService

local function updatePreview(pad: BasePart, color: Color3, billboardText: string)
	local model = pad.Parent
	if not model then
		return
	end
	local preview = model:FindFirstChild(pad.Name .. "_Preview")
	if preview and preview:IsA("BasePart") then
		preview.Color = color
	end
	local gui = pad:FindFirstChildOfClass("BillboardGui")
	local label = gui and gui:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = billboardText
	end
end

function RollService.new(deps: { economy: EconomyLike, base: BaseLike }): RollService
	local self = setmetatable({
		_economy = deps.economy,
		_base = deps.base,
		_pending = {} :: { [Player]: Pending },
		_conns = {} :: { RBXScriptConnection },
		_spinConn = nil :: RBXScriptConnection?,
	}, RollService)

	for i = 1, 6 do
		local plot = deps.base:getPlotByIndex(i)
		if plot then
			self:_bindPlot(plot)
		end
	end

	table.insert(
		self._conns,
		Remotes.RequestRoll.OnServerEvent:Connect(function(player: Player, kind: any)
			if kind == "block" or kind == "pet" then
				self:_spin(player, kind)
			end
		end)
	)

	table.insert(
		self._conns,
		Remotes.ConfirmBuy.OnServerEvent:Connect(function(player: Player, kind: any)
			if kind == "block" or kind == "pet" then
				self:_confirm(player, kind)
			end
		end)
	)

	self._spinConn = RunService.Heartbeat:Connect(function()
		for i = 1, 6 do
			local plot = deps.base:getPlotByIndex(i)
			if not plot then
				continue
			end
			for _, name in { "BlockRollPad_Preview", "PetRollPad_Preview" } do
				local preview = plot.model:FindFirstChild(name)
				if preview and preview:IsA("BasePart") then
					preview.CFrame = preview.CFrame * CFrame.Angles(0, math.rad(1.2), 0)
				end
			end
		end
	end)

	return self
end

function RollService:_bindPlot(plot: BaseBuilder.BasePlot)
	local blockPrompt = plot.blockRollPad:FindFirstChildOfClass("ProximityPrompt")
	local petPrompt = plot.petRollPad:FindFirstChildOfClass("ProximityPrompt")
	local collectPrompt = plot.collectButton:FindFirstChildOfClass("ProximityPrompt")
	local lockPrompt = plot.lockPad:FindFirstChildOfClass("ProximityPrompt")

	if blockPrompt then
		table.insert(self._conns, blockPrompt.Triggered:Connect(function(player: Player)
			if self._base:getPlotForPlayer(player) == plot then
				self:_spin(player, "block")
			end
		end))
	end
	if petPrompt then
		table.insert(self._conns, petPrompt.Triggered:Connect(function(player: Player)
			if self._base:getPlotForPlayer(player) == plot then
				self:_spin(player, "pet")
			end
		end))
	end
	if collectPrompt then
		table.insert(self._conns, collectPrompt.Triggered:Connect(function(player: Player)
			if self._base:getPlotForPlayer(player) == plot then
				local got = self._economy:collectAll(player)
				if got > 0 then
					Remotes.Toast:FireClient(player, string.format("Collected $%d", math.floor(got)))
				else
					Remotes.Toast:FireClient(player, "Nothing to collect")
				end
			end
		end))
	end
	if lockPrompt then
		table.insert(self._conns, lockPrompt.Triggered:Connect(function(player: Player)
			if self._base:getPlotForPlayer(player) == plot then
				self._base:requestToggleLock(player)
			end
		end))
	end
end

function RollService:_nearOwnPad(player: Player, kind: "block" | "pet"): BaseBuilder.BasePlot?
	local plot = self._base:getPlotForPlayer(player)
	if not plot then
		return nil
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local pad = if kind == "block" then plot.blockRollPad else plot.petRollPad
	if (root.Position - pad.Position).Magnitude > 18 then
		return nil
	end
	return plot
end

function RollService:_spin(player: Player, kind: "block" | "pet")
	local plot = self:_nearOwnPad(player, kind)
	if not plot then
		return
	end
	local spinCost = if kind == "block" then BlockDatabase.Config.SpinCostBlock else PetDatabase.SpinCost
	if spinCost > 0 and not self._economy:trySpend(player, spinCost) then
		Remotes.Toast:FireClient(player, "Not enough credits to roll")
		return
	end

	if kind == "block" then
		local blockId = BlockDatabase.rollBlockId()
		local def = BlockDatabase[blockId]
		if not def then
			return
		end
		self._pending[player] = { kind = "block", id = blockId, buyCost = def.buyCost }
		updatePreview(
			plot.blockRollPad,
			def.color,
			string.format("x%d %s\n1 in %d\n$%d", def.grantQty, def.displayName, def.oneIn, def.buyCost)
		)
		Remotes.RollResult:FireClient(player, {
			kind = "block",
			id = blockId,
			displayName = def.displayName,
			rarity = def.rarity,
			oneIn = def.oneIn,
			buyCost = def.buyCost,
			grantQty = def.grantQty,
			spinCost = spinCost,
			animating = true,
		})
	else
		local petId = PetDatabase.rollPetId()
		local def = PetDatabase[petId]
		if not def then
			return
		end
		self._pending[player] = { kind = "pet", id = petId, buyCost = def.buyCost }
		updatePreview(
			plot.petRollPad,
			Color3.fromRGB(200, 180, 255),
			string.format("x1 %s\n1 in %d\n$%g/s · $%d", def.displayName, def.oneIn, def.incomePerSec, def.buyCost)
		)
		Remotes.RollResult:FireClient(player, {
			kind = "pet",
			id = petId,
			displayName = def.displayName,
			rarity = def.rarity,
			oneIn = def.oneIn,
			buyCost = def.buyCost,
			incomePerSec = def.incomePerSec,
			spinCost = spinCost,
			animating = true,
		})
	end
end

function RollService:_confirm(player: Player, kind: "block" | "pet")
	local offer = self._pending[player]
	if not offer or offer.kind ~= kind then
		Remotes.Toast:FireClient(player, "Roll first")
		return
	end
	if not self:_nearOwnPad(player, kind) then
		return
	end

	local ok = false
	if kind == "block" then
		ok = self._economy:buyRolledBlock(player, offer.id, offer.buyCost)
		if ok then
			local def = BlockDatabase[offer.id]
			Remotes.Toast:FireClient(
				player,
				string.format("+%d %s!", if def then def.grantQty else 100, if def then def.displayName else offer.id)
			)
		end
	else
		ok = self._economy:buyRolledPet(player, offer.id, offer.buyCost)
		if ok then
			local def = PetDatabase[offer.id]
			Remotes.Toast:FireClient(player, string.format("%s → yard!", if def then def.displayName else offer.id))
		end
	end

	if not ok then
		Remotes.Toast:FireClient(player, "Not enough credits to buy")
		return
	end

	self._pending[player] = nil
	Remotes.RollResult:FireClient(player, {
		kind = kind,
		id = "",
		displayName = "",
		rarity = "",
		oneIn = 0,
		buyCost = 0,
		animating = false,
		cleared = true,
	})
end

function RollService:destroy()
	for _, conn in self._conns do
		conn:Disconnect()
	end
	if self._spinConn then
		self._spinConn:Disconnect()
	end
	table.clear(self._pending)
end

return RollService
