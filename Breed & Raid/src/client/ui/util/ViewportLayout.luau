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
	viewport: Vector2,
	px: (design: number) -> number,
	text: (design: number, minPx: number?) -> number,
	gap: (design: number) -> number,
	touch: (design: number) -> number,
	isPhone: boolean,
	isTouch: boolean,
}

local REF_W = 1280
local REF_H = 720
local MIN_TEXT = 12

local TIER_SCALE: { [Tier]: { mult: number, min: number, max: number } } = {
	phone = { mult = 1.28, min = 0.86, max = 1.06 },
	tablet = { mult = 1.10, min = 0.84, max = 1.10 },
	desktop = { mult = 0.95, min = 1.0, max = 1.25 },
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

function ViewportLayout.px(design: number): number
	return math.max(1, math.floor(design * ViewportLayout.uiScale() + 0.5))
end

function ViewportLayout.text(design: number, minPx: number?): number
	return math.max(minPx or MIN_TEXT, ViewportLayout.px(design))
end

function ViewportLayout.gap(design: number): number
	return ViewportLayout.px(design)
end

-- Hit target: at least 44 screen px (canon); design still scales.
function ViewportLayout.touch(design: number): number
	return math.max(44, ViewportLayout.px(design))
end

function ViewportLayout.getMetrics(): Metrics
	local tier = ViewportLayout.tier()
	return {
		tier = tier,
		uiScale = ViewportLayout.uiScale(),
		safeTop = SafeArea.topInset(),
		safeLeft = SafeArea.leftInset(),
		viewport = ViewportLayout.getSize(),
		px = ViewportLayout.px,
		text = ViewportLayout.text,
		gap = ViewportLayout.gap,
		touch = ViewportLayout.touch,
		isPhone = tier == "phone",
		isTouch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled,
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
