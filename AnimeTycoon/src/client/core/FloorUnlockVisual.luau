--!strict
-- Show/hide SecondFloor / ThirdFloor and HeroPlace Buttons by Base Expansion unlocks.
-- Local-only (shared MVP plot). Pending floor stays hidden until FloorUnlockCutscene.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local HeroPlaceLayout = require(ReplicatedStorage.shared.util.HeroPlaceLayout)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)

local FloorUnlockVisual = {}

local _saved: {
    [BasePart]: {
        localTransparency: number,
        canCollide: boolean,
        canQuery: boolean,
        canTouch: boolean,
    },
} =
    {}

local _beamSaved: { [Beam]: boolean } = {}
local _pendingFloor: number? = nil
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

local function setBeamVisible(beam: Beam, visible: boolean)
    if _beamSaved[beam] == nil then
        _beamSaved[beam] = beam.Enabled
    end
    beam.Enabled = if visible then _beamSaved[beam] else false
end

local function setInstanceHidden(root: Instance, hidden: boolean)
    for _, d in root:GetDescendants() do
        if d:IsA("BasePart") then
            setPartHidden(d, hidden)
        elseif d:IsA("Decal") or d:IsA("Texture") then
            d.Transparency = if hidden then 1 else 0
        elseif d:IsA("Beam") then
            setBeamVisible(d, not hidden)
        elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
            d.Enabled = not hidden
        elseif d:IsA("ProximityPrompt") then
            if hidden then
                d.Enabled = false
                d.MaxActivationDistance = 0
            end
        end
    end
end

local function setRampCenterBeamsEnabled(ramp: Instance?, enabled: boolean)
    if not ramp then
        return
    end
    local center = ramp:FindFirstChild("Center")
    if not center then
        return
    end
    for _, d in center:GetDescendants() do
        if d:IsA("Beam") then
            setBeamVisible(d, enabled)
        end
    end
end

function FloorUnlockVisual.highestUnlockedFloor(upgrades: { [string]: number }?): number
    local Constants = require(ReplicatedStorage.shared.data.Constants)
    for f = Constants.FLOOR_COUNT, 1, -1 do
        if UpgradeLogic.isFloorUnlocked(upgrades, f) then
            return f
        end
    end
    return 1
end

function FloorUnlockVisual.getFloorModel(floorIndex: number): Model?
    local base = BaseLayout.getPrimary()
    if not base then
        return nil
    end
    for _, floor in HeroPlaceLayout.floors() do
        if floor.floorIndex == floorIndex and floor.floorModelName then
            local m = base:FindFirstChild(floor.floorModelName)
            if m and m:IsA("Model") then
                return m
            end
        end
    end
    return nil
end

function FloorUnlockVisual.setPendingFloor(floorIndex: number?)
    _pendingFloor = if typeof(floorIndex) == "number" then math.floor(floorIndex) else nil
end

function FloorUnlockVisual.getPendingFloor(): number?
    return _pendingFloor
end

function FloorUnlockVisual.clearPendingFloor()
    _pendingFloor = nil
end

function FloorUnlockVisual.getLastUpgrades(): { [string]: number }?
    return _lastUpgrades
end

--- When Base Expansion unlocks a new floor, hold it hidden for the drop cutscene.
function FloorUnlockVisual.noteFloorIncrease(
    prevUpgrades: { [string]: number }?,
    nextUpgrades: { [string]: number }?
): number?
    local prev = FloorUnlockVisual.highestUnlockedFloor(prevUpgrades)
    local nextN = FloorUnlockVisual.highestUnlockedFloor(nextUpgrades)
    if nextN > prev then
        _pendingFloor = nextN
        return nextN
    end
    return nil
end

function FloorUnlockVisual.apply(upgrades: { [string]: number }?)
    _lastUpgrades = upgrades
    local base = BaseLayout.getPrimary()
    if not base then
        return
    end

    for _, floor in HeroPlaceLayout.floors() do
        local unlocked = UpgradeLogic.isFloorUnlocked(upgrades, floor.floorIndex)
        if floor.floorModelName then
            local floorModel = base:FindFirstChild(floor.floorModelName)
            if floorModel then
                local hold = unlocked and _pendingFloor == floor.floorIndex
                setInstanceHidden(floorModel, not unlocked or hold)
                local ramp = floorModel:FindFirstChild(floor.rampName)
                setRampCenterBeamsEnabled(ramp, unlocked and not hold)
            end
        else
            local ramp = base:FindFirstChild(floor.rampName) or BaseLayout.getRamp(base)
            setRampCenterBeamsEnabled(ramp, true)
        end
    end

    for _, slot in HeroPlaceLayout.getOrderedSlots(base) do
        if slot.floorIndex <= 1 then
            continue
        end
        if not UpgradeLogic.isFloorUnlocked(upgrades, slot.floorIndex) then
            continue
        end
        if _pendingFloor == slot.floorIndex then
            setInstanceHidden(slot.button, true)
            continue
        end
        local unlocked = UpgradeLogic.isSlotUnlocked(upgrades, slot.slotIndex)
        setInstanceHidden(slot.button, not unlocked)
    end
end

function FloorUnlockVisual.finishReveal(floorIndex: number)
    if _pendingFloor == floorIndex then
        _pendingFloor = nil
    end
    FloorUnlockVisual.apply(_lastUpgrades)
end

--- Force-show floor parts (cutscene mid-air) without clearing pending.
function FloorUnlockVisual.revealVisible(floorModel: Model)
    for _, d in floorModel:GetDescendants() do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = 0
        elseif d:IsA("Decal") or d:IsA("Texture") then
            d.Transparency = 0
        end
    end
end

return FloorUnlockVisual
