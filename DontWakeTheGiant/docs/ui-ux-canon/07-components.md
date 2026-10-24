# 07 — Components

Каждый компонент — контракт: структура, states, размеры из tokens, feedback.

---

## Общий контракт interactive

Обязательные states: `default · hover(desktop) · pressed · disabled · focused/selected`.

Правила:

1. Visual press **до** сети (optimistic / pending).  
2. `AutoButtonColor = false` — сами красим states.  
3. Hit ≥44.  
4. Sound optional, но vocabulary единый.  
5. Disabled объясним (tooltip / caption), не «мёртвая кнопка».

---

## Button

### Иерархия кнопок (как в проф. DS)

| Variant | Когда | Визуал |
|---------|-------|--------|
| **Primary** | Одно главное действие на view | Filled accent, strongest |
| **Secondary** | Альтернатива | Outline / softer fill |
| **Tertiary / Ghost** | Cancel, low emphasis | Text button |
| **Danger** | Destroy / steal confirm | Danger semantic |
| **Premium** | IAP | Отдельный treatment, не путать с primary gameplay |

На одном экране — **один** Primary.

### Анатомия

```
Control (hit)
└─ Face (visual)
   ├─ UICorner + UIStroke + optional UIGradient
   ├─ Icon
   └─ Label
```

Scale: hover ~1.04–1.06 · press ~0.94–0.96 · spring, не линейный snap.

### Размеры

Высоты из шкалы: 40 / 48 / 56. Padding horizontal ≥16.  
Icon+label gap = 8.

---

## Icon button

Квадрат/круг; tooltip на desktop; на phone — label рядом если действие неочевидно.  
Не полагайся на «все знают шестерёнку» для редких действий.

---

## Panel / Modal shell

См. также 06 и 09.

Обязательно: title, close (touch 46), content padding из шкалы, primary actions в устойчивой зоне (footer).

---

## Card

Одна сущность (pet, upgrade, pack).

```
Card
├─ optional rarity bar
├─ media / icon
├─ title + meta
└─ action / price
```

Hover: scale ~1.02. Locked: overlay + lock + причина.  
Не делай card ради card — только если контейнер для выбора/сравнения.

---

## Chip / Resource readout

Компактный persistent status.

- Icon + animated number + optional accent bar  
- Change → soft pop scale  
- Не дублируй тот же resource в 3 местах HUD

---

## Progress / meter

- Track muted, fill semantic/accent  
- Tween fill 200–400ms  
- Critical threshold: цвет + не только цвет (stripe / icon)  
- Label: текущее/макс или % — один формат везде

---

## Tabs / Dock

- Active: bar 3px + bg tint + full icon opacity  
- Inactive: muted  
- Count badge: spring in  
- Переключение: crossfade / short slide, не hard cut без причины  
- 3–7 top-level tabs; больше → sidebar / overflow

---

## List row

Высота из `ROW_H`.  
`[Icon][Title/Subtitle ........ Value][Chevron]`  
Divider hairline. Stable keys в React lists.

---

## Toast / Banner

| Тип | Цвет | Длительность |
|-----|------|--------------|
| Info | info | 2–3s |
| Success | success | 2–3s |
| Warn | warning | 3–4s |
| Error | danger | 3–5s или sticky |

Не спамь: coalesce одинаковые.  
Stack: top-center или под safe area; `Active=false` если не кликабельны.

---

## Input / Slider / Toggle

- Focus ring обязателен  
- Error: danger stroke + message под полем + shake optional  
- Toggle: state яснее, чем цвет alone (knob position)

---

## Empty / Error / Loading states

Каждый list/panel обязан иметь:

1. **Loading** — skeleton или spinner + «не пустой экран»  
2. **Empty** — icon + title + subtitle + CTA  
3. **Error** — что сломалось + retry  

Отсутствие empty state = любительский UI.

---

## DoD компонента

- [ ] Все states  
- [ ] Tokens only  
- [ ] ≤300 строк модуль  
- [ ] useLayout / theme  
- [ ] Cleanup motors/tweens
