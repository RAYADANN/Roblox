--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local CombatConfig = require(shared.data.CombatConfig)
local Remotes = require(shared.net.Remotes)
local BaseBuilder = require(script.Parent.BaseBuilder)

type BaseServiceLike = {
	getPlotForPlayer: (self: any, player: Player) -> BaseBuilder.BasePlot?,
	getPlotByIndex: (self: any, index: number) -> BaseBuilder.BasePlot?,
	getOwner: (self: any, plot: BaseBuilder.BasePlot) -> Player?,
	isLocked: (self: any, plot: BaseBuilder.BasePlot) -> boolean,
}

type EconomyLike = {
	takePetByUid: (self: any, owner: Player, uid: string) -> string?,
	addToInventory: (self: any, player: Player, petId: string) -> (),
	grantHomePet: (self: any, player: Player, petId: string) -> boolean,
	getState: (self: any, player: Player) -> any,
}

type PetServiceLike = {
	getHomePetNear: (self: any, worldPos: Vector3, maxDist: number) -> (Player?, string?, string?, Model?),
}

type BuildServiceLike = {
	applyBatHit: (self: any, attacker: Player, block: BasePart) -> boolean,
	getTrapSlow: (self: any, plot: any, worldPos: Vector3) -> number,
}

type CarryState = {
	petId: string,
	fromOwner: Player,
	marker: BasePart?,
}

export type StealService = {
	destroy: (self: StealService) -> (),
}

local StealService = {}
StealService.__index = StealService

local function giveTool(player: Player, name: string, color: Color3, tip: string)
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then
		return
	end
	if backpack:FindFirstChild(name) or (player.Character and player.Character:FindFirstChild(name)) then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.ToolTip = tip
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 2.2, 0.5)
	handle.Color = color
	handle.Parent = tool
	tool.Parent = backpack
end

local function giveHotbar(player: Player)
	giveTool(player, "Build", Color3.fromRGB(160, 120, 60), "Place from inventory")
	giveTool(player, "Take", Color3.fromRGB(80, 80, 90), "Remove own block → inventory")
	giveTool(player, "Edit", Color3.fromRGB(100, 140, 200), "Rotate (R) — stub")
	giveTool(player, "Bat", Color3.fromRGB(120, 80, 40), "Knockback thief / break enemy blocks")
end

function StealService.new(deps: {
	base: BaseServiceLike,
	economy: EconomyLike,
	pets: PetServiceLike,
	build: BuildServiceLike,
	cycle: { getPhase: (self: any) -> string },
}): StealService
	local self = setmetatable({
		_base = deps.base,
		_economy = deps.economy,
		_pets = deps.pets,
		_build = deps.build,
		_cycle = deps.cycle,
		_carrying = {} :: { [Player]: CarryState },
		_batCd = {} :: { [number]: number },
		_conns = {} :: { RBXScriptConnection },
	}, StealService)

	local function setupPlayer(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				giveHotbar(player)
			end)
		end)
		if player.Character then
			giveHotbar(player)
		end
	end

	table.insert(self._conns, Players.PlayerAdded:Connect(setupPlayer))
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	table.insert(
		self._conns,
		Remotes.RequestSteal.OnServerEvent:Connect(function(player: Player)
			self:_tryStealOrDeposit(player)
		end)
	)

	table.insert(
		self._conns,
		Remotes.BatHit.OnServerEvent:Connect(function(player: Player, targetUserId: any)
			if typeof(targetUserId) == "number" then
				self:_batHitPlayer(player, targetUserId)
			end
		end)
	)

	table.insert(
		self._conns,
		Remotes.BatHitBlock.OnServerEvent:Connect(function(player: Player, block: any)
			if typeof(block) == "Instance" and block:IsA("BasePart") then
				self._build:applyBatHit(player, block)
			end
		end)
	)

	table.insert(
		self._conns,
		Players.PlayerRemoving:Connect(function(player)
			self:_dropCarry(player)
			self._carrying[player] = nil
		end)
	)

	return self
end

