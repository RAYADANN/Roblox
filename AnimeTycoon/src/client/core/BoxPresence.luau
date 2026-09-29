--!strict
-- Container idle wiggle + buy-focus (smooth scale + outline Highlight).

local Workspace = game:GetService("Workspace")

export type Handle = {
    stop: () -> (),
    setFocused: (focused: boolean) -> (),
    refreshRest: () -> (),
}

export type Opts = {
    pad: BasePart?,
    realign: ((Model, BasePart) -> ())?,
    allowFocus: boolean?,
}

local FOCUS_SCALE = 1.2
local FOCUS_TWEEN_SEC = 0.28
local SHAKE_INTERVAL_MIN = 3.6
local SHAKE_INTERVAL_MAX = 6.2
local SHAKE_BURST_SEC = 0.85
local SHAKE_POS = 0.035
local SHAKE_DEG = 2.8
local SHAKE_FREQ = 7 -- soft oscillations per second during burst

local BoxPresence = {}

local function smoothstep(t: number): number
    local x = math.clamp(t, 0, 1)
    return x * x * (3 - 2 * x)
end

local function getHighlightTemplate(): Highlight?
    local box2 = Workspace:FindFirstChild("Box2")
    if not box2 then
        return nil
    end
    local hl = box2:FindFirstChildWhichIsA("Highlight")
    if hl and hl:IsA("Highlight") then
        return hl
    end
    return nil
end

local function ensureFocusHighlight(model: Model): Highlight
    local existing = model:FindFirstChild("FocusHighlight")
    if existing and existing:IsA("Highlight") then
        existing.FillTransparency = 1
        existing.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        return existing
    end
    local template = getHighlightTemplate()
    local hl: Highlight = if template then template:Clone() else Instance.new("Highlight")
    hl.Name = "FocusHighlight"
    hl.FillTransparency = 1
    hl.OutlineTransparency = 1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Adornee = model
    hl.Parent = model
    return hl
end

local function readScale(model: Model, fallback: number): number
    local ok, value = pcall(function()
        return model:GetScale()
    end)
    if ok and typeof(value) == "number" then
        return value
    end
    return fallback
end

function BoxPresence.start(model: Model, opts: Opts?): Handle
    local allowFocus = if opts then opts.allowFocus == true else false
    local pad = if opts then opts.pad else nil
    local realign = if opts then opts.realign else nil
    local running = true
    local focused = false
    local focusToken = 0
    local shaking = false
    -- Rest pose is ONLY written after a clean realign (never mid-shake).
    local restCf = model:GetPivot()
    local baseScale = readScale(model, 1)

    local function snapToRest()
        if model.Parent then
            model:PivotTo(restCf)
        end
    end

    local function commitRestAfterRealign()
        if not model.Parent then
            return
        end
        if pad and realign then
            -- Place from current (should already be rest orientation).
            realign(model, pad)
        end
        restCf = model:GetPivot()
    end

    local function applyFocusVisual(on: boolean)
        if not allowFocus or not model.Parent then
            return
        end
        focusToken += 1
        local token = focusToken

        -- Leave any mid-shake tilt before scaling.
        snapToRest()

        local fromScale = readScale(model, baseScale)
        local toScale = if on then baseScale * FOCUS_SCALE else baseScale
        local hl = ensureFocusHighlight(model)
        hl.Enabled = true
        hl.FillTransparency = 1
        local fromOutline = hl.OutlineTransparency
        local toOutline = if on then 0 else 1

        task.spawn(function()
            local t0 = os.clock()
            while running and model.Parent and token == focusToken do
                local alpha = smoothstep((os.clock() - t0) / FOCUS_TWEEN_SEC)
                -- Always scale from rest orientation, never from a shaken pose.
                snapToRest()
                pcall(function()
                    model:ScaleTo(fromScale + (toScale - fromScale) * alpha)
                end)
                commitRestAfterRealign()
                hl.OutlineTransparency = fromOutline + (toOutline - fromOutline) * alpha
                if alpha >= 1 then
                    break
                end
                task.wait()
            end
            if not model.Parent or token ~= focusToken then
                return
            end
            snapToRest()
            pcall(function()
                model:ScaleTo(toScale)
            end)
            commitRestAfterRealign()
            hl.OutlineTransparency = toOutline
            if not on then
                hl.Enabled = false
            end
        end)
    end

    task.spawn(function()
        while running and model.Parent do
            local waitSec = SHAKE_INTERVAL_MIN
                + math.random() * (SHAKE_INTERVAL_MAX - SHAKE_INTERVAL_MIN)
            local tWait = os.clock()
            while running and model.Parent and os.clock() - tWait < waitSec do
                task.wait(0.05)
            end
            if not running or not model.Parent then
                break
            end
            shaking = true
            local burstToken = focusToken
            local phase = math.random() * math.pi * 2
            local t0 = os.clock()
            while running and model.Parent and os.clock() - t0 < SHAKE_BURST_SEC do
                if focusToken ~= burstToken then
                    break
                end
                local elapsed = os.clock() - t0
                -- Ease in/out so the burst doesn't slam on/off.
                local envelope = math.sin((elapsed / SHAKE_BURST_SEC) * math.pi)
                local wave = math.sin(elapsed * SHAKE_FREQ * math.pi * 2 + phase)
                local wave2 = math.sin(elapsed * SHAKE_FREQ * 1.37 * math.pi * 2 + phase * 0.7)
                local amp = envelope * envelope -- softer peak
                local ox = wave * SHAKE_POS * amp
                local oy = math.abs(wave2) * SHAKE_POS * 0.35 * amp
                local oz = wave2 * SHAKE_POS * 0.85 * amp
                local rx = math.rad(wave2 * SHAKE_DEG * amp)
                local ry = math.rad(wave * SHAKE_DEG * 0.65 * amp)
                local rz = math.rad((-wave) * SHAKE_DEG * 0.8 * amp)
                model:PivotTo(restCf * CFrame.new(ox, oy, oz) * CFrame.Angles(rx, ry, rz))
                task.wait()
            end
            shaking = false
            if model.Parent then
                snapToRest()
            end
        end
    end)

    return {
        stop = function()
            running = false
            focusToken += 1
            if model.Parent then
                snapToRest()
                if focused then
                    focused = false
                    pcall(function()
                        model:ScaleTo(baseScale)
                    end)
                    commitRestAfterRealign()
                    local hl = model:FindFirstChild("FocusHighlight")
                    if hl and hl:IsA("Highlight") then
                        hl.Enabled = false
                        hl.OutlineTransparency = 1
                    end
                end
            end
        end,
        setFocused = function(on: boolean)
            if not allowFocus then
                return
            end
            if focused == on then
                return
            end
            focused = on
            applyFocusVisual(on)
        end,
        refreshRest = function()
            -- External callers: only after a clean upright place.
            if not shaking then
                snapToRest()
                commitRestAfterRealign()
            end
        end,
    }
end

return BoxPresence
