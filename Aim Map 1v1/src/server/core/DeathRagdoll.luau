--!strict
-- CS-style death: Motor6D → BallSocket + knock impulse. Server-owned physics.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local RagdollLogic = require(ReplicatedStorage.shared.util.RagdollLogic)

local DeathRagdoll = {}

local function convertMotor(motor: Motor6D)
    local part0 = motor.Part0
    local part1 = motor.Part1
    if not part0 or not part1 then
        motor.Enabled = false
        return
    end

    local a0 = Instance.new("Attachment")
    a0.Name = "RagdollA0"
    a0.CFrame = motor.C0
    a0.Parent = part0

    local a1 = Instance.new("Attachment")
    a1.Name = "RagdollA1"
    a1.CFrame = motor.C1
    a1.Parent = part1

    local ball = Instance.new("BallSocketConstraint")
    ball.Name = "RagdollSocket"
    ball.Attachment0 = a0
    ball.Attachment1 = a1
    ball.LimitsEnabled = true
    ball.UpperAngle = 50
    ball.TwistLimitsEnabled = true
    ball.TwistLowerAngle = -30
    ball.TwistUpperAngle = 30
    ball.Parent = part0

    motor.Enabled = false
end

local function impulseRoot(character: Model, hitPos: Vector3?, usp: Instance?): BasePart?
    if hitPos then
        local best: BasePart? = nil
        local bestDist = math.huge
        for _, desc in character:GetDescendants() do
            if desc:IsA("BasePart") then
                if usp and desc:IsDescendantOf(usp) then
                    continue
                end
                local d = (desc.Position - hitPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = desc
                end
            end
        end
        if best then
            return best
        end
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        return hrp
    end
    return character.PrimaryPart
end

function DeathRagdoll.apply(character: Model, shotDirection: Vector3, hitPos: Vector3?)
    if character:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true then
        return
    end
    character:SetAttribute(Constants.RAGDOLL_ATTRIBUTE, true)

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = false
        humanoid.PlatformStand = true
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.BreakJointsOnDeath = false
        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end)
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in animator:GetPlayingAnimationTracks() do
                track:Stop(0)
            end
        end
    end

    for _, desc in character:GetDescendants() do
        if desc:IsA("Motor6D") then
            convertMotor(desc)
        end
    end

    local usp = character:FindFirstChild("USP")
    for _, desc in character:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.Anchored = false
            local underGun = usp ~= nil and desc:IsDescendantOf(usp)
            desc.CanCollide = not underGun
            desc.Massless = underGun
            pcall(function()
                desc:SetNetworkOwner(nil)
            end)
        end
    end

    local vx, vy, vz = RagdollLogic.knockVelocity(
        shotDirection.X,
        shotDirection.Y,
        shotDirection.Z,
        Constants.RAGDOLL_SPEED,
        Constants.RAGDOLL_UP_BIAS
    )
    local root = impulseRoot(character, hitPos, usp)
    if root then
        root.AssemblyLinearVelocity = Vector3.new(vx, vy, vz)
        local spin = Constants.RAGDOLL_SPIN
        root.AssemblyAngularVelocity = Vector3.new(
            (math.random() - 0.5) * spin,
            (math.random() - 0.5) * spin,
            (math.random() - 0.5) * spin
        )
    end
end

return DeathRagdoll
