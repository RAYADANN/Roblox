--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PlotConfig = require(ReplicatedStorage.shared.data.PlotConfig)
local RarityLogic = require(ReplicatedStorage.shared.util.RarityLogic)
local WorldUi = require(ReplicatedStorage.shared.ui.WorldUi)
local SessionTypes = require(ReplicatedStorage.shared.types.Session)
local SessionService = require(script.Parent.SessionService)
local BaseService = require(script.Parent.BaseService)
local PlotBuilder = require(script.Parent.PlotBuilder)

type CreatureInstance = SessionTypes.CreatureInstance
type PlotModel = PlotBuilder.PlotModel

type Wanderer = {
	model: Model,
	body: BasePart,
	plot: PlotModel,
	nestId: string,
	scale: number,
	baseY: number,
	nextMoveAt: number,
	tween: Tween?,
}

export type Deps = {
	sessionService: SessionService.SessionService,
	baseService: BaseService.BaseService,
}

local SPECIES_COLOR: { [string]: Color3 } = {
	pup = Color3.fromRGB(210, 170, 120),
	cat = Color3.fromRGB(240, 160, 90),
	fox = Color3.fromRGB(230, 120, 50),
	owl = Color3.fromRGB(180, 160, 130),
	bug = Color3.fromRGB(90, 160, 70),
}

local CreatureService = {}
CreatureService.__index = CreatureService

export type CreatureService = typeof(setmetatable(
	{} :: {
		_deps: Deps,
		_wanderers: { [string]: Wanderer },
		_conn: RBXScriptConnection?,
	},
	CreatureService
))

function CreatureService.new(deps: Deps): CreatureService
	return setmetatable({
		_deps = deps,
		_wanderers = {},
		_conn = nil,
	}, CreatureService)
end

local function clearNestVisuals(nest: BasePart)
	local existing = nest:FindFirstChild("NestBillboard")
	if existing then
		existing:Destroy()
	end
	for _, child in nest:GetChildren() do
		if child:IsA("Model") or child:IsA("ProximityPrompt") then
			child:Destroy()
		end
	end
end

local function ensureStealPrompt(nest: BasePart, nestId: string, ownerUserId: number)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = "Take creature"
	prompt.HoldDuration = 1.2
	prompt.MaxActivationDistance = 8
	prompt.Parent = nest
	WorldUi.stylePrompt(prompt, "steal")
	nest:SetAttribute("NestId", nestId)
	nest:SetAttribute("OwnerUserId", ownerUserId)
end

local function ensureDepositPrompt(nest: BasePart, nestId: string)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DepositPrompt"
	prompt.ActionText = "Deposit"
	prompt.ObjectText = "Empty nest"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.Parent = nest
	WorldUi.stylePrompt(prompt, "deposit")
	nest:SetAttribute("NestId", nestId)
end

local function attachBillboard(parent: Instance, creature: CreatureInstance)
	WorldUi.attachCreatureBillboard(parent, {
		displayName = creature.displayName,
		oneIn = creature.oneIn,
		mps = creature.mps,
		rarity = creature.rarity :: RarityLogic.Rarity,
		isHybrid = creature.isHybrid,
	})
end

local function randomPetPoint(plot: PlotModel, preferNear: Vector3?): Vector3
	local halfX = PlotConfig.yardSize.X / 2 - PlotConfig.petZoneMargin
	local halfZ = PlotConfig.yardSize.Y / 2 - PlotConfig.petZoneMargin
	local x = plot.origin.X + (math.random() * 2 - 1) * halfX
	local z = plot.origin.Z + (math.random() * 2 - 1) * halfZ
	if preferNear then
		-- Bias toward nest so pets feel tied to their socket
		x = preferNear.X * 0.35 + x * 0.65
		z = preferNear.Z * 0.35 + z * 0.65
		x = math.clamp(x, plot.origin.X - halfX, plot.origin.X + halfX)
		z = math.clamp(z, plot.origin.Z - halfZ, plot.origin.Z + halfZ)
	end
	return Vector3.new(x, 0, z)
end

function CreatureService:_despawn(creatureId: string)
	local wanderer = self._wanderers[creatureId]
	if not wanderer then
		return
	end
	if wanderer.tween then
		wanderer.tween:Cancel()
	end
	wanderer.model:Destroy()
	self._wanderers[creatureId] = nil
end

