--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)

export type Options = {
    hoverScale: number?,
    pressScale: number?,
    disabled: boolean?,
}

local function useHoverPress(opts: Options?): (number, {
    onMouseEnter: () -> (),
    onMouseLeave: () -> (),
    onMouseDown: () -> (),
    onMouseUp: () -> (),
})
    local hoverScale = if opts and opts.hoverScale
        then opts.hoverScale
        else MotionPresets.HOVER_SCALE
    local pressScale = if opts and opts.pressScale
        then opts.pressScale
        else MotionPresets.PRESS_SCALE
    local disabled = if opts and opts.disabled then opts.disabled else false

    local scale, setScale = React.useState(1)
    local motorRef = React.useRef(nil :: Flipper.SingleMotor?)
    local hovering = React.useRef(false)
    local pressing = React.useRef(false)

    React.useEffect(function()
        local motor = Flipper.SingleMotor.new(1, false)
        motorRef.current = motor
        local conn = motor:onStep(function(v)
            setScale(v)
        end)
        motor:start()
        return function()
            conn:disconnect()
            motor:destroy()
        end
    end, {})

    local function setTarget(target: number)
        if disabled then
            return
        end
        local motor = motorRef.current
        if motor then
            motor:setGoal(Flipper.Spring.new(target, {
                frequency = MotionPresets.SPRING_SNAPPY.frequency,
                dampingRatio = MotionPresets.SPRING_SNAPPY.dampingRatio,
            }))
        end
    end

    local handlers = React.useMemo(function()
        return {
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
    end, { disabled, hoverScale, pressScale })

    return scale, handlers
end

return useHoverPress
