--!strict
-- Таймлайн слоёв: stagger 40–80ms без аллокаций в горячем цикле сверх необходимого.

local RunService = game:GetService("RunService")

export type StepFn = () -> ()

export type Timeline = {
	at: (self: Timeline, delaySec: number, fn: StepFn) -> (),
	start: (self: Timeline) -> (),
	cancel: (self: Timeline) -> (),
	destroy: (self: Timeline) -> (),
}

local Timeline = {}
Timeline.__index = Timeline

type Entry = { t: number, fn: StepFn }

function Timeline.new(): Timeline
	local self = setmetatable({
		_entries = {} :: { Entry },
		_conn = nil :: RBXScriptConnection?,
		_elapsed = 0,
		_started = false,
		_destroyed = false,
	}, Timeline)
	return (self :: any) :: Timeline
end

function Timeline:at(delaySec: number, fn: StepFn)
	assert(not self._started, "Timeline already started")
	table.insert(self._entries, { t = math.max(0, delaySec), fn = fn })
end

function Timeline:start()
	if self._destroyed or self._started then
		return
	end
	self._started = true
	table.sort(self._entries, function(a, b)
		return a.t < b.t
	end)
	local index = 1
	local entries = self._entries
	local n = #entries
	if n == 0 then
		return
	end
	self._conn = RunService.Heartbeat:Connect(function(dt)
		self._elapsed += dt
		local elapsed = self._elapsed
		while index <= n and entries[index].t <= elapsed do
			local ok, err = pcall(entries[index].fn)
			if not ok then
				warn(`[VFX.Timeline] step failed: {err}`)
			end
			index += 1
		end
		if index > n then
			self:cancel()
		end
	end)
end

function Timeline:cancel()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
end

function Timeline:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self:cancel()
	table.clear(self._entries)
end

return Timeline
