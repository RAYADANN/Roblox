--!strict
-- Pure FTUE step machine: hints, advance rules (action flags + HUD).

export type Snapshot = {
    didRoll: boolean,
    didBuy: boolean,
    didPlace: boolean,
    --- Unpack timer finished, Open available.
    hasReady: boolean,
    didOpen: boolean,
    --- At least one toy finished the conveyor into SellBox.
    hasSellBoxCoins: boolean,
    didTake: boolean,
    didSell: boolean,
}

export type StepDef = {
    id: string,
    hint: string,
    --- World target kind for beam / spotlight.
    target: string,
}

local TutorialLogic = {}

TutorialLogic.STEP_DONE = 0
TutorialLogic.NEAR_STUDS = 22

TutorialLogic.STEPS = {
    {
        id = "roll",
        hint = "Press ROLL to spin new containers",
        target = "roll",
    },
    {
        id = "buy",
        hint = "BUY a container on Stand 1",
        target = "buy",
    },
    {
        id = "place",
        hint = "PLACE the container on a Hero Pad",
        target = "place",
    },
    {
        id = "wait_ready",
        hint = "Wait until the container is Ready",
        target = "wait_ready",
    },
    {
        id = "open",
        hint = "OPEN the container",
        target = "open",
    },
    {
        id = "wait_path",
        hint = "Wait for the toy to finish the conveyor",
        target = "wait_path",
    },
    {
        id = "take",
        hint = "TAKE the Sell Box",
        target = "take",
    },
    {
        id = "sell",
        hint = "SELL at the Sell Guy",
        target = "sell",
    },
} :: { StepDef }

function TutorialLogic.stepCount(): number
    return #TutorialLogic.STEPS
end

function TutorialLogic.getStep(step: number): StepDef?
    if step < 1 or step > #TutorialLogic.STEPS then
        return nil
    end
    return TutorialLogic.STEPS[step]
end

local function stepSatisfied(step: number, snap: Snapshot): boolean
    if step == 1 then
        return snap.didRoll
    elseif step == 2 then
        -- Only a real Buy during FTUE — not leftover inventory / slots.
        return snap.didBuy
    elseif step == 3 then
        return snap.didPlace
    elseif step == 4 then
        return snap.hasReady or snap.didOpen
    elseif step == 5 then
        return snap.didOpen
    elseif step == 6 then
        return snap.hasSellBoxCoins or snap.didTake or snap.didSell
    elseif step == 7 then
        return snap.didTake or snap.didSell
    elseif step == 8 then
        return snap.didSell
    end
    return false
end

function TutorialLogic.isStepSatisfied(step: number, snap: Snapshot): boolean
    return stepSatisfied(step, snap)
end

function TutorialLogic.resolveStep(snap: Snapshot): number
    for i = 1, #TutorialLogic.STEPS do
        if not stepSatisfied(i, snap) then
            return i
        end
    end
    return TutorialLogic.STEP_DONE
end

function TutorialLogic.advance(current: number, snap: Snapshot): number
    if current == TutorialLogic.STEP_DONE then
        return TutorialLogic.STEP_DONE
    end
    local nextStep = TutorialLogic.resolveStep(snap)
    if nextStep == TutorialLogic.STEP_DONE then
        return TutorialLogic.STEP_DONE
    end
    if nextStep < current then
        return current
    end
    return nextStep
end

function TutorialLogic.advanceOne(current: number, snap: Snapshot): number
    if current == TutorialLogic.STEP_DONE then
        return TutorialLogic.STEP_DONE
    end
    if not stepSatisfied(current, snap) then
        return current
    end
    local nextStep = current + 1
    if nextStep > #TutorialLogic.STEPS then
        return TutorialLogic.STEP_DONE
    end
    return nextStep
end

return TutorialLogic
