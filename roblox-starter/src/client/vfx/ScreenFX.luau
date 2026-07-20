--!strict
-- Screen FX: flash + optional Blur. Один набор эффектов на движок.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

export type ScreenFX = {
	flash: (
		self: ScreenFX,
		color: Color3,
		brightness: number,
		duration: number,
		blurSize: number?
	) -> (),
	destroy: (self: ScreenFX) -> (),
}

local ScreenFX = {}
ScreenFX.__index = ScreenFX

function ScreenFX.new(): ScreenFX
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "VfxScreenFX"
	cc.Enabled = false
	cc.Parent = Lighting

	local blur = Instance.new("BlurEffect")
	blur.Name = "VfxScreenBlur"
	blur.Enabled = false
	blur.Size = 0
	blur.Parent = Lighting

	local self = setmetatable({
		_cc = cc,
		_blur = blur,
		_token = 0,
		_destroyed = false,
	}, ScreenFX)
	return (self :: any) :: ScreenFX
end

function ScreenFX:flash(color: Color3, brightness: number, duration: number, blurSize: number?)
	if self._destroyed or duration <= 0 then
		return
	end
	self._token += 1
	local token = self._token
	local cc = self._cc
	local blur = self._blur

	cc.TintColor = color
	cc.Brightness = brightness
	cc.Contrast = 0.06
	cc.Saturation = 0.04
	cc.Enabled = true

	local useBlur = blurSize ~= nil and blurSize > 0
	if useBlur then
		blur.Size = blurSize :: number
		blur.Enabled = true
	end

	local half = duration * 0.35
	local infoOut = TweenInfo.new(duration - half, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	task.delay(half, function()
		if self._destroyed or token ~= self._token then
			return
		end
		local goals: { [string]: any } = { Brightness = 0, Contrast = 0, Saturation = 0 }
		local tw = TweenService:Create(cc, infoOut, goals)
		tw:Play()
		if useBlur then
			TweenService:Create(blur, infoOut, { Size = 0 }):Play()
		end
		tw.Completed:Wait()
		if token == self._token then
			cc.Enabled = false
			blur.Enabled = false
		end
	end)
end

function ScreenFX:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._token += 1
	self._cc:Destroy()
	self._blur:Destroy()
end

return ScreenFX
