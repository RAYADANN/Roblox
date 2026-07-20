--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local Remotes = require(shared.net.Remotes)
local CycleService = require(script.core.CycleService)
local BaseService = require(script.core.BaseService)
local EconomyService = require(script.core.EconomyService)
local LightService = require(script.core.LightService)
local BuildService = require(script.core.BuildService)
local PetService = require(script.core.PetService)
local RollService = require(script.core.RollService)
local StealService = require(script.core.StealService)
local MonsterService = require(script.core.MonsterService)

local _ = Remotes

local cycle = CycleService.new()
local base = BaseService.new()
local economy = EconomyService.new({ base = base })
base:bindEconomy(economy)

local lights = LightService.new()
local build = BuildService.new({ base = base, economy = economy, lights = lights })
local pets = PetService.new({ base = base })
economy:bindPets(pets)

local roll = RollService.new({ economy = economy, base = base })
local steal = StealService.new({
	base = base,
	economy = economy,
	pets = pets,
	build = build,
	cycle = cycle,
})
local monsters = MonsterService.new({
	cycle = cycle,
	economy = economy,
	lights = lights,
})

print("[NightRaid] PROVE foundation — Hub/Yard dual-roll + Collect + traps")

game:BindToClose(function()
	monsters:destroy()
	steal:destroy()
	roll:destroy()
	pets:destroy()
	build:destroy()
	lights:destroy()
	economy:destroy()
	base:destroy()
	cycle:destroy()
end)
