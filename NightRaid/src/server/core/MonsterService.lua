--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local CombatConfig = require(shared.data.CombatConfig)
local Remotes = require(shared.net.Remotes)
local EconomyServiceMod = require(script.Parent.EconomyService)

type EconomyService = EconomyServiceMod.EconomyService

type CycleServiceLike = {
	getPhase: (self: CycleServiceLike) -> string,
	onPhaseChanged: {
		Connect: (self: any, callback: (phase: string, duration: number) -> ()) -> { Disconnect: (self: any) -> () },
	},
}

type MonsterData = {
	model: Model,
	fear: number,
	state: string, -- chase | grab | retreat
	targetUid: string?,
	targetPetId: string?,
	carryEnds: number?,
}

export type MonsterService = {
	destroy: (self: MonsterService) -> (),
}

local MonsterService = {}
MonsterService.__index = MonsterService

local function makeMonster(position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "NightMonster"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 5, 2)
	body.Color = Color3.fromRGB(20, 20, 28)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = CFrame.new(position)
	body.Parent = model

	local eyes = Instance.new("Part")
	eyes.Name = "Eyes"
	eyes.Size = Vector3.new(2.2, 0.4, 0.3)
	eyes.Color = Color3.fromRGB(255, 60, 40)
	eyes.Material = Enum.Material.Neon
	eyes.Anchored = true
	eyes.CanCollide = false
	eyes.CFrame = body.CFrame * CFrame.new(0, 1.2, -1)
	eyes.Parent = model

	local fearGui = Instance.new("BillboardGui")
	fearGui.Name = "FearBar"
	fearGui.Size = UDim2.fromOffset(80, 10)
	fearGui.StudsOffset = Vector3.new(0, 4, 0)
	fearGui.AlwaysOnTop = true
	fearGui.Parent = body

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bg.BorderSizePixel = 0
	bg.Parent = fearGui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
	fill.BorderSizePixel = 0
	fill.Parent = bg

	model.PrimaryPart = body
	model.Parent = Workspace
	return model
end

function MonsterService.new(deps: {
	cycle: CycleServiceLike,
	economy: EconomyService,
	lights: any?,
}): MonsterService
	local self = setmetatable({
		_cycle = deps.cycle,
		_economy = deps.economy,
		_lights = deps.lights,
		_monsters = {} :: { [Player]: MonsterData },
		_shining = {} :: { [Player]: boolean },
		_conns = {} :: { any },
		_running = true,
	}, MonsterService)

	table.insert(
		self._conns,
		self._cycle.onPhaseChanged:Connect(function(phase: string)
			if phase == "Night" then
				self:_spawnAll()
			elseif phase == "Dawn" then
				self:_onDawn()
			elseif phase == "Day" then
				self:_clearAll()
			end
		end)
	)

	table.insert(
		self._conns,
		Remotes.ShineState.OnServerEvent:Connect(function(player: Player, isShining: boolean)
			self._shining[player] = isShining == true
		end)
	)

	table.insert(
		self._conns,
		RunService.Heartbeat:Connect(function(dt)
			self:_step(dt)
		end)
	)

	return self
end

function MonsterService:_onDawn()
	self:_clearAll()
	for _, player in Players:GetPlayers() do
		self._economy:resolveDawn(player)
	end
end

function MonsterService:_spawnAll()
	self:_clearAll()
	for _, player in Players:GetPlayers() do
		local plot = self._economy:getPlot(player)
		local petId, uid = self._economy:getHighestValuePet(player)
		if not plot or not petId or not uid then
			continue
		end
		local model = makeMonster(plot.monsterSpawn)
		self._monsters[player] = {
			model = model,
			fear = 0,
			state = "chase",
			targetUid = uid,
			targetPetId = petId,
			carryEnds = nil,
		}
		Remotes.Toast:FireClient(player, "NIGHT — shine your flashlight!")
	end
end

function MonsterService:_clearAll()
	for player, data in self._monsters do
		data.model:Destroy()
		self._monsters[player] = nil
	end
end

function MonsterService:_isInFlashlight(player: Player, monsterPos: Vector3): boolean
	if not self._shining[player] then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	local head = character:FindFirstChild("Head") :: BasePart?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not head or not root then
		return false
	end
	local look = root.CFrame.LookVector
	local toMonster = monsterPos - head.Position
	local dist = toMonster.Magnitude
	if dist > CombatConfig.Light.range or dist < 0.1 then
		return false
	end
	local dir = toMonster.Unit
	local cosAngle = look:Dot(dir)
	local minCos = math.cos(math.rad(CombatConfig.Light.coneDeg * 0.5))
	return cosAngle >= minCos
