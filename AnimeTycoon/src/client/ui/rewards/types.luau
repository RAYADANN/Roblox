--!strict

export type RewardKind = "money" | "golden" | "diamond" | "galaxy"

export type RewardItem = {
    id: string,
    kind: RewardKind,
    valueText: string,
    --- unix time (GetServerTimeNow / os.time), когда открывается
    unlockAt: number,
    icon: string?,
    claimed: boolean?,
}

return {}
