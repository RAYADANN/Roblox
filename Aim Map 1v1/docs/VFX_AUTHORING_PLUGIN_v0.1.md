# VFX Authoring Plugin — v0.1 Spec

> **Цель v0.1:** в Studio собрать timed VFX на таймлайне → увидеть preview → одним кликом получить пресет под наш `EffectDef` / `LayerRunner`.  
> Не «лучше всех плагинов на рынке». **Понятный authoring → наш движок.**

**Статус:** спека (без кода). Реализация — по явному OK.  
**Связь:** runtime = `docs/VFX_ENGINE.md`, слои = `shared/vfx/LayerDef.luau`.

---

## DoD v0.1 (готово, когда)

1. Открыл плагин → создал эффект → расставил ≥3 слоя на таймлайне → Play scrub/preview.
2. Export пишет валидный `EffectDef` (Luau или JSON→Luau), который `VfxEngine:register` принимает без правок руками.
3. Пресет играет в `VfxLabPlayground` как остальные.
4. Автор понимает **что / когда / какой тип слоя** без чтения исходников движка.

---

## Архитектура (одна петля)

```
Studio Plugin (Edit)
  → Document (JSON in-memory + optional save)
  → PreviewHost (клон якоря + LayerRunner-совместимый runner ИЛИ тонкий preview)
  → Export → src/client/vfx/presets/<Id>.luau
  → Rojo sync → Playtest в VfxLab
```

- **Источник правды документа:** JSON schema ниже (не инстансы в Workspace как SoT).
- **Источник правды рантайма в игре:** по-прежнему `EffectDef` + `LayerRunner`.
- Плагин **не** патчит `init.client` сам; export + чеклист «добавь в `vfx/init.luau`» (v0.2 — авто-register).

---

## Tracks (типы дорожек v0.1)

Только то, что уже есть в `LayerRunner`:

| Track / `type` | Поля (минимум) | Preview |
|----------------|----------------|---------|
| `Emit` | at, count, texture?, flipbook*, size*, speed*, life*, spread?, drag?, emitStyle?, minTier? | ParticleEmitter burst |
| `Light` | at, range, brightness, duration, minTier? | PointLight pulse |
| `Shockwave` | at, startSize?, endSize, duration, minTier? | ring part |
| `Beam` | at, length, width0?, width1?, duration, minTier? | Beam flash |
| `CameraShake` | at, shakeProfile \| amplitude+duration+roughness, minTier? | log / soft offset in plugin cam |
| `CameraRumble` | at, rumble, roughness?, minTier? | same |
| `ScreenFlash` | at, brightness, duration, blurSize?, minTier? | viewport vignette / note |
| `Sound` | at, soundId, pitch? | Sound:Play |
| `Haptic` | at, hapticProfile?, hapticStrength? | skip in Edit (noop) |

Один документ = один `EffectDef`. Слои = плоский список `{ at, type, ... }` (как сейчас). UI может группировать по track type, данные — flat.

---

## JSON schema (документ плагина)

```json
{
  "schemaVersion": 1,
  "id": "MyUltBlast",
  "kind": "Burst",
  "priority": "Critical",
  "lifetime": 3.5,
  "maxDistance": null,
  "meta": {
    "title": "My Ult Blast",
    "notes": "optional"
  },
  "layers": [
    {
      "at": 0.0,
      "type": "Emit",
      "count": 24,
      "texture": "rbxassetid://…",
      "flipbookLayout": "Grid4x4",
      "flipbookMode": "OneShot",
      "flipbookFpsMin": 16,
      "flipbookFpsMax": 22,
      "emitStyle": "fire",
      "sizeScale": 1.2,
      "speedMin": 8,
      "speedMax": 20,
      "lifetimeMin": 0.4,
      "lifetimeMax": 0.8,
      "spread": 180,
      "drag": 1,
      "minTier": "Medium"
    },
    {
      "at": 0.05,
      "type": "Shockwave",
      "endSize": 14,
      "duration": 0.35
    }
  ]
}
```

**Правила:**

- `id` — PascalCase, уникален, = имя файла пресета.
- `at` ≥ 0; `lifetime` ≥ max(`at`) + небольшой хвост (плагин считает default).
- Неизвестные поля при export **игнорируются** (как LayerRunner).
- Текстуры: только `rbxassetid://` или ключ из `TextureCatalog` (`"catalog:FireBlast"` → resolve при export).

---

## UI плагина (кнопки v0.1)

**Toolbar / header**

| Кнопка | Действие |
|--------|----------|
| New | пустой документ |
| Open | JSON с диска / Selection attribute |
| Save | JSON локально (PluginSettings или файл через prompt) |
| Export Preset | генерит Luau `EffectDef` + копирует в clipboard + путь `presets/<Id>.luau` |
| Play / Stop | preview от t=0 |
| Register checklist | текст: добавь require в `vfx/init.luau` |

**Timeline**

- Scrubber + playhead, zoom не обязателен (v0.1: фиксированная шкала 0…lifetime).
- Add Layer → выбор type → клик на время или `at = playhead`.
- Selected layer → property panel (числа/enums, без curve editor).
- Delete / Duplicate layer.
- Snap: 0.05s.

**Viewport**

- Якорь `PreviewAnchor` (Part) в folder плагина.
- Preview = те же типы слоёв, что export (желательно shared preview module, не копипаста формул).

**Inspector (эффект)**

- id, kind, priority, lifetime, color default для preview.

---

## Что не входит в v0.1

- Attachment-rig / sockets на персонаже  
- Keyframe Part / Mesh deformation / Moon-like animation  
- LoopEmit, Trail, Projectile, Highlight (добавим в v0.2 по запросу)  
- Авто-правка `init.luau` / git commit  
- Collaborative editing, marketplace publish  
- Полный паритет с ParticleEmitter (NumberSequence curve UI) — только упрощённые поля + `emitStyle`  
- Сетевой PlayVfx / серверный trigger из плагина  

Это **намеренно**: v0.1 = понятный timed composer → движок.

---

## Оценка «несколько дней» (рабочий план)

| День | Результат |
|------|-----------|
| 1 | Plugin shell + JSON document + timeline UI (add/select/scrub) |
| 2 | Preview runner для Emit/Light/Shockwave/Beam + Play/Stop |
| 3 | Export → Luau EffectDef + TextureCatalog resolve + lab smoke test |
| +0.5 | Polish: duplicate, snap, lifetime auto, checklist register |

Риск: Studio plugin API / Rojo path write — закладываем clipboard-export как fallback в тот же день.

---

## Открытые решения (закрыть до кода)

1. **Preview:** шарить код с `client/vfx` (через Plugin + require mirrored modules) или отдельный thin preview? → **Recommended:** thin preview + те же поля; shared `stylePack` вынести в `shared/vfx` при необходимости.  
2. **Save:** PluginSettings vs файл на диск? → **Recommended:** clipboard + Save JSON в PluginSettings; файл — если легко.  
3. **Первый эффект-эталон для dogfood:** CinemaCataclysm slice или новый короткий `AuthoringDemo`?

---

## v0.2 (не сейчас, якорь)

Attachments, LoopEmit/Trail/Projectile, auto-register stub, undo stack, library browser (`TextureCatalog`).
