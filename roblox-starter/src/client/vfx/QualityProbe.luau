--!strict
-- Снимает DeviceHints с клиента + скользящий FPS для адаптивного тира.

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local UserSettings = UserSettings

local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type DeviceHints = QualityLogic.DeviceHints
export type QualityBudget = QualityLogic.QualityBudget

export type QualityProbeDeps = {
	isReduceMotion: (() -> boolean)?,
}

export type QualityProbe = {
	getHints: (self: QualityProbe) -> DeviceHints,
	getBudget: (self: QualityProbe) -> QualityBudget,
	destroy: (self: QualityProbe) -> (),
}

local QualityProbe = {}
QualityProbe.__index = QualityProbe

local function readSavedQuality(): number
	local ok, level = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	if ok and typeof(level) == "number" then
		return level
	end
	return 0
end

function QualityProbe.new(deps: QualityProbeDeps?): QualityProbe
	local self = setmetatable({
		_isReduceMotion = if deps then deps.isReduceMotion else nil,
		_fpsEma = 60,
		_conn = nil :: RBXScriptConnection?,
		_destroyed = false,
	}, QualityProbe)

	local acc = 0
	local frames = 0
	self._conn = RunService.Heartbeat:Connect(function(dt)
		if dt <= 0 then
			return
		end
		acc += dt
		frames += 1
		if acc >= 0.5 then
			local fps = frames / acc
			-- EMA: сглаживаем, чтобы тир не дёргался
			self._fpsEma = self._fpsEma * 0.7 + fps * 0.3
			acc = 0
			frames = 0
		end
	end)

	return (self :: any) :: QualityProbe
end

function QualityProbe:getHints(): DeviceHints
	local reduce = false
	if self._isReduceMotion then
		reduce = self._isReduceMotion()
	end
	-- GuiService.PreferredTransparency / touch — эвристика mobile
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if GuiService:IsTenFootInterface() then
		touch = false
	end
	return {
		touchEnabled = touch,
		savedQualityLevel = readSavedQuality(),
		averageFps = self._fpsEma,
		reduceMotion = reduce,
	}
end

function QualityProbe:getBudget(): QualityBudget
	return QualityLogic.resolveBudget(self:getHints())
end

function QualityProbe:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
end

return QualityProbe
