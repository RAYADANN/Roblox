--!strict
-- LoadingScreen.lua — профессиональный загрузочный/сплэш-экран.
--
-- Показывается на старте клиента, пока не готов HUD и не пришли первые
-- PlayerStats с сервера. Минимум MIN_VISIBLE сек (даже если всё быстро),
-- кнопка «Пропустить» — после SKIP_AFTER сек. Жёсткий потолок MAX_VISIBLE.
--
-- API:
--   LoadingScreen.show()         -- идемпотентно
--   LoadingScreen.notifyReady()  -- данные/HUD готовы → скрыть после MIN (3–5с FTUE)
--   LoadingScreen.skip()         -- досрочно (не раньше SKIP_AFTER)
--   LoadingScreen.hide()         -- немедленный fade-out
--   LoadingScreen.isVisible()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local shared = ReplicatedStorage:WaitForChild("shared")
local UiAssets = require(shared.data.UiAssets)
local L = require(shared.loc.Localization).t
local ViewportLayout = require(script.Parent.util.ViewportLayout)
local UiScreen = require(script.Parent.util.UiScreen)
local theme = require(script.Parent.hud.theme)

local C = theme.C
local FONT = theme.FONT

local GUI_NAME = "DeepDigger_LoadingScreen"
local FADE_OUT = 0.5
local TIP_INTERVAL = 4.0
local TIP_FADE = 0.4
local MIN_VISIBLE_DEFAULT = 5
local MIN_VISIBLE_FTUE = 3
local SKIP_AFTER = 3
local MAX_VISIBLE = 15

local _minVisible = MIN_VISIBLE_DEFAULT

-- Подсказки геймплея. Цикл каждые ~4 сек с fade. Покрывают все системы игры,
-- чтобы новичок за время загрузки узнал базовые механики. Резолвим лениво
-- через L() — текст берётся под язык сессии.
local TIP_KEYS: { string } = {
	"loading.tip.1",
	"loading.tip.2",
	"loading.tip.3",
	"loading.tip.4",
	"loading.tip.5",
	"loading.tip.6",
	"loading.tip.7",
	"loading.tip.8",
}

local function tipText(index: number): string
	return L(TIP_KEYS[index])
end

export type State = {
	gui: ScreenGui,
	root: CanvasGroup,
	title: TextLabel,
	tipLabel: TextLabel,
	spinner: ImageLabel,
	track: Frame,
	fill: Frame,
	skipButton: TextButton,
	alive: boolean,
	tipIndex: number,
	unsubscribe: (() -> ())?,
	spinTween: Tween?,
	fillTween: Tween?,
	hideScheduled: boolean?,
}

local LoadingScreen = {}

local _state: State? = nil
local _shownAt = 0
local _readyNotified = false
local _hideTask: thread? = nil
local _maxTask: thread? = nil
local _skipTask: thread? = nil

local function pgui(): PlayerGui?
	local plr = Players.LocalPlayer
	if not plr then
		return nil
	end
	return plr:FindFirstChildOfClass("PlayerGui") or plr:WaitForChild("PlayerGui", 5) :: PlayerGui?
end

-- Пересчёт всех размеров/позиций под текущий тир (phone/tablet/desktop).
local function applyLayout(s: State)
	local phone = ViewportLayout.isPhone()

	local titleSize = ViewportLayout.textPx(if phone then 44 else 56)
	s.title.TextSize = titleSize

	-- Подзаголовок/подсказка — это полноценные предложения, поэтому используем
	-- px() без десктопного ×2 текст-множителя (он для мелких HUD-подписей),
	-- иначе строки не влезают и обрезаются.
	local subtitle = s.root:FindFirstChild("Subtitle")
	if subtitle and subtitle:IsA("TextLabel") then
		subtitle.TextSize = ViewportLayout.px(if phone then 15 else 20)
	end

	local spinnerPx = ViewportLayout.px(if phone then 46 else 60)
	s.spinner.Size = UDim2.fromOffset(spinnerPx, spinnerPx)

	local trackW = ViewportLayout.px(if phone then 220 else 320)
	local trackH = ViewportLayout.px(if phone then 7 else 9)
	s.track.Size = UDim2.fromOffset(trackW, trackH)

	s.tipLabel.TextSize = ViewportLayout.px(if phone then 15 else 20)
	local tipW = math.min(ViewportLayout.playableWidth() - ViewportLayout.px(40), ViewportLayout.px(820))
	s.tipLabel.Size = UDim2.new(0, tipW, 0, ViewportLayout.px(if phone then 56 else 64))

	local skipH = ViewportLayout.px(if phone then 34 else 40)
	local skipW = ViewportLayout.px(if phone then 120 else 140)
	s.skipButton.Size = UDim2.fromOffset(skipW, skipH)
	s.skipButton.TextSize = ViewportLayout.px(if phone then 14 else 16)
end

local function cancelHideTask()
	if _hideTask then
		task.cancel(_hideTask)
		_hideTask = nil
	end
end

