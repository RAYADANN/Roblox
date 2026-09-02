--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FormatOneIn = require(ReplicatedStorage.shared.util.FormatOneIn)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local Remotes = require(ReplicatedStorage.shared.net.Remotes)
local SessionService = require(script.Parent.SessionService)
local BaseService = require(script.Parent.BaseService)
local CreatureService = require(script.Parent.CreatureService)
local RateLimiter = require(script.Parent.util.RateLimiter)

local DEFAULT_WALK = 16
local CARRY_WALK = 16 * 0.55
local PROTECT_SEC = if RunService:IsStudio() then 0 else 180
local LOCK_SEC = 45
local MAX_CARRY_SEC = 90

export type CarryState = {
	creatureId: string,
	victimUserId: number,
	fromNestId: string,
	startedAt: number,
	oneIn: number,
	isHybrid: boolean,
}

export type Deps = {
	sessionService: SessionService.SessionService,
	baseService: BaseService.BaseService,
	creatureService: CreatureService.CreatureService,
	remotes: Remotes.RemotesApi,
	syncHud: (player: Player) -> (),
	notify: (player: Player, kind: string, payload: string) -> (),
	getTrapMult: ((Player) -> number)?,
}

local StealService = {}
StealService.__index = StealService

export type StealService = typeof(setmetatable(
	{} :: {
		_deps: Deps,
		_carries: { [Player]: CarryState },
		_nestImmunity: { [string]: number }, -- "plotId:nestId" -> until
		_limit: RateLimiter.RateLimiter,
		_connections: { RBXScriptConnection },
		_accum: number,
	},
	StealService
))

function StealService.new(deps: Deps): StealService
	return setmetatable({
		_deps = deps,
		_carries = {},
		_nestImmunity = {},
		_limit = RateLimiter.new(3, 1),
		_connections = {},
		_accum = 0,
	}, StealService)
end

local function setWalk(player: Player, speed: number, jumpMult: number)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = speed
		hum.JumpPower = 50 * jumpMult
	end
end

function StealService:_carrySpeed(state: CarryState): number
	local speed = CARRY_WALK
	if state.oneIn >= 1000 then
		speed *= 0.75
	elseif state.oneIn >= 200 or state.isHybrid then
		speed *= 0.85
	end
	return speed
end

function StealService:_findVictimPlayer(userId: number): Player?
	for _, p in Players:GetPlayers() do
		if p.UserId == userId then
			return p
		end
	end
	return nil
end

function StealService:_returnToVictim(thief: Player, state: CarryState)
	local victim = self:_findVictimPlayer(state.victimUserId)
	local victimData = victim and self._deps.sessionService:get(victim)
	local thiefData = self._deps.sessionService:get(thief)
	if not thiefData then
		return
	end
	local creature = thiefData.creatures[state.creatureId]
	if not creature then
		self._carries[thief] = nil
		setWalk(thief, DEFAULT_WALK, 1)
		return
	end

	thiefData.creatures[state.creatureId] = nil
	creature.ownerUserId = state.victimUserId
	if victimData then
		local nest = state.fromNestId
		local occupied = false
		for _, c in victimData.creatures do
			if c.nestId == nest then
				occupied = true
				break
			end
		end
		creature.nestId = if occupied then nil else nest
		victimData.creatures[creature.id] = creature
		self._deps.creatureService:refreshPlayer(victim)
		self._deps.syncHud(victim)
		self._deps.notify(victim, "steal", "Creature returned")
	end
	self._carries[thief] = nil
	setWalk(thief, DEFAULT_WALK, 1)
	self._deps.creatureService:refreshPlayer(thief)
	self._deps.syncHud(thief)
	if thief.Parent == Players then
		self._deps.notify(thief, "steal", "Carry lost")
	end
end

