--!strict
-- Guide beam. Prefers Workspace.Attach.Attachment (authored Beam). Falls back to a plain Beam.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local TutorialBeam = {}

local _playerAtt: Attachment? = nil
local _targetAtt: Attachment? = nil
local _beam: Beam? = nil
local _charConn: RBXScriptConnection? = nil
local _target: Instance? = nil
local _visible = true

local function hrpOf(character: Model?): BasePart?
    if character == nil then
        return nil
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        return hrp
    end
    return nil
end

local function resolveHost(target: Instance): BasePart?
    if target:IsA("BasePart") then
        return target
    end
    if target:IsA("Model") then
        return target.PrimaryPart
    end
    return nil
end

local function templateAttachment(): Attachment?
    local folder = Workspace:FindFirstChild("Attach")
    if folder == nil then
        return nil
    end
    local att = folder:FindFirstChild("Attachment")
    if att and att:IsA("Attachment") then
        return att
    end
    return nil
end

local function clearInstances()
    if _beam and _beam.Parent ~= _playerAtt then
        _beam:Destroy()
    end
    _beam = nil
    if _playerAtt then
        _playerAtt:Destroy()
        _playerAtt = nil
    end
    if _targetAtt then
        _targetAtt:Destroy()
        _targetAtt = nil
    end
end

local function makeFallback(playerAtt: Attachment): Beam
    local beam = Instance.new("Beam")
    beam.Name = "TutorialBeam"
    beam.FaceCamera = true
    beam.Width0 = 0.35
    beam.Width1 = 0.15
    beam.LightEmission = 0.4
    beam.Parent = playerAtt
    return beam
end

local function wire()
    clearInstances()
    if not _visible then
        return
    end
    local target = _target
    if target == nil or target.Parent == nil then
        return
    end
    local player = Players.LocalPlayer
    local hrp = hrpOf(if player then player.Character else nil)
    local host = resolveHost(target)
    if hrp == nil or host == nil then
        return
    end

    local template = templateAttachment()
    local playerAtt = if template then template:Clone() else Instance.new("Attachment")
    playerAtt.Name = "TutorialPlayerAttach"
    playerAtt.Position = Vector3.new(0, 1.2, 0)
    playerAtt.Parent = hrp
    _playerAtt = playerAtt

    local beam = playerAtt:FindFirstChildWhichIsA("Beam")
    if beam == nil then
        beam = makeFallback(playerAtt)
    end
    _beam = beam

    local targetAtt = Instance.new("Attachment")
    targetAtt.Name = "TutorialTargetAttach"
    targetAtt.Parent = host
    _targetAtt = targetAtt

    beam.Attachment0 = targetAtt
    beam.Attachment1 = playerAtt
    beam.Enabled = true
end

function TutorialBeam.setTarget(target: Instance?)
    _target = target
    wire()
end

function TutorialBeam.setVisible(visible: boolean)
    _visible = visible
    if not visible then
        clearInstances()
        return
    end
    wire()
end

function TutorialBeam.start()
    local player = Players.LocalPlayer
    if _charConn == nil and player then
        _charConn = player.CharacterAdded:Connect(function()
            task.defer(wire)
        end)
    end
    wire()
end

function TutorialBeam.stop()
    if _charConn then
        _charConn:Disconnect()
        _charConn = nil
    end
    _target = nil
    _visible = false
    clearInstances()
end

return TutorialBeam
