--!strict
-- Dim + hole in absolute pixels. The hole center comes from TutorialFocusLogic.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TutorialFocusLogic = require(ReplicatedStorage.shared.util.TutorialFocusLogic)
local ViewportLayout = require(script.Parent.Parent.ui.util.ViewportLayout)
local theme = require(script.Parent.Parent.ui.theme)

local TutorialSpotlight = {}

local _root: Frame? = nil
local _hole: Frame? = nil
local _conn: RBXScriptConnection? = nil
local _target: BasePart? = nil

local function dim(parent: Frame, name: string): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.BackgroundColor3 = theme.Colors.bg1
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Active = false
    frame.Parent = parent
    return frame
end

local function ensure(parent: Instance): Frame
    local existing = _root
    if existing and existing.Parent == parent then
        return existing
    end
    local root = Instance.new("Frame")
    root.Name = "TutorialSpotlight"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Active = false
    root.Visible = false
    root.Parent = parent
    dim(root, "Top")
    dim(root, "Bottom")
    dim(root, "Left")
    dim(root, "Right")
    local hole = Instance.new("Frame")
    hole.Name = "Hole"
    hole.AnchorPoint = Vector2.new(0.5, 0.5)
    hole.BackgroundTransparency = 1
    hole.BorderSizePixel = 0
    hole.Parent = root
    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Colors.gold
    stroke.Thickness = theme.Stroke.thick
    stroke.Parent = hole
    local corner = Instance.new("UICorner")
    corner.CornerRadius = theme.Radius.chip
    corner.Parent = hole
    _hole = hole
    _root = root
    return root
end

local function layoutHole(focusX: number, focusY: number, view: Vector2)
    local root = _root
    local hole = _hole
    if root == nil or hole == nil then
        return
    end
    local halfW = ViewportLayout.px(56)
    local halfH = ViewportLayout.px(40)
    local cx = focusX * view.X
    local cy = focusY * view.Y
    hole.Position = UDim2.fromOffset(cx, cy)
    hole.Size = UDim2.fromOffset(halfW * 2, halfH * 2)

    local top = root:FindFirstChild("Top")
    local bottom = root:FindFirstChild("Bottom")
    local left = root:FindFirstChild("Left")
    local right = root:FindFirstChild("Right")
    if
        not (
            top
            and top:IsA("Frame")
            and bottom
            and bottom:IsA("Frame")
            and left
            and left:IsA("Frame")
            and right
            and right:IsA("Frame")
        )
    then
        return
    end
    local topH = math.max(0, cy - halfH)
    local bottomY = cy + halfH
    top.Position = UDim2.fromOffset(0, 0)
    top.Size = UDim2.fromOffset(view.X, topH)
    bottom.Position = UDim2.fromOffset(0, bottomY)
    bottom.Size = UDim2.fromOffset(view.X, math.max(0, view.Y - bottomY))
    left.Position = UDim2.fromOffset(0, topH)
    left.Size = UDim2.fromOffset(math.max(0, cx - halfW), halfH * 2)
    right.Position = UDim2.fromOffset(cx + halfW, topH)
    right.Size = UDim2.fromOffset(math.max(0, view.X - (cx + halfW)), halfH * 2)
end

local function step()
    local root = _root
    local target = _target
    local camera = Workspace.CurrentCamera
    if root == nil or camera == nil or target == nil or target.Parent == nil then
        if root then
            root.Visible = false
        end
        return
    end
    local view = camera.ViewportSize
    local world = camera:WorldToViewportPoint(target.Position)
    local focus = TutorialFocusLogic.fromViewport(
        world.X,
        world.Y,
        world.Z,
        view.X,
        view.Y,
        TutorialFocusLogic.EDGE_MARGIN
    )
    root.Visible = true
    layoutHole(focus.x, focus.y, view)
end

function TutorialSpotlight.mount(parent: Instance)
    ensure(parent)
end

function TutorialSpotlight.setTarget(target: BasePart?)
    _target = target
    if _root then
        _root.Visible = target ~= nil
    end
end

function TutorialSpotlight.start(parent: Instance)
    TutorialSpotlight.mount(parent)
    if _conn then
        return
    end
    _conn = RunService.Heartbeat:Connect(step)
end

function TutorialSpotlight.stop()
    if _conn then
        _conn:Disconnect()
        _conn = nil
    end
    _target = nil
    if _root then
        _root.Visible = false
    end
end

return TutorialSpotlight