function StealService:startSteal(thief: Player, victim: Player, nestId: string): boolean
	if not self._limit:allow(thief) then
		return false
	end
	if self._carries[thief] then
		return false
	end
	if thief == victim then
		return false
	end
	local victimData = self._deps.sessionService:get(victim)
	local thiefData = self._deps.sessionService:get(thief)
	if not victimData or not thiefData then
		return false
	end
	if os.time() < victimData.lockUntil then
		self._deps.notify(thief, "error", "Base locked")
		return false
	end
	if os.time() - victimData.joinedAt < PROTECT_SEC then
		-- tutorial protect own nests from steal for first 180s of victim
		self._deps.notify(thief, "error", "Newbie protect")
		return false
	end
	local key = `{victimData.plotId}:{nestId}`
	if self._nestImmunity[key] and os.time() < self._nestImmunity[key] then
		self._deps.notify(thief, "error", "Nest immune")
		return false
	end

	local target = nil
	for _, c in victimData.creatures do
		if c.nestId == nestId then
			target = c
			break
		end
	end
	if not target then
		return false
	end

	-- transfer ownership to thief carry (not on nest)
	victimData.creatures[target.id] = nil
	target.ownerUserId = thief.UserId
	target.nestId = nil
	thiefData.creatures[target.id] = target

	local state: CarryState = {
		creatureId = target.id,
		victimUserId = victim.UserId,
		fromNestId = nestId,
		startedAt = os.time(),
		oneIn = target.oneIn,
		isHybrid = target.isHybrid,
	}
	self._carries[thief] = state
	setWalk(thief, self:_carrySpeed(state), 0.75)
	self._deps.creatureService:refreshPlayer(victim)
	self._deps.creatureService:refreshPlayer(thief)
	self._deps.syncHud(victim)
	self._deps.syncHud(thief)
	self._deps.notify(victim, "steal", `Robbed! {FormatOneIn(target.oneIn)}`)
	self._deps.notify(thief, "steal", `Carrying {FormatOneIn(target.oneIn)}`)
	Logger.info("StealService", `{thief.Name} stole {target.displayName}`)
	return true
end

function StealService:deposit(thief: Player, nestId: string): boolean
	local state = self._carries[thief]
	local data = self._deps.sessionService:get(thief)
	if not state or not data then
		return false
	end
	local creature = data.creatures[state.creatureId]
	if not creature then
		self._carries[thief] = nil
		return false
	end
	for _, c in data.creatures do
		if c.nestId == nestId then
			self._deps.notify(thief, "error", "Nest occupied")
			return false
		end
	end
	if (tonumber(string.sub(nestId, 2)) or 99) > data.nestsUnlocked then
		return false
	end

	creature.nestId = nestId
	local victim = self:_findVictimPlayer(state.victimUserId)
	local victimData = victim and self._deps.sessionService:get(victim)
	if victimData and victimData.plotId then
		self._nestImmunity[`{victimData.plotId}:{state.fromNestId}`] = os.time() + 20
	end

	self._carries[thief] = nil
	setWalk(thief, DEFAULT_WALK, 1)
	self._deps.creatureService:refreshPlayer(thief)
	self._deps.syncHud(thief)
	self._deps.notify(thief, "steal", "Deposited!")
	return true
end

function StealService:batSwing(attacker: Player): boolean
	if not self._limit:allow(attacker) then
		return false
	end
	local char = attacker.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return false
	end
	local hit: Player? = nil
	local best = 12
	for other, state in self._carries do
		if other ~= attacker and other.Character then
			local ohrp = other.Character:FindFirstChild("HumanoidRootPart")
			if ohrp and ohrp:IsA("BasePart") then
				local d = (ohrp.Position - hrp.Position).Magnitude
				if d <= best then
					best = d
					hit = other
				end
			end
		end
	end
	if hit then
		local state = self._carries[hit]
		if state then
			local ohrp = hit.Character and hit.Character:FindFirstChild("HumanoidRootPart")
			if ohrp and ohrp:IsA("BasePart") then
				local dir = (ohrp.Position - hrp.Position).Unit
				ohrp.AssemblyLinearVelocity = dir * 60 + Vector3.new(0, 40, 0)
			end
			self:_returnToVictim(hit, state)
			self._deps.notify(attacker, "bat", "Dropped thief!")
			return true
		end
	end
	return false
end

