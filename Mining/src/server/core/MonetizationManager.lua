--!strict
-- MonetizationManager.lua — Phase 12 (Монетизация).
--
-- Серверная часть revenue stream. Структура совпадает с RebirthManager (Phase 9)
-- / DailyReward (Phase 10) / PetManager (Phase 11): DI через Deps, обработчики
-- регистрируются в new(), onProfileLoaded идемпотентен.
--
-- Отвечает за:
--   1) GAME-PASSES (одноразовые):
--      * onProfileLoaded → UserOwnsGamePassAsync (source of truth) → кэш в
--        playerData.gamepasses[key] + применение эффектов.
--      * PromptGamePassPurchaseFinished → пометить owned + применить + notify.
--      Эффекты: VIP (+10% монет лежит в SellInventory через MonetizationLogic;
--      здесь — титул/ник), Auto-Sell (autoSellUnlocked=true навсегда),
--      +2 pet slots (maxEquipped считает PetLogic live, persist не нужен).
--   2) DEVPRODUCTS (повторяемые) через MarketplaceService.ProcessReceipt:
--      coin packs (+coins), Egg 10x (grantHatch). Защита от двойного
--      начисления — DataStore purchase history по PurchaseId.
--   3) VIP-визуал (золотой ник/титул) рисует PlayerTag (core/PlayerTag.lua);
--      здесь только выдача/снятие эффектов пасса.
--
-- Формулы (coinBoost / petSlotBonus / lookup id→def) — единый источник в
-- shared/util/MonetizationLogic.lua. Здесь только применение/выдача.
--
-- В Studio реальные покупки невозможны — эмуляция через DevCommands
-- (/grantpass <key>, /grantproduct <key> [N]) поверх devGrantPass /
-- devGrantProduct.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("shared")

local Logger = require(shared.util.Logger)
local GameAnalytics = require(script.Parent.GameAnalytics)
local Constants = require(shared.constants)
local MonetizationLogic = require(shared.util.MonetizationLogic)
require(shared.util.EggMonetization)
local PlayerBoosts = require(script.Parent.PlayerBoosts)
local EggManager = require(script.Parent.EggManager)

export type Deps = {
    profileManager: any,
    onProfileChanged: ((player: Player) -> ())?,
    notify: ((player: Player, payload: any) -> ())?,
    -- PetManager — нужен для девпродукта «Egg 10x» (grantHatch).
    petManager: any?,
}

local MonetizationManager = {}
MonetizationManager.__index = MonetizationManager

-- Версионируем суффиксом _v1 — при смене схемы введём _v2 без потери истории.
local PURCHASE_HISTORY_STORE = "PurchaseHistory_v1"

local GOLD = { r = 255, g = 210, b = 50 }

function MonetizationManager.new(deps: Deps)
    local self = setmetatable({}, MonetizationManager)
    self._log = Logger.new("MonetizationManager")
    self._profileManager = deps.profileManager
    self._onProfileChanged = deps.onProfileChanged
    self._notify = deps.notify
    self._petManager = deps.petManager
    -- В Studio без API Services GetAsync/SetAsync спамят StudioAccessToApisNotAllowed
    -- даже внутри pcall. Живой dedup — только через DataStore на проде.
    self._purchaseMemory = {} :: { [string]: boolean }
    self._purchaseStoreLive = not RunService:IsStudio()
    self._purchaseStore = if self._purchaseStoreLive
        then DataStoreService:GetDataStore(PURCHASE_HISTORY_STORE)
        else nil
    if not self._purchaseStoreLive then
        self._log:info("Studio: PurchaseHistory in-memory fallback (no DataStore API calls)")
    end
    -- Studio dev-команды (/wipe, /grantpass, /revokepass) управляют
    -- gamepasses локально; Marketplace sync не должен перезаписывать профиль
    -- до конца сессии (иначе UserOwnsGamePassAsync вернёт VIP обратно).
    self._studioGamepassOverride = {} :: { [number]: boolean }
    Players.PlayerRemoving:Connect(function(player: Player)
        self._studioGamepassOverride[player.UserId] = nil
    end)

    -- ProcessReceipt можно назначить только один раз на сервере.
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        return self:_processReceipt(receiptInfo)
    end

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, wasPurchased: boolean)
        if not wasPurchased then
            return
        end
        local def = MonetizationLogic.gamepassById(gamePassId)
        if not def then
            self._log:warn("Куплен неизвестный gamepass id", gamePassId, "(нет в Constants.GAMEPASSES)")
            return
        end
        self:_grantGamepass(player, def.key, true)
    end)

    self._log:info("MonetizationManager initialized")
    return self
