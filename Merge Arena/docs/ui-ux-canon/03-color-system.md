# 03 — Color System

Профессиональная палитра — **система ролей**, не набор «красивых» hex.  
Цель: быстрое чтение, статус без путаницы, бренд без жертвы контраста.

---

## Почему game UI жёстче WCAG

WCAG AA (4.5:1 body, 3:1 large/UI) рассчитан на спокойное чтение.  
В игре UI читают **200–400ms**, часто периферией, на шумном фоне.

| Класс | Целевой контраст |
|-------|------------------|
| Critical (HP, error, primary numeric) | **≥7:1** (AAA-like) |
| Body / labels | ≥4.5:1 |
| Large title / bold display | ≥3:1 минимум, лучше выше |
| Non-text (icon, border, focus ring) | ≥3:1 к adjacent |

Контраст считается **парой** (fg на bg), не «цвет сам по себе».

---

## Как собрать палитру (процесс)

### Шаг 1 — Контекст продукта

Ответь письменно:

1. Жанр / mood (horror, cozy, competitive, sim).  
2. Доминирующий тон мира (тёмный cave / яркий outdoor).  
3. Primary flex (что игрок должен узнавать мгновенно: `1 in X`, DPS, depth…).  
4. Платформы (phone яркий день? TV?).

UI base часто **тёмный**, даже если мир светлый — меньше clash с VFX и меньше eye strain.  
Светлая parchment-палитра допустима, если: (a) мир не вспыхивает белым, (b) accent всё ещё ≥7:1 на surface, (c) есть stroke/shadow под текст поверх мира.

### Шаг 2 — Primitive scale

Собери нейтрали + 1–2 brand hues как **шкалы** (50–900 или 1–12), не одиночные swatches.

Пример структуры:

- `neutral.0 … neutral.1000` (фон → текст)  
- `brand.100 … brand.900`  
- `success / warning / danger / info` шкалы  
- Опционально `rarity.*` (game-specific)

Инструменты: OKLCH / HSL с равными шагами lightness; проверяй perceptual steps глазом на целевом мониторе.

### Шаг 3 — Semantic tokens (имена по роли)

| Token | Роль |
|-------|------|
| `bg1` … `bg4` | Слои глубины UI |
| `surface` / `surfaceRaised` | Панель / карточка |
| `textMain` / `textSub` / `textMuted` | Текст |
| `border` / `borderStrong` | Рамки |
| `primary` / `primaryPressed` | Главное действие |
| `accent` | Highlight (один на секцию) |
| `success` / `warning` / `danger` / `info` | Статус |
| `focus` | Кольцо фокуса / selection |
| `overlay` | Backdrop модалки |

**Запрещено** в коде компонентов: `Color3.fromRGB(…)` мимо tokens.

### Шаг 4 — Четыре слоя читаемости (game UI)

1. **Deep base** — самый тёмный/светлый холст  
2. **Panel** — чуть отделён от base  
3. **Muted info** — secondary text / inactive  
4. **Vivid action** — CTA, alerts, live meters  

Action-цвета **не должны** случайно совпадать с ключевыми цветами мира (трава = collect pad = путаница).

### Шаг 5 — States

Для каждого interactive цвета определи:

`default → hover → pressed → disabled → focus → selected`

Disabled: ↓ contrast / ↑ transparency, **не** только серый без смены opacity hit-target policy.  
Focus: отдельный ring ≥3:1, не только смена fill.

---

## Выбор hue (практика)

| Нужда | Типичный выбор | Осторожность |
|-------|----------------|--------------|
| Trust / info | Blue–cyan | Не путать с link-only |
| Success / earn | Green–jade | Не единственный сигнал «можно» |
| Warning | Amber | На тёмном часто лучше золота |
| Danger / steal | Red–crimson | Photosensitivity; не flash 3–50Hz |
| Premium / rare | Gold / violet | Gold легко «жёлтит» текст — проверяй контраст |
| Neutral UI | Warm or cool gray | Выбери **один** temperature и держи |

Бренд: 1 primary + 1 secondary max в action layer. Остальное — neutrals + semantic.

---

## Rarity / odds цвета

Если rarity color-coded:

- Каждая rarity = уникальный hue **и** уникальный secondary cue (border style / icon / label).  
- Mythic/Secret не обязаны быть «ещё ярче» — лучше distinct silhouette.  
- Primary flex (`1 in X`) читается **типографикой**, цвет rarity — поддержка.

---

## Harmony без китча

Проф. системы используют:

- **Dominant / secondary / accent** (60 / 30 / 10 по площади, приблизительно).  
- Ограниченную chroma на больших площадях; высокую chroma на маленьких controls.  
- Один temperature (warm parchment **или** cool steel), не смесь random.

Избегай «AI default»: purple-on-white gradient, cream+#terracotta serif combo как единственный стиль без системы, rainbow neon outlines.

---

## Проверки палитры (DoD цвета)

- [ ] Все text/surface пары прогнаны contrast checker  
- [ ] Deuteranopia / protanopia / tritanopia simulation: статусы различимы  
- [ ] Grayscale: hierarchy жив  
- [ ] Critical UI читается на bright snow **и** dark cave (panel/stroke/shadow)  
- [ ] Нет color-only meaning  
- [ ] Tokens задокументированы в `theme.luau`

---

## Roblox note

`Color3` в sRGB; OLED phone ≠ Studio monitor. Проверяй на реальном устройстве.  
`UIGradient` не заменяет контраст base fill.
