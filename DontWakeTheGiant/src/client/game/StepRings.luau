--!strict
-- Видимый шум шагов (GDD 2.2): на каждом шаге в зоне от ног расходится кольцо,
-- чем громче шаг — тем больше и краснее. Формула шума общая с сервером (NoiseLogic).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)
local ItemsConfig = require(ReplicatedStorage.shared.data.ItemsConfig)
local NoiseLogic = require(ReplicatedStorage.shared.util.NoiseLogic)

local STEP_SEC = 0.35
local RING_SEC = 0.6
local MAX_CAMERA_DIST = 120
-- Шум шага в секунду, при котором кольцо самое большое и красное (вес 5 по монетам ≈ 13.5).
local LOUD_RATE = 8
local QUIET = Color3.fromHex("#F2F3F3")
local LOUD = Color3.fromHex("#C4281C")

local StepRings = {}

local folder: Folder
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function surfaceAt(character: Model, root: BasePart): (string?, Vector3?)
    rayParams.FilterDescendantsInstances =
        { character, workspace:FindFirstChild("Items") :: Instance, folder }
    local hit = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), rayParams)
    if not hit then
        return nil, nil
    end
    local surface = hit.Instance:GetAttribute("Surface")
    local giant = workspace:FindFirstChild("Giant")
    if typeof(surface) ~= "string" and giant and hit.Instance:IsDescendantOf(giant) then
        surface = "Body"
    end
    return if typeof(surface) == "string" then surface else nil, hit.Position
end

local function spawnRing(position: Vector3, loudness: number)
    local ring = Instance.new("Part")
    ring.Name = "StepRing"
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanQuery = false
    ring.CanTouch = false
    ring.CastShadow = false
    ring.Shape = Enum.PartType.Cylinder
    ring.Material = Enum.Material.Neon
    ring.Color = QUIET:Lerp(LOUD, loudness)
    ring.Transparency = 0.4
    ring.Size = Vector3.new(0.1, 1, 1)
    ring.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
    ring.Parent = folder
    local diameter = 2 + 10 * loudness
    TweenService
        :Create(ring, TweenInfo.new(RING_SEC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.1, diameter, diameter),
            Transparency = 1,
        })
        :Play()
    task.delay(RING_SEC, function()
        ring:Destroy()
    end)
end

local lastStep: { [Player]: number } = {}

local function update()
    local camera = workspace.CurrentCamera
    local now = os.clock()
    for _, other in Players:GetPlayers() do
        local character = other.Character
        local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not (character and root) or other:GetAttribute("Ragdolled") then
            continue
        end
        local pos = root.Position
        if Vector2.new(pos.X, pos.Z).Magnitude > GiantConfig.ZONE_RADIUS then
            continue
        end
        if camera and (camera.CFrame.Position - pos).Magnitude > MAX_CAMERA_DIST then
            continue
        end
        local v = root.AssemblyLinearVelocity
        local moving = Vector3.new(v.X, 0, v.Z).Magnitude > GiantConfig.MOVING_MIN_SPEED
        if not moving or now - (lastStep[other] or 0) < STEP_SEC then
            continue
        end
        local surface, ground = surfaceAt(character, root)
        if not ground then
            continue
        end
        lastStep[other] = now
        local itemId = other:GetAttribute("CarryingItemId")
        local def = if typeof(itemId) == "string" then ItemsConfig.BY_ID[itemId] else nil
        local rate = NoiseLogic.stepRate({
            moving = true,
            sneaking = other:GetAttribute("Sneaking") == true,
            carryWeight = if def then def.weight else 0,
            surface = surface,
        }, GiantConfig :: any, ItemsConfig.CARRY_NOISE_MULT)
        spawnRing(ground, math.clamp(rate / LOUD_RATE, 0, 1))
    end
end

function StepRings.start()
    folder = Instance.new("Folder")
    folder.Name = "StepRings"
    folder.Parent = workspace
    Players.PlayerRemoving:Connect(function(other)
        lastStep[other] = nil
    end)
    RunService.Heartbeat:Connect(update)
end

return StepRings
