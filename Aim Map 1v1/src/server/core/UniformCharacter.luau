--!strict
-- Every player gets the same R15 Dummy body + welded USP visual (fair hitboxes).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetTemplates = require(script.Parent.AssetTemplates)
local Constants = require(ReplicatedStorage.shared.data.Constants)

local UniformCharacter = {}

local ATTR = Constants.UNIFORM_RIG_ATTRIBUTE

local function configurePlayerHumanoid(humanoid: Humanoid)
    humanoid.RigType = Enum.HumanoidRigType.R15
    humanoid.MaxHealth = Constants.MATCH_PLAYER_HP
    humanoid.Health = Constants.MATCH_PLAYER_HP
    humanoid.BreakJointsOnDeath = false
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    humanoid.PlatformStand = false
    humanoid.AutoRotate = false
end

local function buildUniformRig(name: string): Model
    local rig = AssetTemplates.cloneR15(name)
    rig:SetAttribute(ATTR, true)

    local humanoid = rig:FindFirstChildOfClass("Humanoid")
    if humanoid then
        configurePlayerHumanoid(humanoid)
    end

    for _, desc in rig:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.Anchored = false
        end
    end
    return rig
end

local function parentAsCharacter(player: Player, rig: Model, pivot: CFrame)
    local old = player.Character
    rig.Parent = workspace
    AssetTemplates.equipUsp(rig)
    player.Character = rig
    rig:PivotTo(pivot)
    if old and old ~= rig then
        pcall(function()
            old:Destroy()
        end)
    end
end

--- Fresh dummy at `pivot`. Do not LoadCharacter after ragdoll: Roblox will not
--- reliably replace a custom `player.Character` dummy, so the round never starts.
function UniformCharacter.respawnAt(player: Player, pivot: CFrame): Model?
    if not AssetTemplates.hasTemplates() then
        player:LoadCharacter()
        local character = UniformCharacter.waitReady(player, 8)
        if character then
            character:PivotTo(pivot)
        end
        return character
    end

    local rig = buildUniformRig(player.Name)
    parentAsCharacter(player, rig, pivot)
    return rig
end

local function replaceWithUniformRig(player: Player, oldCharacter: Model)
    if not AssetTemplates.hasTemplates() then
        return
    end
    local pivot = oldCharacter:GetPivot()
    local rig = buildUniformRig(player.Name)
    parentAsCharacter(player, rig, pivot)
end

local function onCharacterAdded(player: Player, character: Model)
    if character:GetAttribute(ATTR) == true then
        AssetTemplates.equipUsp(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            configurePlayerHumanoid(humanoid)
        end
        return
    end

    -- Defer so default avatar finishes parenting before we swap.
    task.defer(function()
        if player.Character ~= character or not character.Parent then
            return
        end
        replaceWithUniformRig(player, character)
    end)
end

local function hookDeathRespawn(player: Player, character: Model)
    task.spawn(function()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            local child = character:WaitForChild("Humanoid", 5)
            if child and child:IsA("Humanoid") then
                humanoid = child
            end
        end
        if not humanoid then
            return
        end
        humanoid.Died:Connect(function()
            -- Match round reset runs at ROUND_RESET_DELAY_SEC. This is only for
            -- lobby/void deaths where MatchManager never respawns.
            task.delay(Constants.ROUND_RESET_DELAY_SEC + 2, function()
                if player.Parent == nil then
                    return
                end
                if player.Character == character then
                    UniformCharacter.respawnAt(player, character:GetPivot())
                end
            end)
        end)
    end)
end

--- Wait until the uniform (non-ragdoll) body exists. LoadCharacter first yields the
--- default avatar, which UniformCharacter immediately destroys — callers must not
--- teleport/heal that doomed rig, and must not CharacterAdded:Wait() forever.
function UniformCharacter.waitReady(player: Player, timeoutSec: number): Model?
    local needUniform = AssetTemplates.hasTemplates()
    local deadline = os.clock() + math.max(timeoutSec, 0)
    while os.clock() < deadline do
        if player.Parent == nil then
            return nil
        end
        local character = player.Character
        if character and character.Parent then
            local ragdolled = character:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true
            local uniform = character:GetAttribute(ATTR) == true
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local bodyOk = not ragdolled and humanoid ~= nil and humanoid.Health > 0
            if bodyOk and (uniform or not needUniform) then
                return character
            end
        end
        task.wait()
    end
    return player.Character
end

function UniformCharacter.start()
    if not AssetTemplates.ensure() then
        warn("[UniformCharacter] Templates missing — keeping default avatars")
        return
    end

    -- MatchManager owns round respawn. Default auto-load (~5s after Died) races
    -- a custom dummy Character and can leave the duel without a playable body.
    Players.CharacterAutoLoads = false

    local function bind(player: Player)
        player.CharacterAdded:Connect(function(character)
            onCharacterAdded(player, character)
            hookDeathRespawn(player, character)
        end)
        if player.Character then
            onCharacterAdded(player, player.Character)
            hookDeathRespawn(player, player.Character)
        else
            player:LoadCharacter()
        end
    end

    Players.PlayerAdded:Connect(bind)
    for _, player in Players:GetPlayers() do
        bind(player)
    end
end

return UniformCharacter