function CreatureService:_spawnWanderer(plot: PlotModel, creature: CreatureInstance, nest: BasePart)
	self:_despawn(creature.id)

	local scale = RarityLogic.displayScale(creature.genes.scale, creature.oneIn)
	local baseY = 1.1 * scale
	local start = randomPetPoint(plot, nest.Position)

	local model = Instance.new("Model")
	model.Name = creature.id
	model:SetAttribute("CreatureId", creature.id)
	model:SetAttribute("OneIn", creature.oneIn)
	model:SetAttribute("NestId", creature.nestId)
	model.Parent = plot.petZone

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.1, 2.1, 2.1) * scale
	body.Color = SPECIES_COLOR[creature.speciesId] or Color3.fromRGB(200, 200, 200)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = CFrame.new(start.X, baseY, start.Z)
	body.Parent = model

	-- Tiny “head” bump for silhouette
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.1, 1.1, 1.1) * scale
	head.Color = body.Color
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = body.CFrame * CFrame.new(0, 0.85 * scale, 0.15 * scale)
	head.Parent = model

	model.PrimaryPart = body
	attachBillboard(body, creature)

	self._wanderers[creature.id] = {
		model = model,
		body = body,
		plot = plot,
		nestId = creature.nestId :: string,
		scale = scale,
		baseY = baseY,
		nextMoveAt = os.clock() + math.random() * 1.5,
		tween = nil,
	}
end

function CreatureService:_moveWanderer(wanderer: Wanderer)
	if wanderer.tween then
		wanderer.tween:Cancel()
		wanderer.tween = nil
	end
	local nest = wanderer.plot.nests[wanderer.nestId]
	local targetFlat = randomPetPoint(wanderer.plot, if nest then nest.Position else nil)
	local from = wanderer.body.Position
	local to = Vector3.new(targetFlat.X, wanderer.baseY, targetFlat.Z)
	local dist = (Vector3.new(to.X, 0, to.Z) - Vector3.new(from.X, 0, from.Z)).Magnitude
	local duration = math.clamp(dist / PlotConfig.petMoveSpeed, 0.8, 3.2)
	local look = CFrame.lookAt(Vector3.new(from.X, wanderer.baseY, from.Z), Vector3.new(to.X, wanderer.baseY, to.Z))
	wanderer.body.CFrame = CFrame.new(from) * (look - look.Position)

	local tween = TweenService:Create(
		wanderer.body,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ CFrame = CFrame.new(to) * (look - look.Position) }
	)
	wanderer.tween = tween
	tween:Play()
	tween.Completed:Connect(function()
		if self._wanderers[wanderer.model.Name] == wanderer then
			wanderer.tween = nil
			wanderer.nextMoveAt = os.clock()
				+ PlotConfig.petWanderMinSec
				+ math.random() * (PlotConfig.petWanderMaxSec - PlotConfig.petWanderMinSec)
		end
	end)
end

function CreatureService:_tickBob()
	local t = os.clock()
	for _, wanderer in self._wanderers do
		if wanderer.tween == nil then
			local bob = math.sin(t * 3.2 + wanderer.body.Position.X) * 0.18 * wanderer.scale
			local pos = wanderer.body.Position
			wanderer.body.CFrame = CFrame.new(pos.X, wanderer.baseY + bob, pos.Z) * (wanderer.body.CFrame - wanderer.body.CFrame.Position)
		end
		-- Keep head glued (WeldConstraint with Anchored parts doesn't simulate — sync manually)
		local head = wanderer.model:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			head.CFrame = wanderer.body.CFrame * CFrame.new(0, 0.85 * wanderer.scale, 0.15 * wanderer.scale)
		end
		if wanderer.tween == nil and t >= wanderer.nextMoveAt then
			self:_moveWanderer(wanderer)
		end
	end
end

function CreatureService:start()
	if self._conn then
		return
	end
	self._conn = RunService.Heartbeat:Connect(function()
		self:_tickBob()
	end)
end

function CreatureService:refreshPlayer(player: Player)
	local plot = self._deps.baseService:getPlotForPlayer(player)
	local data = self._deps.sessionService:get(player)
	if not plot or not data then
		return
	end

	local liveIds: { [string]: boolean } = {}

	for nestId, nest in plot.nests do
		clearNestVisuals(nest)
		nest:SetAttribute("OwnerUserId", player.UserId)
		nest:SetAttribute("NestId", nestId)
		local found: CreatureInstance? = nil
		for _, creature in data.creatures do
			if creature.nestId == nestId then
				found = creature
				break
			end
		end
		local unlocked = nest:GetAttribute("Unlocked") == true
		if found then
			liveIds[found.id] = true
			self:_spawnWanderer(plot, found, nest)
			ensureStealPrompt(nest, nestId, player.UserId)
			WorldUi.styleNest(nest, true, true)
		elseif unlocked then
			ensureDepositPrompt(nest, nestId)
			WorldUi.styleNest(nest, true, false)
		else
			WorldUi.styleNest(nest, false, false)
		end
	end

	-- Despawn wanderers no longer on nests for this player
	for creatureId, wanderer in self._wanderers do
		if wanderer.plot.id == plot.id and not liveIds[creatureId] then
			self:_despawn(creatureId)
		end
	end
end

function CreatureService:onClaimed(player: Player, _plot: PlotModel)
	self:start()
	self:refreshPlayer(player)
end

function CreatureService:destroy()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	for id in self._wanderers do
		self:_despawn(id)
	end
end

return CreatureService