local function scheduleHideAfterMinDelay()
	cancelHideTask()
	if not _state or not _state.alive then
		return
	end
	local elapsed = os.clock() - _shownAt
	local wait = math.max(0, _minVisible - elapsed)
	if wait <= 0 then
		LoadingScreen.hide()
		return
	end
	_hideTask = task.delay(wait, function()
		_hideTask = nil
		if _state and _state.alive and _readyNotified then
			LoadingScreen.hide()
		end
	end)
end

local function buildTip(s: State)
	s.tipIndex = ((s.tipIndex) % #TIP_KEYS) + 1
	local text = tipText(s.tipIndex)
	local label = s.tipLabel

	-- fade out → сменить текст → fade in.
	local fadeOut = TweenService:Create(label, TweenInfo.new(TIP_FADE, Enum.EasingStyle.Quad), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	fadeOut:Play()
	fadeOut.Completed:Once(function()
		if not s.alive then
			return
		end
		label.Text = text
		TweenService:Create(label, TweenInfo.new(TIP_FADE, Enum.EasingStyle.Quad), {
			TextTransparency = 0,
			TextStrokeTransparency = 0.4,
		}):Play()
	end)
end

local function startAnimations(s: State)
	-- Спиннер: бесконечное вращение (искра-самоцвет крутится).
	s.spinTween = TweenService:Create(
		s.spinner,
		TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
		{ Rotation = 360 }
	)
	s.spinTween:Play()

	-- Индикатор загрузки: сегмент бежит слева направо по кругу (indeterminate).
	s.fill.Position = UDim2.fromScale(-0.4, 0)
	s.fillTween = TweenService:Create(
		s.fill,
		TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false),
		{ Position = UDim2.fromScale(1.0, 0) }
	)
	s.fillTween:Play()

	-- Цикл подсказок.
	task.spawn(function()
		while s.alive do
			task.wait(TIP_INTERVAL)
			if not s.alive then
				break
			end
			buildTip(s)
		end
	end)
end

local function build(s: State)
	local root = s.root

	local bg = Instance.new("ImageLabel")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = C.bg1
	bg.BackgroundTransparency = 0
	bg.BorderSizePixel = 0
	bg.Image = UiAssets.image("loading_bg")
	bg.ScaleType = Enum.ScaleType.Crop
	bg.Parent = root

	-- Затемняющий градиент снизу для читаемости подсказок/индикатора.
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = C.backdrop
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.Parent = root

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.85),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	grad.Parent = overlay

	-- Заголовок игры.
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.36)
	title.Size = UDim2.new(1, -40, 0, 70)
	title.BackgroundTransparency = 1
	title.Text = "DEEP DIGGER"
	title.Font = FONT.title
	title.TextColor3 = C.gold
	title.TextStrokeColor3 = C.outlineDark
	title.TextStrokeTransparency = 0.4
	title.TextScaled = false
	title.Parent = root
	s.title = title

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.Position = UDim2.fromScale(0.5, 0.44)
	subtitle.Size = UDim2.new(1, -40, 0, 28)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = L("loading.subtitle")
	subtitle.Font = FONT.label
	subtitle.TextColor3 = C.textSub
	subtitle.TextStrokeColor3 = C.outlineDark
	subtitle.TextStrokeTransparency = 0.5
	subtitle.Parent = root

	-- Спиннер (вращающаяся искра-самоцвет).
	local spinner = Instance.new("ImageLabel")
	spinner.Name = "Spinner"
	spinner.AnchorPoint = Vector2.new(0.5, 0.5)
	spinner.Position = UDim2.fromScale(0.5, 0.60)
	spinner.Size = UDim2.fromOffset(56, 56)
	spinner.BackgroundTransparency = 1
	spinner.Image = UiAssets.image("icon_sparkle")
	spinner.ImageColor3 = C.goldHi
	spinner.ScaleType = Enum.ScaleType.Fit
	spinner.Parent = root
	s.spinner = spinner

	-- Индикатор загрузки (indeterminate bar).
	local track = Instance.new("Frame")
	track.Name = "ProgressTrack"
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.fromScale(0.5, 0.70)
	track.Size = UDim2.fromOffset(320, 9)
	track.BackgroundColor3 = C.depthBg
	track.BackgroundTransparency = 0.25
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.Parent = root
	s.track = track

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0.4, 1)
	fill.Position = UDim2.fromScale(-0.4, 0)
	fill.BackgroundColor3 = C.gold
	fill.BorderSizePixel = 0
	fill.Parent = track
	s.fill = fill

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local fillGrad = Instance.new("UIGradient")
	fillGrad.Color = ColorSequence.new(C.gold, C.goldHi)
	fillGrad.Parent = fill

	-- Подсказка внизу экрана.
	local tip = Instance.new("TextLabel")
	tip.Name = "Tip"
	tip.AnchorPoint = Vector2.new(0.5, 1)
	tip.Position = UDim2.fromScale(0.5, 0.94)
	tip.Size = UDim2.new(0, 760, 0, 40)
	tip.BackgroundTransparency = 1
	tip.Text = tipText(1)
	tip.Font = FONT.body
	tip.TextColor3 = C.textMain
	tip.TextStrokeColor3 = C.outlineDark
	tip.TextStrokeTransparency = 0.4
	tip.TextWrapped = true
	tip.TextTransparency = 0
	tip.Parent = root
	s.tipLabel = tip

	local skip = Instance.new("TextButton")
	skip.Name = "Skip"
	skip.AnchorPoint = Vector2.new(0.5, 0.5)
	skip.Position = UDim2.fromScale(0.5, 0.78)
	skip.Size = UDim2.fromOffset(140, 40)
	skip.BackgroundColor3 = C.btnBg
	skip.BackgroundTransparency = 0.15
	skip.BorderSizePixel = 0
	skip.AutoButtonColor = true
	skip.Font = FONT.label
	skip.Text = L("loading.skip")
	skip.TextColor3 = C.textSub
	skip.Visible = false
	skip.Parent = root
	s.skipButton = skip

	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, ViewportLayout.px(8))
	skipCorner.Parent = skip

	local skipStroke = Instance.new("UIStroke")
	skipStroke.Color = C.dockBorder
	skipStroke.Thickness = 1
	skipStroke.Transparency = 0.5
	skipStroke.Parent = skip

	skip.Activated:Connect(function()
		LoadingScreen.skip()
	end)
