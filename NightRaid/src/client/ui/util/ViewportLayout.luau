--!strict
-- Единый адаптивный слой: design space 1280×720 → screen px.
-- Компоненты НЕ ветвятся по tier для размеров — только для структуры (show/hide).

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SafeArea = require(script.Parent.SafeArea)

export type Tier = "phone" | "tablet" | "desktop"

export type Metrics = {
	tier: Tier,
	uiScale: number,
	safeTop: number,
	safeLeft: number,
	viewport: Vector2,
	px: (design: number) -> number,
	text: (design: number, minPx: number?) -> number,
	gap: (design: number) -> number,
	touch: (design: number) -> number,
	modalFitScale: (designW: number, designH: number) -> number,
	modalSizeFrac: () -> (number, number),
	isPhone: boolean,
	isTouch: boolean,
}

local REF_W = 1280
local REF_H = 720
local MIN_TEXT = 12
local MIN_TOUCH = 44

local PHONE_MAX = 520
local TABLET_MAX = 900

-- Один набор клампов на тир — без отдельных text/chrome/dock множителей.
local TIER_SCALE: { [Tier]: { mult: number, min: number, max: number } } = {
	phone = { mult = 1.28, min = 0.86, max = 1.06 },
	tablet = { mult = 1.10, min = 0.84, max = 1.10 },
	desktop = { mult = 0.95, min = 1.0, max = 1.25 },
}

local MODAL_W_FRAC: { [Tier]: number } = {
	phone = 0.92,
	tablet = 0.76,
	desktop = 0.52,
}
local MODAL_H_FRAC: { [Tier]: number } = {
	phone = 0.88,
	tablet = 0.84,
	desktop = 0.80,
}

local ViewportLayout = {}

local _listeners: { () -> () } = {}
local _cameraConn: RBXScriptConnection? = nil

local function getCamera(): Camera?
	return Workspace.CurrentCamera
end

function ViewportLayout.getSize(): Vector2
	local camera = getCamera()
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(REF_W, REF_H)
end

function ViewportLayout.tier(): Tier
	local vp = ViewportLayout.getSize()
	local shortSide = math.min(vp.X, vp.Y)
	if shortSide < 420 or vp.X < PHONE_MAX then
		return "phone"
	elseif shortSide < 580 or vp.X < TABLET_MAX then
		return "tablet"
	end
	return "desktop"
end

function ViewportLayout.uniformScale(): number
	local vp = ViewportLayout.getSize()
	local w = math.max(160, vp.X)
	local h = math.max(160, vp.Y)
	return math.min(w / REF_W, h / REF_H)
end

function ViewportLayout.uiScale(): number
	local tier = ViewportLayout.tier()
	local cfg = TIER_SCALE[tier]
	local uniform = ViewportLayout.uniformScale()
	return math.clamp(uniform * cfg.mult, cfg.min, cfg.max)
end

function ViewportLayout.px(design: number): number
	return math.max(1, math.floor(design * ViewportLayout.uiScale() + 0.5))
end

function ViewportLayout.text(design: number, minPx: number?): number
	return math.max(minPx or MIN_TEXT, ViewportLayout.px(design))
end

function ViewportLayout.gap(design: number): number
	return ViewportLayout.px(design)
end

function ViewportLayout.touch(design: number): number
	local scaled = ViewportLayout.px(design)
	if ViewportLayout.tier() == "phone" then
		return math.max(MIN_TOUCH, scaled)
	end
	return scaled
end

function ViewportLayout.modalSizeFrac(): (number, number)
	local tier = ViewportLayout.tier()
	return MODAL_W_FRAC[tier], MODAL_H_FRAC[tier]
end

function ViewportLayout.modalFitScale(designW: number, designH: number): number
	local vp = ViewportLayout.getSize()
	local wFrac, hFrac = ViewportLayout.modalSizeFrac()
	local maxW = vp.X * wFrac
	local maxH = vp.Y * hFrac
	return math.min(maxW / designW, maxH / designH, 1)
end

function ViewportLayout.isTouchPrimary(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

function ViewportLayout.getMetrics(): Metrics
	local tier = ViewportLayout.tier()
	local scale = ViewportLayout.uiScale()
	local vp = ViewportLayout.getSize()

	return {
		tier = tier,
		uiScale = scale,
		safeTop = SafeArea.topInset(),
		safeLeft = SafeArea.leftInset(),
		viewport = vp,
		px = ViewportLayout.px,
		text = ViewportLayout.text,
		gap = ViewportLayout.gap,
		touch = ViewportLayout.touch,
		modalFitScale = ViewportLayout.modalFitScale,
		modalSizeFrac = ViewportLayout.modalSizeFrac,
		isPhone = tier == "phone",
		isTouch = ViewportLayout.isTouchPrimary(),
	}
end

function ViewportLayout.start()
	if _cameraConn then
		return
	end
	local function onResize()
		for _, listener in _listeners do
			listener()
		end
	end
	local camera = getCamera()
	if camera then
		_cameraConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(onResize)
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if _cameraConn then
			_cameraConn:Disconnect()
			_cameraConn = nil
		end
		ViewportLayout.start()
		onResize()
	end)
	SafeArea.subscribe(onResize)
end

function ViewportLayout.subscribe(listener: () -> ()): () -> ()
	table.insert(_listeners, listener)
	ViewportLayout.start()
	return function()
		local index = table.find(_listeners, listener)
		if index then
			table.remove(_listeners, index)
		end
	end
end

return ViewportLayout
