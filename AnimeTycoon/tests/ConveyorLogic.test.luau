return {
    ["travel duration positive"] = function(expect)
        local ConveyorLogic = require("../src/shared/util/ConveyorLogic")
        expect(ConveyorLogic.travelDuration(1) > 0).toBeTruthy()
        expect(ConveyorLogic.arriveAt(100, 1) > 100).toBeTruthy()
    end,
}
