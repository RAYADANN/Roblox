--!strict
-- World SellBox: every Side / SidePart grows along local axis aligned with world +Y.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local SellBoxLogic = require(ReplicatedStorage.shared.util.SellBoxLogic)

local ATTR_SIZE = "SellBoxBaseSize"
local ATTR_CF = "SellBoxBaseCF"
local ATTR_AXIS = "SellBoxSkyAxis"
local ATTR_SIGN = "SellBoxSkySign"

type SideBase = {
    size: Vector3,
    cf: CFrame,
    axis: number,
    skySign: number,
}

local SellBoxVisual = {}

local _deposits = 0
local _bound = false
local _conn: RBXScriptConnection? = nil
local _baseConn: RBXScriptConnection? = nil
local _tweens: { [BasePart]: Tween } = {}
local _retrying = false
local _warnedMissing = false

local function isSideName(name: string): boolean
    return name == "Side" or name == "SidePart" or string.match(name, "^Side%d*$") ~= nil
end

local function collectSides(root: Instance): { BasePart }
    local out: { BasePart } = {}
    for _, d in root:GetDescendants() do
        if d:IsA("BasePart") and isSideName(d.Name) then
            table.insert(out, d)
        end
    end
    return out
end

local function unlockForTween(part: BasePart)
    for _, ch in part:GetChildren() do
        if
            ch:IsA("WeldConstraint")
            or ch:IsA("Weld")
            or ch:IsA("Snap")
            or ch:IsA("RigidConstraint")
            or ch:IsA("Motor6D")
        then
            ch:Destroy()
        end
    end
    for _, joint in part:GetJoints() do
        if
            joint:IsA("WeldConstraint")
            or joint:IsA("Weld")
            or joint:IsA("Motor6D")
            or joint:IsA("Snap")
        then
            joint:Destroy()
        end
    end
    part.Anchored = true
end

--- Local axis most aligned with world +Y, and sign that points skyward.
local function skyAxis(part: BasePart): (number, number)
    local cf = part.CFrame
    local rx, ux, lx = cf.RightVector.Y, cf.UpVector.Y, cf.LookVector.Y
    local ax, ay, az = math.abs(rx), math.abs(ux), math.abs(lx)
    if ax >= ay and ax >= az then
        return 1, if rx >= 0 then 1 else -1
    elseif ay >= ax and ay >= az then
        return 2, if ux >= 0 then 1 else -1
    end
    return 3, if lx >= 0 then 1 else -1
end

local function sizeOnAxis(size: Vector3, axis: number, value: number): Vector3
    if axis == 1 then
        return Vector3.new(value, size.Y, size.Z)
    elseif axis == 2 then
        return Vector3.new(size.X, value, size.Z)
    end
    return Vector3.new(size.X, size.Y, value)
end

local function axisComponent(size: Vector3, axis: number): number
    if axis == 1 then
        return size.X
    elseif axis == 2 then
        return size.Y
    end
    return size.Z
end

local function offsetAlongAxis(axis: number, signedDelta: number): Vector3
    if axis == 1 then
        return Vector3.new(signedDelta, 0, 0)
    elseif axis == 2 then
        return Vector3.new(0, signedDelta, 0)
    end
    return Vector3.new(0, 0, signedDelta)
end

local function readBase(part: BasePart): SideBase?
    local sizeAny = part:GetAttribute(ATTR_SIZE)
    local cfAny = part:GetAttribute(ATTR_CF)
    local axisAny = part:GetAttribute(ATTR_AXIS)
    local signAny = part:GetAttribute(ATTR_SIGN)
    if typeof(sizeAny) ~= "Vector3" or typeof(cfAny) ~= "CFrame" then
        return nil
    end
    if typeof(axisAny) ~= "number" or typeof(signAny) ~= "number" then
        return nil
    end
    return {
        size = sizeAny,
        cf = cfAny,
        axis = math.clamp(math.floor(axisAny), 1, 3),
        skySign = if signAny >= 0 then 1 else -1,
    }
end

local function writeBase(part: BasePart, base: SideBase)
    part:SetAttribute(ATTR_SIZE, base.size)
    part:SetAttribute(ATTR_CF, base.cf)
    part:SetAttribute(ATTR_AXIS, base.axis)
    part:SetAttribute(ATTR_SIGN, base.skySign)
end

local function clearBaseAttrs(part: BasePart)
    part:SetAttribute(ATTR_SIZE, nil)
    part:SetAttribute(ATTR_CF, nil)
    part:SetAttribute(ATTR_AXIS, nil)
    part:SetAttribute(ATTR_SIGN, nil)
end

