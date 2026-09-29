--!strict
-- Пропорции HUD: масштаб по ширине И высоте, на phone ÷1.5.

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SafeArea = require(script.Parent.SafeArea)

export type Tier = "phone" | "tablet" | "desktop"
export type DockMetrics = {
	btnW: number,
	shopW: number,
	gap: number,
	groupGap: number,
	padX: number,
	btnH: number,
	dockH: number,
}

export type Cleanup = () -> ()

local PHONE_MAX = 520
local PHONE_SHORT_MAX = 420
local TABLET_MAX = 900
local TABLET_SHORT_MAX = 580
local REF_W = 1280
local REF_H = 720
local SIDE_PAD = 10
local TOP_PAD = 8
local BOTTOM_MARGIN = 8

-- Целевой масштаб UI по тирам. Раньше клампы были занижены (phone 0.62..0.76,
-- desktop max 1.0), из-за чего весь интерфейс выглядел мелким и на телефоне, и
-- на больших мониторах. Делаем UI крупнее: на телефоне относительно больше
-- (крупные тач-цели и читаемый текст), на десктопе — до 1.25× от дизайна.
local PHONE_SCALE_MULT = 1.30
local PHONE_SCALE_MIN = 0.86
local PHONE_SCALE_MAX = 1.06
local TABLET_SCALE_MULT = 1.12
local TABLET_SCALE_MIN = 0.84
local TABLET_SCALE_MAX = 1.10
local DESKTOP_SCALE_MULT = 0.95
local DESKTOP_SCALE_MIN = 1.0
local DESKTOP_SCALE_MAX = 1.25

-- Множитель РАЗМЕРА ТЕКСТА (только текст, не геометрия). На десктопе экран
-- крупный, поэтому подписи умышленно увеличены вдвое для читаемости. На phone и
-- tablet множитель = 1.0 → размеры текста остаются байт-в-байт прежними.
-- Применяется централизованно в PanelScale.text()/tsize() и точечно там, где
-- размер текста считается вручную (sc()/px()/computed/hardcoded).
local DESKTOP_TEXT_MULT = 2.0

-- Множитель ГЕОМЕТРИИ верхнего HUD-хрома (монеты/глубина/рюкзак/бафы) на десктопе.
-- Чипы, иконки и отступы верхнего бара растут ×2 вместе с текстом.
-- На phone/tablet = 1.0 → размеры прежние.
local DESKTOP_CHROME_MULT = 2.0

-- Множитель нижнего дока / навигации (Shop, Inventory, TabBtn, DockIcon) на десктопе.
-- Отдельно от верхнего хрома — владелец хотел увеличить именно панель вкладок.
local DESKTOP_DOCK_MULT = 1.5

local DOCK_DESIGN: DockMetrics = {
	btnW = 52,
	shopW = 66,
	gap = 4,
	groupGap = 8,
	padX = 9,
	btnH = 58,
	dockH = 72,
}

-- Пропорции модалок. Раньше ширина бралась почти максимальной, а высота —
-- меньше, из-за чего окна выглядели низкими «лежачими» прямоугольниками.
-- Делаем уже по ширине и выше по высоте — окна ближе к книжной/квадратной форме.
local MODAL_W_FRAC: { [Tier]: number } = {
	phone = 0.90,
	tablet = 0.74,
	desktop = 0.52,
}
local MODAL_H_FRAC: { [Tier]: number } = {
	phone = 0.88,
	tablet = 0.84,
	desktop = 0.82,
}

local ViewportLayout = {}

local _listeners: { () -> () } = {}
local _cameraConn: RBXScriptConnection? = nil
local _workspaceConn: RBXScriptConnection? = nil

local function getCamera(): Camera?
	return Workspace.CurrentCamera
end

function ViewportLayout.getSize(): Vector2
	local camera = getCamera()
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1280, 720)
end

function ViewportLayout.tier(): Tier
	local vp = ViewportLayout.getSize()
	local shortSide = math.min(vp.X, vp.Y)
	if shortSide < PHONE_SHORT_MAX or vp.X < PHONE_MAX then
		return "phone"
	elseif shortSide < TABLET_SHORT_MAX or vp.X < TABLET_MAX then
		return "tablet"
	end
	return "desktop"
