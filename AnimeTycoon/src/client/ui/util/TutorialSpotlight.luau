--!strict
-- Imperative FTUE dim + gold hole. Hole matches projected world target bounds.

local RunService = game:GetService("RunService")

local theme = require(script.Parent.Parent.theme)

type Layer = {
    root: Frame,
    top: Frame,
    bottom: Frame,
    left: Frame,
    right: Frame,
    hole: Frame,
    stroke: UIStroke,
}

local FALLBACK_HALF_W = 0.06
local FALLBACK_HALF_H = 0.05
local MIN_HALF = 0.02
local MAX_HALF = 0.45
local PAD_SCALE = 1.08
local FOCUS_CORNER = 0.1
local DIM_TARGET = 0.32
local FADE_IN_SEC = 0.35
local FADE_OUT_SEC = 0.25
-- Generous: beam guides from afar; frame appears as you approach (and on-screen).
local DEFAULT_NEAR = 22

local layer: Layer? = nil
local conn: RBXScriptConnection? = nil
local _target: Instance? = nil
local _nearStuds = DEFAULT_NEAR
local _playerRoot: (() -> BasePart?)? = nil
local _fade = 0
local _holeHalfW = FALLBACK_HALF_W
local _holeHalfH = FALLBACK_HALF_H
local _holeX = 0.5
local _holeY = 0.45

local TutorialSpotlight = {}

local function paintDim(frame: Frame)
    frame.BackgroundColor3 = theme.Colors.bg1
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Active = false
    frame.ZIndex = 1
end

local function ensureLayer(parent: Frame): Layer
    local existing = layer
    if existing and existing.root.Parent == parent then
        return existing
    end

    local root = Instance.new("Frame")
    root.Name = "WorldCue"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Active = false
    root.Visible = false
    root.ZIndex = 1
    root.Parent = parent

    local top = Instance.new("Frame")
    top.Name = "Top"
    paintDim(top)
    top.Parent = root
    local bottom = Instance.new("Frame")
    bottom.Name = "Bottom"
    paintDim(bottom)
    bottom.Parent = root
    local left = Instance.new("Frame")
    left.Name = "Left"
    paintDim(left)
    left.Parent = root
    local right = Instance.new("Frame")
    right.Name = "Right"
    paintDim(right)
    right.Parent = root

    local hole = Instance.new("Frame")
    hole.Name = "Hole"
    hole.AnchorPoint = Vector2.new(0.5, 0.5)
    hole.BackgroundTransparency = 1
    hole.BorderSizePixel = 0
    hole.ZIndex = 2
    hole.Active = false
    hole.Parent = root
    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Colors.gold
    stroke.Thickness = theme.Stroke.thick
    stroke.Transparency = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = hole
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(FOCUS_CORNER, 0)
    corner.Parent = hole

    local built: Layer = {
        root = root,
        top = top,
        bottom = bottom,
        left = left,
        right = right,
        hole = hole,
        stroke = stroke,
    }
    layer = built
    return built
end

local function layoutHole(ui: Layer, x: number, y: number, hw: number, hh: number)
    local holeTop = y - hh
    local holeBottom = y + hh
    local holeLeft = x - hw
    local holeRight = x + hw
    ui.top.Size = UDim2.fromScale(1, math.max(holeTop, 0))
    ui.top.Position = UDim2.fromScale(0, 0)
    ui.bottom.Size = UDim2.fromScale(1, math.max(1 - holeBottom, 0))
    ui.bottom.Position = UDim2.fromScale(0, holeBottom)
    ui.left.Size = UDim2.fromScale(math.max(holeLeft, 0), hh * 2)
    ui.left.Position = UDim2.fromScale(0, holeTop)
    ui.right.Size = UDim2.fromScale(math.max(1 - holeRight, 0), hh * 2)
    ui.right.Position = UDim2.fromScale(holeRight, holeTop)
    ui.hole.Size = UDim2.fromScale(hw * 2, hh * 2)
    ui.hole.Position = UDim2.fromScale(x, y)
end

local function applyFade(ui: Layer, fade: number)
    local dimT = 1 - (1 - DIM_TARGET) * fade
    ui.top.BackgroundTransparency = dimT
    ui.bottom.BackgroundTransparency = dimT
    ui.left.BackgroundTransparency = dimT
    ui.right.BackgroundTransparency = dimT
    ui.stroke.Transparency = 1 - fade
    ui.root.Visible = fade > 0.01
end

local function flatDist(a: Vector3, b: Vector3): number
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

--- Visible solid parts only (skip hidden / tiny FX).
local function collectParts(target: Instance): { BasePart }
    local parts: { BasePart } = {}
    local function consider(part: BasePart)
        if part.Transparency >= 0.95 then
            return
        end
        if part.LocalTransparencyModifier >= 0.95 then
            return
        end
        local vol = part.Size.X * part.Size.Y * part.Size.Z
        if vol < 0.08 then
            return
        end
        table.insert(parts, part)
    end

    if target:IsA("BasePart") then
        consider(target)
        -- Single MeshPart: always include even if small (Button / Cube.001).
        if
            #parts == 0
            and target.Transparency < 0.95
            and target.LocalTransparencyModifier < 0.95
        then
            table.insert(parts, target)
        end
        return parts
    end

    for _, d in target:GetDescendants() do
        if d:IsA("BasePart") then
            consider(d)
        end
    end
    if #parts == 0 and target:IsA("Model") then
        local primary = target.PrimaryPart
        if primary then
            table.insert(parts, primary)
        end
    end
    return parts
