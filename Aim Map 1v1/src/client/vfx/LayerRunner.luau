--!strict
-- Исполняет LayerStep[]. Расширяется через register(type, fn).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LayerDef = require(ReplicatedStorage.shared.vfx.LayerDef)
local QualityLogic = require(ReplicatedStorage.shared.vfx.QualityLogic)
local ShakeProfiles = require(ReplicatedStorage.shared.vfx.ShakeProfiles)

local BeamBurstLayer = require(script.Parent.layers.BeamBurstLayer)
local EmitterLayer = require(script.Parent.layers.EmitterLayer)
local HighlightLayer = require(script.Parent.layers.HighlightLayer)
local LightLayer = require(script.Parent.layers.LightLayer)
local LoopEmitterLayer = require(script.Parent.layers.LoopEmitterLayer)
local ProjectileLayer = require(script.Parent.layers.ProjectileLayer)
local ShockwaveLayer = require(script.Parent.layers.ShockwaveLayer)
local TracerLayer = require(script.Parent.layers.TracerLayer)
local TrailLayer = require(script.Parent.layers.TrailLayer)

export type LayerStep = LayerDef.LayerStep
export type QualityBudget = QualityLogic.QualityBudget

export type RunContext = {
    folder: Folder,
    cframe: CFrame,
    color: Color3,
    intensity: number,
    budget: QualityBudget,
    distanceScale: number,
    target: Instance?,
    from: CFrame?,
    to: CFrame?,
    cameraShake: (amplitude: number, duration: number, roughness: number?) -> (),
    cameraRumble: (amplitude: number, roughness: number?) -> (),
    screenFlash: (color: Color3, brightness: number, duration: number, blurSize: number?) -> (),
    playSound: ((soundId: string, pitch: number?) -> ())?,
    playHaptic: ((profile: string?, strength: number?) -> ())?,
    --- Сборщик stop-коллбеков для Loop/Attached/Projectile
    trackStop: (stopFn: () -> ()) -> (),
    trackIntensity: (fn: (number) -> ()) -> (),
}

export type LayerFn = (ctx: RunContext, step: LayerStep) -> ()

local LayerRunner = {}

local registry: { [string]: LayerFn } = {}

function LayerRunner.register(layerType: string, fn: LayerFn)
    registry[layerType] = fn
end

function LayerRunner.runStep(ctx: RunContext, step: LayerStep)
    if not QualityLogic.allowsMinTier(step.minTier, ctx.budget) then
        return
    end
    local fn = registry[step.type]
    if not fn then
        warn(`[VFX.LayerRunner] unknown layer type: {step.type}`)
        return
    end
    fn(ctx, step)
end

