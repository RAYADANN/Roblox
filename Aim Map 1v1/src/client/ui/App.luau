--!strict
-- Duel / practice HUD — design space 1920×1080 via DesignRoot. SimPop chrome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages").ReactRoblox)

local AimHost = require(script.Parent.util.AimHost)
local Crosshair = require(script.Parent.components.Crosshair)
local DesignRoot = require(script.Parent.DesignRoot)
local DuelHud = require(script.Parent.components.DuelHud)
local FireCooldownBar = require(script.Parent.components.FireCooldownBar)
local FirstPersonController = require(script.Parent.Parent.core.FirstPersonController)
local HitMarker = require(script.Parent.components.HitMarker)
local HudContext = require(script.Parent.context.HudContext)
local InventoryPanel = require(script.Parent.components.InventoryPanel)
local KillBanner = require(script.Parent.components.KillBanner)
local ModalHost = require(script.Parent.util.ModalHost)
local ModalScrim = require(script.Parent.components.ModalScrim)
local SensitivityPanel = require(script.Parent.components.SensitivityPanel)
local ShopPanel = require(script.Parent.components.ShopPanel)
local SkinDatabase = require(ReplicatedStorage.shared.data.SkinDatabase)
local SkinOfferPanel = require(script.Parent.components.SkinOfferPanel)
local ToastStack = require(script.Parent.components.ToastStack)
local adapt = require(script.Parent.adapt)

