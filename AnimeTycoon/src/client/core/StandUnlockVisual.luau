--!strict
-- Show/hide Stand1..Stand5 by Pad Unlock. Local-only (shared MVP plot).
-- Pending pad stays hidden until PadUnlockCutscene reveals it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)

local StandUnlockVisual = {}

local _saved: {
    [BasePart]: {
        localTransparency: number,
        canCollide: boolean,
        canQuery: boolean,
        canTouch: boolean,
    },
} =
    {}

local _pendingPad: number? = nil
local _lastUpgrades: { [string]: number }? = nil

local function setPartHidden(part: BasePart, hidden: boolean)
    if _saved[part] == nil then
        _saved[part] = {
            localTransparency = part.LocalTransparencyModifier,
            canCollide = part.CanCollide,
            canQuery = part.CanQuery,
            canTouch = part.CanTouch,
        }
    end
    local saved = _saved[part]
    if hidden then
        part.LocalTransparencyModifier = 1
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
    else
        part.LocalTransparencyModifier = saved.localTransparency
        part.CanCollide = saved.canCollide
        part.CanQuery = saved.canQuery
        part.CanTouch = saved.canTouch
    end
end

local function setInstanceHidden(root: Instance, hidden: boolean)
    for _, d in root:GetDescendants() do
        if d:IsA("BasePart") then
            setPartHidden(d, hidden)
        elseif d:IsA("Decal") or d:IsA("Texture") then
            d.Transparency = if hidden then 1 else 0
        elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
            -- Stand pads should not idle-emit; unlock hide/show used to force these on.
            d.Enabled = false
        elseif d:IsA("ProximityPrompt") then
            if hidden then
                d.Enabled = false
                d.MaxActivationDistance = 0
            end
        end
    end
end

function StandUnlockVisual.getStand(padIndex: number): Instance?
    local stands = BaseLayout.getStands()
    if not stands then
        return nil
    end
    return stands:FindFirstChild("Stand" .. math.floor(padIndex))
end

function StandUnlockVisual.setPendingPad(padIndex: number?)
    _pendingPad = if typeof(padIndex) == "number" then math.floor(padIndex) else nil
end

function StandUnlockVisual.getPendingPad(): number?
    return _pendingPad
end

function StandUnlockVisual.clearPendingPad()
    _pendingPad = nil
end

--- Mark the newly unlocked pad as pending (call before apply when pad count rises).
function StandUnlockVisual.notePadIncrease(
    prevUpgrades: { [string]: number }?,
    nextUpgrades: { [string]: number }?
): number?
    local prev = UpgradeLogic.unlockedPads(prevUpgrades)
    local nextN = UpgradeLogic.unlockedPads(nextUpgrades)
    if nextN > prev then
        _pendingPad = nextN
        return nextN
    end
    return nil
end

function StandUnlockVisual.apply(upgrades: { [string]: number }?)
    _lastUpgrades = upgrades
    local stands = BaseLayout.getStands()
    if not stands then
        return
    end
    for i = 1, Constants.OFFER_COUNT do
        local stand = stands:FindFirstChild("Stand" .. i)
        if not stand then
            continue
        end
        local unlocked = UpgradeLogic.isPadUnlocked(upgrades, i)
        local holdForCutscene = unlocked and _pendingPad == i
        setInstanceHidden(stand, not unlocked or holdForCutscene)
    end
end

--- Make pad visible at authored pose (after cutscene drop lands).
function StandUnlockVisual.finishReveal(padIndex: number)
    if _pendingPad == padIndex then
        _pendingPad = nil
    end
    StandUnlockVisual.apply(_lastUpgrades)
end

return StandUnlockVisual
