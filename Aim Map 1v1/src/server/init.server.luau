--!strict
-- Boot: DI, менеджеры, сеть. Без бизнес-логики.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local AssetTemplates = require(script.core.AssetTemplates)
local BotAgentManager = require(script.core.BotAgentManager)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local GameAnalytics = require(script.core.GameAnalytics)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local MatchManager = require(script.core.MatchManager)
local MonetizationManager = require(script.core.MonetizationManager)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local PracticeDummyManager = require(script.core.PracticeDummyManager)
local ProfileManager = require(script.core.ProfileManager)
local SettingsManager = require(script.core.SettingsManager)
local SkinManager = require(script.core.SkinManager)
local UniformCharacter = require(script.core.UniformCharacter)
local WeaponFireManager = require(script.core.WeaponFireManager)
local Zap = require(script.net.NetServer)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)

Logger.setMinLevel(if RunService:IsStudio() then "debug" else "warn")

-- Studio assets: Workspace "R15 Dummy" + "USP-S Main" → ServerStorage clones.
AssetTemplates.ensure()
UniformCharacter.start()

local profileManager = ProfileManager.new({})

local function syncHud(player: Player, payload: NetTypes.HudSyncPayload?)
    local data = profileManager:get(player)
    if not data then
        return
    end
    local hud = if payload then payload else buildHudPayload.fromPlayerData(data)
    Zap.PlayerDataSync.Fire(player, NetTypes.toZapSync(hud))
end

local function syncMatch(player: Player, payload: NetTypes.MatchSyncPayload)
    Zap.MatchStateSync.Fire(player, NetTypes.toZapMatch(payload))
end

local function notify(player: Player, kind: string, pl: string)
    Zap.Notify.Fire(player, { kind = kind, payload = pl })
end

local function offerSkinEquip(player: Player, skinId: string, owned: boolean)
    Zap.OfferSkinEquip.Fire(player, {
        skinId = skinId,
        owned = owned,
    })
end

local matchManager: MatchManager.MatchManager
local weaponFireManager: WeaponFireManager.WeaponFireManager

local botAgent = BotAgentManager.new({
    fireBot = function(model, origin, direction)
        return weaponFireManager:fireFromBot(model, origin, direction)
    end,
    getTargetPlayer = function(matchId)
        return matchManager:getPlayerForBotMatch(matchId)
    end,
    isMatchLive = function(matchId)
        return matchManager:isMatchLive(matchId)
    end,
})

matchManager = MatchManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    syncMatch = syncMatch,
    notify = notify,
    offerSkinEquip = offerSkinEquip,
    botAgent = botAgent,
})

local practiceDummies = PracticeDummyManager.new()
practiceDummies:start()

local settingsManager = SettingsManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
})
local skinManager = SkinManager.new({
    profileManager = profileManager,
    syncHud = syncHud,
    matchManager = matchManager,
})

weaponFireManager = WeaponFireManager.new({
    matchManager = matchManager,
    practiceDummies = practiceDummies,
    setCrosshair = function(player, crosshairId)
        return settingsManager:setCrosshair(player, crosshairId)
    end,
    notify = notify,
})

Zap.FireWeapon.SetCallback(function(player, origin, direction)
    return weaponFireManager:fire(player, origin, direction)
end)

Zap.RequestRematch.SetCallback(function(player)
    return matchManager:requestRematch(player)
end)

Zap.StartBotMatch.SetCallback(function(player)
    return matchManager:startBotMatch(player)
end)

Zap.SetLookSensitivity.SetCallback(function(player, value)
    return settingsManager:setLookSensitivity(player, value)
end)

Zap.SetCrosshair.SetCallback(function(player, crosshairId)
    return settingsManager:setCrosshair(player, crosshairId)
end)

Zap.SetEquippedSkin.SetCallback(function(player, skinId)
    return skinManager:setEquippedSkin(player, skinId)
end)

profileManager:onLoaded(function(player, data)
    syncHud(player, buildHudPayload.fromPlayerData(data))
    matchManager:onEquippedSkinChanged(player, data.equippedSkinId)
    GameAnalytics.log(player, "session_start", 1)
    if not data.firstSessionComplete then
        profileManager:mutate(player, function(d)
            d.firstSessionComplete = true
        end)
        GameAnalytics.log(player, "first_action", 1)
    end
    -- Graybox: auto-queue into 1v1 when profile ready.
    matchManager:enqueue(player)
end)

MonetizationManager.new({
    grantProduct = function(player, _productId)
        -- Soft shop later: grant skin ids. Stub keeps receipt pipeline alive.
        local ok = profileManager:mutate(player, function(d)
            d.ownedSkins.usp_slate = true
        end)
        if ok then
            syncHud(player, nil)
        end
        return ok
    end,
}):start()

botAgent:start()
matchManager:start()
profileManager:start()

StarterPlayer.CameraMode = Enum.CameraMode.Classic
StarterPlayer.EnableMouseLockOption = false

Logger.info("server", `boot complete firstTo={Constants.MATCH_FIRST_TO}`)
