--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local springs = require(script.Parent.springs)

export type Options = {
    hoverScale: number?,
    pressScale: number?,
    disabled: boolean?,
    spring: springs.SpringOpts?,
}

local function useHoverPress(opts: Options?): (number, {
    onMouseEnter: () -> (),
    onMouseLeave: () -> (),
    onMouseDown: () -> (),
    onMouseUp: () -> (),
})
    local hoverScale = if opts and opts.hoverScale then opts.hoverScale else 1.035
    local pressScale = if opts and opts.pressScale then opts.pressScale else 0.96
    local disabled = if opts and opts.disabled then opts.disabled else false
    local spring = if opts and opts.spring then opts.spring else springs.soft

    local scale, setScale = React.useState(1)
    local motorRef = React.useRef(nil :: any)
    local hovering = React.useRef(false)
    local pressing = React.useRef(false)

    React.useEffect(function()
        local motor = Flipper.SingleMotor.new(1, false)
        motorRef.current = motor
        local conn = motor:onStep(function(v: number)
            setScale(v)
        end)
        motor:start()
        return function()
            conn:disconnect()
            motor:destroy()
            motorRef.current = nil
        end
    end, {})

    local function setTarget(target: number)
        if disabled then
            return
        end
        local motor = motorRef.current
        if motor then
            motor:setGoal(Flipper.Spring.new(target, spring))
        end
    end

    local handlers = {
        onMouseEnter = function()
            hovering.current = true
            if UserInputService.MouseEnabled then
                setTarget(hoverScale)
            end
        end,
        onMouseLeave = function()
            hovering.current = false
            pressing.current = false
            setTarget(1)
        end,
        onMouseDown = function()
            pressing.current = true
            setTarget(pressScale)
        end,
        onMouseUp = function()
            pressing.current = false
            if hovering.current and UserInputService.MouseEnabled then
                setTarget(hoverScale)
            else
                setTarget(1)
            end
        end,
    }

    return scale, handlers
end

return useHoverPress
