--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)

export type SpringConfig = { frequency: number, dampingRatio: number }

local function useFlipperSpring(target: number, config: SpringConfig): number
	local value, setValue = React.useState(target)
	local motorRef = React.useRef(nil :: Flipper.SingleMotor?)

	React.useEffect(function()
		local motor = Flipper.SingleMotor.new(target, false)
		motorRef.current = motor
		local conn = motor:onStep(function(v)
			setValue(v)
		end)
		motor:start()
		return function()
			conn:disconnect()
			motor:destroy()
			motorRef.current = nil
		end
	end, {})

	React.useEffect(function()
		local motor = motorRef.current
		if motor then
			motor:setGoal(Flipper.Spring.new(target, {
				frequency = config.frequency,
				dampingRatio = config.dampingRatio,
			}))
		end
	end, { target, config.frequency, config.dampingRatio })

	return value
end

return useFlipperSpring
