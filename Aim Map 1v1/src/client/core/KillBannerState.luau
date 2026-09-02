--!strict
-- Local kill-banner pulses (ring + skull) after a confirmed elim.

export type Snapshot = {
    token: number,
}

local KillBannerState = {}

local token = 0
local listeners: { () -> () } = {}

local function notify()
    for _, listener in listeners do
        listener()
    end
end

function KillBannerState.pulse()
    token += 1
    notify()
end

function KillBannerState.getSnapshot(): Snapshot
    return { token = token }
end

function KillBannerState.subscribe(listener: () -> ()): () -> ()
    table.insert(listeners, listener)
    listener()
    return function()
        local i = table.find(listeners, listener)
        if i then
            table.remove(listeners, i)
        end
    end
end

return KillBannerState