function StealService:lock(player: Player): boolean
	local data = self._deps.sessionService:get(player)
	if not data then
		return false
	end
	if os.time() < data.lockUntil then
		data.lockUntil = 0
		self._deps.syncHud(player)
		self._deps.notify(player, "lock", "Unlocked")
		return true
	end
	local cost = math.min(5_000, 500 * (1 + data.timesLockedToday))
	if data.cash < cost then
		self._deps.notify(player, "error", `Need ${cost}`)
		return false
	end
	data.cash -= cost
	data.timesLockedToday += 1
	data.lockUntil = os.time() + LOCK_SEC
	self._deps.syncHud(player)
	self._deps.notify(player, "lock", `Locked {LOCK_SEC}s`)
	return true
end

function StealService:_giveBat(player: Player)
	local function equip(character: Model)
		if character:FindFirstChild("Bat") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Bat")) then
			return
		end
		local tool = Instance.new("Tool")
		tool.Name = "Bat"
		tool.RequiresHandle = true
		tool.CanBeDropped = false
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.4, 3, 0.4)
		handle.Color = Color3.fromRGB(120, 80, 40)
		handle.Parent = tool
		tool.Parent = player:FindFirstChild("Backpack") or character
		tool.Activated:Connect(function()
			self:batSwing(player)
		end)
	end
	if player.Character then
		equip(player.Character)
	end
	table.insert(self._connections, player.CharacterAdded:Connect(equip))
end

function StealService:start()
	table.insert(self._connections, self._deps.remotes.RequestStartSteal.OnServerEvent:Connect(function(player, nestId, victimUserId)
		if typeof(nestId) ~= "string" or typeof(victimUserId) ~= "number" then
			return
		end
		local victim = self:_findVictimPlayer(victimUserId)
		if victim then
			self:startSteal(player, victim, nestId)
		end
	end))
	table.insert(self._connections, self._deps.remotes.RequestDepositSteal.OnServerEvent:Connect(function(player, nestId)
		if typeof(nestId) == "string" then
			self:deposit(player, nestId)
		end
	end))
	table.insert(self._connections, self._deps.remotes.RequestLock.OnServerEvent:Connect(function(player)
		self:lock(player)
	end))
	table.insert(self._connections, self._deps.remotes.RequestBatSwing.OnServerEvent:Connect(function(player)
		self:batSwing(player)
	end))

	table.insert(
		self._connections,
		ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
			if prompt.Name == "LockPrompt" then
				local plot = self._deps.baseService:getPlotForPlayer(player)
				if plot and prompt.Parent == plot.lockPart then
					self:lock(player)
				end
				return
			end
			if prompt.Name == "StealPrompt" then
				local nest = prompt.Parent
				if not nest or not nest:IsA("BasePart") then
					return
				end
				local nestId = nest:GetAttribute("NestId")
				local ownerUserId = nest:GetAttribute("OwnerUserId")
				if typeof(nestId) ~= "string" or typeof(ownerUserId) ~= "number" then
					return
				end
				local victim = self:_findVictimPlayer(ownerUserId)
				if victim then
					self:startSteal(player, victim, nestId)
				end
				return
			end
			if prompt.Name == "DepositPrompt" then
				local nest = prompt.Parent
				local nestId = nest and nest:GetAttribute("NestId")
				if typeof(nestId) == "string" then
					self:deposit(player, nestId)
				end
			end
		end)
	)

	table.insert(
		self._connections,
		RunService.Heartbeat:Connect(function(dt)
			self._accum += dt
			if self._accum < 0.2 then
				return
			end
			self._accum = 0
			local now = os.time()
			local getTrap = self._deps.getTrapMult
			for _, player in Players:GetPlayers() do
				local trapMult = if getTrap then getTrap(player) else 1
				local state = self._carries[player]
				if state then
					if now - state.startedAt >= MAX_CARRY_SEC then
						self:_returnToVictim(player, state)
					else
						setWalk(player, self:_carrySpeed(state) * trapMult, 0.75)
					end
				else
					setWalk(player, DEFAULT_WALK * trapMult, 1)
				end
			end
		end)
	)

	table.insert(self._connections, Players.PlayerRemoving:Connect(function(player)
		local state = self._carries[player]
		if state then
			self:_returnToVictim(player, state)
		end
	end))
end

function StealService:onClaimed(player: Player)
	self:_giveBat(player)
end

function StealService:isCarrying(player: Player): boolean
	return self._carries[player] ~= nil
end

function StealService:destroy()
	for _, c in self._connections do
		c:Disconnect()
	end
	table.clear(self._connections)
end

return StealService