function StealService:_attachCarryVisual(thief: Player, petId: string): BasePart?
	local character = thief.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local marker = Instance.new("Part")
	marker.Name = "StolenPet"
	marker.Shape = Enum.PartType.Ball
	marker.Size = Vector3.new(1.6, 1.6, 1.6)
	marker.Color = Color3.fromRGB(255, 160, 80)
	marker.Material = Enum.Material.Neon
	marker.Anchored = false
	marker.CanCollide = false
	marker.Massless = true
	marker.CFrame = root.CFrame * CFrame.new(0, 2.2, 1.2)
	marker.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = marker
	weld.Parent = marker
	return marker
end

function StealService:_tryStealOrDeposit(thief: Player)
	if self._cycle:getPhase() == "Night" then
		Remotes.Toast:FireClient(thief, "Can't steal at night")
		return
	end
	if self._carrying[thief] then
		self:_tryDeposit(thief)
		return
	end

	local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local owner, uid, petId = self._pets:getHomePetNear(root.Position, CombatConfig.Steal.stealRange)
	if not owner or not uid or not petId or owner == thief then
		return
	end
	local plot = self._base:getPlotForPlayer(owner)
	if not plot or self._base:isLocked(plot) then
		Remotes.Toast:FireClient(thief, "Base is locked")
		return
	end

	local taken = self._economy:takePetByUid(owner, uid)
	if taken ~= petId then
		return
	end

	local humanoid = thief.Character and thief.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16 * 0.65
	end

	self._carrying[thief] = {
		petId = petId,
		fromOwner = owner,
		marker = self:_attachCarryVisual(thief, petId),
	}
	thief:SetAttribute("StealingPetId", petId)
	Remotes.Toast:FireClient(thief, "Carrying pet — E in your yard!")
	Remotes.Toast:FireClient(owner, thief.Name .. " is stealing your pet!")
end

function StealService:_tryDeposit(thief: Player)
	local carry = self._carrying[thief]
	local ownPlot = self._base:getPlotForPlayer(thief)
	if not carry or not ownPlot then
		return
	end
	local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local zoneCenter = plot.origin.Position + Vector3.new(0, 2, 0)
	if (root.Position - zoneCenter).Magnitude > 22 then
		Remotes.Toast:FireClient(thief, "Stand in your yard to drop off")
		return
	end

	if self._economy:grantHomePet(thief, carry.petId) then
		if carry.marker then
			carry.marker:Destroy()
		end
		self._carrying[thief] = nil
		thief:SetAttribute("StealingPetId", "")
		local humanoid = thief.Character and thief.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
		end
		Remotes.Toast:FireClient(thief, "Stolen pet secured!")
	end
end

function StealService:_dropCarry(thief: Player)
	local carry = self._carrying[thief]
	if not carry then
		return
	end
	if carry.marker then
		carry.marker:Destroy()
	end
	if carry.fromOwner.Parent then
		self._economy:addToInventory(carry.fromOwner, carry.petId)
	end
	self._carrying[thief] = nil
	thief:SetAttribute("StealingPetId", "")
	local humanoid = thief.Character and thief.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
end

function StealService:_batHitPlayer(attacker: Player, targetUserId: number)
	local cd = self._batCd[attacker.UserId] or 0
	if os.clock() < cd then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or not self._carrying[target] then
		return
	end
	local aRoot = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
	local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not aRoot or not tRoot or not aRoot:IsA("BasePart") or not tRoot:IsA("BasePart") then
		return
	end
	if (aRoot.Position - tRoot.Position).Magnitude > CombatConfig.Steal.batRange then
		return
	end

	self._batCd[attacker.UserId] = os.clock() + CombatConfig.Steal.batCooldownSec
	local dir = (tRoot.Position - aRoot.Position)
	if dir.Magnitude < 0.1 then
		dir = aRoot.CFrame.LookVector
	end
	tRoot.AssemblyLinearVelocity = dir.Unit * CombatConfig.Steal.batKnockbackStuds * 3 + Vector3.new(0, 30, 0)
	self:_dropCarry(target)
	Remotes.Toast:FireClient(attacker, "Bat hit — pet dropped!")
	Remotes.Toast:FireClient(target, "Knocked! Pet returned to owner")
end

function StealService:destroy()
	for _, conn in self._conns do
		conn:Disconnect()
	end
	for player in self._carrying do
		self:_dropCarry(player)
	end
end

return StealService
