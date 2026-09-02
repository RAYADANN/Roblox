--!strict
-- Спавн / сбор монет. Server-authoritative.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local CoinLogic = require(ReplicatedStorage.shared.util.CoinLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local ProfileManager = require(script.Parent.ProfileManager)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

type HudSyncPayload = NetTypes.HudSyncPayload

local COIN_TAG = "Coin"

export type Deps = {
	profileManager: ProfileManager.ProfileManager,
	syncHud: (player: Player, payload: HudSyncPayload?) -> (),
	onPointsChanged: ((player: Player) -> ())?,
	onCoinCollected: ((player: Player, worldPos: Vector3, isRed: boolean) -> ())?,
}

local CoinManager = {}
CoinManager.__index = CoinManager

local function getAreaModel(areaId: string): Model?
	local scriptabled = workspace:FindFirstChild("Scriptabled")
	if not scriptabled then
		return nil
	end
	local area = scriptabled:FindFirstChild(areaId)
	if area and area:IsA("Model") then
		return area
	end
	return nil
end

local function getCoinZone(areaId: string): (BasePart?, Folder?)
	local area = getAreaModel(areaId)
	if not area then
		return nil, nil
	end
	local coinsModel = area:FindFirstChild("Coins")
	if not coinsModel then
		return nil, nil
	end
	local zone = coinsModel:FindFirstChild("Area")
	if not zone or not zone:IsA("BasePart") then
		return nil, nil
	end

	local folder = coinsModel:FindFirstChild("Active")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Active"
		folder.Parent = coinsModel
	end

	return zone, folder :: Folder
end

function CoinManager.new(deps: Deps)
	return setmetatable({
		_deps = deps,
		_counts = { Area1 = 0, Area2 = 0 } :: { [string]: number },
		_started = false,
		_lastLogAt = 0,
	}, CoinManager)
end

function CoinManager:_logCounts(force: boolean?)
	local now = os.clock()
	if not force and now - self._lastLogAt < 1 then
		return
	end
	self._lastLogAt = now
	local max = Constants.COIN_MAX_PER_AREA
	local a1 = self._counts.Area1 or 0
	local a2 = self._counts.Area2 or 0
	Logger.info("CoinManager", `монеты Area1={a1}/{max} Area2={a2}/{max} total={a1 + a2}`)
end

function CoinManager:_collect(player: Player, coinModel: Model, areaId: string)
	if coinModel:GetAttribute("Collected") == true then
		return
	end
	coinModel:SetAttribute("Collected", true)

	local points = coinModel:GetAttribute("Points")
	if typeof(points) ~= "number" then
		points = CoinLogic.pointsPerCoin()
	end

	local primary = coinModel.PrimaryPart
	local worldPos = if primary then primary.Position else coinModel:GetPivot().Position
	local isRed = areaId == "Area2"

	if coinModel.Parent then
		coinModel:Destroy()
	end
	self._counts[areaId] = math.max(0, (self._counts[areaId] or 1) - 1)
	self:_logCounts(true)

	local ok = self._deps.profileManager:mutate(player, function(data)
		data.points += points :: number
	end)

	if ok then
		self._deps.syncHud(player, nil)
		if self._deps.onCoinCollected then
			self._deps.onCoinCollected(player, worldPos, isRed)
		end
		if self._deps.onPointsChanged then
			self._deps.onPointsChanged(player)
		end
	end
end

function CoinManager:_createCoin(areaId: string)
	local zone, folder = getCoinZone(areaId)
	if not zone or not folder then
		return
	end
	if not CoinLogic.canSpawn(self._counts[areaId] or 0) then
		return
	end

	local ox, oz = CoinLogic.randomOffset(zone.Size.X, zone.Size.Z)
	local colorName = CoinLogic.colorForArea(areaId)
	local r, g, b = CoinLogic.rgbForColor(colorName)
	local pos = zone.Position + Vector3.new(ox, zone.Size.Y / 2 + Constants.COIN_HEIGHT, oz)

	local model = Instance.new("Model")
	model.Name = "Coin"
	model:SetAttribute("AreaId", areaId)
	model:SetAttribute("Points", CoinLogic.pointsPerCoin())
	model:SetAttribute("Collected", false)

	-- Визуал (тонкий цилиндр) — вертикально, крутится + bob на клиенте
	local visual = Instance.new("Part")
	visual.Name = "Visual"
	visual.Shape = Enum.PartType.Cylinder
	visual.Size = Vector3.new(Constants.COIN_THICKNESS, Constants.COIN_RADIUS * 2, Constants.COIN_RADIUS * 2)
	-- Identity: ось цилиндра по X → монета стоит вертикально
	visual.CFrame = CFrame.new(pos)
	visual.Anchored = true
	visual.CanCollide = false
	visual.CanTouch = false
	visual.CanQuery = false
	visual.CastShadow = false
	visual.Material = Enum.Material.Neon
	visual.Color = Color3.fromRGB(r, g, b)
	visual:SetAttribute("HomeY", pos.Y)
	visual:SetAttribute("BobPhase", math.random() * math.pi * 2)
	visual.Parent = model
	CollectionService:AddTag(visual, COIN_TAG)

	-- Крупный хитбокс — надёжный Touched
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Shape = Enum.PartType.Ball
	hitbox.Size = Vector3.new(Constants.COIN_HITBOX, Constants.COIN_HITBOX, Constants.COIN_HITBOX)
	hitbox.CFrame = CFrame.new(pos)
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanTouch = true
	hitbox.CanQuery = true
	hitbox.Transparency = 1
	hitbox.CastShadow = false
	hitbox.Parent = model

	model.PrimaryPart = hitbox
	model.Parent = folder

	self._counts[areaId] = (self._counts[areaId] or 0) + 1
	local count = self._counts[areaId]
	-- На лимите — сразу в консоль; иначе не чаще раза в секунду
	self:_logCounts(count >= Constants.COIN_MAX_PER_AREA)

	hitbox.Touched:Connect(function(hit)
		if model:GetAttribute("Collected") == true or not model.Parent then
			return
		end
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		self:_collect(player, model, areaId)
	end)
end

function CoinManager:_spawnLoop(areaId: string)
	task.spawn(function()
		while self._started do
			local ok, err = pcall(function()
				self:_createCoin(areaId)
			end)
			if not ok then
				Logger.warn("CoinManager", `spawn {areaId}: {err}`)
			end
			task.wait(Constants.COIN_SPAWN_INTERVAL)
		end
	end)
end

function CoinManager:start()
	if self._started then
		return
	end
	self._started = true

	task.spawn(function()
		local deadline = os.clock() + 30
		while os.clock() < deadline do
			if getCoinZone("Area1") and getCoinZone("Area2") then
				break
			end
			task.wait(0.25)
		end
		if not getCoinZone("Area1") then
			Logger.warn("CoinManager", "Area1 Coins.Area not found — is TEST place open?")
		end
		self:_spawnLoop("Area1")
		self:_spawnLoop("Area2")
		Logger.info("CoinManager", "started")
	end)
end

return CoinManager
