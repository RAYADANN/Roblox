--!strict
-- Data-driven последовательность сцен онбординга.
--
-- Конвенция таргетов:
--   * `block`              → ближайший part в workspace.DeepDigger_Mine
--   * `Tab_inventory`      → кнопка рюкзака в нижнем доке
--   * `HubZone_SELL`       → Workspace.SELL (зона продажи в хабе)
--   * `HubZone_UPGRADE`    → Workspace.UPGRADE (зона улучшений)
--   * `UpgRow_pickaxe`     → строка покупки кирки в открытой панели
--
-- `completeOn`:
--   * `block_mined`      → totalBlocksMined вырос
--   * `ore_sold`         → totalCoinsEarned вырос (авто-продажа в зоне SELL)
--   * `upgrades_ready`   → панель улучшений открыта (UpgRow_pickaxe виден)
--   * `pickaxe_bought`   → pickaxeLevel > 1
--   * `tab_inventory`    → клик по Tab_inventory (опционально)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

export type CompleteCriterion =
	"block_mined"
	| "ore_sold"
	| "pickaxe_bought"
	| "tab_inventory"
	| "upgrades_ready"

export type Scene = {
	id: string,
	speaker: string,
	name: string,
	text: string,
	task: { title: string, description: string, goal: number? }?,
	target: string?,
	arrowText: string?,
	completeOn: CompleteCriterion?,
	hideAdvanceButton: boolean?,
	kind: "intro" | "task" | "success" | "finale",
	next: string?,
}

local NARRATOR_NAME = L("tutorial.narrator.name")
local NARRATOR_ICON = "🤖"

local TutorialFlow = {}

TutorialFlow.STEPS = {
	{
		id = "welcome",
		kind = "intro",
		speaker = NARRATOR_ICON,
		name = NARRATOR_NAME,
		text = L("tutorial.welcome"),
	} :: Scene,

	-- ===== STEP 0: добыть первый блок =====
	{
		id = "step_0_task",
		kind = "task",
		speaker = NARRATOR_ICON,
		name = NARRATOR_NAME,
        text = L("tutorial.step0.task"),
		task = { title = L("tutorial.task.counter", { current = 1, total = 3 }), description = L("tutorial.step0.taskDesc"), goal = 1 },
		target = "block",
		arrowText = L("tutorial.step0.arrow"),
		completeOn = "block_mined",
		hideAdvanceButton = true,
	} :: Scene,
	{
		id = "step_0_success",
		kind = "success",
		speaker = NARRATOR_ICON,
		name = NARRATOR_NAME,
		text = L("tutorial.step0.success"),
	} :: Scene,

	-- ===== STEP 1: продажа в зоне хаба =====
	{
		id = "step_1_sell",
		kind = "task",
		speaker = NARRATOR_ICON,
		name = NARRATOR_NAME,
        text = L("tutorial.step1.task"),
		task = { title = L("tutorial.task.counter", { current = 2, total = 3 }), description = L("tutorial.step1.taskDesc") },
		target = "HubZone_SELL",
		arrowText = L("tutorial.step1.arrow"),
		completeOn = "ore_sold",
		hideAdvanceButton = true,
	} :: Scene,
	{
		id = "step_1_success",
		kind = "success",
		speaker = NARRATOR_ICON,
		name = NARRATOR_NAME,
		text = L("tutorial.step1.success"),
	} :: Scene,

	-- ===== STEP 2: улучшения в зоне хаба =====
	{
		id = "step_2_go_upgrades",
		kind = "task",
		speaker = NARRATOR_ICON,
		name = NARRATOR_NAME,
		text = L("tutorial.step2.goTask"),
		task = { title = L("tutorial.task.counter", { current = 3, total = 3 }), description = L("tutorial.step2.goDesc") },
		target = "HubZone_UPGRADE",
		arrowText = L("tutorial.step2.goArrow"),
		completeOn = "upgrades_ready",
		hideAdvanceButton = true,
	} :: Scene,
	{
		id = "step_2_buy_pickaxe",
		kind = "task",
		speaker = NARRATOR_ICON,
		name = NARRATOR_NAME,
		text = L("tutorial.step2.buyTask"),
		task = { title = L("tutorial.task.counter", { current = 3, total = 3 }), description = L("tutorial.step2.buyDesc") },
		target = "UpgRow_pickaxe",
		arrowText = L("tutorial.step2.buyArrow"),
		completeOn = "pickaxe_bought",
		hideAdvanceButton = true,
	} :: Scene,

	{
		id = "finale",
		kind = "finale",
		speaker = NARRATOR_ICON,
		name = NARRATOR_NAME,
		text = L("tutorial.finale"),
	} :: Scene,
}

TutorialFlow.SERVER_STEP_AFTER = {
	step_0_success = 1,
	step_1_success = 2,
	finale = 3,
}

TutorialFlow.ENTRY_BY_SERVER_STEP = {
	[0] = "welcome",
	[1] = "step_1_sell",
	[2] = "step_2_go_upgrades",
	[3] = nil,
}

function TutorialFlow.findIndex(sceneId: string): number?
	for i, scene in ipairs(TutorialFlow.STEPS) do
		if scene.id == sceneId then
			return i
		end
	end
	return nil
end

function TutorialFlow.getById(sceneId: string): Scene?
	local idx = TutorialFlow.findIndex(sceneId)
	if not idx then
		return nil
	end
	return TutorialFlow.STEPS[idx]
end

function TutorialFlow.getNext(sceneId: string): Scene?
	local scene = TutorialFlow.getById(sceneId)
	if not scene then
		return nil
	end
	if scene.next then
		return TutorialFlow.getById(scene.next)
	end
	local idx = TutorialFlow.findIndex(sceneId)
	if idx then
		return TutorialFlow.STEPS[idx + 1]
	end
	return nil
end

return TutorialFlow
