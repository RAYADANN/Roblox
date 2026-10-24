--!strict
-- Перенос, полёт после поимки, бросок шанса редкости. Без Roblox API.

local CarryLogic = {}

-- Можно ли поднять: сила не меньше требуемой (GDD 2.1).
function CarryLogic.canLift(strength: number, need: number): boolean
    return strength >= need
end

-- Скорость с предметом по отношению Strength / Need (GDD 2.1).
function CarryLogic.speedMult(
    strength: number,
    need: number,
    table_: { { ratio: number, mult: number } }
): number
    if need <= 0 then
        return 1
    end
    local ratio = strength / need
    for _, step in table_ do
        if ratio < step.ratio then
            return step.mult
        end
    end
    return 1
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
