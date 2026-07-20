--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local PetDatabase = require(shared.data.PetDatabase)
local BlockDatabase = require(shared.data.BlockDatabase)
local CycleConfig = require(shared.data.CycleConfig)
local Remotes = require(shared.net.Remotes)
local BaseBuilder = require(script.Parent.BaseBuilder)

type BaseServiceLike = {
	getPlotForPlayer: (self: any, player: Player) -> BaseBuilder.BasePlot?,
	ensureClaim: (self: any, player: Player) -> (),
}

type PetServiceLike = {
	spawnHome: (self: any, player: Player, petId: string) -> string?,
	removeByUid: (self: any, player: Player, uid: string) -> string?,
	clearFogVisuals: (self: any, player: Player, petId: string) -> (),
	getPetWorldPos: (self: any, player: Player, uid: string) -> Vector3?,
}

export type PlayerState = {
	credits: number,
	buffer: number,
	incomePerSec: number,
	blockInv: { [string]: number },
	petBag: { string },
	placed: { [string]: string },
	fogPetId: string?,
	monsterCarryUid: string?,
}

export type EconomyService = {
	trySpend: (self: EconomyService, player: Player, amount: number) -> boolean,
	addCredits: (self: EconomyService, player: Player, amount: number) -> (),
	getCredits: (self: EconomyService, player: Player) -> number,
	getIncome: (self: EconomyService, player: Player) -> number,
	getBuffer: (self: EconomyService, player: Player) -> number,
	collectAll: (self: EconomyService, player: Player) -> number,
	addBlockStack: (self: EconomyService, player: Player, blockId: string, qty: number) -> (),
	tryConsumeBlock: (self: EconomyService, player: Player, blockId: string, qty: number) -> boolean,
	getBlockQty: (self: EconomyService, player: Player, blockId: string) -> number,
	buyRolledBlock: (self: EconomyService, player: Player, blockId: string, buyCost: number) -> boolean,
	buyRolledPet: (self: EconomyService, player: Player, petId: string, buyCost: number) -> boolean,
	grantHomePet: (self: EconomyService, player: Player, petId: string) -> boolean,
	addToInventory: (self: EconomyService, player: Player, petId: string) -> (),
	releaseInventoryToBase: (self: EconomyService, player: Player, invIndex: number) -> boolean,
	startMonsterCarry: (self: EconomyService, player: Player, petId: string, uid: string) -> boolean,
	cancelMonsterCarry: (self: EconomyService, player: Player) -> boolean,
	finishMonsterToFog: (self: EconomyService, player: Player) -> boolean,
	resolveDawn: (self: EconomyService, player: Player) -> (),
	getHighestValuePet: (self: EconomyService, player: Player) -> (string?, string?),
	getPlot: (self: EconomyService, player: Player) -> BaseBuilder.BasePlot?,
	getState: (self: EconomyService, player: Player) -> PlayerState?,
	takePetByUid: (self: EconomyService, owner: Player, uid: string) -> string?,
	takePetFromPad: (self: EconomyService, owner: Player, uid: string) -> string?,
	getPetWorldPos: (self: EconomyService, player: Player, uid: string) -> Vector3?,
	bindPets: (self: EconomyService, pets: PetServiceLike) -> (),
	syncAll: (self: EconomyService, player: Player) -> (),
	destroy: (self: EconomyService) -> (),
}

local STARTER_PETS = { "scrap_pup" }
local STARTER_DIRT = 100
local STARTER_CASH = 800
local TICK = 0.5

local EconomyService = {}
EconomyService.__index = EconomyService

