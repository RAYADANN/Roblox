--!strict
-- CS-custom style wall: shoot a panel to equip that crosshair.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local CrosshairDatabase = require(ReplicatedStorage.shared.data.CrosshairDatabase)

local CrosshairWall = {}

local WALL_NAME = "CrosshairWall"

local function paintPreview(gui: SurfaceGui, def: CrosshairDatabase.CrosshairDef)
    gui:ClearAllChildren()
    local color = Color3.new(def.r, def.g, def.b)
    local root = Instance.new("Frame")
    root.Name = "Preview"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
    root.BorderSizePixel = 0
    root.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 22)
    title.Position = UDim2.new(0, 0, 1, -24)
    title.BackgroundTransparency = 1
    title.Text = def.name
    title.TextColor3 = Color3.fromRGB(200, 205, 220)
    title.TextSize = 14
    title.Font = Enum.Font.GothamMedium
    title.Parent = root

    local cx = 0.5
    local cy = 0.42
    local scale = 2.2

    local function arm(size: UDim2, pos: UDim2)
        local f = Instance.new("Frame")
        f.Size = size
        f.Position = pos
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BackgroundColor3 = color
        f.BorderSizePixel = 0
        f.Parent = root
        if def.outline then
            local s = Instance.new("UIStroke")
            s.Color = Color3.new(0, 0, 0)
            s.Thickness = 1
            s.Parent = f
        end
        return f
    end

    local size = def.size * scale
    local gap = def.gap * scale
    local thick = math.max(2, def.thickness * scale)

    if def.style == "dot" or def.style == "cross_dot" then
        local d = arm(UDim2.fromOffset(def.size * scale, def.size * scale), UDim2.fromScale(cx, cy))
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = d
    end

    if def.style == "circle" then
        local ring = arm(UDim2.fromOffset(size, size), UDim2.fromScale(cx, cy))
        ring.BackgroundTransparency = 1
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ring
        local stroke = Instance.new("UIStroke")
        stroke.Color = color
        stroke.Thickness = thick
        stroke.Parent = ring
    end

    if
        def.style == "cross"
        or def.style == "cross_dot"
        or def.style == "gap_cross"
        or def.style == "t"
    then
        local half = size
        local g = gap
        -- left / right
        arm(UDim2.fromOffset(half, thick), UDim2.new(cx, -(g + half / 2), cy, 0))
        arm(UDim2.fromOffset(half, thick), UDim2.new(cx, g + half / 2, cy, 0))
        -- bottom (and top unless T)
        arm(UDim2.fromOffset(thick, half), UDim2.new(cx, 0, cy, g + half / 2))
        if def.style ~= "t" then
            arm(UDim2.fromOffset(thick, half), UDim2.new(cx, 0, cy, -(g + half / 2)))
        end
    end
end

function CrosshairWall.ensure(arena: Instance)
    local existing = arena:FindFirstChild(WALL_NAME)
    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = WALL_NAME
    folder.Parent = arena

    local list = CrosshairDatabase.list()
    local cols = 4
    local panelW = 5
    local panelH = 5
    local gap = 0.6
    local rows = math.ceil(#list / cols)
    local boardW = cols * panelW + (cols + 1) * gap
    local boardH = rows * panelH + (rows + 1) * gap + 1.5

    -- Side board near SpawnA: face the lane (+Z) so panels are shootable from spawn.
    local boardCf = CFrame.new(-48, 1 + boardH / 2, -16) * CFrame.Angles(0, math.pi, 0)

    local board = Instance.new("Part")
    board.Name = "Board"
    board.Size = Vector3.new(boardW, boardH, 0.6)
    board.CFrame = boardCf
    board.Color = Color3.fromRGB(40, 42, 48)
    board.Material = Enum.Material.SmoothPlastic
    board.Anchored = true
    board.CanCollide = true
    board.Parent = folder

    local header = Instance.new("Part")
    header.Name = "Header"
    header.Size = Vector3.new(boardW - 0.4, 1.2, 0.2)
    header.CFrame = boardCf * CFrame.new(0, boardH / 2 - 0.9, -0.4)
    header.Color = Color3.fromRGB(55, 58, 68)
    header.Anchored = true
    header.CanCollide = false
    header.Parent = folder

    local headerGui = Instance.new("SurfaceGui")
    headerGui.Face = Enum.NormalId.Front
    headerGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    headerGui.PixelsPerStud = 40
    headerGui.Parent = header
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.fromScale(1, 1)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "CROSSHAIRS  ·  shoot to select"
    headerLabel.TextColor3 = Color3.fromRGB(230, 235, 245)
    headerLabel.TextSize = 22
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.Parent = headerGui

    local startX = -boardW / 2 + gap + panelW / 2
    local startY = boardH / 2 - gap - 1.5 - panelH / 2

    for i, def in list do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = startX + col * (panelW + gap)
        local y = startY - row * (panelH + gap)

        local panel = Instance.new("Part")
        panel.Name = `Panel_{def.id}`
        panel.Size = Vector3.new(panelW, panelH, 0.35)
        panel.CFrame = boardCf * CFrame.new(x, y, -0.45)
        panel.Color = Color3.fromRGB(32, 34, 40)
        panel.Material = Enum.Material.SmoothPlastic
        panel.Anchored = true
        panel.CanCollide = true
        panel:SetAttribute(Constants.CROSSHAIR_PANEL_ATTRIBUTE, def.id)
        panel.Parent = folder

        local gui = Instance.new("SurfaceGui")
        gui.Face = Enum.NormalId.Front
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.PixelsPerStud = 50
        gui.Parent = panel
        paintPreview(gui, def)
    end
end

return CrosshairWall
