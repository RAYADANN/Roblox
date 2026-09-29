--!strict
-- World pad names on each Island.Buttons (incl. MainButton deposit).

export type PadAction =
    "Buy1"
    | "Buy5"
    | "Buy25"
    | "Buy100"
    | "Merge"
    | "Deposit"
    | "CollectCash"
    | "UpgradeProcess"
    | "UpgradeProduction"
    | "AutoCollectEggs"
    | "AutoCollectCash"
    | "FinishNow"
    | "DoubleItems"
    | "GroupReward"

export type PadDef = {
    action: PadAction,
    modelName: string,
    parent: "Buttons" | "Island",
    qty: number?,
}

local PadIds: { PadDef } = {
    { action = "Buy1", modelName = "Buton1Rooms", parent = "Buttons", qty = 1 },
    { action = "Buy5", modelName = "Buton5Rooms", parent = "Buttons", qty = 5 },
    { action = "Buy25", modelName = "Buton25Rooms", parent = "Buttons", qty = 25 },
    { action = "Buy100", modelName = "Buton100Rooms", parent = "Buttons", qty = 100 },
    { action = "Merge", modelName = "ButonMerge", parent = "Buttons" },
    { action = "UpgradeProcess", modelName = "ButonPerSecond", parent = "Buttons" },
    { action = "UpgradeProduction", modelName = "ButonUpgrade", parent = "Buttons" },
    { action = "AutoCollectEggs", modelName = "ButtonAutoCollectItems", parent = "Buttons" },
    { action = "AutoCollectCash", modelName = "ButtonAutoCollect", parent = "Buttons" },
    { action = "CollectCash", modelName = "ButtonCollect", parent = "Buttons" },
    { action = "FinishNow", modelName = "ButtonFinishNow", parent = "Buttons" },
    { action = "DoubleItems", modelName = "ButtonX2Items", parent = "Buttons" },
    { action = "GroupReward", modelName = "ButonGroup", parent = "Buttons" },
    { action = "Deposit", modelName = "MainButton", parent = "Buttons" },
}

return PadIds
