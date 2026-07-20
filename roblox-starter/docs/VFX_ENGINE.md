# VFX Engine — production client FX runtime

> Цель: **топ-уровень Roblox VFX** (не Unreal). Красота на PC, тепловой бюджет на телефонах.
> Полный API: kinds → declarative layers → handles → pluggable camera.

## Структура

```
src/shared/vfx/
  Types.luau          EffectKind, tiers, budgets
  QualityLogic.luau   pure: device→tier, soft-LOD, gates (CI)
  LayerDef.luau       EffectDef + LayerStep (данные)

src/client/vfx/
  VfxEngine.luau      play/stopAll/register/registerLayer
  EffectHandle.luau   stop / setIntensity / isPlaying
  LayerRunner.luau    исполняет type="Emit"|"Projectile"|...
  QualityProbe.luau   device + FPS EMA
  BudgetGate.luau     concurrent cap
  Timeline.luau       stagger слоёв
  ScreenFX.luau       ColorCorrection + Blur
  InstancePool.luau   пул для своих частых инстансов
  camera/
    HumanoidOffsetDriver  ← default Roblox character camera
    ShakeBusDriver        ← custom/scriptable/spectate/vehicle
    NoopDriver            ← reduce motion / cutscene lock
  layers/             Emit, Light, Shockwave, Beam, Trail,
                      LoopEmit, Projectile, Highlight
  presets/            готовые EffectDef
```

## Effect kinds

| Kind | Жизненный цикл | Контекст | Пример |
|------|----------------|----------|--------|
| **Burst** | auto-stop по `lifetime` | `cframe` | ImpactBurst, CastBurst |
| **Loop** | до `handle:stop()` | `cframe` | PowerAura |
| **Attached** | до `stop()` | `target: BasePart` | HandGlow |
| **Projectile** | A→B + impact | `from`, `to` | NeonBolt |
| **Screen** | short | цвет/intensity | DamageFlash |
| **Chain** | multi-point (расширяй слоем) | payload | custom |

```luau
local handle = VfxController.play("PowerAura", {
	cframe = root.CFrame,
	color = Color3.fromRGB(120, 80, 255),
	intensity = 1,
})
-- ...
handle:setIntensity(0.4)
handle:stop()
```

## Camera — не один способ

VFX **не владеет** `Camera.CFrame`. Драйвер выбирает игра:

| Mode | Когда |
|------|--------|
| `HumanoidOffset` | Обычный персонаж / default camera (дефолт) |
| `ShakeBus` | Scriptable camera, spectate, vehicle, cutscene — **ты** читаешь offset |
| `Noop` | Reduce motion / камера залочена |
| Custom `cameraDriver` | Полный свой адаптер под контракт |

### Default
```luau
VfxController.start() -- HumanoidOffset
```

### Свой camera controller
```luau
VfxController.start({
	cameraMode = "ShakeBus",
	onShakeOffset = function(offset)
		-- добавь offset к финальному CFrame камеры
		myCamera:setShakeOffset(offset)
	end,
})

-- или смени на лету:
VfxController.setCameraMode("Noop")
VfxController.setCameraMode("HumanoidOffset")
```

### Контракт драйвера
```luau
shake(amplitude, duration, roughness?)
setRumble(amplitude, roughness?)  -- Loop aura
isSupported() -> boolean
destroy()
```

## Свой эффект (данные, не копипаста)

```luau
engine:register({
	id = "SmokeDash",
	kind = "Burst",
	priority = "High",
	lifetime = 1.0,
	layers = {
		{ at = 0, type = "Emit", count = 30 },
		{ at = 0, type = "Trail", duration = 0.4, minTier = "Medium" },
		{ at = 0.05, type = "Shockwave", endSize = 6 },
		{ at = 0, type = "CameraShake", amplitude = 0.12, minTier = "Medium" },
	},
})
```

### Built-in layer types

`Emit` `Light` `Shockwave` `Beam` `Trail` `LoopEmit` `AttachedEmit` `Projectile` `Highlight` `ScreenFlash` `CameraShake` `CameraRumble`

Свой слой:
```luau
engine:registerLayer("MyGlyph", function(ctx, step)
	-- ctx.folder, ctx.cframe, ctx.color, ctx.budget, ctx.trackStop(...)
end)
```

## Качество / тепло

| Tier | Particles | Lights/Beams | Screen/Shake | Loops/Trails |
|------|-----------|--------------|--------------|--------------|
| Low | ×0.3 | off | off | off |
| Medium | ×0.6 | on | on | on |
| High | ×1 | on | on | on |
| Ultra | ×1.3 | on | on | on |

- Device + `SavedQualityLevel` → base tier  
- FPS EMA → adapt down  
- Soft-LOD по дистанции (`distanceScale`)  
- Concurrent cap + priority gate  
- `minTier` на каждом слое  
- Только `Emit(n)` для burst; loop rate режется scale  

## Сеть

Сервер шлёт «каст/хит» → **все релевантные клиенты** `play()`.  
Не спавни ParticleEmitter на сервере.

## UI FX vs World VFX

| | `ui/fx` FxKit | `client/vfx` |
|--|---------------|--------------|
| Где | ScreenGui | Workspace + Lighting |
| Для | coins, hatch UI | powers, combat, auras |

## Антипаттерны

- Один способ shake через `camera.CFrame` для всех режимов камеры  
- Серверный VFX  
- Rate=∞ на мобиле  
- Loop без `handle:stop()`  
- Игнор `reduceMotion` / Low tier  

## Flipbook atlases + playground

Custom 4×4 atlases (generated + uploaded):
- Neon: `rbxassetid://117687641569968` → `TextureCatalog.NeonBurst`
- Smoke: `rbxassetid://131840252392616` → `TextureCatalog.SmokePuff`
- Source PNGs: `assets/vfx/*.png` (`tools/gen_flipbooks.py`)

Signature presets: `NeonImpact`, `SmokeDash`.

Studio playground: `VfxLabPlayground` + `StarterPlayerScripts.VfxLabDemo`
- Right panel buttons, hotkeys `1-4`, auto cycle, camera modes
- Auto-rebuilds `Workspace.VfxLab` if empty