function EconomyService.new(deps: { base: BaseServiceLike }): EconomyService
	local self = setmetatable({
		_base = deps.base,
		_pets = nil :: PetServiceLike?,
		_states = {} :: { [Player]: PlayerState },
		_running = true,
		_conns = {} :: { RBXScriptConnection },
	}, EconomyService)

	table.insert(self._conns, Players.PlayerAdded:Connect(function(player)
		self:_initPlayer(player)
	end))
	table.insert(self._conns, Players.PlayerRemoving:Connect(function(player)
		self._states[player] = nil
	end))
	for _, player in Players:GetPlayers() do
		self:_initPlayer(player)
	end

	table.insert(self._conns, Remotes.ReclaimFog.OnServerEvent:Connect(function(player: Player)
		if self:reclaimFog(player) then
			Remotes.Toast:FireClient(player, "Pet reclaimed from Fog Cage")
		end
	end))

	table.insert(self._conns, Remotes.CollectAll.OnServerEvent:Connect(function(player: Player)
		local got = self:collectAll(player)
		if got > 0 then
			Remotes.Toast:FireClient(player, string.format("Collected $%d", math.floor(got)))
		end
	end))

	table.insert(self._conns, Remotes.PlacePet.OnServerEvent:Connect(function(player: Player, invIndex: any)
		if typeof(invIndex) == "number" and self:releaseInventoryToBase(player, invIndex) then
			Remotes.Toast:FireClient(player, "Pet sent to yard!")
		end
	end))

	task.spawn(function()
		while self._running do
			task.wait(TICK)
			for player, state in self._states do
				if player.Parent then
					state.buffer += state.incomePerSec * TICK
					player:SetAttribute("Buffer", math.floor(state.buffer))
					player:SetAttribute("IncomePerSec", state.incomePerSec)
					player:SetAttribute("Credits", math.floor(state.credits))
				end
			end
		end
	end)

	return self
end

function EconomyService:bindPets(pets: PetServiceLike)
	self._pets = pets
	for player, state in self._states do
		if next(state.placed) == nil then
			for _, petId in STARTER_PETS do
				self:grantHomePet(player, petId)
			end
		end
	end
end

function EconomyService:_recomputeIncome(state: PlayerState)
	local sum = 0
	for _, petId in pairs(state.placed) do
		local def = PetDatabase[petId]
		if def then
			sum += def.incomePerSec
		end
	end
	state.incomePerSec = sum
end

function EconomyService:syncAll(player: Player)
	local state = self._states[player]
	if not state then
		return
	end
	player:SetAttribute("Credits", math.floor(state.credits))
	player:SetAttribute("Buffer", math.floor(state.buffer))
	player:SetAttribute("IncomePerSec", state.incomePerSec)
	player:SetAttribute("FogPetId", state.fogPetId or "")
	Remotes.InventorySync:FireClient(player, state.petBag)
	Remotes.BlockInvSync:FireClient(player, state.blockInv)
	Remotes.BufferSync:FireClient(player, state.buffer, state.incomePerSec)
	player:SetAttribute("InventoryJson", HttpService:JSONEncode(state.petBag))
	player:SetAttribute("BlockInvJson", HttpService:JSONEncode(state.blockInv))
end

function EconomyService:_initPlayer(player: Player)
	self._base:ensureClaim(player)
	task.defer(function()
		local character = player.Character or player.CharacterAdded:Wait()
		local plot = self._base:getPlotForPlayer(player)
		if plot then
			local root = character:WaitForChild("HumanoidRootPart") :: BasePart
			root.CFrame = plot.spawnCFrame
		end
	end)

	local state: PlayerState = {
		credits = STARTER_CASH,
		buffer = 0,
		incomePerSec = 0,
		blockInv = { dirt = STARTER_DIRT },
		petBag = {},
		placed = {},
		fogPetId = nil,
		monsterCarryUid = nil,
	}
	self._states[player] = state
	self:syncAll(player)

	if self._pets then
		task.defer(function()
			for _, petId in STARTER_PETS do
				self:grantHomePet(player, petId)
			end
		end)
	end
end

function EconomyService:trySpend(player: Player, amount: number): boolean
	local state = self._states[player]
	if not state or state.credits < amount then
		return false
	end
	state.credits -= amount
	player:SetAttribute("Credits", math.floor(state.credits))
	return true
end

function EconomyService:addCredits(player: Player, amount: number)
	local state = self._states[player]
	if not state then
		return
	end
	state.credits += amount
	player:SetAttribute("Credits", math.floor(state.credits))
end

