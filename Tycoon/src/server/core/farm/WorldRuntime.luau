--!strict
-- Plot world: units, ground drops, backpack flush.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local FarmLogic = require(ReplicatedStorage.shared.util.FarmLogic)
local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)
local PickupScoreLogic = require(ReplicatedStorage.shared.util.PickupScoreLogic)
local WorldFarmFactory = require(script.Parent.Parent.WorldFarmFactory)

local Types = require(script.Parent.Types)

type DropKind = Types.DropKind
type FarmHost = Types.FarmHost
type PlayerData = Types.PlayerData
type Session = Types.Session

local WorldRuntime = {}

function WorldRuntime._syncBag(self: FarmHost, player: Player)
    self._deps.syncHud(player, nil)
    local session = self._sessions[player]
    local data = self:_data(player)
    if session == nil or data == nil then
        return
    end
    WorldFarmFactory.setPadText(
        session.pads.Deposit,
        "Sell Items",
        FormatMoney.short(data.backpackEggs) .. " items"
    )
end

function WorldRuntime._flushBag(self: FarmHost, player: Player, session: Session)
    session.bagFlushQueued = false
    local eggs = session.pendingEggs
    local lucky = session.pendingLucky
    if eggs <= 0 and lucky <= 0 then
        return
    end
    session.pendingEggs = 0
    session.pendingLucky = 0
    self._deps.profileManager:mutate(player, function(d)
        if eggs > 0 then
            d.backpackEggs += eggs
        end
        if lucky > 0 then
            d.luckyBlocks += lucky
        end
    end)
    self:_syncBag(player)
end

function WorldRuntime._syncUnits(_self: FarmHost, session: Session, data: PlayerData)
    local now = os.clock()
    local units = data.units

    for i = #session.unitModels, #units + 1, -1 do
        local model = session.unitModels[i]
        if model ~= nil then
            model:Destroy()
        end
        session.unitModels[i] = nil
        session.nextLay[i] = nil
    end

    for i, tier in units do
        local slot = session.slots[i]
        if slot == nil then
            break
        end
        local existing = session.unitModels[i]
        if existing ~= nil and existing.Parent ~= nil and existing:GetAttribute("Tier") == tier then
            continue
        end
        if existing ~= nil then
            existing:Destroy()
        end
        session.unitModels[i] =
            WorldFarmFactory.spawnUnit(session.unitsFolder, session.template, slot, tier)
        session.nextLay[i] = now + FarmLogic.layIntervalSec(tier, data.productionLevel)
    end
end

function WorldRuntime._collectDrop(self: FarmHost, player: Player, drop: BasePart)
    local session = self._sessions[player]
    if session == nil or drop.Parent == nil then
        return
    end
    if drop:GetAttribute("Collected") == true then
        return
    end
    drop:SetAttribute("Collected", true)

    local kind = drop:GetAttribute("DropKind")
    local value = drop:GetAttribute("EggValue")
    local idx = table.find(session.drops, drop)
    if idx then
        table.remove(session.drops, idx)
    end
    drop:Destroy()

    if typeof(kind) ~= "string" or typeof(value) ~= "number" then
        return
    end
    self._deps.notify(player, "pickup_score", PickupScoreLogic.encode(kind, value))
    if kind == "lucky" then
        session.pendingLucky += 1
    else
        session.pendingEggs += value
    end

    if session.bagFlushQueued then
        return
    end
    session.bagFlushQueued = true
    task.defer(function()
        local live = self._sessions[player]
        if live == nil then
            return
        end
        self:_flushBag(player, live)
    end)
end

function WorldRuntime._grantDropDirect(
    self: FarmHost,
    player: Player,
    kind: DropKind,
    value: number,
    syncFull: boolean?
)
    self._deps.notify(player, "pickup_score", PickupScoreLogic.encode(kind, value))
    self._deps.profileManager:mutate(player, function(d)
        if kind == "lucky" then
            d.luckyBlocks += 1
        else
            d.backpackEggs += value
        end
    end)
    if syncFull then
        self:_sync(player)
    else
        self:_syncBag(player)
    end
end

function WorldRuntime._spawnDrop(
    self: FarmHost,
    session: Session,
    unitIndex: number,
    kind: DropKind,
    value: number
)
    if #session.drops >= Constants.MAX_GROUND_DROPS then
        self:_grantDropDirect(session.player, kind, value, false)
        return
    end

    local slot = session.slots[unitIndex] or session.slots[1]
    local offset = FarmLogic.dropSpawnLocalOffset(math.random(), math.random())
    local cf = slot * CFrame.new(offset.x, offset.y, offset.z)
    local drop =
        WorldFarmFactory.spawnDrop(session.dropsFolder, cf, kind, value, session.player.UserId)
    table.insert(session.drops, drop)
end

function WorldRuntime._pickupNear(self: FarmHost, player: Player, session: Session)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local data = self:_data(player)
    local autoCollect = data ~= nil and data.autoCollectEggs
    local tip = session.collectTip
    local tipPos = if tip and tip.Parent ~= nil then tip.Position else nil

    local radius = Constants.DROP_PICKUP_RADIUS
    local radiusSq = radius * radius
    local autoRadius = Constants.DROP_AUTO_COLLECT_RADIUS
    local origin = if root and root:IsA("BasePart") then root.Position else nil

    local snapshot = table.clone(session.drops)
    for _, drop in snapshot do
        if drop.Parent == nil then
            local idx = table.find(session.drops, drop)
            if idx then
                table.remove(session.drops, idx)
            end
            continue
        end

        local nearPlayer = false
        if origin then
            local delta = drop.Position - origin
            nearPlayer = delta:Dot(delta) <= radiusSq
        end

        local nearTip = false
        if autoCollect and tipPos then
            local p = drop.Position
            nearTip = FarmLogic.isInAutoCollectZone(
                p.X,
                p.Y,
                p.Z,
                tipPos.X,
                tipPos.Y,
                tipPos.Z,
                autoRadius
            )
        end

        local fallen = drop.Position.Y < Constants.DROP_DESPAWN_Y
        if nearPlayer or nearTip or fallen then
            self:_collectDrop(player, drop)
        end
    end
end

return WorldRuntime
