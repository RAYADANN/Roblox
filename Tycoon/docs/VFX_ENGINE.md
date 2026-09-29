# VFX Engine — production client FX runtime

> Цель: **топ-уровень Roblox VFX** (не Unreal). Красота на PC, тепловой бюджет на телефонах.
> Полный API: kinds → declarative layers → handles → pluggable camera.
>
> **Ядро vs демо:** runtime (`VfxEngine`, layers, QualityLogic, camera) — часть шаблона.
> Папка `presets/` + `VfxLabPlayground` — демо/dogfood (Megumin, CinemaCataclysm, OreShatter…).
> Новой игре нужны 2–5 своих пресетов; лишние demo-пресеты можно не копировать или удалить.

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
| Где | ScreenGui (`UiFxOverlay`) | Workspace + Lighting |
| Для | FloatText, FlyBurst/CoinRain, UI shockwave | powers, combat, auras |
| Кастомизация | text / texture / color / from→to **на каждую игру** | EffectDef presets |

Примитивы: `FxKit.floatText`, `FxKit.flyBurst`, `FxKit.coinRain`, `FxKit.shockwave`, `FxKit.overlay`.  
Demo в VfxLab: кнопки **UI FloatText / CoinRain / Shockwave**.  
Не через `VfxController` — вызывай из Notify/UI напрямую.

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
- Spark: `rbxassetid://137306757060329` → `TextureCatalog.SparkBurst`
- Ember: `rbxassetid://76717224586863` → `TextureCatalog.EmberTrail`
- Source PNGs: `assets/vfx/*.png` (`tools/gen_flipbooks.py`)

### AAA layering
- `StyleTokens` — palette + stagger timings (flash → peak → recovery)
- Layers `Sound` / `Haptic` on timeline (with pitch + profiles)
- `HapticsManager` respects Settings + reduceMotion (`HapticLogic` CI-tested)
- Pools: emitters, lights, shockwaves
- Metrics: active / emitters / dropped / thermal / FPS

### Preset pack
| Preset | Kind | Notes |
|--------|------|-------|
| NeonImpact / SmokeDash | Burst | Signature flipbooks |
| MeguminBlast | Burst | Ult explosion (charge → detonate → ash) |
| CinemaCataclysm | Burst | Cinematic 7-act ultimate (~7s): charge → ascension → breath → detonation → maelstrom → aftermath → fade |
| MeteorStrike | Burst | Sky streak → ground punch |
| OreShatter | Burst | Demo shatter (replace with game-specific) |
| PetAppear | Burst | Pet equip / summon |
| EggHatch | Burst | Egg crack → reveal |
| CritImpact | Burst | Critical priority, punches soft-cap |
| GroundSlam | Burst | Wide shockwave read |
| HealPulse | Burst | Soft non-combat |
| ChainStrike | Chain | Multi-point along from→to |
| UltimateCharge | Loop | Rumble + intensity ramp |
| + Impact/Cast/Bolt/Aura/Hand/Hit/Flash | — | Wired with SFX/haptics |

### Performance
- `EmitterLayer` / `LightLayer` / `ShockwaveLayer` → `InstancePool`
- `QualityLogic.thermalScale` / `applyThermal`
- Per-layer `minTier`; Stress Mode in lab forces Low + flood

### Camera
- `ShakeProfiles` Light / Medium / Heavy
- Auto-switch to `Noop` while `SettingsManager.isReduceMotion()`

### Network (Zap `PlayVfx`)
```luau
VfxBroadcaster.playAll({ effectId = "NeonImpact", pos = hitPos, intensity = 1.2 })
VfxBroadcaster.castBoltImpact(from, to)
```

Studio playground: intensity/tier/replay, Stress Mode, Drop counter, AAA presets

## Authoring (будущее)

Спека плагина-таймлайна → export в `EffectDef`: [`VFX_AUTHORING_PLUGIN_v0.1.md`](./VFX_AUTHORING_PLUGIN_v0.1.md).
