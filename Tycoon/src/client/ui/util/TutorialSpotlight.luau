--!strict
-- Imperative FTUE dim + gold hole + look-at arrow. No React state (walking must not lag).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local PadIds = require(ReplicatedStorage.shared.data.PadIds)
local TutorialFocusLogic = require(ReplicatedStorage.shared.util.TutorialFocusLogic)
local theme = require(script.Parent.Parent.theme)

local TWO_PI = math.pi * 2
local PEAK_SCALE = 1.1
local L = theme.Layout.tutorial

local STEP_PAD: { [number]: string } = {
    [1] = "Buy1",
    [3] = "Deposit",
    [4] = "CollectCash",
}

type Layer = {
    root: Frame,
    top: Frame,
    bottom: Frame,
    left: Frame,
    right: Frame,
    hole: Frame,
    arrow: ImageLabel,
    arrowScale: UIScale,
}

local layer: Layer? = nil
local conn: RBXScriptConnection? = nil
local step = 1
-- Smoothed arrow pose (lerp toward target each frame).
local smoothX = 0.5
local smoothY = 0.35
local smoothDeg = 180
local smoothOut = 0
local smoothReady = false

local TutorialSpotlight = {}

local function padModelName(action: string): string?
    for _, def in PadIds do
        if def.action == action then
            return def.modelName
        end
    end
    return nil
end

local function isIsland(inst: Instance): boolean
    return inst.Name == "IslandMain" or string.match(inst.Name, "^Island%d+$") ~= nil
end

local function islandAnchor(island: Instance): Vector3?
    if island:IsA("Model") then
        return island:GetPivot().Position
    end
    local part = island:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.Position
    end
    return nil
end

local function closestIsland(): Instance?
    local player = Players.LocalPlayer
    local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local origin: Vector3? = if root and root:IsA("BasePart") then root.Position else nil
    local best: Instance? = nil
    local bestDist = math.huge
    for _, child in workspace:GetChildren() do
        if not isIsland(child) then
            continue
        end
        local pos = islandAnchor(child)
        if pos == nil then
            continue
        end
        local dist = if origin then (pos - origin).Magnitude else 0
        if dist < bestDist then
            bestDist = dist
            best = child
            if origin == nil then
                return child
            end
        end
    end
    return best
end

local function findStepPart(which: number, island: Instance): BasePart?
    if which == 2 then
        local stand = island:FindFirstChild("Stand")
        local plane = stand and stand:FindFirstChild("Plane")
        if plane and plane:IsA("BasePart") then
            return plane
        end
        return nil
    end
    local action = STEP_PAD[which]
    local name = if action then padModelName(action) else nil
    if name == nil then
        return nil
    end
    local inst = island:FindFirstChild(name, true)
    if inst == nil then
        return nil
    end
    if inst:IsA("BasePart") then
        return inst
    end
    return inst:FindFirstChildWhichIsA("BasePart", true)
end

local function paintDim(frame: Frame)
    frame.BackgroundColor3 = theme.Colors.bg1
    frame.BackgroundTransparency = 0.28
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
    stroke.Thickness = theme.Stroke.panel * 0.55
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = hole
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(L.focusCornerScale, 0)
    corner.Parent = hole

    local arrow = Instance.new("ImageLabel")
    arrow.Name = "LookArrow"
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.BackgroundTransparency = 1
    arrow.BackgroundColor3 = Color3.new(1, 1, 1)
    arrow.BorderSizePixel = 0
    arrow.Image = IconCatalog.resolveImage(IconCatalog.TutorialArrow, "TutorialArrow")
    arrow.ImageTransparency = 0
    arrow.ScaleType = Enum.ScaleType.Fit
    arrow.Size = UDim2.fromScale(L.arrowW, L.arrowH)
    arrow.ZIndex = 3
    arrow.Active = false
    arrow.Parent = root
    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 1
    aspect.DominantAxis = Enum.DominantAxis.Height
    aspect.Parent = arrow
    local arrowScale = Instance.new("UIScale")
    arrowScale.Scale = 1
    arrowScale.Parent = arrow

    local built: Layer = {
        root = root,
        top = top,
        bottom = bottom,
        left = left,
        right = right,
        hole = hole,
        arrow = arrow,
        arrowScale = arrowScale,
    }
    layer = built
    return built
end

local function layoutHole(ui: Layer, x: number, y: number)
    local hw = L.focusHalfW
    local hh = L.focusHalfH
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

local function tick(dt: number)
    local ui = layer
    if ui == nil then
        return
    end
    local island = closestIsland()
    local camera = workspace.CurrentCamera
    if island == nil or camera == nil then
        return
    end
    local part = findStepPart(step, island)
    if part == nil then
        return
    end
    local view = camera.ViewportSize
    local p = camera:WorldToViewportPoint(part.Position + Vector3.new(0, 2, 0))
    local focus = TutorialFocusLogic.fromViewport(
        p.X,
        p.Y,
        p.Z,
        view.X,
        view.Y,
        TutorialFocusLogic.EDGE_MARGIN
    )
    layoutHole(ui, focus.x, focus.y)

    local tipDeg = if focus.onScreen then 180 else focus.arrowDeg
    local outwardDeg = tipDeg + 180
    local margin = L.arrowOut * 0.55
    local restX, restY, deg = TutorialFocusLogic.arrowOutsideFrame(
        focus.x,
        focus.y,
        L.focusHalfW,
        L.focusHalfH,
        outwardDeg,
        tipDeg,
        margin
    )
    local edgePad = TutorialFocusLogic.EDGE_MARGIN * 0.5
    restX = math.clamp(restX, edgePad, 1 - edgePad)
    restY = math.clamp(restY, edgePad, 1 - edgePad)

    local alpha = TutorialFocusLogic.expAlpha(dt, MotionPresets.TUTORIAL_ARROW.smoothSpeed)
    if not smoothReady then
        smoothX = restX
        smoothY = restY
        smoothDeg = deg
        smoothOut = outwardDeg
        smoothReady = true
    else
        smoothX = TutorialFocusLogic.lerp(smoothX, restX, alpha)
        smoothY = TutorialFocusLogic.lerp(smoothY, restY, alpha)
        smoothDeg = TutorialFocusLogic.lerpAngle(smoothDeg, deg, alpha)
        smoothOut = TutorialFocusLogic.lerpAngle(smoothOut, outwardDeg, alpha)
    end

    local period = MotionPresets.TUTORIAL_ARROW.periodSec
    local along = (math.sin(os.clock() / period * TWO_PI) + 1) * 0.5
    local bx, by = TutorialFocusLogic.arrowOffset(smoothOut, along * L.arrowBob)
    ui.arrow.BackgroundTransparency = 1
    ui.arrow.BackgroundColor3 = Color3.new(1, 1, 1)
    ui.arrow.BorderSizePixel = 0
    ui.arrow.ImageTransparency = 0
    ui.arrow.Rotation = smoothDeg
    ui.arrow.Position = UDim2.fromScale(smoothX + bx, smoothY + by)
    ui.arrowScale.Scale = 1 + (PEAK_SCALE - 1) * along
end

function TutorialSpotlight.bind(parent: Frame, tutorialStep: number)
    step = tutorialStep
    smoothReady = false
    ensureLayer(parent)
    if conn == nil then
        conn = RunService.RenderStepped:Connect(tick)
    end
    tick(1 / 60)
end

function TutorialSpotlight.unbind()
    if conn then
        conn:Disconnect()
        conn = nil
    end
    smoothReady = false
    local ui = layer
    if ui then
        ui.root:Destroy()
        layer = nil
    end
end

return TutorialSpotlight
