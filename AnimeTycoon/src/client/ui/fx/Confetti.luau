--!strict
-- Purchase confetti: full-width rain + soft center burst (independent RNG streams).
-- Ported from Tycoon; see docs/VFX_ENGINE.md «UI FX».

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local FxOverlay = require(script.Parent.FxOverlay)
local SettingsManager = require(script.Parent.Parent.Parent.core.SettingsManager)
local theme = require(script.Parent.Parent.theme)

export type ConfettiOptions = {
    count: number?,
    duration: number?,
    maxCount: number?,
    colors: { Color3 }?,
}

local DEFAULT_COLORS: { Color3 } = {
    theme.Colors.gold,
    theme.Colors.goldHi,
    theme.Colors.primary,
    theme.Colors.primaryHi,
    theme.Colors.success,
    theme.Colors.sellHi,
    Color3.fromRGB(255, 70, 130),
    Color3.fromRGB(255, 120, 40),
    Color3.fromRGB(60, 210, 255),
    Color3.fromRGB(180, 90, 255),
    Color3.fromRGB(255, 55, 55),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(255, 230, 80),
    Color3.fromRGB(100, 255, 160),
}

local GRAVITY = 480

type Piece = {
    gui: Frame,
    x: number,
    y: number,
    vx: number,
    vy: number,
    rot: number,
    spin: number,
    age: number,
    life: number,
    w: number,
    h: number,
    flutter: number,
    phase: number,
    delay: number,
    started: boolean,
}

local Confetti = {}

local function frac(n: number): number
    return n - math.floor(n)
end

local function hash(i: number, salt: number): number
    return frac(i * salt)
end

local function viewport(): Vector2
    local cam = workspace.CurrentCamera
    return if cam then cam.ViewportSize else Vector2.new(1920, 1080)
end

local function toScale(absX: number, absY: number): UDim2
    local vp = viewport()
    return UDim2.fromScale(absX / math.max(1, vp.X), absY / math.max(1, vp.Y))
end

local function clampCount(requested: number, maxCount: number?): number
    local cap = maxCount or 520
    if SettingsManager.isReduceMotion() then
        cap = math.min(cap, 36)
    end
    return math.clamp(math.floor(requested + 0.5), 1, cap)
end

local function makeBit(color: Color3, w: number, h: number, rot: number): Frame
    local bit = Instance.new("Frame")
    bit.Name = "ConfettiBit"
    bit.BackgroundColor3 = color
    bit.BackgroundTransparency = 0
    bit.BorderSizePixel = 0
    bit.AnchorPoint = Vector2.new(0.5, 0.5)
    bit.Size = UDim2.fromOffset(w, h)
    bit.Rotation = rot
    bit.Visible = false
    bit.ZIndex = 20

    local radius = Instance.new("UICorner")
    radius.CornerRadius = UDim.new(0, 2)
    radius.Parent = bit

    return bit
end

local function pieceSize(i: number): (number, number)
    local shape = i % 6
    if shape <= 2 then
        return (16 + (i % 6) * 3) * 1.25, (6 + (i % 4) * 2) * 1.25
    elseif shape <= 4 then
        local s = (12 + (i % 5) * 3) * 1.25
        return s, s
    end
    return (22 + (i % 4) * 4) * 1.25, (5 + (i % 3)) * 1.25
end