local function App(): React.Node
    local ctx = React.useContext(HudContext)
    local match = ctx.match

    local statusText = "Practice — shoot the BOT dummies"
    local scoreText = "Solo aim"
    local skinText = SkinDatabase.displayName(ctx.hud.equippedSkinId)
    local showRematch = false

    if match then
        if match.phase == "Live" then
            statusText = `vs {match.oppName}`
            scoreText = `{match.youScore} — {match.oppScore}`
            skinText = `USP · {SkinDatabase.displayName(match.visibleSkinId)}`
        elseif match.phase == "Ended" then
            local won = match.youScore > match.oppScore
            statusText = if won then "You win" else "Defeat"
            scoreText = `{match.youScore} — {match.oppScore}`
            showRematch = true
            if match.youReadyRematch then
                statusText = if match.oppReadyRematch then "Rematch…" else "Waiting opponent…"
            end
        end
    end

    local showVsBot = match == nil
    local menuUnlock = showRematch or ctx.settingsOpen or ctx.inventoryOpen or ctx.shopOpen
    local cursorFree, setCursorFree = React.useState(FirstPersonController.isCursorFree())

    React.useEffect(function()
        FirstPersonController.setMenuCursorUnlock(menuUnlock)
        return function()
            FirstPersonController.setMenuCursorUnlock(false)
        end
    end, { menuUnlock })

    React.useEffect(function()
        return FirstPersonController.onCursorFreeChanged(setCursorFree)
    end, {})

    React.useEffect(function()
        local conn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then
                return
            end
            if input.KeyCode == Enum.KeyCode.I then
                ctx.setShopOpen(false)
                ctx.setInventoryOpen(not ctx.inventoryOpen)
            elseif input.KeyCode == Enum.KeyCode.K then
                ctx.setSettingsOpen(not ctx.settingsOpen)
            elseif input.KeyCode == Enum.KeyCode.Escape then
                if ctx.shopOpen then
                    ctx.setShopOpen(false)
                elseif ctx.inventoryOpen then
                    ctx.setInventoryOpen(false)
                elseif ctx.settingsOpen then
                    ctx.setSettingsOpen(false)
                end
            elseif input.KeyCode == Enum.KeyCode.Y and ctx.skinOffer ~= nil then
                ctx.equipOfferedSkin()
            end
        end)
        return function()
            conn:Disconnect()
        end
    end, {
        ctx.settingsOpen,
        ctx.setSettingsOpen,
        ctx.inventoryOpen,
        ctx.setInventoryOpen,
        ctx.shopOpen,
        ctx.setShopOpen,
        ctx.skinOffer,
        ctx.equipOfferedSkin,
    })

    local freeCursor = cursorFree

    local function soon(label: string)
        return function()
            ctx.pushToast({
                text = `{label} — soon`,
            })
        end
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Toasts = React.createElement(ToastStack, {
            items = ctx.toasts,
        }),

        -- Crosshair / hitmarker live on a full-bleed ScreenGui so 50% = camera center.
        Aim = if freeCursor
            then nil
            else ReactRoblox.createPortal(
                React.createElement(DesignRoot, {
                    config = adapt.DEFAULT,
                }, {
                    Crosshair = React.createElement(Crosshair, {
                        crosshairId = ctx.hud.crosshairId,
                    }),
                    HitMarker = React.createElement(HitMarker),
                }),
                AimHost.get()
            ),
        KillBanner = if freeCursor then nil else React.createElement(KillBanner),
        FireCd = if freeCursor then nil else React.createElement(FireCooldownBar),

        Chrome = React.createElement(DuelHud, {
            statusText = statusText,
            scoreText = scoreText,
            skinText = skinText,
            recordText = `W {ctx.hud.wins}  ·  L {ctx.hud.losses}  ·  Sens {string.format(
                "%.1f",
                ctx.hud.lookSensitivity
            )}`,
            hintText = "Alt — cursor · I — inventory · K — sens",
            health = ctx.health,
            maxHealth = ctx.maxHealth,
            showVsBot = showVsBot,
            showRematch = showRematch,
            rematchReady = ctx.match ~= nil and ctx.match.youReadyRematch,
            settingsOpen = ctx.settingsOpen,
            onSettings = function()
                ctx.setSettingsOpen(not ctx.settingsOpen)
            end,
            onVsBot = ctx.startBotMatch,
            onRematch = ctx.requestRematch,
            onShop = function()
                ctx.setInventoryOpen(false)
                ctx.setShopOpen(true)
            end,
            onInvite = soon("Invite"),
            onInventory = function()
                ctx.setShopOpen(false)
                ctx.setInventoryOpen(true)
            end,
        }),

        Settings = if ctx.settingsOpen
            then React.createElement(SensitivityPanel, {
                value = ctx.hud.lookSensitivity,
                onChange = ctx.setLookSensitivity,
                onClose = function()
                    ctx.setSettingsOpen(false)
                end,
            })
            else nil,

        Inventory = if ctx.inventoryOpen
            then ReactRoblox.createPortal(
                React.createElement("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 20,
                }, {
                    Scrim = React.createElement(ModalScrim, {
                        onActivated = function()
                            ctx.setInventoryOpen(false)
                        end,
                    }),
                    Root = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                    }, {
                        Design = React.createElement(DesignRoot, {
                            config = adapt.DEFAULT,
                        }, {
                            Panel = React.createElement(InventoryPanel, {
                                ownedSkinIds = ctx.hud.ownedSkinIds,
                                equippedSkinId = ctx.hud.equippedSkinId,
                                tab = ctx.inventoryTab,
                                onTabChange = ctx.setInventoryTab,
                                onEquipSkin = ctx.equipSkin,
                                onClose = function()
                                    ctx.setInventoryOpen(false)
                                end,
                            }),
                        }),
                    }),
                }),
                ModalHost.get()
            )
            else nil,

        Shop = if ctx.shopOpen
            then ReactRoblox.createPortal(
                React.createElement("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 20,
                }, {
                    Scrim = React.createElement(ModalScrim, {
                        onActivated = function()
                            ctx.setShopOpen(false)
                        end,
                    }),
                    Root = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                    }, {
                        Design = React.createElement(DesignRoot, {
                            config = adapt.DEFAULT,
                        }, {
                            Panel = React.createElement(ShopPanel, {
                                onBuy = function(offerId: string, qty: number)
                                    ctx.pushToast({
                                        text = `Buy {qty}x {offerId} — soon`,
                                    })
                                end,
                                onClose = function()
                                    ctx.setShopOpen(false)
                                end,
                            }),
                        }),
                    }),
                }),
                ModalHost.get()
            )
            else nil,
        SkinOffer = if ctx.skinOffer
            then React.createElement("Frame", {
                Size = UDim2.fromScale(0.15, 0.23),
                Position = UDim2.fromScale(1 - 0.02, 0.12),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
            }, {
                Panel = React.createElement(SkinOfferPanel, {
                    token = ctx.skinOffer.token,
                    skinId = ctx.skinOffer.skinId,
                    owned = ctx.skinOffer.owned,
                    equipped = ctx.hud.equippedSkinId == ctx.skinOffer.skinId,
                    onEquip = ctx.equipOfferedSkin,
                }),
            })
            else nil,
    })
end

return App
