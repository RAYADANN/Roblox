--!strict

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreatureDatabase = require(ReplicatedStorage.shared.data.CreatureDatabase)
local BlockDatabase = require(ReplicatedStorage.shared.data.BlockDatabase)
local EconomyConfig = require(ReplicatedStorage.shared.data.EconomyConfig)
local FormatOneIn = require(ReplicatedStorage.shared.util.FormatOneIn)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local RarityLogic = require(ReplicatedStorage.shared.util.RarityLogic)
local WorldUi = require(ReplicatedStorage.shared.ui.WorldUi)
local RollLogic = require(ReplicatedStorage.shared.util.RollLogic)
local CreatureFactory = require(ReplicatedStorage.shared.util.CreatureFactory)
local Remotes = require(ReplicatedStorage.shared.net.Remotes)
local SessionService = require(script.Parent.SessionService)
local BaseService = require(script.Parent.BaseService)
local CreatureService = require(script.Parent.CreatureService)
local RateLimiter = require(script.Parent.util.RateLimiter)

export type Deps = {
	sessionService: SessionService.SessionService,
	baseService: BaseService.BaseService,
	creatureService: CreatureService.CreatureService,
	remotes: Remotes.RemotesApi,
	syncHud: (player: Player) -> (),
	notify: (player: Player, kind: string, payload: string) -> (),
}

local RollService = {}
RollService.__index = RollService

export type RollService = typeof(setmetatable(
	{} :: {
		_deps: Deps,
		_rollLimit: RateLimiter.RateLimiter,
		_buyLimit: RateLimiter.RateLimiter,
		_connections: { RBXScriptConnection },
	},
	RollService
))

function RollService.new(deps: Deps): RollService
	return setmetatable({
		_deps = deps,
		_rollLimit = RateLimiter.new(5, 1),
		_buyLimit = RateLimiter.new(4, 1),
		_connections = {},
	}, RollService)
end

local function setPreviewLabel(part: BasePart, billboardName: string, props: {
	title: string,
	odds: string,
	meta: string,
	accent: Color3?,
})
	WorldUi.setPadPreview(part, billboardName, props)
end

local function setBuyEnabled(part: BasePart, promptName: string, enabled: boolean, objectText: string?)
	local prompt = part:FindFirstChild(promptName)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = enabled
		if objectText then
			prompt.ObjectText = objectText
		end
	end
end

function RollService:_updateCreaturePad(player: Player)
	local plot = self._deps.baseService:getPlotForPlayer(player)
	local data = self._deps.sessionService:get(player)
	if not plot or not data then
		return
	end
	local preview = data.creaturePreview
	if preview then
		local rarity = preview.rarity :: RarityLogic.Rarity
		local accent = WorldUi.bandColor(rarity)
		setPreviewLabel(plot.creatureRollPart, "CreaturePreviewBillboard", {
			title = preview.displayName,
			odds = FormatOneIn(preview.oneIn),
			meta = `${preview.buyCost}`,
			accent = accent,
		})
		setBuyEnabled(plot.creatureRollPart, "CreatureBuyPrompt", true, `${preview.buyCost}`)
	else
		setPreviewLabel(plot.creatureRollPart, "CreaturePreviewBillboard", {
			title = "Ready",
			odds = "Press Roll",
			meta = "Free preview",
			accent = WorldUi.Colors.gold,
		})
		setBuyEnabled(plot.creatureRollPart, "CreatureBuyPrompt", false, "Confirm purchase")
	end
end

function RollService:_updateBlockPad(player: Player)
	local plot = self._deps.baseService:getPlotForPlayer(player)
	local data = self._deps.sessionService:get(player)
	if not plot or not data then
		return
	end
	local preview = data.blockPreview
	if preview then
		local rarity = preview.rarity :: RarityLogic.Rarity
		local accent = WorldUi.bandColor(rarity)
		setPreviewLabel(plot.blockRollPart, "BlockPreviewBillboard", {
			title = preview.displayName,
			odds = FormatOneIn(preview.oneIn),
			meta = `${preview.buyCost} → +{preview.grantQty or 100}`,
			accent = accent,
		})
		setBuyEnabled(plot.blockRollPart, "BlockBuyPrompt", true, `${preview.buyCost} · +{preview.grantQty or 100}`)
	else
		setPreviewLabel(plot.blockRollPart, "BlockPreviewBillboard", {
			title = "Ready",
			odds = "Press Roll",
			meta = "Free preview",
			accent = WorldUi.Colors.gold,
		})
		setBuyEnabled(plot.blockRollPart, "BlockBuyPrompt", false, "+100 blocks")
	end
