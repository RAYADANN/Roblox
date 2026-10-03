--!strict
-- Монеты летят в HUD money → pop счётчика + текст +$ (как Tycoon ScorePop).

local GuiService = game:GetService("GuiService")

local CoinRain = require(script.Parent.CoinRain)
local HudMoneyAnchor = require(script.Parent.HudMoneyAnchor)
local MoneyPop = require(script.Parent.MoneyPop)
local hudAssets = require(script.Parent.Parent.hud.assets)
local theme = require(script.Parent.Parent.theme)

export type Options = {
    from: Vector2?,
    amount: number?,
    count: number?,
    onLanded: (() -> ())?,
}

local MoneyGainFx = {}

local function defaultFrom(): Vector2
    local cam = workspace.CurrentCamera
    local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
    local inset = GuiService:GetGuiInset()
    -- низ экрана по центру (конец конвейера / награда)
    return Vector2.new(vp.X * 0.5, inset.Y + vp.Y * 0.72)
end

local function worldCenter(inst: Instance): Vector3?
    if inst:IsA("Model") then
        return inst:GetPivot().Position
    end
    if inst:IsA("BasePart") then
        return inst.Position
    end
    local part = inst:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.Position
    end
    return nil
end

--- World instance → AbsolutePosition-space px (IgnoreGuiInset-aware). Nil if off/behind cam.
function MoneyGainFx.screenFromInstance(inst: Instance?): Vector2?
    if inst == nil then
        return nil
    end
    local world = worldCenter(inst)
    if world == nil then
        return nil
    end
    local cam = workspace.CurrentCamera
    if cam == nil then
        return nil
    end
    local viewport = cam:WorldToViewportPoint(world)
    if viewport.Z <= 0 then
        return nil
    end
    local inset = GuiService:GetGuiInset()
    return Vector2.new(viewport.X + inset.X, viewport.Y + inset.Y)
end

local function countForAmount(amount: number): number
    local a = math.max(amount, 1)
    return math.clamp(math.floor(4 + math.log10(a) * 3.5), 5, 16)
end

local function playCoinCollect()
    local core = script.Parent.Parent.Parent:FindFirstChild("core")
    if core == nil then
        return
    end
    local module = core:FindFirstChild("SoundManager")
    if module == nil then
        return
    end
    local ok, sound = pcall(require, module)
    if ok and sound ~= nil then
        sound.play("coin_collect")
    end
end

function MoneyGainFx.play(opts: Options)
    local to = HudMoneyAnchor.getCenter()
    if to == nil then
        if opts.onLanded then
            opts.onLanded()
        end
        return
    end

    local from = opts.from or defaultFrom()
    local amount = opts.amount or 0
    local count = opts.count or countForAmount(amount)
    local duration = 0.62

    playCoinCollect()

    CoinRain.play({
        from = from,
        to = to,
        count = count,
        texture = hudAssets.moneyIcon,
        color = theme.Colors.goldHi,
        sizePx = 110, -- 22 × 5
        duration = duration,
        spreadPx = 160,
        stagger = 0.022,
        maxCount = 18,
    })

    if amount > 0 then
        MoneyPop.play({
            amount = amount,
            position = Vector2.new(from.X, from.Y - 24),
        })
    end

    task.delay(duration * 0.85, function()
        HudMoneyAnchor.pulse()
        if opts.onLanded then
            opts.onLanded()
        end
    end)
end

return MoneyGainFx
