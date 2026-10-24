# 04 — Typography

Типографика в играх — система **ролей + углового размера**, не «красивый шрифт».

---

## Выбор шрифта (профессиональный критерий)

### Что важно

1. **x-height** — достаточный (мелкий текст читается).  
2. **Open apertures** — c, e, a не замыливаются.  
3. **Distinct digits** — `1/I/l`, `0/O` различаются (критично для cash / odds).  
4. **Weight axis** — Regular → Medium → Bold → Black для hierarchy без второго family.  
5. **Licensing** — для Roblox: встроенные `Font` / `FontFace` или загруженные с правами.

### Сколько семейств

| Бюджет | Правило |
|--------|---------|
| Проф. минимум | **1 family** + weights |
| Допустимо | 1 display (редко) + 1 UI body |
| Запрет | 3+ fonts, script+pixel+serif в одном HUD |

Display font — только для splash / hatch title, не для ammo.

### Roblox pragmatic set

Часто используют:

- **Gotham / GothamBold / GothamBlack** — UI body & numeric  
- **GothamMedium** — secondary  
- Избегай Fancy / Cartoon для competitive readability  

Если бренд требует ornate — ограничь **title modal**, body остаётся нейтральным.

---

## Type roles (назначь имена)

| Role | Использование | Вес |
|------|---------------|-----|
| `display` | Score pop, hatch name | Black / Bold, редко |
| `title` | Modal / section headers | Bold |
| `body` | Основной текст | Medium / Regular |
| `caption` | Hints, timestamps | Regular, muted color |
| `numeric` | Cash, MPS, 1-in-X, timers | Bold/Black, tabular feel |
| `button` | Labels on controls | Bold, all-caps только если letter-spacing осознан |

В коде: `theme.Font.*` + `layout.text(designPx)`.

---

## Scale

От **floor** (минимально читаемый размер на платформе) строй вверх ratio:

| Контекст | Ratio | Зачем |
|----------|-------|-------|
| Dense HUD | ~1.25 (Major Third) | Шаги различимы, не огромны |
| Menus / marketing | ~1.333 (Perfect Fourth) | Ясная иерархия заголовков |

Пример HUD scale (design px @ reference 1080p phone-friendly):

`11 → 12 → 14 → 16 → 18 → 22 → 28`

Не добавляй размеры вне шкалы (`13`, `17`, `19`) без причины.

### Дистанция и angular size

| Платформа | Практический floor body |
|-----------|-------------------------|
| Phone / handheld ~30cm | ~14–16px design часто ок |
| Desktop | ~14–18 |
| TV / couch ~2–3m @1080p | часто **20–28px** body |

Roblox multi-device: один **design space** + `layout.text()` scale (см. `UI_ADAPTIVITY.md`), не ручные if phone.

---

## Line length & leading

- UI labels: 1 строка предпочтительно; wrap только в модалках.  
- Line-height: **кратен 4** (20/24/28…), лучше согласовать с 8pt grid.  
- Paragraph (редко в HUD): 45–75 символов.  
- Letter-spacing: +0 на body; лёгкий tracking на ALL CAPS captions.

---

## Числа и flex

Если primary flex = `1 in X`:

- Odds **крупнее** displayName.  
- Один форматтер (`FormatOneIn`, `shortNumber`) — везде одинаково.  
- Не смешивай `1/1000` и `1 in 1K` в одном продукте.

### Odds-as-hero scale (sim / breed)

Design px @ 1280×720 reference (via `layout.text`):

| Role | Size | Weight |
|------|------|--------|
| Nest / panel odds hero | 28–36 | GothamBlack |
| Creature name | 14–16 | GothamBold |
| Meta `$/s` / cost | 12–14 | GothamMedium |
| Compact badge | 18–22 | GothamBlack |

Rule: odds TextSize ≥ name × **1.5**. If space fails, shrink name first.

Currency: всегда с символом/иконкой; анимация числа = spring display, логика по authoritative value.

---

## Локализация

- Заложи **+30%…+40%** длины для DE/RU/PT.  
- Truncate с ellipsis только где есть tooltip / details.  
- Не зашивай ширину кнопки под английский «OK».

---

## Анти-паттерны типографики

- TextScaled на всём подряд (ломает hierarchy).  
- Outline 4px «чтобы читалось» вместо panel/contrast.  
- Тень текста как единственный contrast hack на busy background.  
- Разный TextSize у соседних chips без роли.

---

## DoD типографики

- [ ] Roles в theme  
- [ ] Scale без rogue sizes  
- [ ] Numeric distinct  
- [ ] Worst-case scene readable  
- [ ] Locale stress (+30%) не ломает CTA
