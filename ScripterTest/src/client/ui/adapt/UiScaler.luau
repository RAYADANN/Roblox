--!strict
-- Viewport → scale factor for a 1920×1080 design canvas.

local Workspace = game:GetService("Workspace")

export type Config = {
	reference: Vector2?,
	minScale: number?,
	maxScale: number?,
	fit: boolean?,
	-- Multiply scale on small screens (phones). 1.5 = 50% larger UI.
	mobileBoost: number?,
	-- Treat as phone when shortest viewport axis is below this (px).
	mobileBelow: number?,
}

local DEFAULT_REF = Vector2.new(1920, 1080)
local DEFAULT_MIN = 0.45
local DEFAULT_MAX = 1.2
local DEFAULT_MOBILE_BOOST = 1
local DEFAULT_MOBILE_BELOW = 900

local function resolve(config: Config?): (Vector2, number, number, boolean, number, number)
	local c = config or {}
	return c.reference or DEFAULT_REF,
		c.minScale or DEFAULT_MIN,
		c.maxScale or DEFAULT_MAX,
		if c.fit == nil then true else c.fit,
		c.mobileBoost or DEFAULT_MOBILE_BOOST,
		c.mobileBelow or DEFAULT_MOBILE_BELOW
end

local function computeScale(viewport: Vector2, config: Config?): number
	local ref, minS, maxS, fit, mobileBoost, mobileBelow = resolve(config)
	if viewport.X <= 1 or viewport.Y <= 1 then
		return 1
	end
	local sx = viewport.X / ref.X
	local sy = viewport.Y / ref.Y
	local raw = if fit then math.min(sx, sy) else sx

	local shortest = math.min(viewport.X, viewport.Y)
	if shortest < mobileBelow and mobileBoost ~= 1 then
		raw *= mobileBoost
	end

	return math.clamp(raw, minS, maxS)
end

local function getViewport(): Vector2
	local cam = Workspace.CurrentCamera
	if cam == nil then
		return DEFAULT_REF
	end
	return cam.ViewportSize
end

local UiScaler = {}

UiScaler.DEFAULT_REF = DEFAULT_REF

function UiScaler.getReference(config: Config?): Vector2
	local ref = resolve(config)
	return ref
end

function UiScaler.compute(config: Config?): number
	return computeScale(getViewport(), config)
end

function UiScaler.listen(config: Config?, onChange: (number) -> ()): () -> ()
	local camConn: RBXScriptConnection? = nil

	local function attachCam()
		if camConn then
			camConn:Disconnect()
			camConn = nil
		end
		local cam = Workspace.CurrentCamera
		if cam == nil then
			return
		end
		camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			onChange(computeScale(cam.ViewportSize, config))
		end)
		onChange(computeScale(cam.ViewportSize, config))
	end

	local workspaceConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(attachCam)
	attachCam()

	return function()
		workspaceConn:Disconnect()
		if camConn then
			camConn:Disconnect()
		end
	end
end

return UiScaler
