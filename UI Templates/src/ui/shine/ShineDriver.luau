--!strict
-- Shared shine sweep: normalized 0→1 motor; each binding maps its own X range from shineWidth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)

export type Config = {
    intervalSec: number,
    durationSec: number,
}

export type BindOpts = {
    intervalSec: number?,
    durationSec: number?,
    positionY: number?,
    -- Shine strip width as fraction of parent width (AnchorPoint 0.5 on X).
    shineWidth: number?,
}

export type Binding = {
    instance: GuiObject,
    positionY: number,
    startX: number,
    endX: number,
}

type Phase = "sweep" | "wait" | "reset"

local SWEEP_DAMPING = 0.92
local DEFAULT_SHINE_WIDTH = 0.28
local SWEEP_MARGIN = 0.06

local DEFAULT_CONFIG: Config = {
    intervalSec = 2,
    durationSec = 0.65,
}

local bindings: { [number]: Binding } = {}
local nextBindingId = 0
local currentT = 0
local activeConfig: Config = DEFAULT_CONFIG

local motor: any = nil
local stepConn: any = nil
local completeConn: any = nil
local phase: Phase = "sweep"
local cancelled = false

local function sweepRange(shineWidth: number): (number, number)
    local half = shineWidth * 0.5
    return -half - SWEEP_MARGIN, 1 + half + SWEEP_MARGIN
end

local function bindingCount(): number
    local count = 0
    for _ in bindings do
        count += 1
    end
    return count
end

local function applyBinding(binding: Binding, t: number)
    local inst = binding.instance
    if inst.Parent == nil then
        return
    end
    local x = binding.startX + (binding.endX - binding.startX) * t
    inst.Position = UDim2.new(x, 0, binding.positionY, 0)
end

local function broadcast(t: number)
    currentT = t
    for _, binding in bindings do
        applyBinding(binding, t)
    end
end

local function destroyMotor()
    cancelled = true
    if stepConn then
        stepConn:disconnect()
        stepConn = nil
    end
    if completeConn then
        completeConn:disconnect()
        completeConn = nil
    end
    if motor then
        motor:destroy()
        motor = nil
    end
end

local function sweepRight()
    if motor == nil then
        return
    end
    phase = "sweep"
    motor:setGoal(Flipper.Spring.new(1, {
        frequency = 1 / activeConfig.durationSec,
        dampingRatio = SWEEP_DAMPING,
    }))
end

local function ensureMotor(opts: BindOpts?)
    if motor ~= nil then
        return
    end

    activeConfig = {
        intervalSec = if opts and opts.intervalSec
            then opts.intervalSec
            else DEFAULT_CONFIG.intervalSec,
        durationSec = if opts and opts.durationSec
            then opts.durationSec
            else DEFAULT_CONFIG.durationSec,
    }

    cancelled = false
    phase = "sweep"
    motor = Flipper.SingleMotor.new(0, false)
    stepConn = motor:onStep(broadcast)
    motor:start()

    completeConn = motor:onComplete(function()
        if cancelled or motor == nil then
            return
        end
        if phase == "sweep" then
            phase = "wait"
            task.delay(activeConfig.intervalSec, function()
                if cancelled or motor == nil then
                    return
                end
                phase = "reset"
                motor:setGoal(Flipper.Instant.new(0))
            end)
        elseif phase == "reset" then
            sweepRight()
        end
    end)

    task.defer(sweepRight)
end

local function maybeStopMotor()
    if bindingCount() == 0 then
        destroyMotor()
    end
end

local ShineDriver = {}

function ShineDriver.sweepRange(shineWidth: number): (number, number)
    return sweepRange(shineWidth)
end

function ShineDriver.getT(): number
    return currentT
end

function ShineDriver.bind(instance: GuiObject, opts: BindOpts?): number
    local shineWidth = if opts and opts.shineWidth then opts.shineWidth else DEFAULT_SHINE_WIDTH
    local startX, endX = sweepRange(shineWidth)

    local id = nextBindingId
    nextBindingId += 1

    bindings[id] = {
        instance = instance,
        positionY = if opts and opts.positionY then opts.positionY else 0.5,
        startX = startX,
        endX = endX,
    }

    if bindingCount() == 1 then
        ensureMotor(opts)
    end

    applyBinding(bindings[id], currentT)

    return id
end

function ShineDriver.unbind(id: number)
    bindings[id] = nil
    maybeStopMotor()
end

return ShineDriver
