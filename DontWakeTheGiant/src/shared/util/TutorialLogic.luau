--!strict
-- Pure FTUE step machine. Steps are data: a flag on the snapshot completes a step.
-- Replace STEPS for the game. Do not encode the loop in the client.

export type StepDef = {
    id: string,
    hint: string,
    --- World target id. The client resolves it to a part.
    target: string,
    --- Snapshot key that means this step is done.
    flag: string,
}

export type Snapshot = { [string]: boolean }

local TutorialLogic = {}

TutorialLogic.STEP_DONE = 0
TutorialLogic.NEAR_STUDS = 22

--- Two placeholder steps. A new game replaces this list and keeps the functions.
TutorialLogic.STEPS = {
    {
        id = "act",
        hint = "Do the first action",
        target = "action",
        flag = "didAct",
    },
    {
        id = "reward",
        hint = "Collect the reward",
        target = "reward",
        flag = "didReward",
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
    local def = TutorialLogic.STEPS[step]
    if def == nil then
        return false
    end
    return snap[def.flag] == true
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
