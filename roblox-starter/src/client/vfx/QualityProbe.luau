--!strict
-- Снимает DeviceHints с клиента + скользящий FPS для адаптивного тира.

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local UserSettings = UserSettings

local Types = require(game:GetService("ReplicatedStorage").shared.vfx.Types)
local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type DeviceHints = QualityLogic.DeviceHints
export type QualityBudget = QualityLogic.QualityBudget
export type QualityTier = Types.QualityTier

export type QualityProbeDeps = {
	isReduceMotion: (() -> boolean)?,
}

export type QualityProbe = {
	getHints: (self: QualityProbe) -> DeviceHints,
	getBudget: (self: QualityProbe) -> QualityBudget,
	getFps: (self: QualityProbe) -> number,
	setTierOverride: (self: QualityProbe, tier: QualityTier?) -> (),
	getTierOverride: (self: QualityProbe) -> QualityTier?,
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
		_tierOverride = nil :: QualityTier?,
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

function QualityProbe:getFps(): number
	return self._fpsEma
end

function QualityProbe:setTierOverride(tier: QualityTier?)
	self._tierOverride = tier
end

function QualityProbe:getTierOverride(): QualityTier?
	return self._tierOverride
end

function QualityProbe:getBudget(): QualityBudget
	if self._tierOverride then
		local budget = QualityLogic.budgetFor(self._tierOverride)
		return QualityLogic.applyThermal(budget, self._fpsEma)
	end
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
