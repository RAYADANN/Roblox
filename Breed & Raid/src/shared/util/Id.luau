--!strict

local counter = 0

local Id = {}

function Id.new(): string
	counter += 1
	local a = math.floor(os.clock() * 1_000_000)
	local b = math.random(1, 1_000_000_000)
	return string.format("%d-%d-%d", a, b, counter)
end

return Id
