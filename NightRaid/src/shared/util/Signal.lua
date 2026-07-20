--!strict

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Disconnect: (self: Connection) -> (),
	Connected: boolean,
}

export type Signal = {
	Connect: (self: Signal, callback: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	Destroy: (self: Signal) -> (),
}

function Signal.new(): Signal
	local self = setmetatable({
		_handlers = {} :: { (...any) -> () },
		_destroyed = false,
	}, Signal)
	return self
end

function Signal:Connect(callback: (...any) -> ()): Connection
	table.insert(self._handlers, callback)

	-- Two-step init: Disconnect must not close over a nil `connection` binding.
	local connection: Connection
	connection = {
		Connected = true,
		Disconnect = function(selfConn: Connection)
			if not selfConn.Connected then
				return
			end
			selfConn.Connected = false
			for i, handler in ipairs(self._handlers) do
				if handler == callback then
					table.remove(self._handlers, i)
					break
				end
			end
		end,
	}
	return connection
end

function Signal:Fire(...: any)
	if self._destroyed then
		return
	end
	for _, handler in ipairs(self._handlers) do
		task.spawn(handler, ...)
	end
end

function Signal:Destroy()
	self._destroyed = true
	table.clear(self._handlers)
end

return Signal