end

local function worldAnchor(target: Instance, parts: { BasePart }): Vector3?
    if target:IsA("Model") then
        return target:GetPivot().Position
    end
    if target:IsA("BasePart") then
        return target.Position
    end
    if #parts == 0 then
        return nil
    end
    local sum = Vector3.zero
    for _, p in parts do
        sum += p.Position
    end
    return sum / #parts
end

local function projectTarget(
    target: Instance,
    camera: Camera,
    viewX: number,
    viewY: number
): (number, number, number, number, boolean)
    if viewX <= 0 or viewY <= 0 then
        return 0.5, 0.45, FALLBACK_HALF_W, FALLBACK_HALF_H, false
    end
    local parts = collectParts(target)
    if #parts == 0 then
        return 0.5, 0.45, FALLBACK_HALF_W, FALLBACK_HALF_H, false
    end

    local minX = math.huge
    local maxX = -math.huge
    local minY = math.huge
    local maxY = -math.huge
    local any = false

    for _, part in parts do
        local cf = part.CFrame
        local sx = part.Size.X * 0.5
        local sy = part.Size.Y * 0.5
        local sz = part.Size.Z * 0.5
        for _, ox in { -sx, sx } do
            for _, oy in { -sy, sy } do
                for _, oz in { -sz, sz } do
                    local world = cf:PointToWorldSpace(Vector3.new(ox, oy, oz))
                    local vp = camera:WorldToViewportPoint(world)
                    if vp.Z > 0 then
                        any = true
                        minX = math.min(minX, vp.X)
                        maxX = math.max(maxX, vp.X)
                        minY = math.min(minY, vp.Y)
                        maxY = math.max(maxY, vp.Y)
                    end
                end
            end
        end
    end

    if not any then
        return 0.5, 0.45, FALLBACK_HALF_W, FALLBACK_HALF_H, false
    end

    local cx = ((minX + maxX) * 0.5) / viewX
    local cy = ((minY + maxY) * 0.5) / viewY
    local halfW = ((maxX - minX) / viewX) * 0.5 * PAD_SCALE
    local halfH = ((maxY - minY) / viewY) * 0.5 * PAD_SCALE
    halfW = math.clamp(halfW, MIN_HALF, MAX_HALF)
    halfH = math.clamp(halfH, MIN_HALF, MAX_HALF)
    cx = math.clamp(cx, halfW, 1 - halfW)
    cy = math.clamp(cy, halfH, 1 - halfH)
    return cx, cy, halfW, halfH, true
end

local function tick(dt: number)
    local ui = layer
    if ui == nil then
        return
    end
    local target = _target
    local camera = workspace.CurrentCamera
    local rootPart = if _playerRoot then _playerRoot() else nil

    local alive = target ~= nil and target.Parent ~= nil
    local parts = if alive and target then collectParts(target) else {} :: { BasePart }
    local anchor = if alive and target then worldAnchor(target, parts) else nil

    local shouldShow = alive
        and camera ~= nil
        and rootPart ~= nil
        and anchor ~= nil
        and flatDist(rootPart.Position, anchor) <= _nearStuds

    if shouldShow and target and camera then
        local view = camera.ViewportSize
        local cx, cy, hw, hh = projectTarget(target, camera, view.X, view.Y)
        _holeX = cx
        _holeY = cy
        _holeHalfW = hw
        _holeHalfH = hh
        layoutHole(ui, cx, cy, hw, hh)
        _fade = math.min(1, _fade + dt / FADE_IN_SEC)
    else
        _fade = math.max(0, _fade - dt / FADE_OUT_SEC)
        if _fade > 0.01 then
            layoutHole(ui, _holeX, _holeY, _holeHalfW, _holeHalfH)
        end
    end

    applyFade(ui, _fade)
end

function TutorialSpotlight.bind(parent: Frame, getPlayerRoot: () -> BasePart?, nearStuds: number?)
    _playerRoot = getPlayerRoot
    _nearStuds = nearStuds or DEFAULT_NEAR
    _fade = 0
    ensureLayer(parent)
    if conn == nil then
        conn = RunService.RenderStepped:Connect(tick)
    end
    tick(1 / 60)
end

function TutorialSpotlight.setTarget(target: Instance?)
    _target = target
end

function TutorialSpotlight.unbind()
    if conn then
        conn:Disconnect()
        conn = nil
    end
    _target = nil
    _playerRoot = nil
    _fade = 0
    local ui = layer
    if ui then
        ui.root:Destroy()
        layer = nil
    end
end

return TutorialSpotlight
