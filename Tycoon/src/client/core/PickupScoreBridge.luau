--!strict
-- Client: Zap Notify pickup_score → ScorePop (outside React so FX always mounts).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FxKit = require(script.Parent.Parent.ui.fx.FxKit)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local SoundManager = require(script.Parent.SoundManager)
local Zap = require(script.Parent.Parent.net.NetClient)

local PickupScoreBridge = {}

local _started = false

function PickupScoreBridge.start()
    if _started then
        return
    end
    _started = true

    Zap.Notify.On(function(payload)
        if payload.kind ~= "pickup_score" then
            return
        end
        SoundManager.playWithPitch("item_pickup", 0.95 + math.random() * 0.1)
        local ok, err = pcall(function()
            FxKit.scorePop.playFromPayload(payload.payload)
        end)
        if not ok then
            Logger.warn("PickupScoreBridge", `ScorePop failed: {err}`)
        end
    end)

    Logger.info("PickupScoreBridge", "listening for pickup_score")
end

return PickupScoreBridge