end

function ViewportLayout.isNarrow(): boolean
	return ViewportLayout.tier() ~= "desktop"
end

function ViewportLayout.isPhone(): boolean
	return ViewportLayout.tier() == "phone"
end

function ViewportLayout.isTablet(): boolean
	return ViewportLayout.tier() == "tablet"
end

function ViewportLayout.isTouchPrimary(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Реальный touch-устройство ИЛИ Studio device emulator (телефон/планшет).
function ViewportLayout.useMobileTouchMining(): boolean
	if ViewportLayout.isTouchPrimary() then
		return true
	end
	local RunService = game:GetService("RunService")
	if RunService:IsStudio() and UserInputService.TouchEnabled then
		local tier = ViewportLayout.tier()
		return tier == "phone" or tier == "tablet"
	end
	return false
end

-- Левая полоса под виртуальный стик (остальное экран — копание, включая центр).
local MOVE_ZONE_FRAC = 0.24
local MOVE_ZONE_MIN_PX = 72
local MOVE_ZONE_MAX_PX = 132

export type MineRaySpace = "viewport" | "screen"

-- Screen → viewport только для HUD-зон. Луч на touch: ScreenPointToRay(raw Position).
function ViewportLayout.screenToViewport(screenPos: Vector2): Vector2
	local inset = game:GetService("GuiService"):GetGuiInset()
	return Vector2.new(screenPos.X - inset.X, screenPos.Y - inset.Y)
end

function ViewportLayout.mineRayViewportPos(): Vector2
	return UserInputService:GetMouseLocation()
end

function ViewportLayout.moveStickZoneWidth(): number
	local vp = ViewportLayout.getSize()
	local fracW = math.floor(vp.X * MOVE_ZONE_FRAC + 0.5)
	return math.clamp(fracW, MOVE_ZONE_MIN_PX, MOVE_ZONE_MAX_PX)
end

function ViewportLayout.canMineAtViewport(viewportPos: Vector2): boolean
	if not ViewportLayout.useMobileTouchMining() then
		return true
	end
	return viewportPos.X >= ViewportLayout.moveStickZoneWidth()
end

export type HomePillMetrics = {
	w: number,
	h: number,
	gapAboveDock: number,
	textDesign: number,
}

function ViewportLayout.homePillMetrics(): HomePillMetrics
	local tier = ViewportLayout.tier()
	if tier == "phone" then
		return { w = 96, h = 28, gapAboveDock = 2, textDesign = 11 }
	end
	if tier == "tablet" then
		return { w = 118, h = 34, gapAboveDock = 6, textDesign = 12 }
	end
	return { w = 132, h = 38, gapAboveDock = 10, textDesign = 13 }
end

-- min(ширина/REF_W, высота/REF_H) — адаптация по обеим осям.
function ViewportLayout.uniformScale(): number
	local vp = ViewportLayout.getSize()
	local w = math.max(160, vp.X)
	local h = math.max(160, vp.Y)
	return math.min(w / REF_W, h / REF_H)
end

function ViewportLayout.uiScale(): number
	local tier = ViewportLayout.tier()
	local uniform = ViewportLayout.uniformScale()

	if tier == "phone" then
		return math.clamp(uniform * PHONE_SCALE_MULT, PHONE_SCALE_MIN, PHONE_SCALE_MAX)
	elseif tier == "tablet" then
		return math.clamp(uniform * TABLET_SCALE_MULT, TABLET_SCALE_MIN, TABLET_SCALE_MAX)
	end
	return math.clamp(uniform * DESKTOP_SCALE_MULT, DESKTOP_SCALE_MIN, DESKTOP_SCALE_MAX)
end

function ViewportLayout.px(design: number): number
	return math.max(1, math.floor(design * ViewportLayout.uiScale() + 0.5))
end

-- Множитель размера текста для текущего тира: 2.0 на desktop, 1.0 иначе.
-- НЕ трогает px()/геометрию — только там, где вычисляется размер шрифта.
function ViewportLayout.textMult(): number
	if ViewportLayout.tier() == "desktop" then
		return DESKTOP_TEXT_MULT
	end
	return 1.0
end

-- Множитель титула PlayerTag (BillboardGui над головой). Сервер строит
-- канонический desktop-размер (×3 от base TextSize 11); клиент ужимает на
-- phone/tablet, чтобы бейдж не занимал пол-экрана.
local TAG_TITLE_MULT: { [Tier]: number } = {
	phone = 0.5,
	tablet = 0.67,
	desktop = 1.0,
}

function ViewportLayout.tagTitleMult(): number
	return TAG_TITLE_MULT[ViewportLayout.tier()]
end

-- Размер текста из дизайн-пикселей с учётом текстового множителя тира.
-- Без нижнего порога читаемости (для порога используйте PanelScale.text()).
function ViewportLayout.textPx(design: number): number
	return math.max(1, math.floor(ViewportLayout.px(design) * ViewportLayout.textMult() + 0.5))
end

-- Множитель геометрии верхнего HUD-хрома: 2.0 на desktop, 1.0 иначе.
function ViewportLayout.chromeMult(): number
	if ViewportLayout.tier() == "desktop" then
		return DESKTOP_CHROME_MULT
	end
	return 1.0
end

-- Множитель геометрии нижнего дока / навигации: 1.5 на desktop, 1.0 иначе.
function ViewportLayout.dockMult(): number
	if ViewportLayout.tier() == "desktop" then
		return DESKTOP_DOCK_MULT
	end
	return 1.0
end

-- Геометрия хрома в пикселях: дизайн × chromeMult × uiScale. На phone/tablet
-- (chromeMult=1.0) идентична px(design), т.е. поведение неизменно.
function ViewportLayout.chromePx(design: number): number
	return math.max(1, math.floor(design * ViewportLayout.chromeMult() * ViewportLayout.uiScale() + 0.5))
end

function ViewportLayout.topHudScale(): number
	return ViewportLayout.uiScale()
end

function ViewportLayout.sidePad(): number
	return math.max(6, ViewportLayout.px(SIDE_PAD))
end

function ViewportLayout.topHudY(): number
	return math.max(6, SafeArea.topInset() + ViewportLayout.px(TOP_PAD))
end

function ViewportLayout.notificationStackTop(): number
	-- Тосты на полном экране (IgnoreGuiInset): у самого верха, поверх системного UI.
	if ViewportLayout.isPhone() or ViewportLayout.isTouchPrimary() then
		return math.max(4, ViewportLayout.px(4))
	end
	return ViewportLayout.topHudY() + ViewportLayout.px(4)
end

function ViewportLayout.buffBarLeftPad(): number
	return ViewportLayout.sidePad()
end

function ViewportLayout.dockBottomMargin(): number
	if ViewportLayout.isPhone() then
		return math.max(2, ViewportLayout.px(4))
	end
	if ViewportLayout.isTouchPrimary() then
		return ViewportLayout.px(8)
	end
	return ViewportLayout.px(BOTTOM_MARGIN)
end

-- Нижний край дока и баф-бара: одна линия от низа safe-полосы.
function ViewportLayout.dockRowBottom(): number
	return ViewportLayout.dockBottomMargin()
end

function ViewportLayout.playableHeight(): number
	local vp = ViewportLayout.getSize()
	return math.max(160, vp.Y)
end

function ViewportLayout.playableWidth(): number
	local vp = ViewportLayout.getSize()
	return math.max(160, vp.X)
end

function ViewportLayout.modalCenterY(modalH: number): number
	local playH = ViewportLayout.playableHeight()
	local half = modalH * 0.5
	local minCenter = half
	local maxCenter = playH - half
	if minCenter > maxCenter then
		return playH * 0.5
	end
	return math.clamp(playH * 0.5, minCenter, maxCenter)
end

function ViewportLayout.ribbonDimensions(): (number, number)
	return ViewportLayout.px(158), ViewportLayout.px(104)
end

function ViewportLayout.coinChipSize(): (number, number)
	return ViewportLayout.chromePx(168), ViewportLayout.chromePx(46)
end

function ViewportLayout.inventoryChipSize(): (number, number)
	local _, coinH = ViewportLayout.coinChipSize()
	return ViewportLayout.chromePx(118), coinH
end

function ViewportLayout.dockIconPx(): number
	return math.max(14, math.floor(24 * ViewportLayout.dockMult() * ViewportLayout.uiScale() + 0.5))
end

function ViewportLayout.dockLabelPx(): number
	return math.max(7, math.floor(9 * ViewportLayout.dockMult() * ViewportLayout.uiScale() + 0.5))
end

function ViewportLayout.buffSlotPx(): number
	local design = if ViewportLayout.isPhone() then 44 else 54
	local floorPx = if ViewportLayout.isPhone() then 28 else 32
	return math.max(floorPx, ViewportLayout.chromePx(design))
end

function ViewportLayout.topChromeHeight(): number
	local _, coinH = ViewportLayout.coinChipSize()
	local _, invH = ViewportLayout.inventoryChipSize()
	return math.max(coinH, invH) + ViewportLayout.topHudY() + ViewportLayout.px(6)
end

function ViewportLayout.availableWidth(): number
	return math.max(120, ViewportLayout.playableWidth() - ViewportLayout.sidePad() * 2)
end

function ViewportLayout.availableHeight(): number
	return math.max(120, ViewportLayout.playableHeight() - ViewportLayout.bottomChromeInset() - ViewportLayout.topHudY())
end

function ViewportLayout.modalPixels(designW: number, designH: number): (number, number)
	local playW = ViewportLayout.playableWidth()
	local playH = ViewportLayout.playableHeight()
	local tier = ViewportLayout.tier()
	local capW = math.floor(playW * MODAL_W_FRAC[tier] + 0.5)
	local capH = math.floor(playH * MODAL_H_FRAC[tier] + 0.5)
	local aspect = designH / designW

	local targetW = capW
	local targetH = math.min(math.floor(targetW * aspect + 0.5), capH)
	if targetH < capH * 0.82 then
		targetH = capH
		targetW = math.min(math.floor(targetH / aspect + 0.5), capW)
	end

	local minW = if tier == "phone" then math.floor(playW * 0.84 + 0.5) else 320
	local minH = if tier == "phone" then math.floor(playH * 0.78 + 0.5) else 240
	targetW = math.clamp(targetW, minW, capW)
	targetH = math.clamp(targetH, minH, capH)
	return targetW, targetH
end

function ViewportLayout.modalHeaderPixels(baseH: number): number
	local _, modalH = ViewportLayout.modalPixels(600, 450)
	return math.clamp(math.floor(modalH * 0.14 + 0.5), ViewportLayout.px(32), ViewportLayout.px(baseH))
end

-- maxScale по умолчанию 1.0 (окно не увеличиваем сверх дизайна). Десктоп может
-- передать больший потолок, чтобы модалка (и весь её текст) масштабировалась
-- ВВЕРХ в пределах safe-полосы — так десктопный текст становится реально крупнее.
function ViewportLayout.fitModalScale(designW: number, designH: number, maxScale: number?): number
	local w, h = ViewportLayout.modalPixels(designW, designH)
	return math.clamp(math.min(w / designW, h / designH), 0.45, maxScale or 1.0)
end

local function scaleDockField(design: number): number
	return math.max(1, math.floor(design * ViewportLayout.dockMult() * ViewportLayout.uiScale() + 0.5))
end

function ViewportLayout.dockMetrics(): DockMetrics
	return {
		btnW = scaleDockField(DOCK_DESIGN.btnW),
		shopW = scaleDockField(DOCK_DESIGN.shopW),
		gap = scaleDockField(DOCK_DESIGN.gap),
		groupGap = scaleDockField(DOCK_DESIGN.groupGap),
		padX = scaleDockField(DOCK_DESIGN.padX),
		btnH = scaleDockField(DOCK_DESIGN.btnH),
		dockH = scaleDockField(DOCK_DESIGN.dockH),
	}
end

function ViewportLayout.dockWidthForTabs(metrics: DockMetrics, tabs: { { isShop: boolean? } }, shopIndex: number): number
	local function tabWidth(tab: { isShop: boolean? }): number
		return if tab.isShop then metrics.shopW else metrics.btnW
	end

	local x = metrics.padX
	for i = 1, #tabs - 1 do
		x += tabWidth(tabs[i]) + metrics.gap
		if i == shopIndex - 1 or i == shopIndex then
			x += metrics.groupGap
		end
	end
	return x + tabWidth(tabs[#tabs]) + metrics.padX
end

function ViewportLayout.slotX(
	metrics: DockMetrics,
	tabs: { { isShop: boolean? } },
	shopIndex: number,
	index: number
): number
	local function tabWidth(tab: { isShop: boolean? }): number
		return if tab.isShop then metrics.shopW else metrics.btnW
	end

	local x = metrics.padX
	for i = 1, index - 1 do
		x += tabWidth(tabs[i]) + metrics.gap
		if i == shopIndex - 1 or i == shopIndex then
			x += metrics.groupGap
		end
	end
	return x
end

function ViewportLayout.dockPixelSize(designW: number, designH: number): (number, number)
	local availW = ViewportLayout.availableWidth()
	local scale = math.min(1, availW / designW)
	return math.floor(designW * scale + 0.5), math.floor(designH * scale + 0.5)
end

function ViewportLayout.bottomChromeInset(): number
	local metrics = ViewportLayout.dockMetrics()
	local tabs = {
		{}, {}, {}, { isShop = true }, {}, {}, {},
	}
	local designW = ViewportLayout.dockWidthForTabs(metrics, tabs, 4)
	local _, dockH = ViewportLayout.dockPixelSize(designW, metrics.dockH)
	return dockH + ViewportLayout.dockBottomMargin() + ViewportLayout.px(4)
end

function ViewportLayout.questTrackerWidth(): number
	return ViewportLayout.px(168)
end

function ViewportLayout.questTrackerVisible(): boolean
	return not ViewportLayout.isPhone()
end

function ViewportLayout.notificationWidth(): number
	local maxW = math.max(120, ViewportLayout.playableWidth() - ViewportLayout.sidePad() * 2)
	return math.clamp(ViewportLayout.px(360), math.min(200, maxW), maxW)
end

-- Тосты — отдельно от HUD: без desktop textMult (2×), иначе текст не влезает в фикс. высоту.
function ViewportLayout.notificationTextSize(): number
	return math.max(12, ViewportLayout.px(16))
end

function ViewportLayout.notificationMinHeight(): number
	return ViewportLayout.px(52)
end

function ViewportLayout.notificationMaxHeight(): number
	return ViewportLayout.px(112)
end

function ViewportLayout.notificationRowGap(): number
	return ViewportLayout.px(6)
end

function ViewportLayout.notificationSize(): (number, number)
	return ViewportLayout.notificationWidth(), ViewportLayout.notificationMinHeight()
end

function ViewportLayout.notificationRowStep(): number
	local _, minH = ViewportLayout.notificationSize()
	return minH + ViewportLayout.notificationRowGap()
end

local function notifyListeners()
	for _, listener in _listeners do
		listener()
	end
end

local function bindCamera(camera: Camera)
	if _cameraConn then
		_cameraConn:Disconnect()
		_cameraConn = nil
	end
	_cameraConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(notifyListeners)
	notifyListeners()
end

function ViewportLayout.start(): ()
	SafeArea.start()
	if _workspaceConn then
		return
	end
	local camera = getCamera()
	if camera then
		bindCamera(camera)
	end
	_workspaceConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local nextCamera = getCamera()
		if nextCamera then
			bindCamera(nextCamera)
		end
	end)
	SafeArea.subscribe(notifyListeners)
end

function ViewportLayout.subscribe(listener: () -> (), scope: { any }?): Cleanup
	table.insert(_listeners, listener)
	ViewportLayout.start()

	local function cleanup()
		local index = table.find(_listeners, listener)
		if index then
			table.remove(_listeners, index)
		end
	end

	if scope then
		table.insert(scope, cleanup)
	end

	return cleanup
end

return ViewportLayout
