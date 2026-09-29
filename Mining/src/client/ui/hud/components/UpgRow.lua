--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t
local ServerMessage = require(ReplicatedStorage:WaitForChild("shared").loc.ServerMessage)

local ScopeFactory = require(script.Parent.Parent.ScopeFactory)
local theme = require(script.Parent.Parent.theme)
local Formatters = require(script.Parent.Parent.formatters)
local UpgradeMeta = require(script.Parent.Parent.UpgradeMeta)
local SoundManager = require(script.Parent.Parent.Parent.Parent.core.SoundManager)
local UpgradeLogic = require(ReplicatedStorage:WaitForChild("shared").util.UpgradeLogic)
local Notification = require(script.Parent.Parent.Parent.Notification)
local UpgradeFanfareFX = require(script.Parent.Parent.Parent.UpgradeFanfareFX)
local Tooltip = require(script.Parent.Tooltip)
local UiAssets = require(ReplicatedStorage:WaitForChild("shared").data.UiAssets)
local UiMotion = require(script.Parent.Parent.Parent.util.UiMotion)
local UiInteract = require(script.Parent.Parent.Parent.util.UiInteract)
local PanelScale = require(script.Parent.Parent.PanelScale)

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local peek = Fusion.peek
local C = theme.C
local ICON = theme.ICON

local ERROR_HINT_SECONDS = 1.2
local SUCCESS_POP_PEAK = 1.12
-- Десктоп: геометрия ×2 синхронно с ×2 текстом (gsc). Phone/tablet без изменений.
local sc = PanelScale.gsc
local text = PanelScale.text

local function colorTag(c: Color3): string
    return string.format(
        "rgb(%d,%d,%d)",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5)
    )
end

-- Phase 8: цвета для error-тостов. Серверная экономика возвращает локализованный
-- `result.message` — мы лишь подбираем цвет под код ошибки.
local ERROR_COLOR_BY_CODE = {
    not_enough_coins = Color3.fromRGB(255, 90, 60),
    max_level = Color3.fromRGB(180, 180, 180),
}
local DEFAULT_ERROR_COLOR = Color3.fromRGB(255, 140, 60)

export type Props = {
    upgradeId: string,
    rowHeight: number?,
    coinsValue: any,
    upgradesValue: any,
    rebirthsValue: any,
    onBuy: () -> any,
}

local UpgRow = {}

