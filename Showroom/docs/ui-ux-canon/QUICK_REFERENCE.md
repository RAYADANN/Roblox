# QUICK REFERENCE — Professional Game UI/UX

Читай это перед любым UI-изменением. Сначала ступень: **[00-priority-ladder.md](./00-priority-ladder.md)**.

---

## 5 законов (порядок важности)

1. **Readability** — если не читается на худшем фоне, стиль бесполезен.  
2. **Hierarchy** — глаз знает куда смотреть за ≤0.5s. ≤4 уровней веса.  
3. **Consistency** — один язык: цвет, радиус, stroke, confirm/cancel.  
4. **Feedback** — каждый input → visual (± audio) ≤100ms.  
5. **Progressive disclosure** — на экране только то, что нужно сейчас.

---

## Цвет (минимум)

| Слой | Роль |
|------|------|
| Base / bg1 | Фон UI |
| Surface / bg2–3 | Панели |
| Text / ink | ≥4.5:1; critical ≥7:1 |
| Accent (1–2) | CTA |
| Semantic | success / warning / danger / info |

Семантические имена. Не color-only. Акцент ≠ цвет мира.

Шаблон: [templates/theme-token-sheet.md](./templates/theme-token-sheet.md)

---

## Тип / chrome / внимание

- 1–2 font families; roles: display/title/body/caption/numeric.  
- Scale ~1.25 HUD / ~1.333 menus; line-height ×4; space 8pt.  
- Radius 2–4 tokens; stroke 1–2px; elevation 0–3; без glow-спама.  
- Critical → size+contrast+motion; углы = persistent; центр = momentary.

---

## Timing (см. 21)

Press 0–16ms · Modal in 150–250 · Out быстрее · Toast 2–4s · Hit ≥44 (sim ≥48)

---

## По задаче — куда идти

| Задача | Файлы |
|--------|-------|
| Не утонуть | 00 |
| Новый экран | templates/screen-brief → 19/20 → 07/09 → 18 |
| Палитра | 03 + theme sheet |
| Roblox sim | **20** + R11 |
| World prompts | 10 + 22 |
| Метрики playtest | 21 + playtest-scorecard |
| Учиться на хитах | references/ |
| DoD | 18 |

---

## Do / Don't

**Do:** ladder · tokens · worst-case test · world=HUD language · empty states.  
**Don't:** ornament before L3 · default prompts · neon pads · color-only · magic px.
