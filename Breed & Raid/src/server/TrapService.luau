--!strict

-- Spikes: WalkSpeed ×0.5 while standing on enemy trap cell (GDD §8.7).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotConfig = require(ReplicatedStorage.shared.data.PlotConfig)
local BaseService = require(script.Parent.BaseService)

local CELL = PlotConfig.cellSize
local SLOW_MULT = 0.5

export type Deps = {
	baseService: BaseService.BaseService,
}

local TrapService = {}
TrapService.__index = TrapService

export type TrapService = typeof(setmetatable(
	{} :: {
		_deps: Deps,
	},
	TrapService
))

function TrapService.new(deps: Deps): TrapService
	return setmetatable({
		_deps = deps,
	}, TrapService)
end

local function onTrapCell(hrp: BasePart, trap: BasePart): boolean
	local pos = hrp.Position
	local tp = trap.Position
	local half = CELL * 0.55
	return math.abs(pos.X - tp.X) <= half
		and math.abs(pos.Z - tp.Z) <= half
		and pos.Y >= tp.Y - 1.5
		and pos.Y <= tp.Y + CELL + 3
end

function TrapService:getSlowMult(player: Player): number
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return 1
	end

	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return 1
	end

	for _, plotModel in plots:GetChildren() do
		if plotModel:IsA("Model") then
			local build = plotModel:FindFirstChild("Build")
			if build then
				for _, part in build:GetChildren() do
					if part:IsA("BasePart") and part:GetAttribute("IsTrap") == true then
						local ownerUserId = part:GetAttribute("OwnerUserId")
						if ownerUserId ~= player.UserId and onTrapCell(hrp, part) then
							return SLOW_MULT
						end
					end
				end
			end
		end
	end
	return 1
end

function TrapService:destroy() end

return TrapService