end

function MonetizationManager:_data(player: Player)
    return self._profileManager:getData(player)
end

function MonetizationManager:_sync(player: Player)
    if self._onProfileChanged then
        self._onProfileChanged(player)
    end
end

local function isStudio(): boolean
    return RunService:IsStudio()
end

function MonetizationManager:_setStudioGamepassOverride(player: Player)
    if isStudio() then
        self._studioGamepassOverride[player.UserId] = true
    end
end

function MonetizationManager:_shouldSkipMarketplaceSync(player: Player): boolean
    return isStudio() and self._studioGamepassOverride[player.UserId] == true
end

local function ensureGamepasses(data: any)
    if typeof(data.gamepasses) ~= "table" then
        data.gamepasses = {}
    end
    return data.gamepasses
end

local function ensureShopPurchases(data: any)
    if typeof(data.shopPurchases) ~= "table" then
        data.shopPurchases = {}
    end
    return data.shopPurchases
end

local function ensureActiveBoosts(data: any)
    if typeof(data.activeBoosts) ~= "table" then
        data.activeBoosts = {}
    end
    return data.activeBoosts
end

----------------------------------------------------------------------
-- Gamepasses
----------------------------------------------------------------------

--[[
    Применить ПЕРСИСТЕНТНЫЕ эффекты владения пассом. Идемпотентно.
      * autoSell  → autoSellUnlocked = true (навсегда).
      * vip       → нейм-тег (титул + золото) рисует PlayerTag на сервере,
                    здесь ничего делать не нужно.
      * petSlots  → ничего: PetLogic.maxEquipped(data) считает слоты live.
]]
function MonetizationManager:_applyGamepassEffects(player: Player, data: any, key: string)
    if key == "autoSell" then
        data.autoSellUnlocked = true
    end
end

--[[
    Пометить пасс как owned, применить эффекты, (опц.) notify. Используется и
    реальной покупкой (PromptGamePassPurchaseFinished), и dev-эмуляцией.
]]
function MonetizationManager:_grantGamepass(player: Player, key: string, doNotify: boolean?)
    local data = self:_data(player)
    if not data then
        return false
    end
    local def = (Constants.GAMEPASSES or {})[key]
    if not def then
        return false
    end
    local gp = ensureGamepasses(data)
    local wasOwned = gp[key] == true
    gp[key] = true
    self:_applyGamepassEffects(player, data, key)

    if doNotify and not wasOwned and self._notify then
        self._notify(player, {
            text = "server.notify.gamepassActivated",
            textParams = { name = def.name or key },
            icon = def.icon or "icon_sparkle",
            color = GOLD,
            duration = 4,
            kind = "shop_purchase",
            shopKey = key,
        })
        GameAnalytics.trackPurchase(player, key)
    end
    self:_sync(player)
    self._log:info("Gamepass granted:", player.UserId, key)
    return true
end