end

function LoadingScreen.setMinVisible(seconds: number): ()
	_minVisible = math.max(0, seconds)
end

function LoadingScreen.minVisibleForTutorial(tutorialStep: number): ()
	_minVisible = if tutorialStep < 3 then MIN_VISIBLE_FTUE else MIN_VISIBLE_DEFAULT
end

function LoadingScreen.show(): ()
	if _state and _state.alive then
		return
	end
	_minVisible = MIN_VISIBLE_DEFAULT
	cancelHideTask()
	if _maxTask then
		task.cancel(_maxTask)
		_maxTask = nil
	end
	if _skipTask then
		task.cancel(_skipTask)
		_skipTask = nil
	end
	_readyNotified = false
	_shownAt = os.clock()

	local pg = pgui()
	if not pg then
		return
	end

	local gui = UiScreen.ensure(pg, GUI_NAME, "loading")
	for _, child in ipairs(gui:GetChildren()) do
		child:Destroy()
	end

	local root = Instance.new("CanvasGroup")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = C.bg1
	root.BackgroundTransparency = 0
	root.BorderSizePixel = 0
	root.GroupTransparency = 0
	root.Parent = gui

	local s: State = {
		gui = gui,
		root = root,
		title = nil :: any,
		tipLabel = nil :: any,
		spinner = nil :: any,
		track = nil :: any,
		fill = nil :: any,
		skipButton = nil :: any,
		alive = true,
		tipIndex = 1,
		unsubscribe = nil,
		spinTween = nil,
		fillTween = nil,
	}
	_state = s

	build(s)
	applyLayout(s)
	s.unsubscribe = ViewportLayout.subscribe(function()
		if s.alive then
			applyLayout(s)
		end
	end)
	startAnimations(s)

	_skipTask = task.delay(SKIP_AFTER, function()
		_skipTask = nil
		if _state and _state.alive then
			_state.skipButton.Visible = true
		end
	end)

	_maxTask = task.delay(MAX_VISIBLE, function()
		_maxTask = nil
		if _state and _state.alive then
			LoadingScreen.hide()
		end
	end)
end

function LoadingScreen.notifyReady(): ()
	if _readyNotified then
		return
	end
	_readyNotified = true
	scheduleHideAfterMinDelay()
end

function LoadingScreen.skip(): ()
	if not _state or not _state.alive then
		return
	end
	if os.clock() - _shownAt < SKIP_AFTER then
		return
	end
	cancelHideTask()
	LoadingScreen.hide()
end

function LoadingScreen.hide(): ()
	local s = _state
	if not s or not s.alive then
		return
	end
	s.alive = false
	_state = nil
	cancelHideTask()
	if _maxTask then
		task.cancel(_maxTask)
		_maxTask = nil
	end
	if _skipTask then
		task.cancel(_skipTask)
		_skipTask = nil
	end
	_readyNotified = false

	if s.unsubscribe then
		pcall(s.unsubscribe)
		s.unsubscribe = nil
	end
	if s.spinTween then
		s.spinTween:Cancel()
	end
	if s.fillTween then
		s.fillTween:Cancel()
	end

	local fade = TweenService:Create(s.root, TweenInfo.new(FADE_OUT, Enum.EasingStyle.Quad), {
		GroupTransparency = 1,
	})
	fade:Play()
	fade.Completed:Once(function()
		if s.gui and s.gui.Parent then
			s.gui:Destroy()
		end
	end)
end

function LoadingScreen.isVisible(): boolean
	return _state ~= nil and _state.alive
end

return LoadingScreen