function EconomyService:getBuffer(player: Player): number
	local state = self._states[player]
	return if state then state.buffer else 0
end

function EconomyService:collectAll(player: Player): number
	local state = self._states[player]
	if not state or state.buffer <= 0 then
		return 0
	end
	local got = state.buffer
	state.credits += got
	state.buffer = 0
	self:syncAll(player)
	return got
end

function EconomyService:addBlockStack(player: Player, blockId: string, qty: number)
	local state = self._states[player]
	if not state or not BlockDatabase[blockId] or qty <= 0 then
		return
	end
	state.blockInv[blockId] = (state.blockInv[blockId] or 0) + qty
	Remotes.BlockInvSync:FireClient(player, state.blockInv)
	player:SetAttribute("BlockInvJson", HttpService:JSONEncode(state.blockInv))
end

function EconomyService:tryConsumeBlock(player: Player, blockId: string, qty: number): boolean
	local state = self._states[player]
	if not state then
		return false
	end
	local have = state.blockInv[blockId] or 0
	if have < qty then
		return false
	end
	state.blockInv[blockId] = have - qty
	if state.blockInv[blockId] <= 0 then
		state.blockInv[blockId] = nil
	end
	Remotes.BlockInvSync:FireClient(player, state.blockInv)
	player:SetAttribute("BlockInvJson", HttpService:JSONEncode(state.blockInv))
	return true
end

function EconomyService:getBlockQty(player: Player, blockId: string): number
	local state = self._states[player]
	if not state then
		return 0
	end
	return state.blockInv[blockId] or 0
end

function EconomyService:buyRolledBlock(player: Player, blockId: string, buyCost: number): boolean
	local def = BlockDatabase[blockId]
	if not def then
		return false
	end
	if not self:trySpend(player, buyCost) then
		return false
	end
	self:addBlockStack(player, blockId, def.grantQty)
	return true
end

function EconomyService:grantHomePet(player: Player, petId: string): boolean
	local state = self._states[player]
	local pets = self._pets
	if not state or not pets or not PetDatabase[petId] then
		return false
	end
	local uid = pets:spawnHome(player, petId)
	if not uid then
		return false
	end
	state.placed[uid] = petId
	self:_recomputeIncome(state)
	player:SetAttribute("IncomePerSec", state.incomePerSec)
	return true
end

function EconomyService:buyRolledPet(player: Player, petId: string, buyCost: number): boolean
	if not self:trySpend(player, buyCost) then
		return false
	end
	if not self:grantHomePet(player, petId) then
		self:addCredits(player, buyCost)
		return false
	end
	return true
end

function EconomyService:addToInventory(player: Player, petId: string)
	local state = self._states[player]
	if not state or not PetDatabase[petId] then
		return
	end
	table.insert(state.petBag, petId)
	Remotes.InventorySync:FireClient(player, state.petBag)
end

function EconomyService:releaseInventoryToBase(player: Player, invIndex: number): boolean
	local state = self._states[player]
	if not state then
		return false
	end
	local petId = state.petBag[invIndex]
	if not petId then
		return false
	end
	if not self:grantHomePet(player, petId) then
		return false
	end
	table.remove(state.petBag, invIndex)
	Remotes.InventorySync:FireClient(player, state.petBag)
	return true
end

function EconomyService:getHighestValuePet(player: Player): (string?, string?)
	local state = self._states[player]
	if not state then
		return nil, nil
	end
	local bestId: string? = nil
	local bestIncome = -1
	local bestUid: string? = nil
	for uid, petId in pairs(state.placed) do
		local def = PetDatabase[petId]
		if def and def.incomePerSec > bestIncome then
			bestIncome = def.incomePerSec
			bestId = petId
			bestUid = uid
		end
	end
	return bestId, bestUid
end

function EconomyService:startMonsterCarry(player: Player, petId: string, uid: string): boolean
	local state = self._states[player]
	local pets = self._pets
	if not state or not pets or state.placed[uid] ~= petId then
		return false
	end
	local removed = pets:removeByUid(player, uid)
	if removed ~= petId then
		return false
	end
	state.placed[uid] = nil
	state.monsterCarryUid = uid
	self:_recomputeIncome(state)
	player:SetAttribute("IncomePerSec", state.incomePerSec)
	player:SetAttribute("CarryPetId", petId)
	return true
