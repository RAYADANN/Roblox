--!strict
-- Точки появления (GDD 2.5): тег HoardSpawn + атрибут Ring. Одна точка — не больше одного предмета.
-- Точка освобождается, когда её предмет доставлен на участок; затем респаун по таблице кольца.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryLogic = require(ReplicatedStorage.shared.util.CarryLogic)
local HoardConfig = require(ReplicatedStorage.shared.data.HoardConfig)
local ItemsConfig = require(ReplicatedStorage.shared.data.ItemsConfig)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local Rarity = require(ReplicatedStorage.shared.data.Rarity)

type SpawnPoint = { marker: BasePart, ring: string, occupied: boolean, respawnAt: number }

export type Deps = {
    carry: any,
    feed: (text: string) -> (),
}

local HoardService = {}
HoardService.__index = HoardService

function HoardService.new(deps: Deps)
    -- Пул предметов по кольцу и редкости: внутри редкости выбор равновероятный.
    local pool: { [string]: { [string]: { string } } } = {}
    for _, def in ItemsConfig.LIST do
        for _, ring in def.rings do
            pool[ring] = pool[ring] or {}
            pool[ring][def.rarity] = pool[ring][def.rarity] or {}
            table.insert(pool[ring][def.rarity], def.id)
        end
    end
    return setmetatable({
        _deps = deps,
        _points = {} :: { [BasePart]: SpawnPoint },
        _pool = pool,
        _rng = Random.new(),
    }, HoardService)
end

function HoardService:_roll(ring: string): string?
    local ringDef = HoardConfig.RINGS[ring]
    if not ringDef then
        return nil
    end
    local rarity =
        CarryLogic.rollRarity(ringDef.chances, Rarity.ORDER :: any, self._rng:NextNumber() * 100)
    local candidates = rarity and self._pool[ring] and self._pool[ring][rarity]
    if not candidates or #candidates == 0 then
        return nil
    end
    return candidates[self._rng:NextInteger(1, #candidates)]
end

function HoardService:_fill(point: SpawnPoint)
    local itemId = self:_roll(point.ring)
    if not itemId then
        Logger.warn("Hoard", `кольцо {point.ring}: нечего ставить`)
        point.respawnAt = os.clock() + 5
        return
    end
    point.occupied = true
    self._deps.carry:spawnAt(itemId, point.marker)
    local def = ItemsConfig.BY_ID[itemId]
    if point.ring == "Hand" then
        self._deps.feed(`Something {string.upper(def.rarity)} is in his hand...`)
    elseif point.ring == "Teddy" then
        self._deps.feed("A new Teddy has arrived...")
    end
end

-- CarryService: предмет из этой точки ушёл на участок.
function HoardService:onSpawnFreed(marker: BasePart)
    local point = self._points[marker]
    if point then
        point.occupied = false
        point.respawnAt = os.clock() + HoardConfig.RINGS[point.ring].respawnSec
    end
end

function HoardService:_register(marker: Instance)
    if not marker:IsA("BasePart") or self._points[marker] then
        return
    end
    local ring = marker:GetAttribute("Ring")
    if typeof(ring) ~= "string" or not HoardConfig.RINGS[ring] then
        Logger.warn("Hoard", `{marker:GetFullName()}: неизвестный Ring {tostring(ring)}`)
        return
    end
    -- Маркеры моделлера видимы в edit-режиме; в игре их не должно быть видно.
    marker.Transparency = 1
    self._points[marker] = { marker = marker, ring = ring, occupied = false, respawnAt = 0 }
end

function HoardService:start()
    for _, marker in CollectionService:GetTagged("HoardSpawn") do
        self:_register(marker)
    end
    CollectionService:GetInstanceAddedSignal("HoardSpawn"):Connect(function(marker)
        self:_register(marker)
    end)
    local counts: { [string]: number } = {}
    for _, point in self._points do
        counts[point.ring] = (counts[point.ring] or 0) + 1
    end
    for ring, def in HoardConfig.RINGS do
        if (counts[ring] or 0) ~= def.count then
            Logger.warn(
                "Hoard",
                `кольцо {ring}: точек {counts[ring] or 0}, по GDD {def.count}`
            )
        end
    end

    task.spawn(function()
        while true do
            local now = os.clock()
            for _, point in self._points do
                if not point.occupied and now >= point.respawnAt and point.marker.Parent then
                    self:_fill(point)
                end
            end
            task.wait(0.5)
        end
    end)
end

return HoardService
