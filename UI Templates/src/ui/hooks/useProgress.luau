--!strict
-- Animate a 0–1 progress value with Flipper (bars, meters).

local React = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages").React)

local springs = require(script.Parent.springs)
local useSpringValue = require(script.Parent.useSpringValue)

export type Options = {
    progress: number,
    delay: number?,
    frequency: number?,
    dampingRatio: number?,
}

local function useProgress(opts: Options): number
    local target = math.clamp(opts.progress, 0, 1)
    local delaySec = opts.delay or 0
    local spring = {
        frequency = opts.frequency or springs.slow.frequency,
        dampingRatio = opts.dampingRatio or springs.slow.dampingRatio,
    }

    local value, setGoal = useSpringValue(0, spring)

    React.useEffect(function()
        local cancelled = false
        task.delay(delaySec, function()
            if cancelled then
                return
            end
            setGoal(target, spring)
        end)
        return function()
            cancelled = true
        end
    end, { target, delaySec })

    return value
end

return useProgress
