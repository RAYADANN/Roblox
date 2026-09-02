--!strict
-- Solo aim targets: static R15 dummies you can shoot/kill while waiting for a duel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArenaBootstrap = require(script.Parent.ArenaBootstrap)
local AssetTemplates = require(script.Parent.AssetTemplates)
local Constants = require(ReplicatedStorage.shared.data.Constants)

export type PracticeDummyManager = {
    start: (self: PracticeDummyManager) -> (),
    isDummy: (self: PracticeDummyManager, model: Model) -> boolean,
    onKilled: (self: PracticeDummyManager, model: Model) -> (),
}

local PracticeDummyManager = {}
PracticeDummyManager.__index = PracticeDummyManager

local FOLDER_NAME = "PracticeDummies"

local function buildDummy(parent: Instance, cframe: CFrame, index: number): Model
    assert(AssetTemplates.hasTemplates(), "R15 template required for practice dummies")
    local model = AssetTemplates.cloneR15(`Dummy_{index}`)
    model:SetAttribute(Constants.PRACTICE_DUMMY_ATTRIBUTE, true)
    model:SetAttribute(Constants.UNIFORM_RIG_ATTRIBUTE, true)

    local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
    humanoid.RigType = Enum.HumanoidRigType.R15
    humanoid.MaxHealth = Constants.PRACTICE_DUMMY_HP
    humanoid.Health = Constants.PRACTICE_DUMMY_HP
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.BreakJointsOnDeath = false

    local root = model.PrimaryPart :: BasePart
    for _, desc in model:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.Anchored = desc == root
            if desc ~= root then
                desc.Massless = true
            end
        end
    end
    root.Anchored = true

    model.Parent = parent
    model:PivotTo(cframe)
    AssetTemplates.stripUsp(model)
    return model
end

function PracticeDummyManager.new(): PracticeDummyManager
    return setmetatable({
        _folder = nil :: Folder?,
        _slots = {} :: { CFrame },
        _respawning = {} :: { [Model]: boolean },
    }, PracticeDummyManager) :: any
end

function PracticeDummyManager:isDummy(model: Model): boolean
    return model:GetAttribute(Constants.PRACTICE_DUMMY_ATTRIBUTE) == true
end

function PracticeDummyManager:_spawnAt(index: number, cf: CFrame)
    local folder = self._folder
    if not folder then
        return
    end
    buildDummy(folder, cf, index)
end

function PracticeDummyManager:onKilled(model: Model)
    if not self:isDummy(model) then
        return
    end
    if self._respawning[model] then
        return
    end
    self._respawning[model] = true

    local index = tonumber(string.match(model.Name, "%d+")) or 1
    local cf = self._slots[index] or (model.PrimaryPart and model.PrimaryPart.CFrame)
    if not cf then
        model:Destroy()
        self._respawning[model] = nil
        return
    end

    -- Ragdoll already applied by WeaponFireManager; leave corpse, then respawn.
    task.delay(Constants.PRACTICE_DUMMY_RESPAWN_SEC, function()
        if model.Parent then
            model:Destroy()
        end
        self._respawning[model] = nil
        self:_spawnAt(index, cf)
    end)
end

function PracticeDummyManager:start()
    local spawns = ArenaBootstrap.ensure()
    local folder = workspace:FindFirstChild(FOLDER_NAME)
    if folder and folder:IsA("Folder") then
        folder:ClearAllChildren()
    else
        folder = Instance.new("Folder")
        folder.Name = FOLDER_NAME
        folder.Parent = workspace
    end
    self._folder = folder

    if not AssetTemplates.hasTemplates() then
        warn("[PracticeDummyManager] R15 template missing — no practice dummies")
        return
    end

    -- Line of targets facing spawn A (solo player stands at A).
    local mid = spawns.spawnA.Position:Lerp(spawns.spawnB.Position, 0.55)
    local look = CFrame.lookAt(mid, spawns.spawnA.Position)
    local count = Constants.PRACTICE_DUMMY_COUNT
    self._slots = {}
    for i = 1, count do
        local lateral = (i - (count + 1) / 2) * 6
        local cf = look * CFrame.new(lateral, 0, 0) + Vector3.new(0, 3, 0)
        -- stand upright facing A
        cf = CFrame.lookAt(
            cf.Position,
            Vector3.new(spawns.spawnA.Position.X, cf.Position.Y, spawns.spawnA.Position.Z)
        )
        self._slots[i] = cf
        self:_spawnAt(i, cf)
    end
end

return PracticeDummyManager
