--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockDatabase = require(ReplicatedStorage.shared.data.BlockDatabase)
local CreatureDatabase = require(ReplicatedStorage.shared.data.CreatureDatabase)
local EconomyConfig = require(ReplicatedStorage.shared.data.EconomyConfig)
local PlotConfig = require(ReplicatedStorage.shared.data.PlotConfig)
local CreatureFactory = require(ReplicatedStorage.shared.util.CreatureFactory)
local EconomyLogic = require(ReplicatedStorage.shared.util.EconomyLogic)
local SessionTypes = require(ReplicatedStorage.shared.types.Session)

type SessionData = SessionTypes.SessionData
type HudPayload = SessionTypes.HudPayload
type CreatureInstance = SessionTypes.CreatureInstance
type HudCreature = SessionTypes.HudCreature

export type Deps = {}

local SessionService = {}
SessionService.__index = SessionService

export type SessionService = typeof(setmetatable(
	{} :: {
		_sessions: { [Player]: SessionData },
	},
	SessionService
))

function SessionService.new(_deps: Deps): SessionService
	return setmetatable({
		_sessions = {},
	}, SessionService)
end

function SessionService:create(player: Player): SessionData
	local data: SessionData = {
		cash = 0,
		buffer = 0,
		plotId = nil,
		nestsUnlocked = PlotConfig.startNests,
		creatures = {},
		blockInventory = {},
		placeables = {},
		luckCreature = 0,
		luckBreed = 0,
		starterGranted = false,
		creaturePreview = nil,
		blockPreview = nil,
		incubateJob = nil,
		lockUntil = 0,
		timesLockedToday = 0,
		joinedAt = os.time(),
	}
	self._sessions[player] = data
	return data
end

function SessionService:get(player: Player): SessionData?
	return self._sessions[player]
end

function SessionService:remove(player: Player)
	self._sessions[player] = nil
end

function SessionService:grantStarter(player: Player): boolean
	local data = self._sessions[player]
	if not data or data.starterGranted then
		return false
	end

	data.cash = EconomyConfig.starterCash
	data.blockInventory.dirt = (data.blockInventory.dirt or 0) + BlockDatabase.starterDirt
	data.blockInventory.spikes = (data.blockInventory.spikes or 0) + BlockDatabase.starterSpikes

	for _, grant in CreatureDatabase.starterGrants do
		local creature = CreatureFactory.fromTemplateId(grant.templateId, player.UserId, grant.nestId)
		if creature then
			data.creatures[creature.id] = creature
		end
	end

	data.starterGranted = true
	return true
end

function SessionService:creatureCount(player: Player): number
	local data = self._sessions[player]
	if not data then
		return 0
	end
	local n = 0
	for _ in data.creatures do
		n += 1
	end
	return n
end

function SessionService:findEmptyNest(player: Player): string?
	local data = self._sessions[player]
	if not data then
		return nil
	end
	local occupied: { [string]: boolean } = {}
	for _, creature in data.creatures do
		if creature.nestId then
			occupied[creature.nestId] = true
		end
	end
	local order = { "N1", "N2", "N3", "N4", "N5", "N6", "N7", "N8" }
	for _, nestId in order do
		local index = tonumber(string.sub(nestId, 2))
		if index and index <= data.nestsUnlocked and not occupied[nestId] then
			return nestId
		end
	end
	return nil
end

function SessionService:sumNestMps(player: Player): number
	local data = self._sessions[player]
	if not data then
		return 0
	end
	return EconomyLogic.sumNestMps(data.creatures)
end

function SessionService:buildHud(player: Player): HudPayload?
	local data = self._sessions[player]
	if not data then
		return nil
	end

	local list: { HudCreature } = {}
	for _, creature in data.creatures do
		table.insert(list, {
			id = creature.id,
			displayName = creature.displayName,
			oneIn = creature.oneIn,
			rarity = creature.rarity,
			mps = creature.mps,
			nestId = creature.nestId,
			isHybrid = creature.isHybrid,
		})
	end
	table.sort(list, function(a, b)
		return a.oneIn > b.oneIn
	end)

	local incubate = nil
	if data.incubateJob then
		incubate = {
			startedAt = data.incubateJob.startedAt,
			endsAt = data.incubateJob.endsAt,
			expectedOneIn = data.incubateJob.expectedOneIn,
			spedUp = data.incubateJob.spedUp,
		}
	end

	return {
		cash = data.cash,
		buffer = data.buffer,
		mps = self:sumNestMps(player),
		plotId = data.plotId,
		creaturePreview = data.creaturePreview,
		blockPreview = data.blockPreview,
		incubate = incubate,
		lockUntil = data.lockUntil,
		creatures = list,
		dirt = data.blockInventory.dirt or 0,
		spikes = data.blockInventory.spikes or 0,
		blocks = table.clone(data.blockInventory),
		notify = nil,
	}
end

function SessionService:destroy()
	table.clear(self._sessions)
end

return SessionService
