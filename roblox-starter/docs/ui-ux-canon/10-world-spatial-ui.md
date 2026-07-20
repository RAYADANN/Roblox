# 10 — World & Spatial UI

World UI — billboards, prompts, markers. Частая причина ощущения «не топовая игра»: ScreenGui polished, мир — дефолтный Roblox.

---

## Принцип единства

World chrome = **тот же design language**, что HUD:

- Те же surfaces / ink / accent  
- Те же радиусы и stroke logic  
- Та же типографика ролей (numeric hero для odds)

Если HUD parchment/jade, а prompt — серый Default ProximityPrompt — продукт выглядит прототипом.

---

## ProximityPrompt / interaction

Проф. паттерн:

| Элемент | Требование |
|---------|------------|
| ActionText | Глагол: Collect All, Buy Creature |
| ObjectText | Контекст: `$1200 ready`, `Free preview` |
| Key/glyph | Виден (E / TAP / gamepad) |
| Hold | Progress bar если HoldDuration > 0 |
| Style | Custom UI в theme; не полагаться на default forever |

Копирайт: конкретный > абстрактный.  
`Buy` хуже, чем `Buy Creature` + цена в ObjectText.

Exclusivity: избегай двух prompt на одном кадре без нужды.

---

## Billboard hierarchy

Типичная карточка существа (pet):

1. Name (caption)  
2. **Primary flex** крупно (`1 in X`)  
3. Secondary (`$/s`)

Размер billboard растёт с важностью; MaxDistance разумный (не AlwaysOnTop на всём).  
LightInfluence = 0 для UI-карт (стабильный цвет).

---

## Pad / station preview

Roll/Buy станции:

- Header (что за станция)  
- Title (результат)  
- Odds hero  
- Meta (cost / qty)  
- Accent по rarity

Пустое состояние: «Press Roll» / Ready — не чёрный пустой label.

---

## Markers & waypoints

- Силуэт читается без цвета.  
- Кластеризация при >20–30 маркерах.  
- Не вращай UI так, что текст вверх ногами (billboard face camera).

---

## Diegetic caution

Красиво, но часто хуже a11y. Если diegetic:

- Масштаб/контраст опции  
- Дублируй critical в non-diegetic при необходимости

---

## Outdoor parchment / cream readability

Bright grass/sky kills bare ink (~2.5:1 typical). Rules:

1. **Always** put outdoor labels on a surface token (`bgChip` / cream) + bronze stroke.  
2. `LightInfluence = 0` on UI BillboardGui.  
3. Prefer **stroke elevation**, not drop-shadow images.  
4. MaxDistance: nest cards shorter than station previews; avoid AlwaysOnTop infinite.  
5. Accent bar / rarity stroke = non-color cue (CVD).

### Card + Content (layout safety)

```
Card (fill + stroke + optional AccentBar)
└─ Content (ONLY child that owns UIListLayout)
   └─ texts…
```

AccentBar as **sibling** of a UIListLayout → blank/broken cards. Never.

### Custom ProximityPrompt anatomy

| Region | Spec |
|--------|------|
| Card | theme surface, ~228×76 design |
| Key glyph | 40²; accent fill; **dark label** if accent mid-tone (AA) |
| ActionText | verb, GothamBold ~16 |
| ObjectText | price / odds / timer, secondary |
| Hold | 4px bar; fill over HoldDuration |

UiKind → accent map (collect jade, buy/roll gold, steal danger, breed purple…).

---

## DoD world UI

- [ ] Custom prompts в theme  
- [ ] Pet/station cards = screen language  
- [ ] Copy specific  
- [ ] Readable on bright/dark world (cream cards outdoors)  
- [ ] No neon prototype pads без причины  
- [ ] Card/Content layout; no chrome in UIListLayout  
- [ ] Key glyph label passes contrast on accent
