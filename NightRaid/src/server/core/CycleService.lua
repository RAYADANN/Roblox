--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local CycleConfig = require(shared.data.CycleConfig)
local Signal = require(shared.util.Signal)
local Remotes = require(shared.net.Remotes)

type CyclePhase = "Day" | "Dusk" | "Night" | "Dawn"

export type CycleService = {
	getPhase: (self: CycleService) -> CyclePhase,
	getRemaining: (self: CycleService) -> number,
	onPhaseChanged: Signal.Signal,
	destroy: (self: CycleService) -> (),
}

local CycleService = {}
CycleService.__index = CycleService

function CycleService.new(): CycleService
	local self = setmetatable({
		_phase = "Day" :: CyclePhase,
		_endsAt = os.clock() + CycleConfig.durationFor("Day"),
		onPhaseChanged = Signal.new(),
		_running = true,
	}, CycleService)

	Remotes.CycleChanged:FireAllClients(self._phase, CycleConfig.durationFor(self._phase))

	task.spawn(function()
		while self._running do
			local remaining = self._endsAt - os.clock()
			if remaining <= 0 then
				local nextPhase = CycleConfig.nextPhase(self._phase)
				self._phase = nextPhase
				local duration = CycleConfig.durationFor(nextPhase)
				self._endsAt = os.clock() + duration
				self.onPhaseChanged:Fire(nextPhase, duration)
				Remotes.CycleChanged:FireAllClients(nextPhase, duration)
			else
				task.wait(math.min(0.25, remaining))
			end
		end
	end)

	return self
end

function CycleService:getPhase(): CyclePhase
	return self._phase
end

function CycleService:getRemaining(): number
	return math.max(0, self._endsAt - os.clock())
end

function CycleService:destroy()
	self._running = false
	self.onPhaseChanged:Destroy()
end

return CycleService
