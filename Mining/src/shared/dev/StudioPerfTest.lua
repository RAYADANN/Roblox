--!strict
-- StudioPerfTest.lua — 5-минутный цикл нагрузочного теста в Roblox Studio.
-- Запуск: в Play Mode в чате `/perftest` (или `/perftest 300`).
-- Требует фокус на окне Studio (иначе Render FPS троттлится).

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modules = ReplicatedStorage:WaitForChild("Packages")
local shared = ReplicatedStorage:WaitForChild("shared")
local Net = require(modules.Net)
local Constants = require(shared.constants)
local FreezeDiagnostics = nil :: any
local StudioTestHud = require(shared.dev.StudioTestHud)

export type Deps = {
	freezeDiagnostics: any,
	getSwingDelay: () -> number,
}

local UPGRADE_IDS = { "pickaxe", "speed", "fortune", "inventory", "crit", "multiSell", "autoSell" }
local MINE_FOLDER = "DeepDigger_Mine"
local RAYCAST_DISTANCE = 200
local BLOCK_SIZE = Constants.BLOCK_SIZE_STUDS

local StudioPerfTest = {}
local _running = false

local function devCommand(msg: string)
	pcall(function()
		Net:Invoke("StudioDevCommand", msg)
	end)
end

local function parseKey(k: string): (number, number, number)
	local parts = string.split(k, "_")
	return tonumber(parts[1]) or 0, tonumber(parts[2]) or 0, tonumber(parts[3]) or 0
end

local function isMineBlockPart(part: Instance): boolean
	if not part:IsA("BasePart") or part:GetAttribute("_destroying") then
		return false
	end
	local x, z, y = parseKey(part.Name)
	return string.format("%d_%d_%d", x, z, y) == part.Name
end

local function mineRayParams(): RaycastParams?
	local folder = Workspace:FindFirstChild(MINE_FOLDER)
	if not folder then
		return nil
	end
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Include
	p.FilterDescendantsInstances = { folder }
	p.IgnoreWater = true
	return p
end

local function findMineTarget(): BasePart?
	local cam = Workspace.CurrentCamera
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not cam or not root then
		return nil
	end
	local params = mineRayParams()
	if not params then
		return nil
	end
	-- Смотрим чуть вниз от камеры — типичная поза при копании в глубину.
	local origin = cam.CFrame.Position
	local direction = (cam.CFrame.LookVector + Vector3.new(0, -0.35, 0)).Unit
	local hit = Workspace:Raycast(origin, direction * RAYCAST_DISTANCE, params)
	if hit and hit.Instance:IsA("BasePart") and isMineBlockPart(hit.Instance) then
		local dist = (hit.Instance.Position - root.Position).Magnitude
		if dist <= BLOCK_SIZE * (Constants.MAX_MINE_REACH_BLOCKS or 6) + 4 then
			return hit.Instance
		end
	end
	-- Фоллбэк: ближайший блок в радиусе досягаемости.
	local folder = Workspace:FindFirstChild(MINE_FOLDER)
	if not folder then
		return nil
	end
	local best: BasePart? = nil
	local bestDist = math.huge
	local reach = BLOCK_SIZE * (Constants.MAX_MINE_REACH_BLOCKS or 6) + 2
	for _, child in folder:GetChildren() do
		if isMineBlockPart(child) then
			local d = (child.Position - root.Position).Magnitude
			if d <= reach and d < bestDist then
				bestDist = d
				best = child
			end
		end
	end
	return best
end

local function mineOnce(swingDelay: number, lastSwing: { number }): boolean
	local now = os.clock()
	if now - lastSwing[1] < swingDelay * 0.95 then
		return false
	end
	local part = findMineTarget()
	if not part then
		return false
	end
	local x, z, y = parseKey(part.Name)
	lastSwing[1] = now
	local ok, res = pcall(function()
		return Net:Invoke("MineBlock", { { x = x, z = z, y = y } })
	end)
	if ok and res and res[1] and res[1].success then
		return true
	end
	return false
end

local function teleportToMine()
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local target: Vector3?
	local mineRespawn = Workspace:FindFirstChild("MineRespawn")
	if mineRespawn and mineRespawn:IsA("BasePart") then
		target = mineRespawn.Position + Vector3.new(0, BLOCK_SIZE * 3, 0)
	else
		local folder = Workspace:FindFirstChild(MINE_FOLDER)
		local surface = folder and folder:FindFirstChild("0_0_0") :: BasePart?
		if surface then
			target = surface.Position + Vector3.new(0, BLOCK_SIZE * 3, 0)
		end
	end
	if target then
		hrp.CFrame = CFrame.new(target)
	end
