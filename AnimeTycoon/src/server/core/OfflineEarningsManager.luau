--!strict
-- Offline earnings claim (1x) + Robux double (2x).

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local OfflineEarningsLogic = require(ReplicatedStorage.shared.util.OfflineEarningsLogic)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local ProductIds = require(ReplicatedStorage.shared.data.ProductIds)
local ProfileManager = require(script.Parent.ProfileManager)

type PlayerData = PlayerDataModule.PlayerData

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player) -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
}

local OfflineEarningsManager = {}
OfflineEarningsManager.__index = OfflineEarningsManager

function OfflineEarningsManager.new(deps: Deps)
    return setmetatable({
        _deps = deps,
    }, OfflineEarningsManager)
end

function OfflineEarningsManager.productId(): number
    local id = (ProductIds :: any).OfflineDouble
    return if typeof(id) == "number" then id else 0
end

function OfflineEarningsManager.isOfflineDoubleProduct(productId: number): boolean
    local id = OfflineEarningsManager.productId()
    return id > 0 and productId == id
end

function OfflineEarningsManager:claim(player: Player, doubled: boolean): (boolean, string?, number?)
    local deps = (self :: any)._deps
    local granted = 0
    local fail: string? = nil
    local ok = deps.profileManager:mutate(player, function(d: PlayerData)
        local pending = math.max(0, tonumber(d.pendingOfflineCoins) or 0)
        if pending <= 0 then
            fail = "nothing_pending"
            return
        end
        granted = if doubled then OfflineEarningsLogic.doubleAmount(pending) else pending
        d.coins += granted
        d.pendingOfflineCoins = 0
    end)
    if not ok then
        return false, "no_profile", nil
    end
    if fail then
        return false, fail, nil
    end
    deps.syncHud(player)
    deps.notify(player, "offline_claimed", tostring(granted))
    return true, nil, granted
end

--- Cancel / Collect CURRENT (1x).
function OfflineEarningsManager:claimCurrent(player: Player): (boolean, string?, number?)
    return self:claim(player, false)
end

--- After Robux receipt / Studio mock — grant 2x.
function OfflineEarningsManager:claimDouble(player: Player): boolean
    local ok = self:claim(player, true)
    return ok
end

function OfflineEarningsManager:promptDouble(player: Player)
    local deps = (self :: any)._deps
    local data = deps.profileManager:get(player)
    if not data then
        return
    end
    local pending = math.max(0, tonumber(data.pendingOfflineCoins) or 0)
    if pending <= 0 then
        deps.notify(player, "error", "nothing_pending")
        return
    end

    local id = OfflineEarningsManager.productId()
    if id <= 0 then
        if RunService:IsStudio() then
            Logger.info("OfflineEarnings", `Studio mock double for {player.Name}`)
            self:claimDouble(player)
            deps.notify(player, "robux_purchase", "offline_double")
            return
        end
        deps.notify(player, "error", "product_unconfigured")
        return
    end

    local okPrompt, err = pcall(function()
        MarketplaceService:PromptProductPurchase(player, id)
    end)
    if not okPrompt then
        Logger.warn("OfflineEarnings", `prompt failed: {err}`)
        deps.notify(player, "error", "prompt_failed")
    end
end

return OfflineEarningsManager
