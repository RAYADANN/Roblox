--!strict
-- Shared farm session / DI types for FarmManager submodules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DropDatabase = require(ReplicatedStorage.shared.data.DropDatabase)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local PlotRegistry = require(script.Parent.Parent.PlotRegistry)
local ProfileManager = require(script.Parent.Parent.ProfileManager)

export type PlayerData = PlayerDataModule.PlayerData
export type HudSyncPayload = NetTypes.HudSyncPayload
export type DropKind = DropDatabase.DropKind

export type Session = {
    player: Player,
    plot: PlotRegistry.Plot,
    template: Model,
    slots: { CFrame },
    unitsFolder: Folder,
    dropsFolder: Folder,
    unitModels: { Model },
    drops: { BasePart },
    nextLay: { number },
    pads: { [string]: Instance },
    collectTip: BasePart?,
    pendingEggs: number,
    pendingLucky: number,
    bagFlushQueued: boolean,
}

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    plotRegistry: PlotRegistry.PlotRegistry,
    syncHud: (player: Player, payload: HudSyncPayload?) -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
    playVfx: (
        player: Player,
        effectId: string,
        intensity: number,
        from: Vector3?,
        to: Vector3?
    ) -> (),
    getMultiplier: () -> number,
    ownsGamepass: (player: Player, gamepassId: number) -> boolean,
    promptGamepass: (player: Player, gamepassId: number) -> (),
    promptDevProduct: (player: Player, productKey: string) -> (),
}

-- Host surface used by farm/* helpers (FarmManager implements this).
export type FarmHost = {
    _deps: Deps,
    _sessions: { [Player]: Session },
    _data: (self: FarmHost, player: Player) -> PlayerData?,
    _sync: (self: FarmHost, player: Player) -> (),
    _syncBag: (self: FarmHost, player: Player) -> (),
    _flushBag: (self: FarmHost, player: Player, session: Session) -> (),
    _refreshLabels: (self: FarmHost, player: Player) -> (),
    _logItems: (self: FarmHost, player: Player, reason: string) -> (),
    _syncUnits: (self: FarmHost, session: Session, data: PlayerData) -> (),
    _collectDrop: (self: FarmHost, player: Player, drop: BasePart) -> (),
    _grantDropDirect: (
        self: FarmHost,
        player: Player,
        kind: DropKind,
        value: number,
        syncFull: boolean?
    ) -> (),
    _spawnDrop: (
        self: FarmHost,
        session: Session,
        unitIndex: number,
        kind: DropKind,
        value: number
    ) -> (),
    _pickupNear: (self: FarmHost, player: Player, session: Session) -> (),
    tryCollectCash: (self: FarmHost, player: Player) -> (),
    grantGamepass: (
        self: FarmHost,
        player: Player,
        gamepassId: number,
        fromPurchase: boolean?
    ) -> boolean,
    reconcileGamepasses: (self: FarmHost, player: Player) -> (),
    refreshExclusiveHeart: (self: FarmHost, player: Player) -> (),
}

return {}