-- Built-ins
local function stylePack(
    style: string?,
    base: Color3,
    sizeScale: number
): {
    color: ColorSequence,
    size: NumberSequence,
    transparency: NumberSequence,
    lightEmission: number,
    lightInfluence: number?,
    brightness: number?,
}
    local s = style or "soft"
    local scale = sizeScale
    local WHITE = Color3.fromRGB(255, 255, 255)
    local ICE = Color3.fromRGB(228, 234, 255)
    local SKY = Color3.fromRGB(115, 199, 255)
    local PRIMARY_HI = Color3.fromRGB(112, 154, 255)
    local PRIMARY = Color3.fromRGB(82, 126, 255)
    if s == "fire" then
        return {
            color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 220)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 160, 40)),
                ColorSequenceKeypoint.new(0.65, Color3.fromRGB(255, 60, 10)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 10, 5)),
            }),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.4 * scale),
                NumberSequenceKeypoint.new(0.2, 1.4 * scale),
                NumberSequenceKeypoint.new(0.7, 1.1 * scale),
                NumberSequenceKeypoint.new(1, 0),
            }),
            transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(0.5, 0.25),
                NumberSequenceKeypoint.new(1, 1),
            }),
            lightEmission = 0.85,
        }
    elseif s == "plasma" then
        return {
            color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.35, Color3.fromRGB(140, 220, 255)),
                ColorSequenceKeypoint.new(0.7, Color3.fromRGB(180, 80, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 10, 40)),
            }),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5 * scale),
                NumberSequenceKeypoint.new(0.3, 1.6 * scale),
                NumberSequenceKeypoint.new(1, 0),
            }),
            transparency = NumberSequence.new(0.0, 1),
            lightEmission = 0.95,
        }
    elseif s == "smoke" then
        return {
            color = ColorSequence.new(Color3.fromRGB(45, 48, 55), Color3.fromRGB(20, 22, 28)),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.6 * scale),
                NumberSequenceKeypoint.new(0.4, 1.8 * scale),
                NumberSequenceKeypoint.new(1, 2.4 * scale),
            }),
            transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.35),
                NumberSequenceKeypoint.new(0.5, 0.55),
                NumberSequenceKeypoint.new(1, 1),
            }),
            lightEmission = 0.05,
        }
    elseif s == "debris" then
        return {
            color = ColorSequence.new(Color3.fromRGB(120, 90, 60), Color3.fromRGB(50, 40, 30)),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.7 * scale),
                NumberSequenceKeypoint.new(0.5, 0.55 * scale),
                NumberSequenceKeypoint.new(1, 0.2 * scale),
            }),
            transparency = NumberSequence.new(0.1, 1),
            lightEmission = 0.1,
        }
    elseif s == "ember" then
        return {
            color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 120)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 20, 5)),
            }),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.35 * scale),
                NumberSequenceKeypoint.new(0.4, 0.55 * scale),
                NumberSequenceKeypoint.new(1, 0),
            }),
            transparency = NumberSequence.new(0.05, 1),
            lightEmission = 0.8,
        }
    elseif s == "spark" then
        return {
            color = ColorSequence.new(Color3.fromRGB(255, 240, 180), Color3.fromRGB(255, 120, 40)),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.25 * scale),
                NumberSequenceKeypoint.new(0.3, 0.45 * scale),
                NumberSequenceKeypoint.new(1, 0),
            }),
            transparency = NumberSequence.new(0, 1),
            lightEmission = 0.9,
        }
    elseif s == "skyCombat" then
        return {
            color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, ICE),
                ColorSequenceKeypoint.new(0.4, SKY),
                ColorSequenceKeypoint.new(1, PRIMARY),
            }),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.9 * scale),
                NumberSequenceKeypoint.new(0.35, 1.8 * scale),
                NumberSequenceKeypoint.new(1, 0.2 * scale),
            }),
            transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(0.35, 0.15),
                NumberSequenceKeypoint.new(1, 1),
            }),
            lightEmission = 0.35,
            lightInfluence = 0.15,
            brightness = 1.4,
        }
    elseif s == "skySparks" then
        return {
            color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, WHITE),
                ColorSequenceKeypoint.new(0.35, SKY),
                ColorSequenceKeypoint.new(1, PRIMARY_HI),
            }),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.7 * scale),
                NumberSequenceKeypoint.new(0.3, 1.55 * scale),
                NumberSequenceKeypoint.new(1, 0.15 * scale),
            }),
            transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(0.35, 0.15),
                NumberSequenceKeypoint.new(1, 1),
            }),
            lightEmission = 0.75,
            lightInfluence = 0.05,
            brightness = 2.2,
        }
    elseif s == "skyPunch" then
        return {
            color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, WHITE),
                ColorSequenceKeypoint.new(0.25, SKY),
                ColorSequenceKeypoint.new(0.7, PRIMARY_HI),
                ColorSequenceKeypoint.new(1, PRIMARY),
            }),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.85 * scale),
                NumberSequenceKeypoint.new(0.28, 2.1 * scale),
                NumberSequenceKeypoint.new(1, 0.1 * scale),
            }),
            transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(0.35, 0.15),
                NumberSequenceKeypoint.new(1, 1),
            }),
            lightEmission = 0.9,
            lightInfluence = 0,
            brightness = 2.8,
        }
    end
    -- soft default
    return {
        color = ColorSequence.new(base, Color3.new(1, 1, 1)),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1.15 * scale),
            NumberSequenceKeypoint.new(0.4, 0.8 * scale),
            NumberSequenceKeypoint.new(1, 0),
        }),
        transparency = NumberSequence.new(0.1, 1),
        lightEmission = 0.6,
    }
end