--[[
    Синхронизировать кэш владения с MarketplaceService (source of truth).
    Дёргается на заходе. Сетевые вызовы UserOwnsGamePassAsync yield'ят —
    выполняем в task.spawn, чтобы не блокировать остальную инициализацию;
    после — _sync(player), чтобы HUD получил актуальные gamepasses.
]]
function MonetizationManager:onProfileLoaded(player: Player)
    local data = self:_data(player)
    if not data then
        return
    end
    ensureGamepasses(data)

    if self:_shouldSkipMarketplaceSync(player) then
        self:_sync(player)
        return
    end

    task.spawn(function()
        for key, def in pairs(Constants.GAMEPASSES or {}) do
            if self:_shouldSkipMarketplaceSync(player) then
                break
            end
            -- id == 0 → пасс ещё не создан в Creator Hub (плейсхолдер).
            -- Пропускаем сетевой вызов; в Studio владение задаёт /grantpass.
            if typeof(def) == "table" and def.id and def.id ~= 0 then
                local ok, owns = pcall(function()
                    return MarketplaceService:UserOwnsGamePassAsync(player.UserId, def.id)
                end)
                if ok then
                    if not self:_data(player) then
                        return -- игрок успел выйти
                    end
                    local current = self:_data(player)
                    local gp = ensureGamepasses(current)
                    gp[key] = owns and true or false
                    if owns then
                        self:_applyGamepassEffects(player, current, key)
                    end
                else
                    self._log:warn("UserOwnsGamePassAsync failed for", key, owns)
                end
            end
        end
        if self:_data(player) then
            self:_sync(player)
        end
    end)
end

function MonetizationManager:_purchaseHistoryGet(purchaseKey: string): (boolean, boolean?)
    if not self._purchaseStoreLive then
        return true, self._purchaseMemory[purchaseKey] == true
    end
    local already: boolean?
    local ok, err = pcall(function()
        already = self._purchaseStore:GetAsync(purchaseKey)
    end)
    if not ok then
        return false, nil
    end
    return true, already
end

function MonetizationManager:_purchaseHistorySet(purchaseKey: string): (boolean, string?)
    if not self._purchaseStoreLive then
        self._purchaseMemory[purchaseKey] = true
        return true, nil
    end
    local ok, err = pcall(function()
        self._purchaseStore:SetAsync(purchaseKey, true)
    end)
    if not ok then
        return false, tostring(err)
    end
    return true, nil
end

----------------------------------------------------------------------
-- DevProducts (ProcessReceipt)
----------------------------------------------------------------------

--[[
    Выдать одну награду из bundle/starter. Возвращает true при успехе.
]]
function MonetizationManager:_grantReward(
    player: Player,
    data: any,
    reward: any,
    source: string
): boolean
    if typeof(reward) ~= "table" then
        return false
    end
    if reward.kind == "coins" then
        local amt = math.max(0, math.floor(reward.amount or 0))
        data.coins = (data.coins or 0) + amt
        data.totalCoinsEarned = (data.totalCoinsEarned or 0) + amt
        return true
    elseif reward.kind == "eggs" then
        if not self._petManager then
            self._log:warn("Egg-награда без PetManager")
            return false
        end
        local count = math.max(1, math.floor(reward.amount or 1))
        local eggId = EggManager.resolveGrantEggId(reward)
        self._petManager:grantHatch(player, count, eggId, true)
        return true
    elseif reward.kind == "boost" then
        local activeBoosts = ensureActiveBoosts(data)
        PlayerBoosts.addBoost(activeBoosts, {
            kind = reward.boostKind or "coins",
            multiplier = reward.multiplier or 2,
            durationSec = math.max(1, math.floor(reward.durationSec or 900)),
            source = source,
        })
        return true
    end
    return false
end

