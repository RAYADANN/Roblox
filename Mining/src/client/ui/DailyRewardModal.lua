--!strict
-- DailyRewardModal.lua — Phase 10.
--
-- Полноэкранный модал «🎁 Награда за день» с сеткой 7 карточек.
-- Открывается при заходе если dailyState.canClaim == true (через Phase 10
-- логику в init.client.lua: либо первый PlayerStats payload, либо Notify
-- kind="daily_available").
--
-- Структура:
--   * Backdrop (полупрозрачный) + кнопка-overlay для закрытия по клику.
--   * Modal-frame: header «🎁 День N» + grid карточек (4×2 на всех тирах).
--   * Footer: [ЗАБРАТЬ] (золотая) и [ПОЗЖЕ] (серая).
--   * Anti-misclick: 0.4с задержка перед активацией [ЗАБРАТЬ] (по примеру
--     Phase 9 RebirthConfirmModal с 0.3с).
--   * ESC закрывает (без claim).
--
-- На claim:
--   * Net:Invoke("ClaimDaily") без аргументов (сервер сам считает день).
--   * Tween selected-карточки → центр (1.4x scale).
--   * RewardFX.burst(rarity дня).
--   * Через 0.8с fade-out модала.
--
-- API:
--   DailyRewardModal.show({ scope, state }) → Handle :close()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)
local Net = require(ReplicatedStorage:WaitForChild("Packages").Net)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t
local ServerMessage = require(ReplicatedStorage:WaitForChild("shared").loc.ServerMessage)
-- Constants / DailyLogic / DailyRewardDatabase не нужны клиенту напрямую:
-- сервер вычисляет nextDay / rarity и шлёт через PlayerStats + Notify.

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local peek = Fusion.peek

local DailyCard = require(script.Parent.hud.components.DailyCard)
local UiIcon = require(script.Parent.hud.components.UiIcon)
local theme = require(script.Parent.hud.theme)
local Notification = require(script.Parent.Notification)
local SoundManager = require(script.Parent.Parent.core.SoundManager)
local ViewportLayout = require(script.Parent.util.ViewportLayout)
local UiScreen = require(script.Parent.util.UiScreen)
local EngagementTracker = require(script.Parent.util.EngagementTracker)
local Tutorial = require(script.Parent.Tutorial)
-- RewardFX дёргается через Net:Connect("Notify") в init.client.lua с
-- kind="daily_reward" (server-side authority по rarity дня).

local C = theme.C

local MODAL_GUI_NAME = "DeepDigger_DailyModal"
local ANTI_MISCLICK_DELAY = 0.4
local FADE_IN = 0.18
local FADE_OUT = 0.18
local DAILY_COLS = 4
local CARD_ASPECT = 1.38

type DailyLayout = {
	cols: number,
	gap: number,
	padding: number,
	headerH: number,
	footerH: number,
	footerBtnH: number,
	titleText: number,
	streakText: number,
	cardW: number,
	cardH: number,
	gridW: number,
	gridH: number,
	modalW: number,
	modalH: number,
	laterW: number,
	claimW: number,
}