LayerRunner.register("Emit", function(ctx, step)
    local speed = if step.speedMin and step.speedMax
        then NumberRange.new(step.speedMin, step.speedMax)
        else nil
    local life = if step.lifetimeMin and step.lifetimeMax
        then NumberRange.new(step.lifetimeMin, step.lifetimeMax)
        else nil
    local scale = step.sizeScale or 1
    if step.sizeStart then
        scale = step.sizeStart
    end
    local pack = stylePack(step.emitStyle, ctx.color, scale)
    if step.sizeStart and step.sizeMid and step.sizeEnd then
        pack = table.clone(pack)
        pack.size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, step.sizeStart),
            NumberSequenceKeypoint.new(0.4, step.sizeMid),
            NumberSequenceKeypoint.new(1, step.sizeEnd),
        })
    end
    local spread = step.spread or 180
    EmitterLayer.burst(ctx.folder, ctx.cframe, ctx.color, {
        count = step.count or 20,
        texture = step.texture,
        flipbookLayout = step.flipbookLayout,
        flipbookMode = step.flipbookMode,
        flipbookStartRandom = step.flipbookStartRandom,
        flipbookFpsMin = step.flipbookFpsMin,
        flipbookFpsMax = step.flipbookFpsMax,
        sizeScale = scale,
        speed = speed,
        lifetime = life,
        color = pack.color,
        size = pack.size,
        transparency = pack.transparency,
        lightEmission = step.lightEmission or pack.lightEmission,
        lightInfluence = step.lightInfluence or pack.lightInfluence,
        brightness = step.brightness or pack.brightness,
        drag = step.drag,
        spreadAngle = Vector2.new(spread, spread),
        emitDuration = step.emitDuration or 1.6,
        distanceScale = ctx.distanceScale,
        intensity = ctx.intensity,
    }, ctx.budget)
end)

LayerRunner.register("Light", function(ctx, step)
    LightLayer.pulse(ctx.folder, ctx.cframe, ctx.color, {
        range = (step.range or 14) * ctx.intensity,
        brightness = (step.brightness or 2.5) * ctx.intensity,
        duration = step.duration or 0.28,
    }, ctx.budget)
end)

LayerRunner.register("Shockwave", function(ctx, step)
    if not ctx.budget.enableShockwave then
        return
    end
    ShockwaveLayer.ring(ctx.folder, ctx.cframe, ctx.color, {
        startSize = step.startSize,
        endSize = (step.endSize or 10) * ctx.intensity,
        duration = step.duration or 0.35,
    })
end)

LayerRunner.register("Beam", function(ctx, step)
    BeamBurstLayer.flash(ctx.folder, ctx.cframe, ctx.color, {
        length = (step.length or 8) * ctx.intensity,
        width0 = step.width0,
        width1 = step.width1,
        duration = step.duration or 0.22,
    }, ctx.budget)
end)

LayerRunner.register("Tracer", function(ctx, step)
    local from = ctx.from
    local to = ctx.to
    if not from or not to then
        return
    end
    TracerLayer.flash(ctx.folder, from.Position, to.Position, ctx.color, {
        width = step.width0,
        duration = step.duration,
    })
end)

LayerRunner.register("CameraShake", function(ctx, step)
    if not ctx.budget.enableCameraShake then
        return
    end
    local profile = ShakeProfiles.resolve(step.shakeProfile)
    local amp = (if profile then profile.amplitude else step.amplitude or 0.2)
        * ctx.intensity
        * ctx.distanceScale
    local dur = if profile then profile.duration else step.duration or 0.16
    local rough = if profile then profile.roughness else step.roughness
    ctx.cameraShake(amp, dur, rough)
end)

LayerRunner.register("CameraRumble", function(ctx, step)
    if not ctx.budget.enableCameraShake then
        return
    end
    local amp = (step.rumble or step.amplitude or 0.06) * ctx.intensity
    ctx.cameraRumble(amp, step.roughness)
    ctx.trackStop(function()
        ctx.cameraRumble(0)
    end)
    ctx.trackIntensity(function(intensity)
        ctx.cameraRumble((step.rumble or 0.06) * intensity)
    end)
end)

LayerRunner.register("ScreenFlash", function(ctx, step)
    if not ctx.budget.enableScreenFX then
        return
    end
    ctx.screenFlash(
        ctx.color,
        (step.brightness or 0.12) * ctx.intensity,
        step.duration or 0.12,
        step.blurSize
    )
end)

LayerRunner.register("Sound", function(ctx, step)
    if not ctx.playSound or not step.soundId then
        return
    end
    ctx.playSound(step.soundId, step.pitch)
end)

LayerRunner.register("Haptic", function(ctx, step)
    if not ctx.playHaptic then
        return
    end
    ctx.playHaptic(step.hapticProfile, step.hapticStrength or ctx.intensity)
end)

