--!strict
-- Bind shine ImageLabel to shared ShineDriver (direct Position updates, zero React state).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ShineDriver = require(script.Parent.ShineDriver)

export type Options = {
    enabled: boolean?,
    intervalSec: number?,
    durationSec: number?,
    positionY: number?,
    shineWidth: number?,
}

local function useShineRef(opts: Options?): (GuiObject?) -> ()
    local enabled = if opts and opts.enabled ~= nil then opts.enabled else true
    local intervalSec = if opts and opts.intervalSec then opts.intervalSec else 2
    local durationSec = if opts and opts.durationSec then opts.durationSec else 0.65
    local positionY = if opts and opts.positionY then opts.positionY else 0.5
    local shineWidth = opts and opts.shineWidth

    local instanceRef = React.useRef(nil :: GuiObject?)
    local bindingId = React.useRef(nil :: number?)
    local syncRef = React.useRef(function() end)

    local function release()
        local id = bindingId.current
        if id ~= nil then
            ShineDriver.unbind(id)
            bindingId.current = nil
        end
    end

    React.useEffect(function()
        syncRef.current = function()
            release()
            if not enabled then
                return
            end
            local inst = instanceRef.current
            if inst == nil then
                return
            end
            bindingId.current = ShineDriver.bind(inst, {
                intervalSec = intervalSec,
                durationSec = durationSec,
                positionY = positionY,
                shineWidth = shineWidth,
            })
        end
        syncRef.current()
        return release
    end, { enabled, intervalSec, durationSec, positionY, shineWidth })

    return React.useCallback(function(inst: GuiObject?)
        instanceRef.current = inst
        syncRef.current()
    end, {})
end

return useShineRef
