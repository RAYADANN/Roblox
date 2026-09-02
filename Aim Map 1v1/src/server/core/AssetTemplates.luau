--!strict
-- Studio Workspace templates → ServerStorage clones (R15 body + USP-S Main gun).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local UspVisualLogic = require(ReplicatedStorage.shared.util.UspVisualLogic)

local AssetTemplates = {}

local FOLDER_NAME = "AimMapAssets"
local R15_CANDIDATES = { "R15 Dummy", "R15Dummy", "R15" }
-- Live visual: USP-S Main (Studio sometimes typed UPS-S Main). Not USP-S Default.
local USP_MAIN_CANDIDATES = { "USP-S Main", "UPS-S Main" }
local GUN_STASH_NAME = "USPMain_WorldStash"
-- IDs live in SoundDatabase; stash Workspace copies so they aren't loose props in Play.
local COMBAT_SOUND_NAMES =
    { "usp-s_fire", "cs-go-headshot-sound", "Bodyshot", "VALORANT: Kill", "Dead", "Footstep" }

-- Keep UPS-S Main + USPGrip on the dummy (animation authored against that weld).
local STRIP_NAMES = { "AnimSaves" }

local _rig: Model?
local _gun: Model?
local _ensured = false

local function findModel(parent: Instance, names: { string }): Model?
    for _, name in names do
        local child = parent:FindFirstChild(name)
        if child and child:IsA("Model") then
            return child
        end
    end
    return nil
end

local function findEquippedGun(character: Model): Model?
    return findModel(character, { "USP", "USP-S Main", "UPS-S Main" })
end

-- Studio dummy rest is C0 ≈ (0, -1, 0), C1 identity. Code used to overwrite that.
local function gripWasCodeRetargeted(rig: Model): boolean
    local grip = rig:FindFirstChild("USPGrip", true)
    if not grip or not grip:IsA("Motor6D") then
        return true
    end
    return grip.C1.Position.Magnitude > 0.2
end

local function findUspMain(worldR15: Model?, folder: Instance?): Model?
    -- Authored muzzle is Handle.Shoot on the dummy gun. Loose Workspace USP has a guessed tip.
    if worldR15 then
        local dummyGun = findModel(worldR15, USP_MAIN_CANDIDATES)
        if dummyGun and UspVisualLogic.hasAuthoredShoot(dummyGun) then
            return dummyGun
        end
    end
    local world = findModel(workspace, USP_MAIN_CANDIDATES)
    if world and UspVisualLogic.hasAuthoredShoot(world) then
        return world
    end
    if folder then
        local stash = folder:FindFirstChild(GUN_STASH_NAME)
        if stash and stash:IsA("Model") and UspVisualLogic.hasAuthoredShoot(stash) then
            return stash
        end
    end
    if world then
        return world
    end
    if worldR15 then
        return findModel(worldR15, USP_MAIN_CANDIDATES)
    end
    return nil
end

local function stripScripts(root: Instance)
    for _, desc in root:GetDescendants() do
        if desc:IsA("Script") or desc:IsA("LocalScript") then
            desc:Destroy()
        end
    end
end

local function stripEditExtras(model: Model)
    for _, name in STRIP_NAMES do
        local inst = model:FindFirstChild(name)
        if inst then
            inst:Destroy()
        end
    end
end

local function isMassPart(name: string): boolean
    return name == "HumanoidRootPart" or name == "UpperTorso" or name == "LowerTorso"
end

local function prepareRigTemplate(model: Model)
    stripEditExtras(model)
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        model.PrimaryPart = hrp
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.RigType = Enum.HumanoidRigType.R15
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        humanoid.AutoRotate = false
        if not humanoid:FindFirstChildOfClass("Animator") then
            local animator = Instance.new("Animator")
            animator.Parent = humanoid
        end
    end
    for _, desc in model:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.Anchored = false
            desc.Massless = not isMassPart(desc.Name)
        end
    end
    -- Dummy often ships with its own USP; live equip always uses USPMain clone.
    local embedded = findModel(model, USP_MAIN_CANDIDATES)
    if embedded then
        embedded:Destroy()
    end
    stripScripts(model)