LayerRunner.register("ChainEmit", function(ctx, step)
    local from = ctx.from or ctx.cframe
    local to = ctx.to
    if not to then
        EmitterLayer.burst(ctx.folder, ctx.cframe, ctx.color, {
            count = QualityLogic.scaleEmit(
                step.count or 12,
                ctx.budget,
                ctx.distanceScale * ctx.intensity
            ),
            texture = step.texture,
            flipbookLayout = step.flipbookLayout,
            flipbookMode = step.flipbookMode,
            flipbookStartRandom = step.flipbookStartRandom,
            flipbookFpsMin = step.flipbookFpsMin,
            flipbookFpsMax = step.flipbookFpsMax,
            sizeScale = step.sizeScale,
        }, ctx.budget)
        return
    end
    local segments = 4
    if ctx.budget.tier == "Low" then
        segments = 2
    elseif ctx.budget.tier == "Ultra" then
        segments = 5
    end
    local countEach = QualityLogic.scaleEmit(
        math.max(4, math.floor((step.count or 12) / segments + 0.5)),
        ctx.budget,
        ctx.distanceScale * ctx.intensity
    )
    for i = 0, segments do
        local alpha = i / segments
        local cf = from:Lerp(to, alpha)
        task.delay(i * 0.04, function()
            EmitterLayer.burst(ctx.folder, cf, ctx.color, {
                count = countEach,
                texture = step.texture,
                flipbookLayout = step.flipbookLayout,
                flipbookMode = step.flipbookMode,
                flipbookStartRandom = step.flipbookStartRandom,
                flipbookFpsMin = step.flipbookFpsMin,
                flipbookFpsMax = step.flipbookFpsMax,
                sizeScale = step.sizeScale or 0.55,
                speed = if step.speedMin and step.speedMax
                    then NumberRange.new(step.speedMin, step.speedMax)
                    else nil,
            }, ctx.budget)
        end)
    end
end)

LayerRunner.register("Trail", function(ctx, step)
    local anchor = Instance.new("Part")
    anchor.Name = "VfxTrailAnchor"
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanQuery = false
    anchor.CanTouch = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.CFrame = ctx.cframe
    anchor.Parent = ctx.folder
    TrailLayer.attach(anchor, ctx.color, {
        duration = step.duration or 0.4,
        lifetime = 0.3,
        width0 = step.width0 or 1,
    }, ctx.budget)
    ctx.trackStop(function()
        if anchor.Parent then
            anchor:Destroy()
        end
    end)
end)

LayerRunner.register("LoopEmit", function(ctx, step)
    local handle = LoopEmitterLayer.start(ctx.folder, ctx.cframe, {
        rate = (step.rate or 20) * ctx.intensity,
        color = ctx.color,
    }, ctx.budget, ctx.distanceScale)
    if not handle then
        return
    end
    ctx.trackStop(function()
        handle:stop()
    end)
    ctx.trackIntensity(function(intensity)
        handle:setRate((step.rate or 20) * intensity)
    end)
end)

LayerRunner.register("AttachedEmit", function(ctx, step)
    local target = ctx.target
    if not target or not target:IsA("BasePart") then
        return
    end
    local handle = LoopEmitterLayer.startAttached(ctx.folder, target, CFrame.new(), {
        rate = (step.rate or 16) * ctx.intensity,
        color = ctx.color,
    }, ctx.budget, ctx.distanceScale)
    if not handle then
        return
    end
    ctx.trackStop(function()
        handle:stop()
    end)
    ctx.trackIntensity(function(intensity)
        handle:setRate((step.rate or 16) * intensity)
    end)
end)

LayerRunner.register("Projectile", function(ctx, step)
    local from = ctx.from or ctx.cframe
    local to = ctx.to
    if not to then
        return
    end
    local proj = ProjectileLayer.fire(ctx.folder, from, to, {
        color = ctx.color,
        speed = step.speed or 90,
        withTrail = ctx.budget.enableTrails,
        onArrive = function()
            local count = QualityLogic.scaleEmit(step.count or 24, ctx.budget, ctx.distanceScale)
            EmitterLayer.burst(ctx.folder, to, ctx.color, { count = count }, ctx.budget)
            if ctx.budget.enableShockwave then
                ShockwaveLayer.ring(ctx.folder, to, ctx.color, { endSize = step.endSize or 6 })
            end
        end,
    }, ctx.budget)
    ctx.trackStop(function()
        proj:stop()
    end)
end)

LayerRunner.register("Highlight", function(ctx, step)
    if not ctx.target then
        return
    end
    HighlightLayer.flash(ctx.target, {
        fillColor = ctx.color,
        outlineColor = Color3.new(1, 1, 1),
        duration = step.duration or 0.22,
        fillTransparency = step.fillTransparency,
        outlineTransparency = step.outlineTransparency,
    })
end)

return LayerRunner
