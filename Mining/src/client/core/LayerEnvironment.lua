--!strict
-- Плавная смена освещения по текущему слою — яркость и время суток.
-- Без тумана/дымки: Fog и Atmosphere отключены (мешали обзору при смене слоя).

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("shared")
local Constants = require(shared.constants)
local LayerUtil = require(shared.util.LayerUtil)
local Logger = require(shared.util.Logger)

local TWEEN_DURATION = 1.2
local ATMOSPHERE_NAME = "DeepDigger_LayerAtmosphere"
local DEFAULT_FOG_END = 100000

local LayerEnvironment = {}
LayerEnvironment.__index = LayerEnvironment

function LayerEnvironment.new()
    local self = setmetatable({}, LayerEnvironment)
    self._log = Logger.new("LayerEnvironment")
    self._currentLayerId = ""
    self._activeTween = nil :: Tween?
    return self
end

local function clearLayerFog()
    Lighting.FogStart = 0
    Lighting.FogEnd = DEFAULT_FOG_END

    local existing = Lighting:FindFirstChild(ATMOSPHERE_NAME)
    if existing then
        existing:Destroy()
    end
end

function LayerEnvironment:apply(layerId: string)
    if layerId == self._currentLayerId then
        return
    end
    self._currentLayerId = layerId

    local layer = LayerUtil.getLayer(layerId)
    if not layer then
        return
    end

    if self._activeTween then
        self._activeTween:Cancel()
        self._activeTween = nil
    end

    local light = Constants.LAYER_LIGHTING[layerId] or Constants.LAYER_LIGHTING.dirt
    self._log:info("Layer environment:", layer.name)

    clearLayerFog()

    self._activeTween = TweenService:Create(
        Lighting,
        TweenInfo.new(TWEEN_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Brightness = light.brightness,
            ClockTime = light.clockTime,
            FogEnd = DEFAULT_FOG_END,
            FogStart = 0,
        }
    )
    self._activeTween:Play()
end

function LayerEnvironment:reset()
    self._currentLayerId = ""
    if self._activeTween then
        self._activeTween:Cancel()
        self._activeTween = nil
    end
    clearLayerFog()
    local dirt = LayerUtil.getLayer("dirt")
    if dirt then
        self:apply("dirt")
    end
end

return LayerEnvironment