--[[
    Выдать награду девпродукта. Возвращает true при успехе. Вызывается из
    ProcessReceipt (реальная покупка) и devGrantProduct (эмуляция).
]]
function MonetizationManager:_grantProduct(player: Player, data: any, productDef: any): boolean
    if not productDef then
        return false
    end

    if productDef.oneTime == true then
        local purchases = ensureShopPurchases(data)
        if purchases[productDef.key] == true then
            self._log:warn("Повторная покупка one-time продукта:", productDef.key, player.UserId)
            return false
        end
    end

    if productDef.kind == "bundle" then
        local rewards = productDef.rewards
        if typeof(rewards) ~= "table" or #rewards == 0 then
            return false
        end
        local source = "shop_" .. tostring(productDef.key)
        for _, reward in ipairs(rewards) do
            if not self:_grantReward(player, data, reward, source) then
                return false
            end
        end
        if productDef.oneTime == true then
            ensureShopPurchases(data)[productDef.key] = true
        end
        if self._notify then
            self._notify(player, {
                text = "server.notify.bundleReceived",
                textParams = { name = productDef.name or productDef.key },
                icon = productDef.icon or "icon_gift",
                color = GOLD,
                duration = 4,
                kind = "shop_purchase",
                shopKey = productDef.key,
            })
        end
        GameAnalytics.trackPurchase(player, productDef.key)
        self:_sync(player)
        return true
    elseif productDef.kind == "boost" then
        local activeBoosts = ensureActiveBoosts(data)
        PlayerBoosts.addBoost(activeBoosts, {
            kind = productDef.boostKind or "coins",
            multiplier = productDef.multiplier or 2,
            durationSec = math.max(1, math.floor(productDef.durationSec or 900)),
            source = "shop_" .. tostring(productDef.key),
        })
        if self._notify then
            self._notify(player, {
                text = "server.notify.boostActivated",
                textParams = { name = productDef.name or productDef.key },
                icon = productDef.icon or "icon_sparkle",
                color = GOLD,
                duration = 4,
                kind = "shop_purchase",
                shopKey = productDef.key,
            })
        end
        GameAnalytics.trackPurchase(player, productDef.key)
        self:_sync(player)
        return true
    elseif productDef.kind == "coins" then
        local amt = math.max(0, math.floor(productDef.amount or 0))
        data.coins = (data.coins or 0) + amt
        data.totalCoinsEarned = (data.totalCoinsEarned or 0) + amt
        if self._notify then
            self._notify(player, {
                text = "server.notify.coinsGranted",
                textParams = { amount = amt },
                icon = productDef.icon or "coin",
                color = GOLD,
                duration = 4,
                kind = "shop_purchase",
                shopKey = productDef.key,
            })
        end
        GameAnalytics.trackPurchase(player, productDef.key)
        self:_sync(player)
        return true
    elseif productDef.kind == "eggs" then
        if not self._petManager then
            self._log:warn("Egg-продукт куплен, но PetManager не подключён")
            return false
        end
        local count = math.max(1, math.floor(productDef.amount or 1))
        local eggId = EggManager.resolveGrantEggId(productDef)
        local hatched = self._petManager:grantHatch(player, count, eggId, true)
        local eggDef = (Constants.PETS or {}).eggs and Constants.PETS.eggs[eggId]
        -- grantHatch уже дёрнул _sync. Шлём egg_purchase для PetHatchFX.
        if self._notify then
            self._notify(player, {
                text = "server.notify.petsHatched",
                textParams = { count = hatched and #hatched or 0 },
                icon = productDef.icon or "icon_egg",
                color = GOLD,
                duration = 4,
                kind = "egg_purchase",
                pets = hatched,
                eggId = eggId,
                eggModelName = eggDef and eggDef.modelName,
                shopKey = productDef.key,
            })
        end
        GameAnalytics.trackPurchase(player, productDef.key)
        return true
    elseif productDef.kind == "egg_hatch" then
        if not self._petManager then
            self._log:warn("Egg hatch продукт без PetManager")
            return false
        end
        local eggId = productDef.eggId
        if typeof(eggId) ~= "string" or eggId == "" then
            return false
        end
        local count = math.max(1, math.floor(productDef.amount or 1))
        local hatched = self._petManager:grantHatch(player, count, eggId)
        local eggDef = (Constants.PETS or {}).eggs and Constants.PETS.eggs[eggId]
        if self._notify then
            self._notify(player, {
                text = "server.notify.petsHatched",
                textParams = { count = hatched and #hatched or 0 },
                icon = productDef.icon or "icon_egg",
                color = GOLD,
                duration = 4,
                kind = "egg_purchase",
                pets = hatched,
                eggId = eggId,
                eggModelName = eggDef and eggDef.modelName,
                shopKey = productDef.key,
            })
        end
        GameAnalytics.trackPurchase(player, productDef.key)
        return true
    end
    return false
end

--[[
    MarketplaceService.ProcessReceipt — обрабатывает покупку девпродукта.
    Защита от двойного начисления — DataStore по ключу
    "<userId>_<purchaseId>" (документированный паттерн Roblox: GetAsync →
    grant → SetAsync). При любой неопределённости возвращаем NotProcessedYet,
    чтобы Roblox повторил позже (не теряем покупку, но и не начисляем дважды).
]]
function MonetizationManager:_processReceipt(receiptInfo)
    local userId = receiptInfo.PlayerId
    local purchaseKey = string.format("%d_%s", userId, tostring(receiptInfo.PurchaseId))

    -- 1) Уже обрабатывали этот PurchaseId? → idempotent grant.
    local okGet, already = self:_purchaseHistoryGet(purchaseKey)
    if okGet and already then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    elseif not okGet then
        self._log:warn("PurchaseHistory GetAsync failed for", purchaseKey)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- 2) Игрок и профиль должны быть в памяти.
    local player = Players:GetPlayerByUserId(userId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    local data = self:_data(player)
    if not data then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- 3) Резолвим продукт по реальному ProductId.
    local productDef = MonetizationLogic.productById(receiptInfo.ProductId)
    if not productDef then
        self._log:warn("Неизвестный ProductId", receiptInfo.ProductId, "(нет в Constants.DEVPRODUCTS)")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- 4) Выдаём награду.
    local okGrant, granted = pcall(function()
        return self:_grantProduct(player, data, productDef)
    end)
    if not okGrant or not granted then
        self._log:warn("Grant product failed:", receiptInfo.ProductId, granted)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- 5) Фиксируем в истории. Если SetAsync упал — NotProcessedYet, Roblox
    --    повторит; GetAsync на повторе вернёт nil (не записано), но эффект
    --    уже выдан. Это редкий кейс при сбое DataStore — приемлемо для MVP.
    local okSet, errSet = self:_purchaseHistorySet(purchaseKey)
    if not okSet then
        self._log:warn("PurchaseHistory SetAsync failed:", errSet)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    self._log:info("Product granted:", player.UserId, productDef.key, "purchase:", receiptInfo.PurchaseId)
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

