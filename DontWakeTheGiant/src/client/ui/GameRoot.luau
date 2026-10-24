--!strict
-- Корень: состояние HUD (сеть + атрибуты GiantState / игрока) и React tree.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local App = require(script.Parent.App)
local HudContext = require(script.Parent.context.HudContext)
local InputController = require(script.Parent.Parent.game.InputController)
local Notification = require(script.Parent.Parent.core.Notification)
local Zap = require(script.Parent.Parent.net.NetClient)
local theme = require(script.Parent.theme)

local FEED_MAX = 4
local FEED_TTL_SEC = 6

local player = Players.LocalPlayer

local TOAST_COLORS: { [string]: Color3 } = {
    steal_warn = theme.Colors.error,
    stolen = theme.Colors.error,
    caught = Color3.fromHex("#FFC93C"),
    delivered = theme.Colors.success,
    hint = theme.Colors.textMain,
}

local function GameRoot(): React.Node
    local giantState = ReplicatedStorage:WaitForChild("GiantState") :: Configuration
    local hud, setHud = React.useState({ coins = 0, incomePerSec = 0 })
    local giant, setGiant = React.useState({ noise = 0, phase = "Deep" })
    local sneaking, setSneaking = React.useState(false)
    local carrying, setCarrying = React.useState(nil :: string?)
    local feed, setFeed = React.useState({} :: { HudContext.FeedEntry })

    React.useEffect(function()
        local nextId = 0
        local function pushFeed(text: string, color: Color3)
            nextId += 1
            local id = nextId
            setFeed(function(prev)
                local list = table.clone(prev)
                table.insert(list, { id = id, text = text, color = color })
                while #list > FEED_MAX do
                    table.remove(list, 1)
                end
                return list
            end)
            task.delay(FEED_TTL_SEC, function()
                setFeed(function(prev)
                    local list = {}
                    for _, entry in prev do
                        if entry.id ~= id then
                            table.insert(list, entry)
                        end
                    end
                    return list
                end)
            end)
        end

        local function readGiant()
            setGiant({
                noise = (giantState:GetAttribute("Noise") :: number?) or 0,
                phase = (giantState:GetAttribute("Phase") :: string?) or "Deep",
            })
        end
        readGiant()
        local function readPlayer()
            setSneaking(player:GetAttribute("Sneaking") == true)
            setCarrying(player:GetAttribute("CarryingItemId") :: string?)
        end
        readPlayer()

        local connections = {
            giantState:GetAttributeChangedSignal("Noise"):Connect(readGiant),
            giantState:GetAttributeChangedSignal("Phase"):Connect(readGiant),
            player:GetAttributeChangedSignal("Sneaking"):Connect(readPlayer),
            player:GetAttributeChangedSignal("CarryingItemId"):Connect(readPlayer),
        }
        local cleanups = {
            Zap.PlayerDataSync.On(function(value)
                setHud({ coins = value.coins, incomePerSec = value.incomePerSec })
            end),
            Zap.Notify.On(function(payload)
                if payload.kind == "feed" then
                    pushFeed(payload.payload, theme.Colors.textMain)
                elseif payload.kind == "wake" then
                    pushFeed(payload.payload, theme.Colors.error)
                    Notification.show({
                        text = payload.payload,
                        color = theme.Colors.error,
                        duration = 2,
                    })
                elseif payload.kind == "delivered" then
                    Notification.show({
                        text = `{payload.payload} is yours!`,
                        color = TOAST_COLORS.delivered,
                    })
                else
                    Notification.show({
                        text = payload.payload,
                        color = TOAST_COLORS[payload.kind] or theme.Colors.textMain,
                    })
                end
            end),
        }
        return function()
            for _, c in connections do
                c:Disconnect()
            end
            for _, cleanup in cleanups do
                cleanup()
            end
        end
    end, {})

    local value = React.useMemo(function()
        return {
            hud = hud,
            giant = giant,
            sneaking = sneaking,
            carryingItemId = carrying,
            feed = feed,
            toggleSneak = InputController.toggleSneak,
            drop = InputController.drop,
        }
    end, { hud, giant, sneaking, carrying, feed } :: { any })

    return React.createElement(HudContext.Provider, { value = value }, {
        App = React.createElement(App),
    })
end

return GameRoot
