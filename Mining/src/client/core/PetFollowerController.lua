--!strict
-- Следование 3D-моделей питомцев за персонажем (local + remote).

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetDatabase = require(ReplicatedStorage:WaitForChild("shared").data.PetDatabase)
local PetLogic = require(ReplicatedStorage:WaitForChild("shared").util.PetLogic)
local PetModelKit = require(ReplicatedStorage:WaitForChild("shared").util.PetModelKit)

export type Controller = {
	setSlots: (self: Controller, slots: { PetLogic.EquippedEntry }) -> (),
	destroy: (self: Controller) -> (),
}

type ActivePet = {
	uid: string,
	petId: string,
	model: Model,
	parts: { BasePart },
	visible: boolean,
	position: Vector3?,
	orientation: CFrame?,
	phase: number,
}

local HEIGHT_BASE = 1.5
local BOB_AMPLITUDE = 0.12
local BOB_SPEED = 2.4
local POS_SMOOTH = 10
local YAW_SMOOTH = 12
local MAX_DT = 1 / 20

local PetFollowerController = {}

local function expAlpha(speed: number, dt: number): number
	return 1 - math.exp(-speed * dt)
end

local function buildOrientation(position: Vector3, root: BasePart): CFrame
	local rootRotation = root.CFrame - root.CFrame.Position
	return CFrame.new(position) * rootRotation * CFrame.Angles(0, math.pi, 0)
end

local function cacheModelParts(model: Model): { BasePart }
	local parts: { BasePart } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			parts[#parts + 1] = d
		end
	end
	return parts
end

local function slotLocalOffset(index: number, count: number): Vector3
	if count <= 1 then
		return Vector3.new(2.0, 0, 3.6)
	end
	if count == 2 then
		local side = if index == 1 then -2.2 else 2.2
		return Vector3.new(side, 0, 3.4)
	end
	local span = math.pi * 0.72
	local t = if count == 1 then 0.5 else (index - 1) / (count - 1)
	local angle = -span * 0.5 + span * t
	return Vector3.new(math.sin(angle) * 3.0, 0, 3.2 + math.cos(angle) * 1.4)
end

local function targetWorldPosition(root: BasePart, index: number, count: number, bob: number): Vector3
	local localOffset = slotLocalOffset(index, count)
	local worldOffset = root.CFrame:VectorToWorldSpace(localOffset)
	return root.Position + worldOffset + Vector3.new(0, HEIGHT_BASE + bob, 0)
end

function PetFollowerController.bind(getRoot: () -> BasePart?): Controller
	local currentSlots: { PetLogic.EquippedEntry } = {}
	local active: { [string]: ActivePet } = {}
	local conn: RBXScriptConnection? = nil
	local alive = true

	local function setEntryVisible(entry: ActivePet, visible: boolean)
		if entry.visible == visible then
			return
		end
		entry.visible = visible
		local transparency = if visible then 0 else 1
		for _, part in ipairs(entry.parts) do
			part.Transparency = transparency
		end
	end

	local function destroyPet(uid: string)
		local entry = active[uid]
		if entry then
			entry.model:Destroy()
			active[uid] = nil
		end
	end

	local function ensurePetModel(uid: string, petId: string, phase: number): ActivePet?
		if active[uid] then
			return active[uid]
		end
		local def = PetDatabase.get(petId)
		if not def then
			return nil
		end
		local display = PetModelKit.clonePetDisplay(def.modelName)
		if not display then
			return nil
		end
		display.model.Name = "DeepDigger_Pet_" .. uid
		display.model.Parent = workspace
		local entry: ActivePet = {
			uid = uid,
			petId = petId,
			model = display.model,
			parts = cacheModelParts(display.model),
			visible = true,
			position = nil,
			orientation = nil,
			phase = phase,
		}
		active[uid] = entry
		return entry
	end

	local function ensureLoop()
		if conn then
			return
		end
		conn = RunService.RenderStepped:Connect(function(dt)
			if not alive then
				return
			end
			dt = math.min(dt, MAX_DT)
			local root = getRoot()
			local count = #currentSlots
			if count == 0 then
				return
			end

			local clock = os.clock()
			local horizontalSpeed = 0
			if root then
				local vel = root.AssemblyLinearVelocity
				horizontalSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
			end
			local posSmooth = POS_SMOOTH + math.min(horizontalSpeed * 0.06, 5)

			for i, slot in ipairs(currentSlots) do
				local entry = active[slot.uid]
				if not entry then
					continue
				end
				if not root then
					setEntryVisible(entry, false)
					continue
				end
				setEntryVisible(entry, true)

				local bob = math.sin(clock * BOB_SPEED + entry.phase) * BOB_AMPLITUDE
				local targetPos = targetWorldPosition(root, i, count, bob)

				if not entry.position then
					entry.position = targetPos
				else
					entry.position = entry.position:Lerp(targetPos, expAlpha(posSmooth, dt))
				end

				local targetCF = buildOrientation(entry.position, root)
				if not entry.orientation then
					entry.orientation = targetCF
				else
					entry.orientation = entry.orientation:Lerp(targetCF, expAlpha(YAW_SMOOTH, dt))
				end

				entry.model:PivotTo(entry.orientation)
			end
		end)
	end

	local self: Controller = {} :: Controller

	function self:setSlots(slots: { PetLogic.EquippedEntry })
		local normalized: { PetLogic.EquippedEntry } = {}
		for _, slot in ipairs(slots) do
			if typeof(slot) == "table" and typeof(slot.uid) == "string" and slot.uid ~= ""
				and typeof(slot.petId) == "string" and slot.petId ~= ""
			then
				table.insert(normalized, { uid = slot.uid, petId = slot.petId })
			end
		end

		local keep: { [string]: boolean } = {}
		for _, slot in ipairs(normalized) do
			keep[slot.uid] = true
		end
		for uid in pairs(active) do
			if not keep[uid] then
				destroyPet(uid)
			end
		end

		currentSlots = normalized
		if #normalized == 0 then
			return
		end

		for i, slot in ipairs(normalized) do
			ensurePetModel(slot.uid, slot.petId, i * 1.9)
		end
		ensureLoop()
	end

	function self:destroy()
		alive = false
		if conn then
			conn:Disconnect()
			conn = nil
		end
		for uid in pairs(active) do
			destroyPet(uid)
		end
		currentSlots = {}
	end

	return self
end

return PetFollowerController
