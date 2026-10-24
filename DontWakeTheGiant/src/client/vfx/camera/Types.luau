--!strict
-- Контракт камеры. Игра выбирает драйвер — VFX не владеет Camera.CFrame.

export type CameraDriver = {
    --- Амплитуда в studs-эквиваленте, duration сек, roughness ≈ частота шума.
    shake: (self: CameraDriver, amplitude: number, duration: number, roughness: number?) -> (),
    --- Для Loop/Attached: постоянный лёгкий shake; 0 = stop rumble.
    setRumble: (self: CameraDriver, amplitude: number, roughness: number?) -> (),
    isSupported: (self: CameraDriver) -> boolean,
    destroy: (self: CameraDriver) -> (),
}

export type CameraMode = "HumanoidOffset" | "ShakeBus" | "Noop"

return {}
