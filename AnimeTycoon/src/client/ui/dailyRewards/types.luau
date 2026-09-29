--!strict

export type DayKind = "money" | "smalltime" | "secret" | "singularity" | "timer" | "admin" | "super"

export type DailyRewardItem = {
    id: string,
    day: number,
    kind: DayKind,
    valueText: string,
    claimed: boolean?,
    icon: string?,
    -- Day 7 only
    opText: string?,
}

return {}
