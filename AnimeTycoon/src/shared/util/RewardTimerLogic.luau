--!strict
-- Pure: таймеры / claimable для Rewards.

local RewardTimerLogic = {}

function RewardTimerLogic.remaining(unlockAt: number, now: number): number
    return math.max(0, math.ceil(unlockAt - now))
end

function RewardTimerLogic.isClaimable(claimed: boolean, remainingSec: number): boolean
    return not claimed and remainingSec <= 0
end

--- MM:SS или H:MM:SS / HH:MM:SS
function RewardTimerLogic.format(seconds: number): string
    local s = math.max(0, math.floor(seconds))
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = s % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, sec)
    end
    return string.format("%02d:%02d", m, sec)
end

--- Первый незаклеймленный с remaining<=0 (порядок сетки).
function RewardTimerLogic.firstClaimableIndex(
    items: { { claimed: boolean, unlockAt: number } },
    now: number
): number?
    for i, item in items do
        local rem = RewardTimerLogic.remaining(item.unlockAt, now)
        if RewardTimerLogic.isClaimable(item.claimed, rem) then
            return i
        end
    end
    return nil
end

return RewardTimerLogic