end

local function prepareGunTemplate(model: Model)
    stripScripts(model)
    local handle = model:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        warn("[AssetTemplates] USP-S Main Handle missing on gun template")
        return
    end
    -- Weld while still in Studio rest pose so Shoot keeps the authored muzzle offset.
    if not UspVisualLogic.assembleGunToHandle(model) then
        return
    end
    UspVisualLogic.prepareMuzzleParts(model)
    model.PrimaryPart = handle
    for _, desc in model:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.Anchored = false
            desc.CanCollide = false
            desc.CanQuery = false
            desc.CanTouch = false
            desc.Massless = true
        end
    end
end

local function stashWorldTemplate(inst: Instance?, folder: Instance, stashName: string)
    if not inst then
        return
    end
    local old = folder:FindFirstChild(stashName)
    if old and old ~= inst then
        old:Destroy()
    end
    inst.Name = stashName
    inst.Parent = folder
end

local function hideWorldTemplate(inst: Instance?)
    if inst and inst.Parent == workspace then
        inst.Parent = nil
    end
end

function AssetTemplates.ensure(): boolean
    if _ensured then
        return _rig ~= nil and _gun ~= nil
    end
    _ensured = true

    local folder = ServerStorage:FindFirstChild(FOLDER_NAME)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = FOLDER_NAME
        folder.Parent = ServerStorage
    end

    for _, soundName in COMBAT_SOUND_NAMES do
        local sound = workspace:FindFirstChild(soundName)
        if sound and sound:IsA("Sound") then
            sound.Playing = false
            sound.Parent = folder
        end
    end

    local cachedRig = folder:FindFirstChild("R15Dummy")
    local cachedGun = folder:FindFirstChild("USPMain")
    local legacyGun = folder:FindFirstChild("USP")
    if legacyGun then
        legacyGun:Destroy()
    end
    -- Rebuild if cache lost USPGrip or still has code-rewritten C0/C1.
    if cachedRig and cachedRig:IsA("Model") and gripWasCodeRetargeted(cachedRig) then
        cachedRig:Destroy()
        cachedRig = nil
    end
    -- Always rebuild gun cache if authored Handle.Shoot is missing (sibling Shoot is a guessed tip).
    if cachedGun and cachedGun:IsA("Model") and not UspVisualLogic.hasAuthoredShoot(cachedGun) then
        cachedGun:Destroy()
        cachedGun = nil
    end
    local badStash = folder:FindFirstChild(GUN_STASH_NAME)
    if badStash and badStash:IsA("Model") and not UspVisualLogic.hasAuthoredShoot(badStash) then
        badStash:Destroy()
    end
    if cachedRig and cachedRig:IsA("Model") and cachedGun and cachedGun:IsA("Model") then
        _rig = cachedRig
        _gun = cachedGun
        return true
    end

    local worldR15 = findModel(workspace, R15_CANDIDATES)
    local worldGun = findUspMain(worldR15, folder)
    if not worldR15 or not worldGun then
        warn("[AssetTemplates] Need Workspace 'R15 Dummy' and 'USP-S Main' (or 'UPS-S Main')")
        return false
    end

    local staleR6 = folder:FindFirstChild("R6Dummy")
    if staleR6 then
        staleR6:Destroy()
    end
    if cachedRig then
        cachedRig:Destroy()
    end
    if cachedGun then
        cachedGun:Destroy()
    end

    local gunSourceParent = worldGun.Parent
    local gun = worldGun:Clone()
    gun.Name = "USPMain"
    prepareGunTemplate(gun)
    gun.Parent = folder
    _gun = gun

    local rig = worldR15:Clone()
    rig.Name = "R15Dummy"
    prepareRigTemplate(rig)
    rig.Parent = folder
    _rig = rig

    -- Stash only a loose workspace gun. Dummy-embedded stays on the dummy until hide.
    if
        gunSourceParent == workspace
        or (worldGun.Parent == folder and worldGun.Name ~= GUN_STASH_NAME)
    then
        stashWorldTemplate(worldGun, folder, GUN_STASH_NAME)
    end
    hideWorldTemplate(worldR15)
    hideWorldTemplate(findModel(workspace, USP_MAIN_CANDIDATES))
    hideWorldTemplate(findModel(workspace, { "USP-S Default", "USP-S" }))
    hideWorldTemplate(findModel(workspace, { "R6 [Dummy]", "R6Dummy", "R6" }))

    return true
