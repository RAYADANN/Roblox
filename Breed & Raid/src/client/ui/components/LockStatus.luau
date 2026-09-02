--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local StatusChip = require(script.Parent.StatusChip)

export type Props = {
	lockUntil: number,
}

local function LockStatus(props: Props): React.Node
	local now, setNow = React.useState(os.time())

	React.useEffect(function()
		if props.lockUntil <= os.time() then
			return
		end
		local last = 0
		local connection = RunService.Heartbeat:Connect(function()
			local current = os.time()
			if current ~= last then
				last = current
				setNow(current)
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { props.lockUntil })

	local seconds = math.max(0, props.lockUntil - now)
	if seconds <= 0 then
		return nil
	end

	return React.createElement(StatusChip, {
		text = `Base locked · {seconds}s`,
		tone = "info",
	})
end

return LockStatus
