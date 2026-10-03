--!strict
-- Guide beam: clone Workspace.Attach.Attachment (+Beam) on player; Attachment on target mesh.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local TutorialBeam = {}

local _playerAtt: Attachment? = nil
local _targetAtt: Attachment? = nil
local _beam: Beam? = nil
local _charConn: RBXScriptConnection? = nil
local _target: Instance? = nil
local _visible = true

local function templateAttachment(): Attachment?
    local folder = Workspace:FindFirstChild("Attach")
    if not folder then
        return nil
    end
    local att = folder:FindFirstChild("Attachment")
    if att and att:IsA("Attachment") then
        return att
    end
    return nil
end

--- Exact MeshPart if provided; else largest MeshPart under Model.
local function resolveAttachHost(target: Instance): BasePart?
    if target:IsA("MeshPart") then
        return target
    end
    if target:IsA("BasePart") then
        return target
    end
    local best: BasePart? = nil
    local bestScore = -1
    for _, d in target:GetDescendants() do
        if d:IsA("BasePart") then
            local vol = d.Size.X * d.Size.Y * d.Size.Z
            local score = if d:IsA("MeshPart") then vol * 10 else vol
            if score > bestScore then
                bestScore = score
                best = d
            end
        end
    end
    if best then
        return best
    end
    if target:IsA("Model") then
        return target.PrimaryPart
    end
    return nil
end

local function clearInstances()
    if _beam then
        _beam:Destroy()
        _beam = nil
    end
    if _playerAtt then
        _playerAtt:Destroy()
        _playerAtt = nil
    end
    if _targetAtt then
        _targetAtt:Destroy()
        _targetAtt = nil
    end
end

local function hrpOf(character: Model?): BasePart?
    if not character then
        return nil
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        return hrp
    end
    return nil
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
    local hrp = hrpOf(player and player.Character)
    if hrp == nil then
        return
    end
    local template = templateAttachment()
    if template == nil then
        warn("[TutorialBeam] Workspace.Attach.Attachment missing")
        return
    end

    local host = resolveAttachHost(target)
    if host == nil then
        return
    end

    local playerAtt = template:Clone()
    playerAtt.Name = "TutorialPlayerAttach"
    playerAtt.Parent = hrp
    playerAtt.Position = Vector3.new(0, 1.2, 0)
    _playerAtt = playerAtt

    local beam = playerAtt:FindFirstChildWhichIsA("Beam")
    if beam == nil then
        warn("[TutorialBeam] Beam missing on Attach template")
        playerAtt:Destroy()
        _playerAtt = nil
        return
    end
    _beam = beam

    local targetAtt = Instance.new("Attachment")
    targetAtt.Name = "TutorialTargetAttach"
    targetAtt.Position = Vector3.zero
    targetAtt.Parent = host
    _targetAtt = targetAtt

    -- Attachment0 = target, Attachment1 = player (arrows toward object).
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
    if _beam then
        _beam.Enabled = visible
    end
    if not visible then
        return
    end
    if _playerAtt == nil then
        wire()
    end
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
    clearInstances()
end

return TutorialBeam