end

function AssetTemplates.hasTemplates(): boolean
    return AssetTemplates.ensure()
end

function AssetTemplates.cloneR15(name: string?): Model
    assert(AssetTemplates.ensure() and _rig, "R15 template missing")
    local model = _rig:Clone()
    model.Name = name or "R15"
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        model.PrimaryPart = hrp
    end
    return model
end

function AssetTemplates.cloneUspGun(): Model
    assert(AssetTemplates.ensure() and _gun, "USP-S Main template missing")
    local gun = _gun:Clone()
    -- Character child name stays USP for FP visibility / WorldMuzzle.
    gun.Name = "USP"
    UspVisualLogic.assembleGunToHandle(gun)
    UspVisualLogic.prepareMuzzleParts(gun)
    return gun
end

local function gripPart(character: Model): BasePart?
    local hand = character:FindFirstChild("RightHand")
    if hand and hand:IsA("BasePart") then
        return hand
    end
    local arm = character:FindFirstChild("Right Arm")
    if arm and arm:IsA("BasePart") then
        return arm
    end
    return nil
end

--- Copy Studio dummy USPGrip. Fallback only if the dummy weld is missing.
local function studioGripCFrames(): (CFrame, CFrame)
    if _rig then
        local src = _rig:FindFirstChild("USPGrip", true)
        if src and src:IsA("Motor6D") then
            return src.C0, src.C1
        end
    end
    return CFrame.new(0, -1, 0), CFrame.new()
end

local function studioGripParent(character: Model, hand: BasePart): Instance
    if _rig then
        local src = _rig:FindFirstChild("USPGrip", true)
        if src and src.Parent then
            local named = character:FindFirstChild(src.Parent.Name)
            if named then
                return named
            end
        end
    end
    return hand
end

function AssetTemplates.stripUsp(character: Model)
    local gun = findEquippedGun(character)
    if gun then
        gun:Destroy()
    end
    for _, desc in character:GetDescendants() do
        if desc:IsA("Motor6D") and desc.Name == "USPGrip" then
            desc:Destroy()
        end
    end
end

function AssetTemplates.equipUsp(character: Model)
    if not AssetTemplates.ensure() then
        return
    end

    -- Always equip from USPMain (Shoot welded in rest pose). Dummy-embedded guns drift.
    AssetTemplates.stripUsp(character)

    local hand = gripPart(character)
    if not hand then
        return
    end

    local gun = AssetTemplates.cloneUspGun()
    local handle = gun:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        gun:Destroy()
        warn("[AssetTemplates] USP-S Main Handle missing")
        return
    end

    for _, desc in gun:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.Anchored = false
            desc.CanCollide = false
            desc.CanQuery = false
            desc.CanTouch = false
            desc.Massless = true
        end
    end

    gun.Parent = character

    local c0, c1 = studioGripCFrames()
    local weld = Instance.new("Motor6D")
    weld.Name = "USPGrip"
    weld.Part0 = hand
    weld.Part1 = handle
    weld.C0 = c0
    weld.C1 = c1
    weld.Parent = studioGripParent(character, hand)
end

return AssetTemplates
