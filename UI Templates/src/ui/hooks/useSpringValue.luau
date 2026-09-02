--!strict
-- Shared Flipper SingleMotor + Spring for React state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local springs = require(script.Parent.springs)

export type SpringOpts = springs.SpringOpts

local function useSpringValue(
    initial: number,
    defaultSpring: SpringOpts?
): (number, (number, SpringOpts?) -> ())
    local value, setValue = React.useState(initial)
    local motorRef = React.useRef(nil :: any)

	local preset = defaultSpring or springs.soft

	React.useEffect(function()
		local motor = Flipper.SingleMotor.new(initial, false)
		motorRef.current = motor
		local conn = motor:onStep(function(v: number)
			setValue(v)
		end)
		motor:start()
		return function()
			conn:disconnect()
			motor:destroy()
			motorRef.current = nil
		end
	end, {})

	local function setGoal(target: number, spring: SpringOpts?)
		local motor = motorRef.current
		if not motor then
			return
		end
		local s = spring or preset
		motor:setGoal(Flipper.Spring.new(target, {
			frequency = s.frequency,
			dampingRatio = s.dampingRatio,
		}))
	end

    return value, setGoal
end

return useSpringValue
