--!strict
-- Swap Stand1..5 mesh for Pad Upgrade tiers (Stand2LVL..Stand4LVL).
-- Keeps authored BoxPlace for Buy prompts; templates have no BoxPlace.
-- Hold tier keeps old look until PadTierCutscene swaps.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local ContentRoots = require(ReplicatedStorage.shared.util.ContentRoots)
local StandUnlockVisual = require(script.Parent.StandUnlockVisual)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)

local VISUAL_NAME = "PadTierVisual"

local StandPadTierVisual = {}

local _appliedTier: { [number]: number } = {}
local _lastUpgrades: { [string]: number }? = nil
--- If set, visuals stay at this tier until clearHold (cutscene pending).
local _holdAtTier: number? = nil

local function templateFolder(): Instance?
    return ContentRoots.stands()
end

local function templateNameForTier(tier: number): string?
    if tier <= 0 then
        return nil
    end
    local names = { "Stand2LVL", "Stand3LVL", "Stand4LVL" }
    return names[math.clamp(tier, 1, 3)]
end

local function setAuthoredMeshesHidden(stand: Instance, hidden: boolean)
    for _, child in stand:GetChildren() do
        if child.Name == "BoxPlace" or child.Name == "EggPlace" or child.Name == VISUAL_NAME then
            continue
        end
        if child:IsA("BasePart") then
            child.LocalTransparencyModifier = if hidden then 1 else 0
            if hidden then
                child.CanCollide = false
                child.CanQuery = false
                child.CanTouch = false
            end
        elseif child:IsA("Model") or child:IsA("Folder") then
            for _, d in child:GetDescendants() do
                if d:IsA("BasePart") then
                    d.LocalTransparencyModifier = if hidden then 1 else 0
                    if hidden then
                        d.CanCollide = false
                        d.CanQuery = false
                        d.CanTouch = false
                    end
                end
            end
        end
    end
end

local function clearVisual(stand: Instance)
    local existing = stand:FindFirstChild(VISUAL_NAME)
    if existing then
        existing:Destroy()
    end
end

local function placeVisual(stand: Model, templateName: string): boolean
    local folder = templateFolder()
    if not folder then
        return false
    end
    local template = folder:FindFirstChild(templateName)
    if not template or not template:IsA("Model") then
        return false
    end
    clearVisual(stand)
    local clone = template:Clone()
    clone.Name = VISUAL_NAME
    for _, d in clone:GetDescendants() do
        if d:IsA("ProximityPrompt") then
            d:Destroy()
        end
    end
    clone.Parent = stand
    clone:PivotTo(stand:GetPivot())
    for _, d in clone:GetDescendants() do
        if d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.CanQuery = false
            d.CanTouch = false
            d.LocalTransparencyModifier = 0
        end
    end
    setAuthoredMeshesHidden(stand, true)
    return true
end

local function restoreAuthored(stand: Instance)
    clearVisual(stand)
    setAuthoredMeshesHidden(stand, false)
end

local function applyVisualTier(upgrades: { [string]: number }?, visualTier: number)
    local stands = BaseLayout.getStands()
    if not stands then
        return
    end
    local templateName = templateNameForTier(visualTier)

    for i = 1, Constants.OFFER_COUNT do
        local stand = stands:FindFirstChild("Stand" .. i)
        if not stand or not stand:IsA("Model") then
            continue
        end
        if not UpgradeLogic.isPadUnlocked(upgrades, i) then
            clearVisual(stand)
            _appliedTier[i] = -1
            continue
        end
        local hasVisual = stand:FindFirstChild(VISUAL_NAME) ~= nil
        local wantVisual = templateName ~= nil
        if _appliedTier[i] == visualTier and hasVisual == wantVisual then
            if wantVisual then
                setAuthoredMeshesHidden(stand, true)
            end
            continue
        end
        if templateName == nil then
            restoreAuthored(stand)
        else
            if not placeVisual(stand, templateName) then
                restoreAuthored(stand)
            end
        end
        _appliedTier[i] = visualTier
    end
end

function StandPadTierVisual.getLastUpgrades(): { [string]: number }?
    return _lastUpgrades
end

function StandPadTierVisual.setHoldTier(tier: number?)
    _holdAtTier = if typeof(tier) == "number" then math.clamp(math.floor(tier), 0, 3) else nil
end

function StandPadTierVisual.getHoldTier(): number?
    return _holdAtTier
end

function StandPadTierVisual.clearHold()
    _holdAtTier = nil
end

--- Call before apply when padTier level rises (keeps old look for cutscene).
function StandPadTierVisual.noteTierIncrease(
    prevUpgrades: { [string]: number }?,
    nextUpgrades: { [string]: number }?
): boolean
    local prev = UpgradeLogic.padTierLevel(prevUpgrades)
    local nextN = UpgradeLogic.padTierLevel(nextUpgrades)
    if nextN > prev then
        _holdAtTier = prev
        return true
    end
    return false
end

function StandPadTierVisual.apply(upgrades: { [string]: number }?)
    _lastUpgrades = upgrades
    local target = UpgradeLogic.padTierLevel(upgrades)
    local visualTier = if _holdAtTier ~= nil then _holdAtTier else target
    applyVisualTier(upgrades, visualTier)
end

function StandPadTierVisual.reapply()
    StandPadTierVisual.apply(_lastUpgrades)
end

--- Debug: set upgrades.padTier; force-unlock all pads and refresh visuals.
function StandPadTierVisual.prepareDebugCutscene(fromTier: number, toTier: number)
    local u: { [string]: number } = if _lastUpgrades then table.clone(_lastUpgrades) else {}
    u.pad = Constants.OFFER_COUNT - Constants.BASE_UNLOCKED_PADS
    u.padTier = math.clamp(math.floor(fromTier), 0, 3)
    _holdAtTier = nil
    table.clear(_appliedTier)
    StandUnlockVisual.clearPendingPad()
    StandUnlockVisual.apply(u)
    StandPadTierVisual.apply(u)
    _holdAtTier = u.padTier
    u.padTier = math.clamp(math.floor(toTier), 0, 3)
    _lastUpgrades = u
end

return StandPadTierVisual
