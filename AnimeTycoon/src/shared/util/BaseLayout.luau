--!strict
-- Resolve player plot roots: Workspace.Base1..Base6 (or Bases/* / legacy Base).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BaseLayout = {}

BaseLayout.ATTR_OWNER_USER_ID = "OwnerUserId"
BaseLayout.ATTR_OWNER_NAME = "OwnerName"
BaseLayout.ATTR_BASE_INDEX = "BaseIndex"
BaseLayout.PLAYER_ATTR_BASE_NAME = "BaseName"

local function looksLikeBase(inst: Instance): boolean
    return inst:FindFirstChild("Stands") ~= nil and inst:FindFirstChild("Ramp") ~= nil
end

local function isBaseName(name: string): boolean
    if name == "Base" then
        return true
    end
    return string.match(name, "^Base%d+$") ~= nil
end

--- All plot folders currently in Workspace (ordered by name).
function BaseLayout.getAll(): { Instance }
    local out: { Instance } = {}
    local basesFolder = Workspace:FindFirstChild("Bases")
    if basesFolder then
        for _, child in basesFolder:GetChildren() do
            if looksLikeBase(child) then
                table.insert(out, child)
            end
        end
    end
    for _, child in Workspace:GetChildren() do
        if isBaseName(child.Name) and looksLikeBase(child) then
            table.insert(out, child)
        end
    end
    table.sort(out, function(a, b)
        return a.Name < b.Name
    end)
    return out
end

function BaseLayout.getOwnerUserId(base: Instance?): number?
    if not base then
        return nil
    end
    local raw = base:GetAttribute(BaseLayout.ATTR_OWNER_USER_ID)
    if typeof(raw) == "number" and raw > 0 then
        return raw
    end
    return nil
end

function BaseLayout.getForUserId(userId: number): Instance?
    if userId <= 0 then
        return nil
    end
    for _, base in BaseLayout.getAll() do
        if BaseLayout.getOwnerUserId(base) == userId then
            return base
        end
    end
    -- Fallback: Player.BaseName (replicates with the player even if base attr lags).
    for _, player in Players:GetPlayers() do
        if player.UserId == userId then
            local byAttr = player:GetAttribute(BaseLayout.PLAYER_ATTR_BASE_NAME)
            if typeof(byAttr) == "string" and byAttr ~= "" then
                local named = Workspace:FindFirstChild(byAttr)
                if named and looksLikeBase(named) then
                    return named
                end
                local folder = Workspace:FindFirstChild("Bases")
                if folder then
                    local nested = folder:FindFirstChild(byAttr)
                    if nested and looksLikeBase(nested) then
                        return nested
                    end
                end
            end
            break
        end
    end
    return nil
end

--- Climb ancestors until a plot folder (Stands+Ramp) is found.
function BaseLayout.findBaseAncestor(inst: Instance?): Instance?
    local cur: Instance? = inst
    while cur and cur ~= Workspace do
        if looksLikeBase(cur) and isBaseName(cur.Name) then
            return cur
        end
        -- Also allow Bases/* children that look like bases even if not BaseN named.
        if looksLikeBase(cur) and cur.Parent ~= nil and cur.Parent.Name == "Bases" then
            return cur
        end
        cur = cur.Parent
    end
    return nil
end

function BaseLayout.isOwnedBy(base: Instance?, userId: number): boolean
    local owner = BaseLayout.getOwnerUserId(base)
    return owner ~= nil and owner == userId
end

--- LocalPlayer's claimed base (client). Nil until claim attribute lands.
function BaseLayout.getLocal(): Instance?
    local player = Players.LocalPlayer
    if player == nil then
        return nil
    end
    local byAttr = player:GetAttribute(BaseLayout.PLAYER_ATTR_BASE_NAME)
    if typeof(byAttr) == "string" and byAttr ~= "" then
        local named = Workspace:FindFirstChild(byAttr)
        if named and looksLikeBase(named) then
            return named
        end
        local folder = Workspace:FindFirstChild("Bases")
        if folder then
            local nested = folder:FindFirstChild(byAttr)
            if nested and looksLikeBase(nested) then
                return nested
            end
        end
    end
    return BaseLayout.getForUserId(player.UserId)
end

--- Preferred plot: local claim (client) → Base → Base1 → first discovered.
function BaseLayout.getPrimary(): Instance?
    if RunService:IsClient() then
        local localBase = BaseLayout.getLocal()
        if localBase then
            return localBase
        end
    end
    local named = Workspace:FindFirstChild("Base")
    if named and looksLikeBase(named) then
        return named
    end
    local base1 = Workspace:FindFirstChild("Base1")
    if base1 and looksLikeBase(base1) then
        return base1
    end
    local all = BaseLayout.getAll()
    if #all > 0 then
        return all[1]
    end
    return nil
end

function BaseLayout.getStands(base: Instance?): Instance?
    local root = base or BaseLayout.getPrimary()
    if root then
        local stands = root:FindFirstChild("Stands")
        if stands then
            return stands
        end
    end
    return Workspace:FindFirstChild("Stands")
end

function BaseLayout.getRamp(base: Instance?): Instance?
    local root = base or BaseLayout.getPrimary()
    if root then
        local ramp = root:FindFirstChild("Ramp")
        if ramp then
            return ramp
        end
    end
    return Workspace:FindFirstChild("Ramp")
end

function BaseLayout.getSellBox(base: Instance?): Instance?
    local root = base or BaseLayout.getPrimary()
    if root then
        local sell = root:FindFirstChild("SellBox")
        if sell then
            return sell
        end
    end
    return Workspace:FindFirstChild("SellBox")
end

function BaseLayout.getSellGuy(base: Instance?): Instance?
    local root = base or BaseLayout.getPrimary()
    if root then
        local guy = root:FindFirstChild("SellGuy")
        if guy then
            return guy
        end
    end
    return Workspace:FindFirstChild("SellGuy")
end

function BaseLayout.getSellTable(base: Instance?): Instance?
    local root = base or BaseLayout.getPrimary()
    if root then
        local t = root:FindFirstChild("SellTable")
        if t then
            return t
        end
    end
    return Workspace:FindFirstChild("SellTable")
end

function BaseLayout.getLimited(base: Instance?): Instance?
    local root = base or BaseLayout.getPrimary()
    if root then
        local limited = root:FindFirstChild("Limited")
        if limited then
            return limited
        end
    end
    return Workspace:FindFirstChild("Limited")
end

return BaseLayout
