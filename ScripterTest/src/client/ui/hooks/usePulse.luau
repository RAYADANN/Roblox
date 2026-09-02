--!strict
-- Idle pulse (scale oscillates via Flipper Spring + onComplete).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local springs = require(script.Parent.springs)

export type Options = {
    minScale: number?,
    maxScale: number?,
    frequency: number?,
    enabled: boolean?,
}

local function usePulse(opts: Options?): number
    local minScale = if opts and opts.minScale then opts.minScale else 1
    local maxScale = if opts and opts.maxScale then opts.maxScale else 1.04
    local frequency = if opts and opts.frequency then opts.frequency else 1.6
    local enabled = if opts and opts.enabled ~= nil then opts.enabled else true

    local scale, setScale = React.useState(minScale)
    local motorRef = React.useRef(nil :: any)
    local towardMax = React.useRef(true)

    React.useEffect(function()
        if not enabled then
            setScale(minScale)
            return function() end
        end

        local motor = Flipper.SingleMotor.new(minScale, false)
        motorRef.current = motor

        local stepConn = motor:onStep(function(v: number)
            setScale(v)
        end)

        local function kick()
            local target = if towardMax.current then maxScale else minScale
            towardMax.current = not towardMax.current
            motor:setGoal(Flipper.Spring.new(target, {
                frequency = frequency,
                dampingRatio = springs.soft.dampingRatio,
            }))
        end

        local completeConn = motor:onComplete(kick)
        motor:start()
        kick()

        return function()
            stepConn:disconnect()
            completeConn:disconnect()
            motor:destroy()
            motorRef.current = nil
        end
    end, { enabled, minScale, maxScale, frequency })

    return scale
end

return usePulse