end

function RollService:rollCreature(player: Player): boolean
	if not self._rollLimit:allow(player) then
		return false
	end
	local data = self._deps.sessionService:get(player)
	if not data then
		return false
	end
	local template = RollLogic.pickCreatureTemplate(data.luckCreature)
	if not template then
		return false
	end
	data.creaturePreview = RollLogic.creaturePreviewFromTemplate(template)
	self:_updateCreaturePad(player)
	self._deps.syncHud(player)
	return true
end

function RollService:buyCreature(player: Player): boolean
	if not self._buyLimit:allow(player) then
		return false
	end
	local data = self._deps.sessionService:get(player)
	if not data or not data.creaturePreview then
		return false
	end
	local preview = data.creaturePreview
	if self._deps.sessionService:creatureCount(player) >= EconomyConfig.storageCap then
		self._deps.notify(player, "error", "Storage full")
		return false
	end
	if data.cash < preview.buyCost then
		self._deps.notify(player, "error", "Not enough cash")
		return false
	end
	local template = CreatureDatabase.getTemplate(preview.templateId)
	if not template then
		return false
	end

	data.cash -= preview.buyCost
	local nestId = self._deps.sessionService:findEmptyNest(player)
	local creature = CreatureFactory.fromTemplate(template, player.UserId, nestId)
	data.creatures[creature.id] = creature
	data.creaturePreview = nil
	self:_updateCreaturePad(player)
	self._deps.creatureService:refreshPlayer(player)
	self._deps.syncHud(player)
	self._deps.notify(player, "buy", `{creature.displayName} · {FormatOneIn(creature.oneIn)}`)
	Logger.debug("RollService", `{player.Name} bought {creature.displayName}`)
	return true
end

function RollService:rollBlock(player: Player): boolean
	if not self._rollLimit:allow(player) then
		return false
	end
	local data = self._deps.sessionService:get(player)
	if not data then
		return false
	end
	local template = RollLogic.pickBlockTemplate()
	if not template then
		return false
	end
	data.blockPreview = RollLogic.blockPreviewFromTemplate(template)
	self:_updateBlockPad(player)
	self._deps.syncHud(player)
	return true
end

function RollService:buyBlock(player: Player): boolean
	if not self._buyLimit:allow(player) then
		return false
	end
	local data = self._deps.sessionService:get(player)
	if not data or not data.blockPreview then
		return false
	end
	local preview = data.blockPreview
	if data.cash < preview.buyCost then
		self._deps.notify(player, "error", "Not enough cash")
		return false
	end
	local template = BlockDatabase.get(preview.templateId)
	if not template then
		return false
	end
	data.cash -= preview.buyCost
	local qty = template.grantQty
	data.blockInventory[template.id] = (data.blockInventory[template.id] or 0) + qty
	data.blockPreview = nil
	self:_updateBlockPad(player)
	self._deps.syncHud(player)
	self._deps.notify(player, "buy", `+{qty} {template.id}`)
	return true
end

function RollService:start()
	local remotes = self._deps.remotes
	table.insert(self._connections, remotes.RequestCreatureRoll.OnServerEvent:Connect(function(player)
		self:rollCreature(player)
	end))
	table.insert(self._connections, remotes.ConfirmCreatureBuy.OnServerEvent:Connect(function(player)
		self:buyCreature(player)
	end))
	table.insert(self._connections, remotes.RequestBlockRoll.OnServerEvent:Connect(function(player)
		self:rollBlock(player)
	end))
	table.insert(self._connections, remotes.ConfirmBlockBuy.OnServerEvent:Connect(function(player)
		self:buyBlock(player)
	end))

	table.insert(
		self._connections,
		ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
			local plot = self._deps.baseService:getPlotForPlayer(player)
			if not plot then
				return
			end
			if prompt.Name == "CreatureRollPrompt" and prompt.Parent == plot.creatureRollPart then
				self:rollCreature(player)
			elseif prompt.Name == "CreatureBuyPrompt" and prompt.Parent == plot.creatureRollPart then
				self:buyCreature(player)
			elseif prompt.Name == "BlockRollPrompt" and prompt.Parent == plot.blockRollPart then
				self:rollBlock(player)
			elseif prompt.Name == "BlockBuyPrompt" and prompt.Parent == plot.blockRollPart then
				self:buyBlock(player)
			end
		end)
	)
end

function RollService:onClaimed(player: Player)
	self:_updateCreaturePad(player)
	self:_updateBlockPad(player)
end

function RollService:destroy()
	for _, conn in self._connections do
		conn:Disconnect()
	end
	table.clear(self._connections)
end

return RollService