local function computeDailyLayout(): DailyLayout
	local phone = ViewportLayout.isPhone()
	local narrow = ViewportLayout.isNarrow()
	local gap = if phone then 8 else 10
	local padding = if phone then 14 else 20
	local headerH = if phone then 52 else 64
	local footerH = if phone then 52 else 64
	local footerBtnH = if phone then 40 else 44
	local rows = math.ceil(7 / DAILY_COLS)

	local cardW = 100
	local cardH = 140

	if narrow then
		local playW = ViewportLayout.playableWidth()
		local playH = ViewportLayout.availableHeight()
		local widthFrac = if phone then 0.92 else 0.86
		local maxModalW = math.floor(playW * widthFrac)
		local maxModalH = math.floor(playH * 0.90)
		local maxGridW = maxModalW - padding * 2
		local maxGridH = math.max(72, maxModalH - headerH - footerH - padding * 2 - 12)
		local cardWFromW = (maxGridW - (DAILY_COLS - 1) * gap) / DAILY_COLS
		local cardHFromH = (maxGridH - (rows - 1) * gap) / rows
		local cardWFromH = cardHFromH / CARD_ASPECT
		cardW = math.floor(math.min(cardWFromW, cardWFromH))
		cardW = math.clamp(cardW, 52, 108)
		cardH = math.floor(cardW * CARD_ASPECT + 0.5)
	end

	local gridW = DAILY_COLS * cardW + (DAILY_COLS - 1) * gap
	local gridH = rows * cardH + (rows - 1) * gap
	local modalW = gridW + padding * 2
	local modalH = headerH + gridH + footerH + padding * 2 + 12
	local innerW = modalW - padding * 2
	local footerGap = 8
	local laterW = math.floor(innerW * 0.34)
	local claimW = innerW - laterW - footerGap

	return {
		cols = DAILY_COLS,
		gap = gap,
		padding = padding,
		headerH = headerH,
		footerH = footerH,
		footerBtnH = footerBtnH,
		titleText = if phone then 18 else 22,
		streakText = if phone then 11 else 13,
		cardW = cardW,
		cardH = cardH,
		gridW = gridW,
		gridH = gridH,
		modalW = modalW,
		modalH = modalH,
		laterW = laterW,
		claimW = claimW,
	}
end

local DailyRewardModal = {}

export type Options = {
    scope: any,
    -- Текущий streak (0..7). Если 0 — игрок никогда не клеймил, рисуем
    -- День 1 как current. Если N — следующий claim даст streak N+1.
    streak: number,
    -- Какой день СЛЕДУЮЩЕГО claim'а (1..7) — DailyLogic.streakToCycleDay уже посчитан.
    nextDay: number,
    onClose: (() -> ())?,
}

export type Handle = {
    close: (self: Handle) -> (),
}

local _activeHandle: any = nil

local function ensureGui(): ScreenGui?
    local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    return UiScreen.ensure(pg, MODAL_GUI_NAME, "modal")
end

