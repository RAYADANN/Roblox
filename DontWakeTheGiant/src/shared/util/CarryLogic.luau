--!strict
-- Перенос, полёт после поимки, бросок шанса редкости. Без Roblox API.

local CarryLogic = {}

-- GDD 2.1: ×(1 − штраф × (Вес − 1)); вес 5 при штрафе 0.08 → 0.68.
function CarryLogic.speedMult(weight: number, penalty: number): number
    if weight <= 1 then
        return 1
    end
    return math.max(0.1, 1 - penalty * (weight - 1))
end

-- Начальная скорость для дуги заданной высоты, приземление на той же высоте через dist.
function CarryLogic.launchVelocity(
    dirX: number,
    dirZ: number,
    dist: number,
    height: number,
    gravity: number
): (number, number, number)
    local vy = math.sqrt(2 * gravity * height)
    local flight = 2 * vy / gravity
    local len = math.sqrt(dirX * dirX + dirZ * dirZ)
    if len < 1e-6 then
        return 0, vy, 0
    end
    local horizontal = dist / flight
    return dirX / len * horizontal, vy, dirZ / len * horizontal
end

-- roll в [0, 100). Порядок задаёт детерминизм.
function CarryLogic.rollRarity(
    chances: { [string]: number },
    order: { string },
    roll: number
): string?
    local acc = 0
    local last: string? = nil
    for _, rarity in order do
        local chance = chances[rarity]
        if chance and chance > 0 then
            acc += chance
            last = rarity
            if roll < acc then
                return rarity
            end
        end
    end
    return last
end

function CarryLogic.chancesSum(chances: { [string]: number }): number
    local sum = 0
    for _, chance in chances do
        sum += chance
    end
    return sum
end

return CarryLogic
