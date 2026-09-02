--!strict
-- Server: broadcast PlayVfx to all clients. Game managers call this — never trust client FX.

local Zap = require(script.Parent.Parent.net.NetServer)

export type PlayArgs = {
    effectId: string,
    intensity: number?,
    pos: Vector3?,
    from: Vector3?,
    to: Vector3?,
    skinId: string?,
}

local VfxBroadcaster = {}

function VfxBroadcaster.playAll(args: PlayArgs)
    Zap.PlayVfx.FireAll({
        effectId = args.effectId,
        intensity = args.intensity or 1,
        pos = args.pos,
        from = args.from,
        to = args.to,
        skinId = args.skinId,
    })
end

function VfxBroadcaster.playExcept(except: Player, args: PlayArgs)
    Zap.PlayVfx.FireExcept(except, {
        effectId = args.effectId,
        intensity = args.intensity or 1,
        pos = args.pos,
        from = args.from,
        to = args.to,
        skinId = args.skinId,
    })
end

--- Example cast → projectile → impact chain (demo / skill template).
function VfxBroadcaster.castBoltImpact(from: Vector3, to: Vector3, intensity: number?)
    local i = intensity or 1
    VfxBroadcaster.playAll({
        effectId = "CastBurst",
        intensity = i * 0.9,
        pos = from,
    })
    task.delay(0.08, function()
        VfxBroadcaster.playAll({
            effectId = "NeonBolt",
            intensity = i,
            from = from,
            to = to,
        })
    end)
    task.delay(0.08 + (to - from).Magnitude / 110, function()
        VfxBroadcaster.playAll({
            effectId = "NeonImpact",
            intensity = i * 1.15,
            pos = to,
        })
    end)
end

return VfxBroadcaster
