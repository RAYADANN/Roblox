# 02 — Attention & Visual Hierarchy

## Цель

Игрок за **≤500ms** понимает: что важно, что можно игнорировать, куда жать дальше.  
Без иерархии всё конкурирует → ничего не читается → UI кажется «дешёвым» даже при дорогих ассетах.

---

## Куда смотрит глаз (практика игр)

1. **Движение / изменение** — мигание, tween scale, fill bar.  
2. **Высокий контраст** — светлое на тёмном (или наоборот).  
3. **Крупный размер / толстый вес**.  
4. **Насыщенный акцент** среди muted.  
5. **Центр / near gaze** (crosshair, персонаж).  
6. **Углы** — вторично; туда кладут persistent state.  
7. **Орнамент и фон** — почти не смотрят (и не должны).

Используй это как рычаги. Не включай все сразу на одном элементе — иначе «всё орёт».

---

## Четыре уровня веса (держи ≤4)

| Уровень | Визуальный вес | Когда |
|---------|----------------|-------|
| **Critical** | Large + high contrast + motion | Low resource, ошибка, угроза, confirm destructive |
| **Important** | Medium + clear accent | Primary CTA, objective, выбранный tab |
| **Informational** | Small, readable, quiet | Secondary stats, captions, helper |
| **Ambient** | Near-blend | Decorative frame, soft glow, world chrome |

Ошибка новичков: 10 элементов на уровне Important.

---

## Рычаги иерархии

| Рычаг | Правило |
|-------|---------|
| **Size** | Больше = важнее. Odds/1-in-X крупнее имени, если это primary flex. |
| **Contrast** | Critical text ≥7:1; body ≥4.5:1; UI chrome ≥3:1 к соседу. |
| **Color** | Один accent на секцию. Semantic только для статуса. |
| **Position** | Top / near gaze / CTA-зона = важнее. |
| **Proximity** | Связанное рядом (Gestalt). Разное — разнести. |
| **Whitespace** | Изоляция = вес. Теснота = «шум». |
| **Motion** | Только для изменения state / привлечения; не AFK-декор. |
| **Weight/font** | Black/Bold для numeric hero; Medium для body. |

---

## Зоны экрана (HUD template)

```
┌────────────────────────────────────────────┐
│ TL: persistent identity     TC: objective  │
│     resources / chips       TR: secondary  │
│                                            │
│              CENTER: gaze                  │
│         prompts · FX · reticle             │
│                                            │
│ BL: vitals / tools     BC: toast/dialogue  │
│ BR: ammo / abilities / shop entry          │
└────────────────────────────────────────────┘
```

- **Corners** — то, что читают периферией.  
- **Center** — только momentary (не permanent shop).  
- **Bottom-center** — narrative / system messages.  
- Не ставь два Critical в противоположных углах без нужды.

Safe area: не клади hit-critical UI под notch / home indicator / TV overscan (~5%).

---

## Progressive disclosure

| Режим | Примеры |
|-------|---------|
| Always | Cash, HP если урон частый |
| Contextual | Prompt у объекта; status effect пока активен |
| Flash-then-hide | Objective update 2–3s |
| On-demand | Inventory, settings, full map |

Veteran players часто хотят **меньше** HUD — опция density = признак проф. продукта.

---

## F-pattern / Z-pattern в меню

- Списки: title слева → value справа (scan).  
- Модалка: title → content → primary CTA справа/снизу (platform convention).  
- Не прячь destructive рядом с primary без confirm.

---

## Тест иерархии (обязательный)

1. Скрин → blur 8px: видна ли форма CTA / critical?  
2. Grayscale: остаётся ли порядок важности?  
3. 2 секунды показа новичку: назвал ли top-3?  
4. Combat / busy scene: critical всё ещё читается?

Если нет — уменьши вес вторичного, не добавляй glow.
