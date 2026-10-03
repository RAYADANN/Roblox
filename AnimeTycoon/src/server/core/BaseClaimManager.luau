--!strict
-- Assign Workspace.Base1..BaseN to players (one each). Release on leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseClaimLogic = require(ReplicatedStorage.shared.util.BaseClaimLogic)
local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)

export type Deps = {
    onClaimed: ((player: Player, base: Instance) -> ())?,
    onReleased: ((player: Player, base: Instance) -> ())?,
}

export type BaseClaimManager = {
    claim: (self: BaseClaimManager, player: Player) -> (Instance?, string?),
    release: (self: BaseClaimManager, player: Player) -> (),
    getBase: (self: BaseClaimManager, player: Player) -> Instance?,
    ownsInstance: (self: BaseClaimManager, player: Player, inst: Instance?) -> boolean,
    teleportToBase: (self: BaseClaimManager, player: Player) -> (),
    start: (self: BaseClaimManager) -> (),
}

local BaseClaimManager = {}
BaseClaimManager.__index = BaseClaimManager

local function clearBaseOwner(base: Instance)
    base:SetAttribute(BaseLayout.ATTR_OWNER_USER_ID, 0)
    base:SetAttribute(BaseLayout.ATTR_OWNER_NAME, "")
end

local function setBaseOwner(base: Instance, player: Player, index: number)
    base:SetAttribute(BaseLayout.ATTR_OWNER_USER_ID, player.UserId)
    base:SetAttribute(BaseLayout.ATTR_OWNER_NAME, player.DisplayName)
    base:SetAttribute(BaseLayout.ATTR_BASE_INDEX, index)
    player:SetAttribute(BaseLayout.PLAYER_ATTR_BASE_NAME, base.Name)
end

local function spawnCFrame(base: Instance): CFrame?
    for _, d in base:GetDescendants() do
        if d:IsA("SpawnLocation") then
            return d.CFrame + Vector3.new(0, 3, 0)
        end
    end
    for _, name in { "PlayerSpawn", "Spawn", "Teleport" } do
        local hit = base:FindFirstChild(name, true)
        if hit and hit:IsA("BasePart") then
            return hit.CFrame + Vector3.new(0, 3, 0)
        end
    end
    local stands = base:FindFirstChild("Stands")
    if stands then
        local roll = stands:FindFirstChild("RollButton")
        local part = (roll and roll:FindFirstChildWhichIsA("BasePart", true))
            or stands:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.CFrame + Vector3.new(0, 4, 0)
        end
    end
    local any = base:FindFirstChildWhichIsA("BasePart", true)
    if any then
        return any.CFrame + Vector3.new(0, 4, 0)
    end
    return nil
end

function BaseClaimManager.new(deps: Deps): BaseClaimManager
    local self = setmetatable({
        _deps = deps,
        _occupied = {} :: { [number]: number },
        _basesByIndex = {} :: { [number]: Instance },
        _playerBase = {} :: { [Player]: Instance },
        _started = false,
    }, BaseClaimManager)
    return self :: any
end

function BaseClaimManager:_rebuildIndex()
    table.clear(self._basesByIndex)
    for i, base in BaseLayout.getAll() do
        self._basesByIndex[i] = base
        base:SetAttribute(BaseLayout.ATTR_BASE_INDEX, i)
        if BaseLayout.getOwnerUserId(base) == nil then
            clearBaseOwner(base)
        end
    end
end

function BaseClaimManager:getBase(player: Player): Instance?
    return self._playerBase[player]
end

function BaseClaimManager:ownsInstance(player: Player, inst: Instance?): boolean
    if inst == nil then
        return false
    end
    local base = BaseLayout.findBaseAncestor(inst)
    if not base then
        return false
    end
    return BaseLayout.isOwnedBy(base, player.UserId)
end

function BaseClaimManager:teleportToBase(player: Player)
    local base = self._playerBase[player]
    if not base then
        return
    end
    local cf = spawnCFrame(base)
    if not cf then
        return
    end
    local char = player.Character
    if not char then
        return
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        hrp.CFrame = cf
    else
        char:PivotTo(cf)
    end
end

function BaseClaimManager:claim(player: Player): (Instance?, string?)
    if self._playerBase[player] then
        return self._playerBase[player], nil
    end
    self:_rebuildIndex()
    local baseCount = 0
    for _ in self._basesByIndex do
        baseCount += 1
    end
    -- Prefer numeric length from getAll order.
    local all = BaseLayout.getAll()
    baseCount = #all
    for i, base in all do
        self._basesByIndex[i] = base
    end

    local index = BaseClaimLogic.pickFreeIndex(self._occupied, baseCount)
    if index == nil then
        return nil, "no_free_base"
    end
    local base = self._basesByIndex[index]
    if not base then
        return nil, "no_free_base"
    end

    self._occupied[index] = player.UserId
    self._playerBase[player] = base
    setBaseOwner(base, player, index)

    local deps = self._deps
    if deps.onClaimed then
        deps.onClaimed(player, base)
    end
    return base, nil
end

function BaseClaimManager:release(player: Player)
    local base = self._playerBase[player]
    self._playerBase[player] = nil
    player:SetAttribute(BaseLayout.PLAYER_ATTR_BASE_NAME, "")
    BaseClaimLogic.releaseUser(self._occupied, player.UserId)
    if base then
        clearBaseOwner(base)
        local deps = self._deps
        if deps.onReleased then
            deps.onReleased(player, base)
        end
    end
end

function BaseClaimManager:start()
    if self._started then
        return
    end
    self._started = true
    self:_rebuildIndex()
    for _, base in BaseLayout.getAll() do
        clearBaseOwner(base)
    end

    local function onCharacter(player: Player)
        task.defer(function()
            if self._playerBase[player] then
                self:teleportToBase(player)
            end
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        local base, err = self:claim(player)
        if not base then
            warn(`[BaseClaimManager] claim failed for {player.Name}: {err}`)
            player:Kick("Server is full (no free bases).")
            return
        end
        player.CharacterAdded:Connect(function()
            onCharacter(player)
        end)
        if player.Character then
            onCharacter(player)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:release(player)
    end)

    for _, player in Players:GetPlayers() do
        local base, err = self:claim(player)
        if not base then
            warn(`[BaseClaimManager] claim failed for {player.Name}: {err}`)
            player:Kick("Server is full (no free bases).")
        else
            player.CharacterAdded:Connect(function()
                onCharacter(player)
            end)
            if player.Character then
                onCharacter(player)
            end
        end
    end
end

return BaseClaimManager