function DailyRewardModal.show(opts: Options): Handle?
    -- Защита: только один модал одновременно.
    if _activeHandle then
        return _activeHandle
    end
    EngagementTracker.trackModal("daily")
    -- Phase 10: каждое открытие — свой innerScope. doCleanup на close()
    -- предотвращает накопление Fusion Value/Computed между показами модала.
    local parentScope = opts.scope
    local s = parentScope:innerScope()
    local gui = ensureGui()
    if not gui then return nil end
    -- Чистим возможные остатки от прошлой сессии.
    for _, child in ipairs(gui:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local handle: any = { _closed = false }
    _activeHandle = handle
    local tutorialWasRunning = Tutorial.isRunning()
    if tutorialWasRunning then
        Tutorial.setChromeVisible(false)
    end
    local enabled = s:Value(false)
    local hoveredClaim = s:Value(false)
    local hoveredLater = s:Value(false)

    local escConn: RBXScriptConnection? = nil
    local backdrop: Frame
    local stopPulse: (() -> ())? = nil

    local function doClose()
        if handle._closed then return end
        handle._closed = true
        _activeHandle = nil
        if escConn then escConn:Disconnect(); escConn = nil end
        if stopPulse then pcall(stopPulse); stopPulse = nil end
        if backdrop then
            TweenService:Create(backdrop, TweenInfo.new(FADE_OUT, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 1,
            }):Play()
            task.delay(FADE_OUT + 0.05, function()
                if backdrop and backdrop.Parent then
                    backdrop:Destroy()
                end
                -- doCleanup освобождает Fusion-аллокации scope'a. Ставим
                -- после destroy frame'a чтобы Computed-биндинги отвалились
                -- штатно (без error на nil instance).
                pcall(function()
                    Fusion.doCleanup(s)
                end)
            end)
        end
        if opts.onClose then
            pcall(opts.onClose)
        end
        if tutorialWasRunning and Tutorial.isRunning() then
            Tutorial.setChromeVisible(true)
        end
    end

    handle.close = function() doClose() end

    -- Расчёт состояний карточек 1..7.
    --   Day N < nextDay → past (✓).
    --   Day == nextDay → current (pulse).
    --   Day > nextDay → future.
    local nextDay = math.clamp(math.floor(opts.nextDay or 1), 1, 7)
    local function stateForDay(day: number): "past" | "current" | "future"
        if day < nextDay then return "past" end
        if day == nextDay then return "current" end
        return "future"
    end

    -- Сетка 4×2 как на десктопе; на phone размер карточек от ширины экрана.
    local layoutEpoch = s:Value(0)
    ViewportLayout.subscribe(function()
        layoutEpoch:set(peek(layoutEpoch) + 1)
    end, s)
    local layout = s:Computed(function(use)
        use(layoutEpoch)
        return computeDailyLayout()
    end)

    local fitScale = s:Computed(function(use)
        use(layoutEpoch)
        local L = use(layout)
        local deskMax = if ViewportLayout.tier() == "desktop" then 1.7 else 1.0
        return ViewportLayout.fitModalScale(L.modalW, L.modalH, deskMax)
    end)
    local modalSize = s:Computed(function(use)
        local L = use(layout)
        local k = use(fitScale)
        return UDim2.fromOffset(math.floor(L.modalW * k + 0.5), math.floor(L.modalH * k + 0.5))
    end)
    local modalPos = s:Computed(function(use)
        local L = use(layout)
        local k = use(fitScale)
        return UDim2.new(0.5, 0, 0, ViewportLayout.modalCenterY(math.floor(L.modalH * k + 0.5)))
    end)

    backdrop = s:New("Frame")({
        Name = "Backdrop",
        Size = UiScreen.backdropSize(),
        Position = UiScreen.backdropPosition(),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = gui,
        Active = true,
        ZIndex = 1,
        [Children] = {
            s:New("TextButton")({
                -- Backdrop клик закрывает (как RebirthConfirmModal).
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                [OnEvent("Activated")] = doClose,
            }),
            s:New("Frame")({
                Name = "Modal",
                Size = modalSize,
                Position = modalPos,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = C.panelBg,
                BorderSizePixel = 0,
                Active = true,
                ClipsDescendants = false,
                ZIndex = 2,
                [Children] = {
                    s:New("UICorner")({ CornerRadius = UDim.new(0, 14) }),
                    s:New("UIStroke")({ Color = C.gold, Thickness = 2, Transparency = 0.1 }),
                    s:New("Frame")({
                    Name = "Content",
                    Size = s:Computed(function(use)
                        local L = use(layout)
                        return UDim2.fromOffset(L.modalW, L.modalH)
                    end),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    [Children] = {
                    s:New("UIScale")({ Scale = fitScale }),
                    UiIcon.titleRow(s, {
                        source = "icon_gift",
                        text = L("modal.daily.title"),
                        textSize = s:Computed(function(use)
                            return use(layout).titleText
                        end),
                        font = Enum.Font.GothamBlack,
                        textColor = C.gold,
                        size = s:Computed(function(use)
                            local pad = use(layout).padding
                            return UDim2.new(1, -pad * 2, 0, 28)
                        end),
                        position = s:Computed(function(use)
                            local pad = use(layout).padding
                            return UDim2.new(0, pad, 0, pad)
                        end),
                        iconSize = 24,
                        zIndex = 5,
                    }),
                    s:New("Frame")({
                        Size = s:Computed(function(use)
                            local pad = use(layout).padding
                            return UDim2.new(1, -pad * 2, 0, 18)
                        end),
                        Position = s:Computed(function(use)
                            local L = use(layout)
                            return UDim2.new(0, L.padding, 0, L.padding + 32)
                        end),
                        BackgroundTransparency = 1,
                        ZIndex = 5,
                        [Children] = {
                            UiIcon.create(s, {
                                source = "icon_streak",
                                size = UDim2.fromOffset(16, 16),
                                position = UDim2.new(0, 0, 0.5, -8),
                                zIndex = 5,
                            }),
                            s:New("TextLabel")({
                                Size = UDim2.new(1, -22, 1, 0),
                                Position = UDim2.new(0, 22, 0, 0),
                                BackgroundTransparency = 1,
                                Text = L("modal.daily.streakInfo", { streak = opts.streak or 0, day = nextDay }),
                                TextSize = s:Computed(function(use)
                                    return use(layout).streakText
                                end),
                                Font = Enum.Font.GothamBold,
                                TextColor3 = C.textLabel,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 5,
                            }),
                        },
                    }),
                    s:New("Frame")({
                        Name = "Grid",
                        Size = s:Computed(function(use)
                            local L = use(layout)
                            return UDim2.fromOffset(L.gridW, L.gridH)
                        end),
                        Position = s:Computed(function(use)
                            local L = use(layout)
                            return UDim2.new(0.5, -L.gridW / 2, 0, L.padding + L.headerH)
                        end),
                        BackgroundTransparency = 1,
                        ClipsDescendants = false,
                        ZIndex = 2,
                        [Children] = {
                            s:New("UIGridLayout")({
                                CellSize = s:Computed(function(use)
                                    local L = use(layout)
                                    return UDim2.fromOffset(L.cardW, L.cardH)
                                end),
                                CellPadding = s:Computed(function(use)
                                    local L = use(layout)
                                    return UDim2.fromOffset(L.gap, L.gap)
                                end),
                                FillDirection = Enum.FillDirection.Horizontal,
                                StartCorner = Enum.StartCorner.TopLeft,
                                FillDirectionMaxCells = DAILY_COLS,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                            }),
                            s:Computed(function(use)
                                local L = use(layout)
                                local cards: { any } = {}
                                for day = 1, 7 do
                                    table.insert(cards, DailyCard.create(s, {
                                        cycleDay = day,
                                        state = stateForDay(day),
                                        layoutOrder = day,
                                        width = L.cardW,
                                        height = L.cardH,
                                    }))
                                end
                                return cards
                            end),
                        },
                    }),
                    s:New("TextButton")({
                        Name = "LaterButton",
                        Size = s:Computed(function(use)
                            local L = use(layout)
                            return UDim2.fromOffset(L.laterW, L.footerBtnH)
                        end),
                        Position = s:Computed(function(use)
                            local L = use(layout)
                            return UDim2.new(0, L.padding, 1, -L.padding - L.footerBtnH)
                        end),
                        ZIndex = 5,
                        BackgroundColor3 = s:Computed(function(use)
                            return use(hoveredLater) and C.btnHover or C.btnBg
                        end),
                        BorderSizePixel = 0,
                        Text = L("modal.daily.later"),
                        TextSize = 14,
                        Font = Enum.Font.GothamBold,
                        TextColor3 = C.textMain,
                        AutoButtonColor = false,
                        [Children] = {
                            s:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
                            s:New("UIStroke")({ Color = C.btnBorder, Thickness = 1.5, Transparency = 0.4 }),
                        },
                        [OnEvent("MouseEnter")] = function() hoveredLater:set(true) end,
                        [OnEvent("MouseLeave")] = function() hoveredLater:set(false) end,
                        [OnEvent("Activated")] = doClose,
                    }),
                    s:New("TextButton")({
                        Name = "ClaimButton",
                        Size = s:Computed(function(use)
                            local L = use(layout)
                            return UDim2.fromOffset(L.claimW, L.footerBtnH)
                        end),
                        Position = s:Computed(function(use)
                            local L = use(layout)
                            return UDim2.new(1, -L.padding - L.claimW, 1, -L.padding - L.footerBtnH)
                        end),
                        ZIndex = 5,
                        BackgroundColor3 = s:Computed(function(use)
                            if not use(enabled) then return C.btnDisabled end
                            return use(hoveredClaim) and Color3.fromRGB(220, 180, 30) or C.gold
                        end),
                        BorderSizePixel = 0,
                        Text = s:Computed(function(use)
                            if not use(enabled) then return "..." end
                            return L("modal.daily.claim")
                        end),
                        TextSize = 17,
                        Font = Enum.Font.GothamBlack,
                        TextColor3 = s:Computed(function(use)
                            return if use(enabled) then Color3.fromRGB(40, 25, 0) else C.textMuted
                        end),
                        AutoButtonColor = false,
                        [Children] = {
                            s:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
                            s:New("UIStroke")({
                                Color = s:Computed(function(use)
                                    return use(enabled) and Color3.fromRGB(255, 240, 150) or C.btnBorder
                                end),
                                Thickness = 2,
                                Transparency = 0.2,
                            }),
                            UiIcon.create(s, {
                                source = "icon_gift",
                                size = UDim2.fromOffset(18, 18),
                                position = UDim2.new(0, 14, 0.5, -9),
                                zIndex = 6,
                                visible = enabled,
                            }),
                        },
                        [OnEvent("MouseEnter")] = function() hoveredClaim:set(true) end,
                        [OnEvent("MouseLeave")] = function() hoveredClaim:set(false) end,
                        [OnEvent("Activated")] = function()
                            if handle._closed then return end
                            if not peek(enabled) then return end
                            -- Disable повторных нажатий пока идёт claim.
                            enabled:set(false)

                            task.spawn(function()
                                local ok, result = pcall(function()
                                    return Net:Invoke("ClaimDaily")
                                end)
                                if not ok or typeof(result) ~= "table" or not result.success then
                                    -- Сетевая ошибка или сервер отказал.
                                    local msg = ServerMessage.fromResult(result, "modal.daily.claimFailed")
                                    SoundManager.play("buy_fail")
                                    Notification.show({
                                        text = msg,
                                        icon = "icon_warning",
                                        color = Color3.fromRGB(255, 140, 60),
                                        duration = 3,
                                    })
                                    doClose()
                                    return
                                end
                                -- Success: SoundManager.play — переиспользуем
                                -- sell_success как daily_claim placeholder
                                -- (отдельный sound TODO playtest).
                                --
                                -- RewardFX.burst НЕ дёргаем здесь — сервер
                                -- шлёт Notify kind="daily_reward" с rarity,
                                -- и client-side handler в init.client.lua
                                -- запускает FX ровно один раз. Так избегаем
                                -- двойного coin-rain'a.
                                SoundManager.play("sell_success")
                                -- Закрываем через 0.8с — даём времени
                                -- coin-rain'у проиграться частично, но
                                -- модал не торчит весь FX.
                                task.delay(0.8, function()
                                    doClose()
                                end)
                            end)
                        end,
                    }),
                    },
                    }),
                },
            }),
        },
    })

    backdrop.BackgroundTransparency = 1
    TweenService:Create(backdrop, TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 0.45,
    }):Play()

    -- Pulse на текущей карточке (Fusion кладёт карточки внутрь Computed — ищем рекурсивно).
    task.defer(function()
        if handle._closed or not backdrop.Parent then
            return
        end
        local modal = backdrop:FindFirstChild("Modal")
        local grid = modal and modal:FindFirstChild("Grid", true)
        local card = grid and grid:FindFirstChild("DailyCard_" .. tostring(nextDay), true)
        if card then
            local stroke = card:FindFirstChild("MainStroke")
            if stroke and stroke:IsA("UIStroke") then
                stopPulse = DailyCard.startPulse(stroke)
            end
            card.ZIndex = 10
        end
    end)

    -- Anti-misclick: 0.4с задержка перед [ЗАБРАТЬ].
    task.delay(ANTI_MISCLICK_DELAY, function()
        if not handle._closed then
            enabled:set(true)
        end
    end)

    -- ESC.
    escConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            doClose()
        end
    end)

    return handle :: Handle
end

--[[
    Удобный helper: показывает модал если canClaim true.
    Используется из init.client.lua при получении PlayerStats и Notify.
]]
function DailyRewardModal.showIfClaimable(scope: any, dailyState: any)
    if not dailyState or not dailyState.canClaim then
        return nil
    end
    return DailyRewardModal.show({
        scope = scope,
        streak = dailyState.currentStreak or 0,
        nextDay = dailyState.nextDay or 1,
    })
end

function DailyRewardModal.isOpen(): boolean
    return _activeHandle ~= nil and not _activeHandle._closed
end

return DailyRewardModal
