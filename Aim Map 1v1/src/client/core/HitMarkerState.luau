--!strict
-- Local hit-confirm pulses for the crosshair hitmarker (Valorant-style).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitMarkerLogic = require(ReplicatedStorage.shared.util.HitMarkerLogic)

export type Snapshot = {
    token: number,
    kind: HitMarkerLogic.HitMarkerKind,
}

local HitMarkerState = {}

local token = 0
local kind: HitMarkerLogic.HitMarkerKind = "body"
local listeners: { () -> () } = {}

local function notify()
    for _, listener in listeners do
        listener()
    end
end

function HitMarkerState.pulse(headshot: boolean, killed: boolean)
    token += 1
    kind = HitMarkerLogic.kind(headshot, killed)
    notify()
end

function HitMarkerState.getSnapshot(): Snapshot
    return {
        token = token,
        kind = kind,
    }
end

function HitMarkerState.subscribe(listener: () -> ()): () -> ()
    table.insert(listeners, listener)
    listener()
    return function()
        local i = table.find(listeners, listener)
        if i then
            table.remove(listeners, i)
        end
    end
end

return HitMarkerState