end

function EconomyService:cancelMonsterCarry(player: Player): boolean
	local state = self._states[player]
	local petId = player:GetAttribute("CarryPetId")
	if not state or typeof(petId) ~= "string" or petId == "" then
		return false
	end
	state.monsterCarryUid = nil
	player:SetAttribute("CarryPetId", "")
	if self:grantHomePet(player, petId) then
		return true
	end
	self:addToInventory(player, petId)
	return true
end

function EconomyService:finishMonsterToFog(player: Player): boolean
	local state = self._states[player]
	local petId = player:GetAttribute("CarryPetId")
	if not state or typeof(petId) ~= "string" or petId == "" then
		return false
	end
	state.monsterCarryUid = nil
	state.fogPetId = petId
	player:SetAttribute("CarryPetId", "")
	player:SetAttribute("FogPetId", petId)
	Remotes.Toast:FireClient(player, "Monster stole your pet → Fog Cage!")
	return true
end

function EconomyService:startCarry(player: Player, petId: string, uid: string): boolean
	return self:startMonsterCarry(player, petId, uid)
end

function EconomyService:cancelCarry(player: Player): boolean
	return self:cancelMonsterCarry(player)
end

function EconomyService:finishCarryToFog(player: Player): boolean
	return self:finishMonsterToFog(player)
end

function EconomyService:takePetByUid(owner: Player, uid: string): string?
	local state = self._states[owner]
	local pets = self._pets
	if not state or not pets then
		return nil
	end
	local petId = pets:removeByUid(owner, uid)
	if not petId then
		return nil
	end
	state.placed[uid] = nil
	self:_recomputeIncome(state)
	owner:SetAttribute("IncomePerSec", state.incomePerSec)
	return petId
end

function EconomyService:takePetFromPad(owner: Player, uid: string): string?
	return self:takePetByUid(owner, uid)
end

function EconomyService:getPetWorldPos(player: Player, uid: string): Vector3?
	local pets = self._pets
	if not pets then
		return nil
	end
	return pets:getPetWorldPos(player, uid)
end

function EconomyService:resolveDawn(player: Player)
	local state = self._states[player]
	if not state then
		return
	end
	if player:GetAttribute("CarryPetId") and player:GetAttribute("CarryPetId") ~= "" then
		self:cancelMonsterCarry(player)
	end
	if state.fogPetId == nil then
		state.credits += CycleConfig.dawnAllSavedBonus
		player:SetAttribute("Credits", math.floor(state.credits))
		Remotes.Toast:FireClient(
			player,
			string.format("Dawn — all pets safe! +%d credits", CycleConfig.dawnAllSavedBonus)
		)
	else
		Remotes.Toast:FireClient(player, "Dawn — reclaim from Fog Cage")
	end
end

function EconomyService:reclaimFog(player: Player): boolean
	local state = self._states[player]
	local pets = self._pets
	if not state or not state.fogPetId then
		return false
	end
	local petId = state.fogPetId
	state.fogPetId = nil
	player:SetAttribute("FogPetId", "")
	if pets then
		pets:clearFogVisuals(player, petId)
	end
	if self:grantHomePet(player, petId) then
		return true
	end
	self:addToInventory(player, petId)
	return true
end

function EconomyService:getCredits(player: Player): number
	local state = self._states[player]
	return if state then state.credits else 0
end

function EconomyService:getIncome(player: Player): number
	local state = self._states[player]
	return if state then state.incomePerSec else 0
end

function EconomyService:getPlot(player: Player): BaseBuilder.BasePlot?
	return self._base:getPlotForPlayer(player)
end

function EconomyService:getState(player: Player): PlayerState?
	return self._states[player]
end

function EconomyService:destroy()
	self._running = false
	for _, conn in self._conns do
		conn:Disconnect()
	end
end

return EconomyService