end

function MonsterService:_updateFearBar(body: BasePart, fear: number)
	local fearGui = body:FindFirstChild("FearBar") :: BillboardGui?
	if not fearGui then
		return
	end
	local bg = fearGui:FindFirstChild("Frame")
	if not bg or not bg:IsA("Frame") then
		return
	end
	local fill = bg:FindFirstChild("Fill")
	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.fromScale(fear, 1)
	end
end

function MonsterService:_step(dt: number)
	if self._cycle:getPhase() ~= "Night" then
		return
	end
	local cfg = CombatConfig.Monster

	for player, data in self._monsters do
		if not player.Parent or not data.model.PrimaryPart then
			continue
		end
		local plot = self._economy:getPlot(player)
		if not plot then
			continue
		end
		local body = data.model.PrimaryPart :: BasePart
		local eyes = data.model:FindFirstChild("Eyes") :: BasePart?

		if data.state == "retreat" then
			local retreatPos = plot.monsterSpawn + Vector3.new(0, 0, 20)
			body.CFrame = body.CFrame:Lerp(CFrame.new(retreatPos), math.min(1, dt * 2))
			if eyes then
				eyes.CFrame = body.CFrame * CFrame.new(0, 1.2, -1)
			end
			if (body.Position - retreatPos).Magnitude < 3 then
				data.model:Destroy()
				self._monsters[player] = nil
			end
			continue
		end

		local lampFear = 0
		if self._lights then
			lampFear = self._lights:getLampFearPerSec(plot, body.Position)
		end
		if self:_isInFlashlight(player, body.Position) then
			data.fear = math.min(1, data.fear + dt / cfg.fearSeconds)
		elseif lampFear > 0 then
			data.fear = math.min(1, data.fear + lampFear * dt)
		else
			data.fear = math.max(0, data.fear - dt * 0.35)
		end
		self:_updateFearBar(body, data.fear)

		if data.fear >= 1 then
			if data.state == "grab" then
				self._economy:cancelCarry(player)
				Remotes.Toast:FireClient(player, "Saved! Grab interrupted")
			else
				Remotes.Toast:FireClient(player, "Monster fled from the light!")
			end
			data.state = "retreat"
			continue
		end

		local inFlash = self:_isInFlashlight(player, body.Position)
		local slow = if self._lights then self._lights:getLightSlowFactor(plot, body.Position) else 1
		local speed = cfg.speed * slow
		if inFlash then
			speed = cfg.speedInLight
		end

		if data.state == "chase" then
			local uid = data.targetUid
			if not uid then
				continue
			end
			local target = self._economy:getPetWorldPos(player, uid)
			if not target then
				continue
			end
			local pos = body.Position
			local delta = target - pos
			if delta.Magnitude < 3 then
				local started = self._economy:startCarry(player, data.targetPetId :: string, uid)
				if started then
					data.state = "grab"
					data.carryEnds = os.clock() + cfg.grabCarrySec
				end
			else
				local step = delta.Unit * speed * dt
				local newPos = pos + step
				body.CFrame = CFrame.lookAt(newPos, target)
				if eyes then
					eyes.CFrame = body.CFrame * CFrame.new(0, 1.2, -1)
				end
			end
		elseif data.state == "grab" then
			local cagePos = plot.fogCage.Position
			local pos = body.Position
			local delta = cagePos - pos
			if data.carryEnds and os.clock() >= data.carryEnds then
				self._economy:finishCarryToFog(player)
				data.state = "retreat"
			elseif delta.Magnitude > 2 then
				local step = delta.Unit * (speed * 0.8) * dt
				local newPos = pos + step
				body.CFrame = CFrame.lookAt(newPos, cagePos)
				if eyes then
					eyes.CFrame = body.CFrame * CFrame.new(0, 1.2, -1)
				end
			end
		end
	end
end

function MonsterService:destroy()
	self._running = false
	self:_clearAll()
	for _, conn in self._conns do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		elseif type(conn) == "table" then
			local disconnect = (conn :: any).Disconnect
			if type(disconnect) == "function" then
				disconnect(conn)
			end
		end
	end
	table.clear(self._conns)
end

return MonsterService
