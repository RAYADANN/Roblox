--!strict
-- Чистые формулы шума и фаз (GDD 2.2, 2.3). Конфиг передаётся аргументом, чтобы тестировать под Lune.

export type Phase = "Deep" | "Restless" | "EyeOpen" | "Wake"

export type StepInput = {
    moving: boolean,
    sneaking: boolean,
    carryWeight: number, -- 0 = ничего не несёт
    surface: string?,
    bootsMult: number?, -- улучшения и пассы, 1 по умолчанию
}

export type NoiseCfg = {
    WALK_NOISE_PER_SEC: number,
    SNEAK_NOISE_PER_SEC: number,
    SURFACE_NOISE_MULT: { [string]: number },
    RESTLESS_AT: number,
    EYE_OPEN_AT: number,
    EYE_CLOSE_BELOW: number,
    DECAY_PER_SEC: number,
    DROUGHT_DECAY_PER_SEC: number,
    WAKE_DROUGHT_SEC: number,
}

local NoiseLogic = {}

function NoiseLogic.carryMult(weight: number, carryMults: { number }): number
    if weight <= 0 then
        return 1
    end
    return carryMults[math.clamp(math.floor(weight), 1, #carryMults)]
end

-- Шум шага в секунду для одного игрока.
function NoiseLogic.stepRate(input: StepInput, cfg: NoiseCfg, carryMults: { number }): number
    if not input.moving then
        return 0
    end
    local base = if input.sneaking then cfg.SNEAK_NOISE_PER_SEC else cfg.WALK_NOISE_PER_SEC
    local surfaceMult = if input.surface then cfg.SURFACE_NOISE_MULT[input.surface] or 1 else 1
    return base
        * NoiseLogic.carryMult(input.carryWeight, carryMults)
        * surfaceMult
        * (input.bootsMult or 1)
end

-- Фаза по шуму с гистерезисом закрытия глаза. WAKE ведёт GiantService, сюда не попадает.
function NoiseLogic.phaseFor(noise: number, current: Phase, cfg: NoiseCfg): Phase
    if current == "EyeOpen" and noise >= cfg.EYE_CLOSE_BELOW then
        return "EyeOpen"
    end
    if noise >= cfg.EYE_OPEN_AT then
        return "EyeOpen"
    elseif noise >= cfg.RESTLESS_AT then
        return "Restless"
    end
    return "Deep"
end

-- На тихих серверах затухание медленнее, чтобы WAKE всё-таки случался (GDD 7.3).
function NoiseLogic.decayRate(secondsSinceWake: number, cfg: NoiseCfg): number
    if secondsSinceWake >= cfg.WAKE_DROUGHT_SEC then
        return cfg.DROUGHT_DECAY_PER_SEC
    end
    return cfg.DECAY_PER_SEC
end

function NoiseLogic.apply(noise: number, delta: number, max: number): number
    return math.clamp(noise + delta, 0, max)
end

return NoiseLogic
