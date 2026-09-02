--!strict
-- Корень: HUD state + сеть + React tree (весь screen UI).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages").ReactRoblox)

local AimHost = require(script.Parent.util.AimHost)
local App = require(script.Parent.App)
local CombatFlashLayer = require(script.Parent.components.CombatFlashLayer)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local DamageFeedbackLayer = require(script.Parent.components.DamageFeedbackLayer)
local DesignRoot = require(script.Parent.DesignRoot)
local HudProvider = require(script.Parent.context.HudProvider)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local SensitivityApplier = require(script.Parent.Parent.core.SensitivityApplier)
local SensitivityLogic = require(ReplicatedStorage.shared.util.SensitivityLogic)
local SkinDatabase = require(ReplicatedStorage.shared.data.SkinDatabase)
local SoundManager = require(script.Parent.Parent.core.SoundManager)
local Toast = require(script.Parent.components.Toast)
local Zap = require(script.Parent.Parent.net.NetClient)
local adapt = require(script.Parent.adapt)
local buildDamageHit = require(script.Parent.util.buildDamageHit)
local useLocalHealth = require(script.Parent.hooks.useLocalHealth)

type ToastItem = Toast.ToastItem
type DamageHit = buildDamageHit.DamageHit
type SkinOffer = {
    token: number,
    skinId: string,
    owned: boolean,
}

local toastSeq = 0
local damageSeq = 0
local skinOfferSeq = 0
local MAX_DAMAGE_HITS = 4

