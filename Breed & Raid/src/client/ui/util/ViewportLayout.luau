--!strict

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SafeArea = require(script.Parent.SafeArea)

export type Tier = "phone" | "tablet" | "desktop"

export type Metrics = {
	tier: Tier,
	uiScale: number,
	safeTop: number,
	safeLeft: number,
	safeRight: number,
	safeBottom: number,
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
local _currentCameraConn: RBXScriptConnection? = nil
local _safeCleanup: (() -> ())? = nil
local _started = false

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
	if shortSide < 420 or vp.X < 520 then
		return "phone"
	elseif shortSide < 580 or vp.X < 900 then
		return "tablet"
	end
	return "desktop"
end

function ViewportLayout.uiScale(): number
	local tier = ViewportLayout.tier()
	local cfg = TIER_SCALE[tier]
	local vp = ViewportLayout.getSize()
	local uniform = math.min(math.max(160, vp.X) / REF_W, math.max(160, vp.Y) / REF_H)
	return math.clamp(uniform * cfg.mult, cfg.min, cfg.max)
end

function ViewportLayout.uniformScale(): number
	local vp = ViewportLayout.getSize()
	return math.min(math.max(160, vp.X) / REF_W, math.max(160, vp.Y) / REF_H)
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
	local safeLeft, safeTop, safeRight, safeBottom = SafeArea.insets()
	local availableW = math.max(1, vp.X - safeLeft - safeRight)
	local availableH = math.max(1, vp.Y - safeTop - safeBottom)
	local baseScale = ViewportLayout.uiScale()
	return math.min((availableW * wFrac) / (designW * baseScale), (availableH * hFrac) / (designH * baseScale), 1)
end

function ViewportLayout.getMetrics(): Metrics
	local tier = ViewportLayout.tier()
	local safeLeft, safeTop, safeRight, safeBottom = SafeArea.insets()
	return {
		tier = tier,
		uiScale = ViewportLayout.uiScale(),
		safeTop = safeTop,
		safeLeft = safeLeft,
		safeRight = safeRight,
		safeBottom = safeBottom,
		viewport = ViewportLayout.getSize(),
		px = ViewportLayout.px,
		text = ViewportLayout.text,
		gap = ViewportLayout.gap,
		touch = ViewportLayout.touch,
		modalFitScale = ViewportLayout.modalFitScale,
		modalSizeFrac = ViewportLayout.modalSizeFrac,
		isPhone = tier == "phone",
		isTouch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled,
	}
end

function ViewportLayout.start()
	if _started then
		return
	end
	_started = true
	local function onResize()
		for _, listener in _listeners do
			listener()
		end
	end
	local function bindCamera()
		if _cameraConn then
			_cameraConn:Disconnect()
			_cameraConn = nil
		end
		local camera = getCamera()
		if camera then
			_cameraConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(onResize)
		end
	end
	bindCamera()
	_currentCameraConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		bindCamera()
		onResize()
	end)
	_safeCleanup = SafeArea.subscribe(onResize)
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