----------------------------------------------------------------------
-- DevHooks (DevCommands, только Studio)
----------------------------------------------------------------------

-- /grantpass <key>: эмулировать покупку геймпасса (реальные покупки в Studio
-- недоступны).
function MonetizationManager:devGrantPass(player: Player, key: string): boolean
    if not (Constants.GAMEPASSES or {})[key] then
        return false
    end
    self:_setStudioGamepassOverride(player)
    return self:_grantGamepass(player, key, true)
end

-- Снять геймпасс (для повторного теста онбординга покупки).
function MonetizationManager:devRevokePass(player: Player, key: string): boolean
    if not (Constants.GAMEPASSES or {})[key] then
        return false
    end
    local data = self:_data(player)
    if not data then
        return false
    end
    self:_setStudioGamepassOverride(player)
    local gp = ensureGamepasses(data)
    gp[key] = nil
    if key == "autoSell" then
        data.autoSellUnlocked = false
    end
    -- VIP-визуал (золотой ник/титул) рисует PlayerTag на сервере и
    -- перестроится при следующем apply после _sync.
    self:_sync(player)
    return true
end

--[[
    После /wipe: профиль уже сброшен (gamepasses = {}), блокируем Marketplace
    re-sync на сессию и пушим HUD/PlayerTag через onProfileChanged.
]]
function MonetizationManager:devAfterWipe(player: Player)
    self:_setStudioGamepassOverride(player)
    self:_sync(player)
end

-- /grantproduct <key> [N]: эмулировать покупку девпродукта N раз.
function MonetizationManager:devGrantProduct(player: Player, key: string, count: number?): boolean
    local data = self:_data(player)
    if not data then
        return false
    end
    local productDef = (Constants.DEVPRODUCTS or {})[key]
    if not productDef then
        return false
    end
    local n = math.max(1, math.floor(count or 1))
    local anyOk = false
    for _ = 1, n do
        if self:_grantProduct(player, data, productDef) then
            anyOk = true
        end
    end
    return anyOk
end

return MonetizationManager
