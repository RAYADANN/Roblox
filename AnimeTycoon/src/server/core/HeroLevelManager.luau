--!strict
-- Spend coins to level an unpacked hero on the owner's ramp slot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local ContainerLogic = require(ReplicatedStorage.shared.util.ContainerLogic)
local HeroLevelLogic = require(ReplicatedStorage.shared.util.HeroLevelLogic)
local LimitedLogic = require(ReplicatedStorage.shared.util.LimitedLogic)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local ProfileManager = require(script.Parent.ProfileManager)
local SlotMap = require(ReplicatedStorage.shared.util.SlotMap)

type PlayerData = PlayerDataModule.PlayerData

export type LevelResult = {
    success: boolean,
    error: string?,
    coins: number?,
    level: number?,
}

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player) -> (),
    publishWorld: () -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
}

local HeroLevelManager = {}
HeroLevelManager.__index = HeroLevelManager

function HeroLevelManager.new(deps: Deps)
    return setmetatable({
        _deps = deps,
    }, HeroLevelManager)
end

function HeroLevelManager:levelUp(player: Player, slotIndex: number): LevelResult
    if typeof(slotIndex) ~= "number" then
        return { success = false, error = "invalid_slot" }
    end
    local idx = math.floor(slotIndex)
    if idx < 1 or idx > Constants.SLOT_COUNT then
        return { success = false, error = "invalid_slot" }
    end

    local deps = self._deps
    local pm = deps.profileManager
    if not pm:get(player) then
        return { success = false, error = "no_profile" }
    end

    local failReason: string? = nil
    local newLevel = 0

    local ok = pm:mutate(player, function(d: PlayerData)
        if not d.slots then
            failReason = "empty_slot"
            return
        end
        local slot = SlotMap.get(d.slots, idx)
        if not slot then
            failReason = "empty_slot"
            return
        end
        if slot.unpacked ~= true then
            failReason = "not_hero"
            return
        end
        local limitedOffer = LimitedLogic.offerFromTemplateId(slot.templateId)
        if limitedOffer then
            LimitedLogic.syncContainerFromOffer(slot, limitedOffer)
        end
        local level = HeroLevelLogic.normalize(slot.level)
        if HeroLevelLogic.isMax(level) then
            failReason = "max_level"
            return
        end
        local base = HeroLevelLogic.basePerMini(slot.rarity, slot.mutations, slot.baseIncome)
        local cost =
            HeroLevelLogic.upgradeCost(base, ContainerLogic.produceInterval(slot.rarity), level)
        if cost == nil or d.coins < cost then
            failReason = "no_coins"
            return
        end
        d.coins -= cost
        slot.level = level + 1
        HeroLevelLogic.syncIncome(slot)
        newLevel = slot.level or level + 1
    end)

    if not ok then
        return { success = false, error = "no_profile" }
    end
    if failReason then
        return { success = false, error = failReason }
    end

    local updated = pm:get(player)
    deps.syncHud(player)
    deps.publishWorld()
    deps.notify(player, "hero_leveled", tostring(newLevel))

    return {
        success = true,
        error = nil,
        coins = if updated then updated.coins else nil,
        level = newLevel,
    }
end

return HeroLevelManager