end

local function setupPlayer()
	devCommand("/coins 999999999")
	task.wait(0.4)
	for _, id in UPGRADE_IDS do
		devCommand("/maxlvl " .. id)
		task.wait(0.15)
	end
	task.wait(0.5)
	teleportToMine()
	task.wait(0.8)
end

local function pollPerfAttrs(): { [string]: any }
	local w = Workspace
	return {
		syncListeners = w:GetAttribute("DD_syncListeners"),
		dupFires = w:GetAttribute("DD_dupFires"),
		maxBatchCreated = w:GetAttribute("DD_maxBatchCreated"),
		createPartMsAvg = w:GetAttribute("DD_createPartMsAvg"),
		createPartMsMax = w:GetAttribute("DD_createPartMsMax"),
		drainMsMax = w:GetAttribute("DD_drainMsMax"),
		applyDeltaMsMax = w:GetAttribute("DD_applyDeltaMsMax"),
		fastRemoves = w:GetAttribute("DD_fastRemoves"),
	}
end

local function countMineParts(): number
	local f = Workspace:FindFirstChild(MINE_FOLDER)
	if not f then
		return 0
	end
	local n = 0
	for _, c in f:GetChildren() do
		if c:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

local function stressHud()
	if StudioTestHud.openTab("upgrades") then
		task.wait(0.8)
		StudioTestHud.openTab("shop")
		task.wait(0.5)
		StudioTestHud.closePanel()
	end
end

function StudioPerfTest.isRunning(): boolean
	return _running
end

function StudioPerfTest.run(deps: Deps, durationSec: number?)
	if not RunService:IsStudio() then
		warn("[PerfTest] Только Roblox Studio")
		return
	end
	if _running then
		print("[PerfTest] Уже выполняется")
		return
	end
	_running = true
	FreezeDiagnostics = deps.freezeDiagnostics
	durationSec = math.clamp(durationSec or 300, 30, 900)

	print(string.format(
		"[PerfTest] Старт %d с. Держите окно Studio в фокусе. FreezeDiagnostics уже активен; финал — /diagreport.",
		durationSec
	))
	print("[PerfTest] Чеклист: копание вглубь → /perftest сам продаёт и открывает панели.")
	print("[PerfTest] Для чистого замера FPS сначала введите /diagreset в чат.")

	setupPlayer()

	local startParts = countMineParts()
	local t0 = os.clock()
	local lastSwing = { 0 }
	local lastSell = 0
	local lastHud = 0
	local lastPoll = 0
	local mines = 0
	local sells = 0

	while os.clock() - t0 < durationSec do
		local swingDelay = deps.getSwingDelay()
		if mineOnce(swingDelay, lastSwing) then
			mines += 1
		end

		local now = os.clock()
		if now - lastSell >= 12 then
			lastSell = now
			local ok = pcall(function()
				Net:Invoke("SellOres")
			end)
			if ok then
				sells += 1
			end
		end

		if now - lastHud >= 45 then
			lastHud = now
			stressHud()
		end

		if now - lastPoll >= 30 then
			lastPoll = now
			local attrs = pollPerfAttrs()
			print(string.format(
				"[PerfTest] t=%.0fs mines=%d sells=%d parts=%d→%d DD_dup=%s DD_maxBatch=%s createMs=%s",
				now - t0,
				mines,
				sells,
				startParts,
				countMineParts(),
				tostring(attrs.dupFires),
				tostring(attrs.maxBatchCreated),
				tostring(attrs.createPartMsAvg)
			))
			if typeof(attrs.dupFires) == "number" and attrs.dupFires > 0 then
				warn("[PerfTest] DD_dupFires > 0 — утечка SyncBlocks listener!")
			end
		end

		RunService.Heartbeat:Wait()
	end

	local elapsed = os.clock() - t0
	print(string.format(
		"[PerfTest] Готово за %.1f с | ударов=%d | продаж=%d | блоков %d→%d",
		elapsed,
		mines,
		sells,
		startParts,
		countMineParts()
	))
	print("[PerfTest] Атрибуты рендера:", pollPerfAttrs())

	if FreezeDiagnostics and FreezeDiagnostics.report then
		FreezeDiagnostics.report()
	else
		print("[PerfTest] Для полного отчёта FPS введите /diagreport в чат.")
	end

	_running = false
end

return StudioPerfTest
