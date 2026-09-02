--!strict
-- Host AbsoluteSize (or safe viewport) → UIScale for a 1920×1080 design canvas.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local UiAdaptLogic = require(ReplicatedStorage.shared.util.UiAdaptLogic)

export type Config = {
    reference: Vector2?,
    minScale: number?,
    maxScale: number?,
    fit: boolean?,
    mobileBoost: number?,
    mobileBelow: number?,
}

local DEFAULT_REF = Vector2.new(1920, 1080)
local DEFAULT_MIN = 0.3
local DEFAULT_MAX = 1.2
local DEFAULT_MOBILE_BOOST = 1
local DEFAULT_MOBILE_BELOW = 900

local function toFit(config: Config?): UiAdaptLogic.FitConfig
    local c = config or {}
    local ref = c.reference or DEFAULT_REF
    return {
        reference = { X = ref.X, Y = ref.Y },
        minScale = c.minScale or DEFAULT_MIN,
        maxScale = c.maxScale or DEFAULT_MAX,
        fit = if c.fit == nil then true else c.fit,
        mobileBoost = c.mobileBoost or DEFAULT_MOBILE_BOOST,
        mobileBelow = c.mobileBelow or DEFAULT_MOBILE_BELOW,
    }
end

local function usableFromCamera(): Vector2
    local cam = Workspace.CurrentCamera
    local vp = if cam then cam.ViewportSize else DEFAULT_REF
    if vp.X < 32 or vp.Y < 32 then
        return DEFAULT_REF
    end
    local topLeft, bottomRight = GuiService:GetGuiInset()
    return Vector2.new(
        math.max(1, vp.X - topLeft.X - bottomRight.X),
        math.max(1, vp.Y - topLeft.Y - bottomRight.Y)
    )
end

local UiScaler = {}

UiScaler.DEFAULT_REF = DEFAULT_REF

function UiScaler.getReference(config: Config?): Vector2
    local c = config or {}
    return c.reference or DEFAULT_REF
end

function UiScaler.getUsableViewport(): Vector2
    return usableFromCamera()
end

--- Prefer ScreenGui / Host AbsoluteSize from DesignRoot.
function UiScaler.computeFromUsable(usable: Vector2, config: Config?): number
    return UiAdaptLogic.fitScale({ X = usable.X, Y = usable.Y }, toFit(config))
end

function UiScaler.compute(config: Config?): number
    return UiScaler.computeFromUsable(usableFromCamera(), config)
end

function UiScaler.isPhone(config: Config?): boolean
    local fit = toFit(config)
    local usable = usableFromCamera()
    return math.min(usable.X, usable.Y) < fit.mobileBelow
end

function UiScaler.listen(config: Config?, onChange: (number) -> ()): () -> ()
    local camConn: RBXScriptConnection? = nil
    local insetConn: RBXScriptConnection? = nil

    local function fire()
        onChange(UiScaler.compute(config))
    end

    local function attachCam()
        if camConn then
            camConn:Disconnect()
            camConn = nil
        end
        local cam = Workspace.CurrentCamera
        if cam == nil then
            return
        end
        camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fire)
        fire()
    end

    local workspaceConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(attachCam)
    insetConn = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fire)
    attachCam()

    return function()
        workspaceConn:Disconnect()
        if camConn then
            camConn:Disconnect()
        end
        if insetConn then
            insetConn:Disconnect()
        end
    end
end

return UiScaler
