--!strict
-- Client: Zap PlayVfx → VfxController.play (all clients render).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.shared.util.Logger)
local VfxController = require(script.Parent.VfxController)
local Zap = require(script.Parent.Parent.net.NetClient)

local VfxNetBridge = {}

local _started = false

function VfxNetBridge.start()
    if _started then
        return
    end
    _started = true

    Zap.PlayVfx.On(function(value)
        local ok, err = pcall(function()
            VfxController.start()
            local intensity = if value.intensity > 0 then value.intensity else 1
            VfxController.play(value.effectId, {
                cframe = if value.pos then CFrame.new(value.pos) else nil,
                from = if value.from then CFrame.new(value.from) else nil,
                to = if value.to then CFrame.new(value.to) else nil,
                intensity = intensity,
            })
        end)
        if not ok then
            Logger.warn("VfxNetBridge", `PlayVfx failed: {err}`)
        end
    end)

    Logger.info("VfxNetBridge", "listening for PlayVfx")
end

return VfxNetBridge
