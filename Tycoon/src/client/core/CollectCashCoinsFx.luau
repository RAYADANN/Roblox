--!strict
-- World coins: pop up → fall to ground → fly to player (CoinPart + Trail).

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SettingsManager = require(script.Parent.SettingsManager)

local CollectCashCoinsFx = {}

local POP_SEC = 0.16
local FALL_SEC = 0.28
local FLY_SEC = 0.4
local GROUND_HOLD_SEC = 0.06

local function getTemplate(): BasePart?
    local assets = ReplicatedStorage:FindFirstChild("GameAssets")
    local template = assets and assets:FindFirstChild("CoinPart")
    if template and template:IsA("BasePart") then
        return template
    end
    local ws = Workspace:FindFirstChild("CoinPart")
    if ws and ws:IsA("BasePart") then
        return ws
    end
    return nil
end

local function ensureFolder(): Folder
    local folder = Workspace:FindFirstChild("CollectCashFx")
    if folder and folder:IsA("Folder") then
        return folder
    end
    local created = Instance.new("Folder")
    created.Name = "CollectCashFx"
    created.Parent = Workspace
    return created
end

local function popOffset(index: number, total: number): Vector3
    local angle = (index / math.max(1, total)) * math.pi * 2 + (index % 3) * 0.4
    local radius = 1.2 + (index % 4) * 0.55
    local up = 3.2 + (index % 5) * 0.45
    return Vector3.new(math.cos(angle) * radius, up, math.sin(angle) * radius)
end

local function landOffset(index: number, total: number): Vector3
    local angle = (index / math.max(1, total)) * math.pi * 2 + 0.7
    local radius = 2.4 + (index % 5) * 0.85
    return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function groundPoint(horizontal: Vector3, fallbackY: number, fxFolder: Folder): Vector3
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { fxFolder }
    local origin = Vector3.new(horizontal.X, fallbackY + 8, horizontal.Z)
    local hit = Workspace:Raycast(origin, Vector3.new(0, -48, 0), params)
    if hit then
        return hit.Position + Vector3.new(0, 0.45, 0)
    end
    return Vector3.new(horizontal.X, fallbackY + 0.4, horizontal.Z)
end

local function tweenTo(
    coin: BasePart,
    pos: Vector3,
    sec: number,
    style: Enum.EasingStyle,
    dir: Enum.EasingDirection
): Tween
    local info = TweenInfo.new(sec, style, dir)
    local tween = TweenService:Create(coin, info, { CFrame = CFrame.new(pos) })
    tween:Play()
    return tween
end

local function flyToPlayer(coin: BasePart, start: Vector3, fallbackTo: Vector3)
    local localPlayer = Players.LocalPlayer
    local elapsed = 0
    local conn: RBXScriptConnection?
    conn = RunService.Heartbeat:Connect(function(dt)
        if coin.Parent == nil then
            if conn then
                conn:Disconnect()
            end
            return
        end
        elapsed += dt
        local alpha = math.clamp(elapsed / FLY_SEC, 0, 1)
        local t = alpha * alpha
        local target = fallbackTo
        local character = localPlayer and localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            target = root.Position
        end
        local pos = start:Lerp(target, t)
        local bob = math.sin(alpha * math.pi) * 0.9 * (1 - alpha)
        coin.CFrame = CFrame.new(pos + Vector3.new(0, bob, 0))
        if alpha >= 1 then
            if conn then
                conn:Disconnect()
            end
            coin:Destroy()
        end
    end)
end

function CollectCashCoinsFx.play(from: Vector3, to: Vector3, count: number)
    local template = getTemplate()
    if template == nil then
        return
    end

    local n = math.clamp(math.floor(count + 0.5), 1, 16)
    if SettingsManager.isReduceMotion() then
        n = math.min(n, 3)
    end

    local folder = ensureFolder()
    local lifetime = POP_SEC + FALL_SEC + GROUND_HOLD_SEC + FLY_SEC + 0.5

    for i = 1, n do
        local coin = template:Clone()
        coin.Name = "CoinFx"
        coin.Anchored = true
        coin.CanCollide = false
        coin.CanTouch = false
        coin.CanQuery = false
        coin.Massless = true
        coin.Transparency = 1
        coin.CFrame = CFrame.new(from)
        coin.Parent = folder

        local trail = coin:FindFirstChildWhichIsA("Trail", true)
        if trail then
            trail.Enabled = true
        end

        local apex = from + popOffset(i, n)
        local landHoriz = from + landOffset(i, n)
        local land = groundPoint(landHoriz, from.Y, folder)
        local stagger = (i - 1) * 0.02

        task.delay(stagger, function()
            if coin.Parent == nil then
                return
            end
            -- 1) pop up
            local popTween =
                tweenTo(coin, apex, POP_SEC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            popTween.Completed:Once(function()
                if coin.Parent == nil then
                    return
                end
                -- 2) fall to ground
                local fallTween =
                    tweenTo(coin, land, FALL_SEC, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                fallTween.Completed:Once(function()
                    if coin.Parent == nil then
                        return
                    end
                    task.delay(GROUND_HOLD_SEC, function()
                        if coin.Parent == nil then
                            return
                        end
                        -- 3) fly to player
                        flyToPlayer(coin, land, to)
                    end)
                end)
            end)
        end)

        Debris:AddItem(coin, lifetime + stagger)
    end
end

return CollectCashCoinsFx
