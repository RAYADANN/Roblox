--!strict
-- Entrance: scale + fade in (optional delay for stagger).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local springs = require(script.Parent.springs)
local useSpringValue = require(script.Parent.useSpringValue)

export type Options = {
    delay: number?,
    fromScale: number?,
    frequency: number?,
    dampingRatio: number?,
}

local function useMountAppear(opts: Options?): (number, number)
    local delaySec = if opts and opts.delay then opts.delay else 0
    local fromScale = if opts and opts.fromScale then opts.fromScale else 0.92
    local spring = {
        frequency = if opts and opts.frequency then opts.frequency else springs.soft.frequency,
        dampingRatio = if opts and opts.dampingRatio
            then opts.dampingRatio
            else springs.soft.dampingRatio,
    }

    local scale, setScale = useSpringValue(fromScale, spring)
    local transparency, setTransparency = useSpringValue(1, springs.slow)

    React.useEffect(function()
        local cancelled = false
        task.delay(delaySec, function()
            if cancelled then
                return
            end
            setScale(1, spring)
            setTransparency(0, springs.slow)
        end)
        return function()
            cancelled = true
        end
    end, {})

    return scale, transparency
end

return useMountAppear
