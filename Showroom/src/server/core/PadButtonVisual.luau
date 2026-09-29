--!strict
-- Stand-on incubator / FavoritePlace Button: Cube.001 (+ Cube.002) dips on press.

local TweenService = game:GetService("TweenService")

local Constants = require(game:GetService("ReplicatedStorage").shared.data.Constants)

-- Face + rim move together (same as Tycoon pads).
local PRESS_PART_NAMES = { "Cube.001", "Cube.002" }

local restCf: { [BasePart]: CFrame } = {}
local pressing: { [Instance]: boolean } = {}

local PadButtonVisual = {}

local function pressParts(model: Instance): { BasePart }
    local parts: { BasePart } = {}
    for _, name in PRESS_PART_NAMES do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    return parts
end

local function rememberRest(parts: { BasePart })
    for _, part in parts do
        if restCf[part] == nil then
            restCf[part] = part.CFrame
        end
    end
end

local function restoreParts(parts: { BasePart })
    for _, part in parts do
        local rest = restCf[part]
        if rest and part.Parent then
            part.CFrame = rest
        end
    end
end

function PadButtonVisual.prepare(model: Instance)
    local parts = pressParts(model)
    for _, part in parts do
        part.Anchored = true
        part.CanCollide = true
        part.CanTouch = true
    end
    rememberRest(parts)
end

function PadButtonVisual.isPressing(model: Instance): boolean
    return pressing[model] == true
end

function PadButtonVisual.playPress(model: Instance, onDone: (() -> ())?)
    if pressing[model] then
        return
    end

    local parts = pressParts(model)
    if #parts == 0 then
        if onDone then
            onDone()
        end
        return
    end

    rememberRest(parts)
    pressing[model] = true

    local state = { done = false }
    local depth = Constants.PAD_PRESS_DEPTH
    local downInfo =
        TweenInfo.new(Constants.PAD_PRESS_DOWN_SEC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local upInfo =
        TweenInfo.new(Constants.PAD_PRESS_UP_SEC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local pendingDown = #parts
    local pendingUp = #parts

    local function finish()
        if state.done then
            return
        end
        state.done = true
        pressing[model] = nil
        restoreParts(parts)
        if onDone then
            onDone()
        end
    end

    local function playUp()
        for _, part in parts do
            local rest = restCf[part]
            if rest == nil or part.Parent == nil then
                finish()
                return
            end
            local tweenUp = TweenService:Create(part, upInfo, { CFrame = rest })
            tweenUp:Play()
            tweenUp.Completed:Once(function()
                pendingUp -= 1
                if pendingUp <= 0 then
                    finish()
                end
            end)
        end
    end

    for _, part in parts do
        part.Anchored = true
        local rest = restCf[part]
        if rest == nil then
            finish()
            return
        end
        local down = rest * CFrame.new(0, -depth, 0)
        local tweenDown = TweenService:Create(part, downInfo, { CFrame = down })
        tweenDown:Play()
        tweenDown.Completed:Once(function(playbackState)
            if state.done then
                return
            end
            if playbackState ~= Enum.PlaybackState.Completed or part.Parent == nil then
                finish()
                return
            end
            pendingDown -= 1
            if pendingDown <= 0 then
                playUp()
            end
        end)
    end
end

return PadButtonVisual
