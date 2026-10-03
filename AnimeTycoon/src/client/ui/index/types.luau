--!strict

-- Tabs = Normal (no mutation) + MutationDatabase ids.
export type IndexTier = "normal" | "golden" | "diamond" | "galaxy" | "secret" | "prismatic"

export type IndexItem = {
    id: string,
    name: string,
    valueText: string,
    mutationText: string,
    rareText: string,
    tier: IndexTier,
    unlocked: boolean,
    image: string?,
    heroId: string?,
    rarity: string?,
}

export type IndexTab = {
    id: IndexTier,
    label: string,
}

return {}
