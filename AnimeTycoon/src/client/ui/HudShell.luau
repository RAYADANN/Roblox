--!strict
-- HUD + окна: Shop / Index / Rewards. Blur + zoom через useModalFocus.
-- SoundManager опционален: в Hoarcekat UI живёт в ReplicatedStorage без client.core.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ExclusiveShopPanel = require(script.Parent.shop.ExclusiveShopPanel)
local HudPanel = require(script.Parent.hud.HudPanel)
local IndexPanel = require(script.Parent.index.IndexPanel)
local MockData = require(script.Parent.shop.MockData)
local RewardsPanel = require(script.Parent.rewards.RewardsPanel)
local useModalFocus = require(script.Parent.hooks.useModalFocus)

export type WindowId = "shop" | "index" | "rewards"

export type Props = {
    moneyText: string?,
    onRebirth: (() -> ())?,
}

local function playClick()
    local core = script.Parent.Parent:FindFirstChild("core")
    if core == nil then
        return
    end
    local module = core:FindFirstChild("SoundManager")
    if module == nil then
        return
    end
    local ok, sound = pcall(require, module)
    if ok and sound ~= nil then
        sound.play("ui_click")
    end
end

local function HudShell(props: Props): React.Node
    local open, setOpen = React.useState(nil :: WindowId?)
    useModalFocus(open ~= nil)

    local function close()
        playClick()
        setOpen(nil)
    end

    local function openWindow(id: WindowId)
        playClick()
        setOpen(id)
    end

    local overlay: React.Node? = nil
    if open == "shop" then
        overlay = React.createElement(ExclusiveShopPanel, {
            boosts = MockData.boosts(),
            cash = MockData.cash(),
            onBuy = function(_productId: string) end,
            onGift = function(_productId: string) end,
            onClose = close,
        })
    elseif open == "index" then
        overlay = React.createElement(IndexPanel, {
            onClose = close,
        })
    elseif open == "rewards" then
        overlay = React.createElement(RewardsPanel, {
            onClose = close,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Hud = React.createElement(HudPanel, {
            data = if props.moneyText then { moneyText = props.moneyText } else nil,
            onShop = function()
                openWindow("shop")
            end,
            onIndex = function()
                openWindow("index")
            end,
            onGift = function()
                openWindow("rewards")
            end,
            onRebirth = props.onRebirth,
        }),
        Window = if overlay
            then React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 50,
            }, {
                Panel = overlay,
            })
            else nil,
    })
end

return HudShell
