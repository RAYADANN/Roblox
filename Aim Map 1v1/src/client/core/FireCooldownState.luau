--!strict
-- Local USP fire cooldown for HUD meter (client prediction of server cooldown).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.shared.data.Constants)

local FireCooldownState = {}

local lastShotAt = -999
local listeners: { () -> () } = {}

local function notify()
    for _, listener in listeners do
        listener()
    end
end

function FireCooldownState.markShot()
    lastShotAt = os.clock()
    notify()
end

--- 0 = just fired (empty), 1 = ready to fire again.
function FireCooldownState.getProgress(): number
    local elapsed = os.clock() - lastShotAt
    return math.clamp(elapsed / Constants.USP_FIRE_COOLDOWN_SEC, 0, 1)
end

function FireCooldownState.isReady(): boolean
    return FireCooldownState.getProgress() >= 1
end

function FireCooldownState.subscribe(listener: () -> ()): () -> ()
    table.insert(listeners, listener)
    listener()
    return function()
        local i = table.find(listeners, listener)
        if i then
            table.remove(listeners, i)
        end
    end
end

return FireCooldownState
