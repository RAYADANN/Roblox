--!strict

--[[
	Unlimited pets on base. Wander inside pet zone. No pad slots.
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local PetDatabase = require(shared.data.PetDatabase)
local BlockDatabase = require(shared.data.BlockDatabase)
local BaseBuilder = require(script.Parent.BaseBuilder)

local Config = BlockDatabase.Config

local WANDER_SPEED = 4
local PICK_INTERVAL_MIN = 2
local PICK_INTERVAL_MAX = 4
local IDLE_MIN = 1
local IDLE_MAX = 2
local ZONE_MARGIN = 2
local YARD_HALF = Config.YARD_SIZE * 0.5 - ZONE_MARGIN

export type PetRuntime = {
	uid: string,
	petId: string,
	owner: Player,
	model: Model,
	state: string, -- Home | FogCage
	nextPickAt: number,
	idleUntil: number,
	target: Vector3?,
}

type BaseServiceLike = {
	getPlotForPlayer: (self: any, player: Player) -> BaseBuilder.BasePlot?,
}

export type PetService = {
	spawnHome: (self: PetService, player: Player, petId: string) -> string?,
	removeByUid: (self: PetService, player: Player, uid: string) -> string?,
	getHomePetNear: (self: PetService, worldPos: Vector3, maxDist: number) -> (Player?, string?, string?, Model?),
	getPetWorldPos: (self: PetService, player: Player, uid: string) -> Vector3?,
	clearFogVisuals: (self: PetService, player: Player, petId: string) -> (),
	moveToFog: (self: PetService, player: Player, uid: string) -> (),
	getHomePos: (self: PetService, player: Player) -> Vector3?,
	destroy: (self: PetService) -> (),
}

local PetService = {}
PetService.__index = PetService

local RARITY_COLOR = {
	Common = Color3.fromRGB(180, 185, 200),
	Uncommon = Color3.fromRGB(80, 200, 120),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(180, 100, 255),
	Mythic = Color3.fromRGB(255, 80, 120),
}

local function makePetModel(petId: string, position: Vector3): Model
	local def = PetDatabase[petId]
	local model = Instance.new("Model")
	model.Name = "Pet_" .. petId
	model:SetAttribute("PetId", petId)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2, 2, 2)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.Neon
	body.Color = if def then (RARITY_COLOR[def.rarity] or RARITY_COLOR.Common) else RARITY_COLOR.Common
	body.CFrame = CFrame.new(position)
	body.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 48)
	billboard.StudsOffset = Vector3.new(0, 2.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = if def
		then string.format("%s\n1 in %d · $%g/s", def.displayName, def.oneIn, def.incomePerSec)
		else petId
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	model.PrimaryPart = body
	model.Parent = workspace
	return model
end

function PetService.new(deps: { base: BaseServiceLike }): PetService
	local self = setmetatable({
		_base = deps.base,
		_pets = {} :: { [Player]: { [string]: PetRuntime } },
		_conns = {} :: { any },
		_rng = Random.new(),
	}, PetService)

	table.insert(
		self._conns,
		RunService.Heartbeat:Connect(function(dt)
			self:_step(dt)
		end)
	)

	return self
end

function PetService:_randomHomePos(player: Player): Vector3?
	local plot = self._base:getPlotForPlayer(player)
	if not plot then
		return nil
	end
	local half = YARD_HALF
	local x = self._rng:NextNumber(-half, half)
	local z = self._rng:NextNumber(-half, half)
	return (plot.origin * CFrame.new(x, 2.5, z)).Position
end

function PetService:getHomePos(player: Player): Vector3?
	return self:_randomHomePos(player)
end

function PetService:_clampToPetZone(plotOrigin: CFrame, worldPos: Vector3, y: number): Vector3
	local localPos = plotOrigin:PointToObjectSpace(worldPos)
	local half = YARD_HALF
	local x = math.clamp(localPos.X, -half, half)
	local z = math.clamp(localPos.Z, -half, half)
	return (plotOrigin * CFrame.new(x, 0, z)).Position + Vector3.new(0, y - plotOrigin.Position.Y, 0)
end

function PetService:spawnHome(player: Player, petId: string): string?
	local plot = self._base:getPlotForPlayer(player)
	if not plot or not PetDatabase[petId] then
		return nil
	end
	local pos = self:_randomHomePos(player)
	if not pos then
		return nil
	end

	local uid = HttpService:GenerateGUID(false)
	local model = makePetModel(petId, pos)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("PetUid", uid)
	model.Parent = plot.model

	self._pets[player] = self._pets[player] or {}
	self._pets[player][uid] = {
		uid = uid,
		petId = petId,
		owner = player,
		model = model,
		state = "Home",
		nextPickAt = os.clock() + self._rng:NextNumber(PICK_INTERVAL_MIN, PICK_INTERVAL_MAX),
		idleUntil = 0,
		target = nil,
	}
	return uid
end

function PetService:removeByUid(player: Player, uid: string): string?
	local bag = self._pets[player]
	local runtime = if bag then bag[uid] else nil
	if not runtime then
		return nil
	end
	local petId = runtime.petId
	runtime.model:Destroy()
	bag[uid] = nil
	return petId
end

function PetService:getHomePetNear(
	worldPos: Vector3,
	maxDist: number
): (Player?, string?, string?, Model?)
	local bestDist = maxDist
	local bestOwner: Player? = nil
	local bestUid: string? = nil
	local bestId: string? = nil
	local bestModel: Model? = nil
	for owner, bag in self._pets do
		for uid, runtime in bag do
			if runtime.state == "Home" and runtime.model.PrimaryPart then
				local dist = (runtime.model.PrimaryPart.Position - worldPos).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestOwner = owner
					bestUid = uid
					bestId = runtime.petId
					bestModel = runtime.model
				end
			end
		end
	end
	return bestOwner, bestUid, bestId, bestModel
end

function PetService:getPetWorldPos(player: Player, uid: string): Vector3?
	local runtime = self._pets[player] and self._pets[player][uid]
	if runtime and runtime.model.PrimaryPart then
		return runtime.model.PrimaryPart.Position
	end
	return nil
end

function PetService:moveToFog(player: Player, uid: string)
	local runtime = self._pets[player] and self._pets[player][uid]
	local plot = self._base:getPlotForPlayer(player)
	if not runtime or not plot then
		return
	end
	runtime.state = "FogCage"
	runtime.target = nil
	if runtime.model.PrimaryPart then
		runtime.model.PrimaryPart.CFrame = plot.fogCage.CFrame
	end
end

function PetService:clearFogVisuals(player: Player, petId: string)
	local bag = self._pets[player]
	if not bag then
		return
	end
	local toRemove = {}
	for uid, runtime in bag do
		if runtime.state == "FogCage" and runtime.petId == petId then
			table.insert(toRemove, uid)
		end
	end
	for _, uid in toRemove do
		self:removeByUid(player, uid)
	end
end

function PetService:_step(dt: number)
	local now = os.clock()
	local half = YARD_HALF
	for _, bag in self._pets do
		for _, runtime in bag do
			if runtime.state ~= "Home" then
				continue
			end
			local body = runtime.model.PrimaryPart
			if not body then
				continue
			end
			local plot = self._base:getPlotForPlayer(runtime.owner)
			if not plot then
				continue
			end
			local y = 2.5 + plot.origin.Position.Y

			if now < runtime.idleUntil then
				continue
			end

			if not runtime.target or now >= runtime.nextPickAt then
				local tx = self._rng:NextNumber(-half, half)
				local tz = self._rng:NextNumber(-half, half)
				runtime.target = (plot.origin * CFrame.new(tx, 0, tz)).Position
					+ Vector3.new(0, y - plot.origin.Position.Y, 0)
				runtime.nextPickAt = now + self._rng:NextNumber(PICK_INTERVAL_MIN, PICK_INTERVAL_MAX)
			end

			local target = runtime.target :: Vector3
			local pos = body.Position
			local flatTarget = Vector3.new(target.X, y, target.Z)
			local delta = flatTarget - Vector3.new(pos.X, y, pos.Z)
			if delta.Magnitude < 0.4 then
				runtime.idleUntil = now + self._rng:NextNumber(IDLE_MIN, IDLE_MAX)
				runtime.target = nil
				body.CFrame = CFrame.new(pos.X, y, pos.Z)
			else
				local step = delta.Unit * WANDER_SPEED * dt
				local newPos = Vector3.new(pos.X, y, pos.Z) + step
				newPos = self:_clampToPetZone(plot.origin, newPos, y)
				body.CFrame = CFrame.lookAt(newPos, flatTarget)
			end
		end
	end
end

function PetService:destroy()
	for _, conn in self._conns do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	for _, bag in self._pets do
		for _, runtime in bag do
			runtime.model:Destroy()
		end
	end
	table.clear(self._pets)
end

return PetService