function UpgRow.create(s: ScopeFactory.HudScope, props: Props)
    local id = props.upgradeId
    local accent = theme.UPGRADE_COLORS[id] or C.rare
    local hovered = s:Value(false)
    local rowPress = s:Value(false)
    local buyBusy = s:Value(false)
    local buyHint = s:Value("")

    local rowH = props.rowHeight or sc(62)
    local function rh(design: number): number
        return math.max(1, math.floor(design * rowH / 62 + 0.5))
    end

    -- Уровень/стоимость/MAX — реактивные Computed от общего state. Строка НЕ
    -- пересобирается на покупку: обновляются только Text/цвет свойства (иначе
    -- destroy+recreate инстансов = визуальное мерцание).
    local level = s:Computed(function(use)
        local u = use(props.upgradesValue)
        local row = if typeof(u) == "table" then u[id] else nil
        return if row and typeof(row.level) == "number" then row.level else 0
    end)
    local rebirths = s:Computed(function(use)
        return use(props.rebirthsValue) or 0
    end)
    local maxLevel = s:Computed(function(use)
        return UpgradeLogic.maxLevel(id, use(rebirths))
    end)
    local isMax = s:Computed(function(use)
        return use(level) >= use(maxLevel)
    end)
    local cost = s:Computed(function(use)
        return Formatters.upgradeCost(id, math.max(use(level), 1))
    end)
    local canAfford = s:Computed(function(use)
        if use(isMax) then
            return false
        end
        return use(props.coinsValue) >= use(cost)
    end)

    -- Phase 8: формируем текст tooltip'a динамически (через UpgradeLogic),
    -- чтобы tooltip всегда показывал актуальное состояние и сравнение
    -- с next-level. На MAX-уровне tooltip объясняет, что улучшать нечего.
    local function buildTooltipText(): string
        local name = UpgradeMeta.NAMES[id] or id
        local desc = UpgradeMeta.DESC[id] or ""
        local lvl = peek(level)
        local maxLvl = peek(maxLevel)
        local rb = peek(rebirths)
        local atMax = peek(isMax)
        local levelLabel = L("component.upg.level", { level = lvl, max = maxLvl })
        local now = UpgradeLogic.describeCurrentLevel(id, lvl)
        local nextStr = UpgradeLogic.describeNextLevel(id, lvl, rb)
        local titleSize = sc(18)
        local bodySize = sc(15)
        local accentSize = sc(16)
        local lines = {
            ('<font size="%d"><b>%s</b></font>'):format(titleSize, name),
            ('<font color="%s" size="%d">%s</font>'):format(colorTag(C.textSub), bodySize, desc),
            "",
            ('<font color="%s" size="%d"><b>%s</b></font>'):format(colorTag(C.primaryHi), accentSize, levelLabel),
            ('<font size="%d">%s <b>%s</b></font>'):format(bodySize, L("component.upg.now"), now),
        }
        if nextStr and not atMax then
            table.insert(
                lines,
                ('<font color="%s" size="%d"><b>%s</b> %s</font>'):format(colorTag(C.gold), accentSize, L("component.upg.next"), nextStr)
            )
        elseif atMax then
            table.insert(
                lines,
                ('<font color="%s" size="%d">%s</font>'):format(colorTag(C.textMuted), bodySize, L("component.upg.maxLevel"))
            )
        end
        if not atMax then
            local coins = peek(props.coinsValue) or 0
            local curCost = peek(cost)
            if coins < curCost then
                local deficit = curCost - coins
                table.insert(
                    lines,
                    ('<font color="%s" size="%d"><b>%s</b></font>'):format(colorTag(C.sellHi), accentSize, L("component.upg.deficit", { coins = deficit }))
                )
            end
        end
        return table.concat(lines, "\n")
    end

    local rowFrame: TextButton

    local function tryPurchase()
        if peek(buyBusy) or peek(isMax) then
            return
        end
        local curCost = peek(cost)
        local coins = peek(props.coinsValue) or 0
        if coins < curCost then
            SoundManager.play("buy_fail")
            buyHint:set("!")
            local deficit = math.max(1, curCost - coins)
            local name = UpgradeMeta.NAMES[id] or id
            Notification.show({
                text = L("component.upg.deficitToast", { name = name, coins = deficit }),
                icon = "coin",
                color = ERROR_COLOR_BY_CODE.not_enough_coins,
                duration = 2.5,
            })
            task.delay(ERROR_HINT_SECONDS, function()
                buyHint:set("")
            end)
            return
        end

        buyBusy:set(true)

        local ok, result = pcall(props.onBuy)
        buyBusy:set(false)

        if not ok then
            SoundManager.play("buy_fail")
            buyHint:set(L("component.upg.error"))
            Notification.show({
                text = L("component.upg.networkError"),
                icon = "icon_warning",
                color = DEFAULT_ERROR_COLOR,
                duration = 2.5,
            })
            task.delay(ERROR_HINT_SECONDS, function()
                buyHint:set("")
            end)
            return
        end

        if typeof(result) == "table" and result.success then
            buyHint:set("")
            local newLevel = peek(level) + 1
            UiMotion.defer(s, rowFrame, function(row)
                local buy = row:FindFirstChild("BuyButton") :: TextButton?
                if buy then
                    UiMotion.pop(buy, SUCCESS_POP_PEAK)
                    UpgradeFanfareFX.play({
                        anchor = buy,
                        accent = accent,
                        newLevel = newLevel,
                        upgradeId = id,
                    })
                end
                return nil
            end)
        elseif typeof(result) == "table" and result.message then
            SoundManager.play("buy_fail")
            local msg = ServerMessage.fromResult(result, "server.error.unknown")
            buyHint:set("!")
            local color = ERROR_COLOR_BY_CODE[result.error or ""] or DEFAULT_ERROR_COLOR
            Notification.show({
                text = msg,
                icon = "icon_warning",
                color = color,
                duration = 2.5,
            })
            task.delay(ERROR_HINT_SECONDS, function()
                buyHint:set("")
            end)
        else
            SoundManager.play("buy_fail")
            buyHint:set(L("component.upg.error"))
            Notification.show({
                text = L("component.upg.purchaseFailed"),
                icon = "icon_warning",
                color = DEFAULT_ERROR_COLOR,
                duration = 2.5,
            })
            task.delay(ERROR_HINT_SECONDS, function()
                buyHint:set("")
            end)
        end
    end

    -- `Name` поле — конвенция Phase 8: TutorialArrow ищет таргет именно
    -- по этому имени (PlayerGui.DeepDiggerHUD:FindFirstChild(..., true)).
    -- В свою очередь Tooltip привязываемся к этому же frame'у через scope,
    -- так что cleanup идёт через Fusion.doCleanup(scope) автоматически.
    rowFrame = s:New("TextButton")({
        Name = "UpgRow_" .. id,
        Size = UDim2.new(1, -sc(8), 0, rowH),
        BackgroundColor3 = s:Computed(function(use)
            return use(hovered) and C.btnHover or C.btnBg
        end),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        Selectable = false,
        ZIndex = 1,
        [OnEvent("MouseEnter")] = function()
            hovered:set(true)
        end,
        [OnEvent("MouseLeave")] = function()
            hovered:set(false)
        end,
        [Children] = {
            s:New("UICorner")({ CornerRadius = UDim.new(0, rh(10)) }),
            s:New("UIStroke")({ Color = C.btnBorder, Thickness = theme.STROKE.medium, Transparency = 0 }),
            s:New("Frame")({
                Name = "IconCircle",
                Size = UDim2.fromOffset(rh(44), rh(44)),
                Position = UDim2.new(0, rh(8), 0.5, -rh(22)),
                BackgroundColor3 = accent,
                BackgroundTransparency = ICON.circleBgAlpha,
                BorderSizePixel = 0,
                [Children] = {
                    s:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
                    s:New("UIStroke")({ Color = accent, Thickness = 1.5, Transparency = 0.3 }),
                    s:New("ImageLabel")({
                        Size = UDim2.fromOffset(rh(28), rh(28)),
                        Position = UDim2.new(0.5, -rh(14), 0.5, -rh(14)),
                        BackgroundTransparency = 1,
                        Image = UiAssets.upgrade(id),
                        ImageColor3 = ICON.tint,
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 2,
                    }),
                },
            }),
            s:New("TextLabel")({
                Size = UDim2.new(0.48, 0, 0, rh(22)),
                Position = UDim2.new(0, rh(60), 0, rh(8)),
                BackgroundTransparency = 1,
                Text = UpgradeMeta.NAMES[id] or id,
                TextSize = text(16),
                Font = Enum.Font.GothamBold,
                TextColor3 = accent,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }),
            s:New("TextLabel")({
                Size = UDim2.new(0.48, 0, 0, rh(16)),
                Position = UDim2.new(0, rh(60), 0, rh(30)),
                BackgroundTransparency = 1,
                Text = UpgradeMeta.DESC[id] or "",
                TextSize = text(13),
                Font = Enum.Font.Gotham,
                TextColor3 = C.textSub,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 2,
            }),
            s:New("TextLabel")({
                Size = UDim2.new(0.16, 0, 0, rh(22)),
                Position = UDim2.new(0.56, 0, 0, rh(8)),
                BackgroundTransparency = 1,
                Text = s:Computed(function(use)
                    if use(isMax) then
                        return L("component.upg.max")
                    end
                    return tostring(use(level))
                end),
                TextSize = text(18),
                Font = Enum.Font.GothamBlack,
                TextColor3 = s:Computed(function(use)
                    return if use(isMax) then C.gold else C.textMain
                end),
                TextXAlignment = Enum.TextXAlignment.Right,
            }),
            s:New("Frame")({
                Size = UDim2.new(0.18, 0, 0, rh(20)),
                Position = UDim2.new(0.56, 0, 0, rh(30)),
                BackgroundTransparency = 1,
                [Children] = {
                    s:New("ImageLabel")({
                        Size = UDim2.fromOffset(rh(14), rh(14)),
                        Position = UDim2.new(1, -rh(52), 0.5, -rh(7)),
                        BackgroundTransparency = 1,
                        Image = UiAssets.image("coin"),
                        ImageColor3 = ICON.tint,
                        ScaleType = Enum.ScaleType.Fit,
                        Visible = s:Computed(function(use)
                            return use(buyHint) == "" and not use(isMax)
                        end),
                    }),
                    s:New("TextLabel")({
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = s:Computed(function(use)
                            local hint = use(buyHint)
                            if hint ~= "" then
                                return hint
                            end
                            if use(isMax) then
                                return ""
                            end
                            return Formatters.shortNumber(use(cost))
                        end),
                        TextSize = text(16),
                        Font = Enum.Font.GothamBold,
                        TextColor3 = s:Computed(function(use)
                            if use(buyHint) ~= "" then
                                return C.gold
                            end
                            return if use(canAfford) then C.gold else C.textMuted
                        end),
                        TextXAlignment = Enum.TextXAlignment.Right,
                    }),
                },
            }),
            s:New("TextButton")({
                Name = "BuyButton",
                Size = UDim2.fromOffset(rh(36), rh(36)),
                Position = UDim2.new(1, -rh(44), 0.5, -rh(18)),
                ZIndex = 2,
                BackgroundColor3 = s:Computed(function(use)
                    if use(isMax) then
                        return C.btnDisabled
                    end
                    return if use(canAfford) then accent else C.btnDisabled
                end),
                BorderSizePixel = 0,
                Text = s:Computed(function(use)
                    return if use(isMax) then "" else "+"
                end),
                TextSize = text(20),
                Font = Enum.Font.GothamBlack,
                TextColor3 = C.white,
                Active = s:Computed(function(use)
                    return not use(isMax)
                end),
                [Children] = {
                    s:New("UICorner")({ CornerRadius = UDim.new(0, rh(6)) }),
                    s:New("UIStroke")({
                        Color = s:Computed(function(use)
                            return if use(canAfford) and not use(isMax) then C.white else C.btnBorder
                        end),
                        Thickness = 1.5,
                        Transparency = 0.5,
                    }),
                    s:New("ImageLabel")({
                        Size = UDim2.fromOffset(rh(18), rh(18)),
                        Position = UDim2.new(0.5, -rh(9), 0.5, -rh(9)),
                        BackgroundTransparency = 1,
                        Image = UiAssets.image("icon_check"),
                        ImageColor3 = ICON.tint,
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 3,
                        Visible = isMax,
                    }),
                },
                [OnEvent("Activated")] = tryPurchase,
            }),
        },
    })

    Tooltip.attach(s, rowFrame, buildTooltipText, { scale = PanelScale.layoutScale() })

    UiMotion.bindHoverPress(s, rowFrame, hovered, rowPress, { hoverScale = 1.015, pressScale = 1 })
    UiMotion.defer(s, rowFrame, function(row)
        local buy = row:FindFirstChild("BuyButton") :: TextButton?
        if buy then
            UiInteract.attachScoped(s, buy, {
                hoverScale = 1.1,
                pressScale = 0.9,
                disabled = function()
                    return peek(isMax)
                end,
            })
        end
        return nil
    end)

    return rowFrame
end

return UpgRow
