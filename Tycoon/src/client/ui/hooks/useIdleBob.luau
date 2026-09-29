--!strict
-- Idle up/down via Flipper Linear + sine. Writes Position on RenderStepped (no React state).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)

local TWO_PI = math.pi * 2

local function useIdleBob(xScale: number, restY: number, bobPx: number): (GuiObject?) -> ()
    local instanceRef = React.useRef(nil :: GuiObject?)
    local motorRef = React.useRef(nil :: Flipper.SingleMotor?)
    local xScaleRef = React.useRef(xScale)
    local restYRef = React.useRef(restY)
    local bobPxRef = React.useRef(bobPx)
    xScaleRef.current = xScale
    restYRef.current = restY
    bobPxRef.current = bobPx

    local function apply(t: number)
        local inst = instanceRef.current
        if inst == nil then
            return
        end
        inst.Position = UDim2.new(
            xScaleRef.current,
            0,
            restYRef.current,
            math.sin(t * TWO_PI) * bobPxRef.current
        )
    end

    React.useEffect(function()
        local periodSec = MotionPresets.IDLE_BOB.periodSec
        local motor = Flipper.SingleMotor.new(0, false)
        motorRef.current = motor
        local cancelled = false
        local wrapping = false

        local function runCycle()
            motor:setGoal(Flipper.Linear.new(1, {
                velocity = 1 / periodSec,
            }))
        end

        local stepConn = motor:onStep(apply)
        local completeConn = motor:onComplete(function()
            if cancelled then
                return
            end
            if wrapping then
                wrapping = false
                runCycle()
                return
            end
            wrapping = true
            motor:setGoal(Flipper.Instant.new(0))
        end)

        motor:start()
        runCycle()

        return function()
            cancelled = true
            stepConn:disconnect()
            completeConn:disconnect()
            motor:destroy()
            motorRef.current = nil
        end
    end, {})

    return React.useCallback(function(inst: GuiObject?)
        instanceRef.current = inst
        local motor = motorRef.current
        if inst and motor then
            apply(motor:getValue())
        end
    end, {})
end

return useIdleBob