local function GameRoot(): React.Node
    local hud, setHud = React.useState({
        wins = 0,
        losses = 0,
        equippedSkinId = Constants.DEFAULT_SKIN_ID,
        lookSensitivity = Constants.LOOK_SENSITIVITY_DEFAULT,
        crosshairId = Constants.DEFAULT_CROSSHAIR_ID,
        ownedSkinIds = { Constants.DEFAULT_SKIN_ID },
    } :: NetTypes.HudSyncPayload)
    local match, setMatch = React.useState(nil :: NetTypes.MatchSyncPayload?)
    local skinOffer, setSkinOffer = React.useState(nil :: SkinOffer?)
    local toasts, setToasts = React.useState({} :: { ToastItem })
    local damageHits, setDamageHits = React.useState({} :: { DamageHit })
    local settingsOpen, setSettingsOpen = React.useState(false)
    local inventoryOpen, setInventoryOpen = React.useState(false)
    local inventoryTab, setInventoryTab = React.useState("gun" :: "gun" | "case")
    local shopOpen, setShopOpen = React.useState(false)
    local localHealth = useLocalHealth()

    local pushToast = React.useCallback(
        function(opts: { text: string, color: Color3?, duration: number? })
            toastSeq += 1
            local id = tostring(toastSeq)
            local item: ToastItem = {
                id = id,
                text = opts.text,
                color = opts.color,
            }
            setToasts(function(prev)
                local nextToasts = table.clone(prev)
                table.insert(nextToasts, item)
                return nextToasts
            end)
            local duration = opts.duration or 2.5
            task.delay(duration, function()
                setToasts(function(prev)
                    local nextToasts = {}
                    for _, t in prev do
                        if t.id ~= id then
                            table.insert(nextToasts, t)
                        end
                    end
                    return nextToasts
                end)
            end)
        end,
        {}
    )

    React.useEffect(function()
        SensitivityApplier.apply(hud.lookSensitivity)
    end, { hud.lookSensitivity })

    React.useEffect(function()
        local cleanups = {
            Zap.PlayerDataSync.On(function(value)
                local nextHud = NetTypes.fromZapSync(value)
                setHud(nextHud)
                SensitivityApplier.apply(nextHud.lookSensitivity)
            end),
            Zap.MatchStateSync.On(function(value)
                setMatch(NetTypes.fromZapMatch(value))
            end),
            Zap.OfferSkinEquip.On(function(value)
                skinOfferSeq += 1
                local token = skinOfferSeq
                setSkinOffer({
                    token = token,
                    skinId = value.skinId,
                    owned = value.owned,
                })
                task.delay(Constants.ROUND_RESET_DELAY_SEC, function()
                    setSkinOffer(function(current)
                        if current and current.token == token then
                            return nil
                        end
                        return current
                    end)
                end)
            end),
            Zap.TookDamage.On(function(value)
                damageSeq += 1
                local id = tostring(damageSeq)
                local hit = buildDamageHit(id, value.damage, value.headshot, value.fromPos)
                if not hit then
                    return
                end
                setDamageHits(function(prev)
                    local nextHits = table.clone(prev)
                    table.insert(nextHits, hit)
                    while #nextHits > MAX_DAMAGE_HITS do
                        table.remove(nextHits, 1)
                    end
                    return nextHits
                end)
                local lifetime = Constants.DAMAGE_INDICATOR_DURATION_SEC
                task.delay(lifetime, function()
                    setDamageHits(function(prev)
                        local nextHits = {}
                        for _, h in prev do
                            if h.id ~= id then
                                table.insert(nextHits, h)
                            end
                        end
                        return nextHits
                    end)
                end)
            end),
            Zap.Notify.On(function(payload)
                if payload.kind == "match_start" then
                    setSkinOffer(nil)
                    SoundManager.play("ui_confirm")
                    pushToast({
                        text = `Duel vs {payload.payload}`,
                        color = Color3.fromRGB(80, 220, 120),
                    })
                elseif payload.kind == "kill" then
                    pushToast({
                        text = `Eliminated {payload.payload}`,
                        color = Color3.fromRGB(255, 212, 38),
                    })
                elseif payload.kind == "death" then
                    SoundManager.playOneShot("dead", 1)
                    pushToast({
                        text = `Killed by {payload.payload}`,
                        color = Color3.fromRGB(255, 120, 80),
                    })
                elseif payload.kind == "opponent_left" then
                    setMatch(nil)
                    setSkinOffer(nil)
                    pushToast({
                        text = "Opponent left — requeue",
                        color = Color3.fromRGB(148, 158, 195),
                    })
                elseif payload.kind == "crosshair" then
                    SoundManager.play("ui_confirm")
                    pushToast({
                        text = `Crosshair: {payload.payload}`,
                        color = Color3.fromRGB(120, 220, 160),
                        duration = 1.6,
                    })
                end
            end),
        }
        return function()
            for _, cleanup in cleanups do
                cleanup()
            end
        end
    end, { pushToast })

    local requestRematch = React.useCallback(function()
        local result = Zap.RequestRematch.Call()
        if not result.success then
            pushToast({
                text = result.error or "Rematch failed",
                color = Color3.fromRGB(255, 120, 80),
            })
        end
    end, { pushToast })

    local startBotMatch = React.useCallback(function()
        local result = Zap.StartBotMatch.Call()
        if not result.success then
            pushToast({
                text = result.error or "Bot match failed",
                color = Color3.fromRGB(255, 120, 80),
            })
        end
    end, { pushToast })

    local equipOfferedSkin = React.useCallback(function()
        local offer = skinOffer
        if not offer or not offer.owned then
            return
        end
        local result = Zap.SetEquippedSkin.Call(offer.skinId)
        if not result.success then
            pushToast({
                text = result.error or "Equip failed",
                color = Color3.fromRGB(255, 120, 80),
            })
            return
        end
        if result.equippedSkinId then
            setHud(function(prev)
                local cloned = table.clone(prev)
                cloned.equippedSkinId = result.equippedSkinId :: string
                return cloned
            end)
        end
        pushToast({
            text = `Equipped {SkinDatabase.displayName(offer.skinId)}`,
            color = Color3.fromRGB(80, 220, 120),
            duration = 1.6,
        })
    end, { pushToast, skinOffer })

    local equipSkin = React.useCallback(function(skinId: string)
        local result = Zap.SetEquippedSkin.Call(skinId)
        if not result.success then
            pushToast({
                text = result.error or "Equip failed",
                color = Color3.fromRGB(255, 120, 80),
            })
            return
        end
        if result.equippedSkinId then
            setHud(function(prev)
                local cloned = table.clone(prev)
                cloned.equippedSkinId = result.equippedSkinId :: string
                return cloned
            end)
        end
        pushToast({
            text = `Equipped {SkinDatabase.displayName(skinId)}`,
            color = Color3.fromRGB(80, 220, 120),
            duration = 1.4,
        })
    end, { pushToast })

    local saveTokenRef = React.useRef(0)

    local setLookSensitivity = React.useCallback(function(value: number)
        local next = SensitivityLogic.round(value)
        -- Optimistic local apply; debounce profile save (slider spam).
        setHud(function(prev)
            local cloned = table.clone(prev)
            cloned.lookSensitivity = next
            return cloned
        end)
        SensitivityApplier.apply(next)

        saveTokenRef.current += 1
        local token = saveTokenRef.current
        task.delay(0.28, function()
            if token ~= saveTokenRef.current then
                return
            end
            local result = Zap.SetLookSensitivity.Call(next)
            if not result.success then
                pushToast({
                    text = result.error or "Sens save failed",
                    color = Color3.fromRGB(255, 120, 80),
                })
            elseif result.lookSensitivity then
                setHud(function(prev)
                    local cloned = table.clone(prev)
                    cloned.lookSensitivity = result.lookSensitivity :: number
                    return cloned
                end)
            end
        end)
    end, { pushToast })

    return React.createElement(DesignRoot, {
        config = adapt.DEFAULT,
    }, {
        Tree = React.createElement(HudProvider, {
            hud = hud,
            match = match,
            skinOffer = skinOffer,
            health = localHealth.health,
            maxHealth = localHealth.maxHealth,
            toasts = toasts,
            pushToast = pushToast,
            requestRematch = requestRematch,
            equipOfferedSkin = equipOfferedSkin,
            equipSkin = equipSkin,
            startBotMatch = startBotMatch,
            setLookSensitivity = setLookSensitivity,
            settingsOpen = settingsOpen,
            setSettingsOpen = setSettingsOpen,
            inventoryOpen = inventoryOpen,
            setInventoryOpen = setInventoryOpen,
            inventoryTab = inventoryTab,
            setInventoryTab = setInventoryTab,
            shopOpen = shopOpen,
            setShopOpen = setShopOpen,
        }, {
            App = React.createElement(App),
        }),
        CombatOverlay = ReactRoblox.createPortal(
            React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Active = false,
                Selectable = false,
                -- Below AimHost crosshair/hitmarker (default ZIndex 1).
                ZIndex = 0,
            }, {
                Flash = React.createElement(CombatFlashLayer, {
                    hits = damageHits,
                }),
                Vignette = React.createElement(DesignRoot, {
                    config = adapt.DEFAULT,
                }, {
                    Damage = React.createElement(DamageFeedbackLayer, {
                        hits = damageHits,
                    }),
                }),
            }),
            AimHost.get()
        ),
    })
end

return GameRoot