function Confetti.play(opts: ConfettiOptions?)
    local options = opts or {}
    local layer = FxOverlay.getLayer()
    local vp = viewport()
    local count = clampCount(options.count or 420, options.maxCount)
    local colors = options.colors or DEFAULT_COLORS
    local maxLife = options.duration or 5.2

    local pieces: { Piece } = table.create(count)
    local folder = Instance.new("Folder")
    folder.Name = "ConfettiBurst"
    folder.Parent = layer
    Debris:AddItem(folder, maxLife + 3)

    local rainCount = math.floor(count * 0.7)
    local burstCount = count - rainCount

    for i = 1, rainCount do
        local x = vp.X * (0.01 + hash(i, 0.7548776662) * 0.98)
        local y = -12 - hash(i, 0.5698402909) * 140
        local color = colors[((i - 1) % #colors) + 1]
        local w, h = pieceSize(i)
        local bit = makeBit(color, w, h, hash(i, 0.4142135623) * 360)
        bit.Position = toScale(x, y)
        bit.Parent = folder

        pieces[i] = {
            gui = bit,
            x = x,
            y = y,
            vx = (hash(i, 0.8672634483) - 0.5) * 90,
            vy = 40 + hash(i, 0.9287294787) * 120,
            rot = bit.Rotation,
            spin = (35 + hash(i, 0.6789012345) * 90) * (if i % 2 == 0 then 1 else -1),
            age = 0,
            life = maxLife * (0.7 + hash(i, 0.3456789012) * 0.35),
            w = w,
            h = h,
            flutter = 0.9 + hash(i, 0.2222222222) * 1.4,
            phase = hash(i, 0.3333333333) * math.pi * 2,
            delay = hash(i, 0.1414213562) * 2.4,
            started = false,
        }
    end

    local cx, cy = vp.X * 0.5, vp.Y * 0.38
    for j = 1, burstCount do
        local i = rainCount + j
        local ang = hash(j, 0.6180339887) * math.pi * 2
        local rad = 8 + hash(j, 0.3819660113) * 36
        local x = cx + math.cos(ang) * rad
        local y = cy + math.sin(ang) * rad * 0.55
        local color = colors[((i - 1) % #colors) + 1]
        local w, h = pieceSize(i)
        local bit = makeBit(color, w, h, hash(j, 0.7071067811) * 360)
        bit.Position = toScale(x, y)
        bit.Parent = folder

        local speed = 180 + hash(j, 0.5773502691) * 220
        pieces[i] = {
            gui = bit,
            x = x,
            y = y,
            vx = math.cos(ang) * speed,
            vy = math.sin(ang) * speed * 0.35 - (120 + hash(j, 0.8660254037) * 160),
            rot = bit.Rotation,
            spin = (50 + hash(j, 0.2588190451) * 110) * (if j % 2 == 0 then 1 else -1),
            age = 0,
            life = maxLife * (0.55 + hash(j, 0.4472135955) * 0.35),
            w = w,
            h = h,
            flutter = 1.0 + hash(j, 0.123456789) * 1.2,
            phase = hash(j, 0.987654321) * math.pi * 2,
            delay = hash(j, 0.1111111111) * 0.35,
            started = false,
        }
    end

    local conn: RBXScriptConnection? = nil
    local elapsed = 0
    conn = RunService.Heartbeat:Connect(function(dt)
        if folder.Parent == nil then
            if conn then
                conn:Disconnect()
            end
            return
        end

        elapsed += dt
        local alive = 0
        for _, p in pieces do
            if p.gui.Parent == nil then
                continue
            end
            if not p.started then
                if elapsed < p.delay then
                    continue
                end
                p.started = true
                p.gui.Visible = true
            end

            p.age += dt
            if p.age >= p.life or p.y > vp.Y + 70 then
                p.gui:Destroy()
                continue
            end

            alive += 1
            local flutterX = math.sin(p.age * p.flutter + p.phase) * 160
            p.vx = p.vx * 0.992 + flutterX * dt
            p.vy = p.vy + GRAVITY * dt
            if p.vy > 420 then
                p.vy = 420
            end
            p.x += p.vx * dt
            p.y += p.vy * dt
            p.rot += p.spin * dt

            local flip = 0.35 + math.abs(math.sin(math.rad(p.rot))) * 0.65
            local fade = if p.age > p.life * 0.86
                then math.clamp((p.age - p.life * 0.86) / (p.life * 0.14), 0, 1)
                else 0

            p.gui.Position = toScale(p.x, p.y)
            p.gui.Rotation = p.rot
            p.gui.Size = UDim2.fromOffset(math.max(4, p.w * flip), p.h)
            p.gui.BackgroundTransparency = fade * 0.9
        end

        if alive == 0 and elapsed > 0.5 and conn then
            conn:Disconnect()
            folder:Destroy()
        end
    end)
end

return Confetti