local function ensureBase(part: BasePart): SideBase
    local existing = readBase(part)
    if existing then
        return existing
    end
    unlockForTween(part)
    local axis, sign = skyAxis(part)
    local base: SideBase = {
        size = part.Size,
        cf = part.CFrame,
        axis = axis,
        skySign = sign,
    }
    writeBase(part, base)
    return base
end

local function cancelTween(part: BasePart)
    local tw = _tweens[part]
    if tw then
        tw:Cancel()
        _tweens[part] = nil
    end
end

local function applyTarget(part: BasePart, depositCount: number)
    local base = ensureBase(part)
    local baseLen = axisComponent(base.size, base.axis)
    local targetLen = SellBoxLogic.sizeX(baseLen, depositCount)
    local newSize = sizeOnAxis(base.size, base.axis, targetLen)
    local delta = targetLen - baseLen
    local newCf = base.cf * CFrame.new(offsetAlongAxis(base.axis, base.skySign * delta * 0.5))

    cancelTween(part)
    unlockForTween(part)

    if depositCount <= 0 then
        part.Size = base.size
        part.CFrame = base.cf
        return
    end

    local info =
        TweenInfo.new(SellBoxLogic.tweenSeconds(), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(part, info, {
        Size = newSize,
        CFrame = newCf,
    })
    _tweens[part] = tween
    tween:Play()
end

local function refreshAll()
    local sellBox = BaseLayout.getSellBox()
    if not sellBox then
        _bound = false
        return
    end
    local sides = collectSides(sellBox)
    _bound = #sides > 0
    for _, part in sides do
        applyTarget(part, _deposits)
    end
end

local function attachSellBoxListener(sellBox: Instance)
    if _conn then
        _conn:Disconnect()
        _conn = nil
    end
    _conn = sellBox.DescendantAdded:Connect(function(inst)
        if inst:IsA("BasePart") and isSideName(inst.Name) then
            ensureBase(inst)
            applyTarget(inst, _deposits)
            _bound = true
        end
    end)
end

--- Bind without wiping deposit count (streaming-safe).
local function ensureBound(base: Instance?): boolean
    local sellBox = BaseLayout.getSellBox(base)
    if not sellBox then
        return false
    end

    attachSellBoxListener(sellBox)

    local sides = collectSides(sellBox)
    if #sides == 0 then
        _bound = false
        return false
    end

    for _, part in sides do
        ensureBase(part)
    end
    _bound = true
    refreshAll()
    return true
end

local function scheduleRetry()
    if _retrying then
        return
    end
    _retrying = true
    task.spawn(function()
        for _ = 1, 40 do
            task.wait(0.25)
            if ensureBound() then
                _retrying = false
                return
            end
            -- SellBox may appear after Base streams in.
            if _baseConn == nil then
                local Workspace = game:GetService("Workspace")
                _baseConn = Workspace.ChildAdded:Connect(function(child)
                    if child.Name == "Base" or string.match(child.Name, "^Base%d+$") then
                        ensureBound()
                    end
                end)
            end
        end
        _retrying = false
        if not _bound and not _warnedMissing then
            _warnedMissing = true
            if BaseLayout.getSellBox() then
                warn("[SellBoxVisual] no Side/SidePart under SellBox after wait")
            else
                warn("[SellBoxVisual] Base.SellBox missing after wait")
            end
        end
    end)
end

function SellBoxVisual.bind(base: Instance?)
    _deposits = 0
    for part, _ in _tweens do
        cancelTween(part)
    end
    table.clear(_tweens)

    local sellBox = BaseLayout.getSellBox(base)
    if sellBox then
        -- Fresh bind: clear authored attrs so we re-capture rest sizes.
        for _, part in collectSides(sellBox) do
            clearBaseAttrs(part)
        end
    end

    if ensureBound(base) then
        return
    end
    scheduleRetry()
end

function SellBoxVisual.setDeposits(depositCount: number)
    if not _bound then
        if not ensureBound() then
            scheduleRetry()
        end
    end
    local nextCount = math.max(0, math.floor(depositCount))
    if nextCount == 0 and _deposits ~= 0 then
        local sellBox = BaseLayout.getSellBox()
        if sellBox then
            for _, part in collectSides(sellBox) do
                cancelTween(part)
                local base = readBase(part)
                if base then
                    part.Size = base.size
                    part.CFrame = base.cf
                end
            end
        end
    end
    _deposits = nextCount
    if _bound then
        refreshAll()
    end
end

function SellBoxVisual.deposit(count: number?)
    if not _bound then
        if not ensureBound() then
            scheduleRetry()
            return
        end
    end
    local n = if typeof(count) == "number" then math.max(1, math.floor(count)) else 1
    _deposits += n
    refreshAll()
end

function SellBoxVisual.start()
    if not ensureBound() then
        scheduleRetry()
    end
end

return SellBoxVisual
