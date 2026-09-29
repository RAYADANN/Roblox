--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local FarmLogic = require(ReplicatedStorage.shared.util.FarmLogic)

export type Deps = {
    onChanged: () -> (),
}

local MultiplierService = {}
MultiplierService.__index = MultiplierService

function MultiplierService.new(deps: Deps)
    return setmetatable({
        _deps = deps,
        _value = 1,
        _index = 5,
    }, MultiplierService)
end

function MultiplierService:get(): number
    return self._value
end

function MultiplierService:start()
    self._index = 5
    self._value = FarmLogic.multiplierFromIndex(self._index)
    task.spawn(function()
        while true do
            task.wait(Constants.MULTIPLIER_PERIOD_SEC)
            self._index += 1
            self._value = FarmLogic.multiplierFromIndex(self._index)
            self._deps.onChanged()
        end
    end)
end

return MultiplierService
