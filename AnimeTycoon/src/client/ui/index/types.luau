--!strict

export type IndexTier = "normal" | "golden" | "diamond" | "galaxy" | "secret"

export type IndexItem = {
    id: string,
    name: string,
    valueText: string,
    mutationText: string,
    rareText: string,
    tier: IndexTier,
    unlocked: boolean,
    image: string?,
}

export type IndexTab = {
    id: IndexTier,
    label: string,
}

return {}
