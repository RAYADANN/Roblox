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
    --- case: show 3D box instead of money icon
    rewardType: "money" | "case"?,
    mutation: string?,
    boxModelName: string?,
    --- money grant amount (for FX / Hoarcekat mock claim)
    coins: number?,
}

return {}
