--!strict
-- Хэндл живого эффекта: stop / setIntensity / isPlaying.

local Types = require(game:GetService("ReplicatedStorage").shared.vfx.Types)

export type EffectKind = Types.EffectKind

export type EffectHandle = {
    id: string,
    kind: EffectKind,
    stop: (self: EffectHandle) -> (),
    setIntensity: (self: EffectHandle, intensity: number) -> (),
    getIntensity: (self: EffectHandle) -> number,
    isPlaying: (self: EffectHandle) -> boolean,
}

local EffectHandleModule = {}
EffectHandleModule.__index = EffectHandleModule

export type Config = {
    id: string,
    kind: EffectKind,
    intensity: number,
    onStop: () -> (),
    onIntensity: ((number) -> ())?,
}

function EffectHandleModule.new(config: Config): EffectHandle
    local self = setmetatable({
        id = config.id,
        kind = config.kind,
        _intensity = config.intensity,
        _playing = true,
        _onStop = config.onStop,
        _onIntensity = config.onIntensity,
    }, EffectHandleModule)
    return (self :: any) :: EffectHandle
end

function EffectHandleModule:isPlaying(): boolean
    return self._playing
end

function EffectHandleModule:getIntensity(): number
    return self._intensity
end

function EffectHandleModule:setIntensity(intensity: number)
    if not self._playing then
        return
    end
    self._intensity = math.clamp(intensity, 0, 4)
    if self._onIntensity then
        self._onIntensity(self._intensity)
    end
end

function EffectHandleModule:stop()
    if not self._playing then
        return
    end
    self._playing = false
    self._onStop()
end

return EffectHandleModule
