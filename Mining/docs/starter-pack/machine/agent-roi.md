# Agent ROI — протокол 10/10

> **Проблема:** diverge без PROVE = отрицательный ROI.  
> **Цель:** агенты только там, где дешевле/быстрее, чем одиночное мышление + Studio.

---

## Правило нулевого дня

```
Нет PROVE graybox → нет diverge round 2
Нет shipped game → нет больше 1 страницы новых docs
```

---

## ROI по ролям

| Роль | ROI | Когда вызывать |
|------|-----|----------------|
| **Red Team** | 9/10 | После diverge, перед PROVE pick |
| **Engineer Veto** | 9/10 | После diverge, перед BUILD |
| **Diverge (×3)** | 7/10 | **1 раз** на проект, timebox 4ч |
| **Post-launch Analyst** | 10/10 | Только с реальными метриками |
| **Diverge round 2+** | 1/10 | Запрещено без PROVE kill log |
| **Full GDD от агента** | 2/10 | Только one-pager ≤ 1 стр |

---

## Протокол одного проекта

### Шаг 0 — INTAKE (ты, 30 мин)
- KPI, genre lifecycle tag (см. ниже)
- Kill criteria
- **Без агентов**

### Шаг 1 — DIVERGE (1 раунд, 3 агента, 4ч max)
**Промпт меняется:**
- Запрещено: self-score, full MVP, CCU fantasy
- Обязательно: PROVE scope 3–5 дней, kill criteria, founder fit G, audience age G2

**Выход:** 3 × **half-page** (не GDD)

### Шаг 2 — CONVERGE (2ч)
- Red Team + Engineer **параллельно**
- Ты выбираешь **1** за 48ч
- **Запрещено:** новые идеи от агентов

### Шаг 3 — PROVE (3–5 дней, Studio)
- **Без агентов** кроме 1 playtest-анализа в конце
- Gate: session / want more / understood

### Шаг 4 — BUILD (solo + Cursor)
- Engineer **только** если scope slip > 1 нед

### Шаг 5 — LAUNCH + genre window
- См. lifecycle tag — сколько недель кормить

### Шаг 6 — ANALYST (1 агент, post-metrics)
- Только predictions vs reality → calibration-log **1 запись**

---

## Что убрать из промптов

| Убрать | Почему |
|--------|--------|
| `Self-score ≥ 32/40` | Агенты завышают |
| `/48` scale | Только /40 + Founder F + Audience G |
| CCU stretch 50k+ | Фантазия |
| Full monetization essay | После PROVE go |

## Что добавить

| Добавить | Почему |
|----------|--------|
| **Genre lifecycle tag** | Mining = 4–6 нед revenue window |
| **PROVE-only deliverable** | Агент не пишет 10-system MVP |
| **Founder Fit F (0–8)** | Ты убил Untangle/Bury правильно |
| **Audience G (0–8)** | 9–14 thumbnail safe |
| **Hard stop:** «no round 2» | Anti-pattern |

---

## Genre lifecycle tags (revenue window)

| Тег | Типичный пик | Сколько кормить | Стратегия $ |
|-----|--------------|-----------------|-------------|
| **L1_BURST** | Нед 1–4 | 4–6 нед max | Aggressive launch, sim #2 в параллель |
| **L2_MID** | Нед 2–8 | 2–3 мес | Weekly liveops |
| **L3_EVERGREEN** | Мес 3+ | Годы | Double down (RP, skill) |

**Mining / incremental sim / brainrot tycoon → L1_BURST**  
Deep Digger = **L1_BURST**. Не 5 месяцев. **4–6 недель** extract max → следующая игра.

---

## 10/10 checklist (перед любым agent call)

- [ ] Это PROVE post-mortem, Red+Engineer, или единственный diverge?
- [ ] Следующий шаг после ответа = Studio?
- [ ] Timebox записан?
- [ ] Нет round 2 diverge?
- [ ] Нет нового .md файла?

Если 2+ «нет» — **не вызывай агента.**

---

## Deep Digger (L1_BURST) — agent use

| Делать | Не делать |
|--------|-----------|
| Ship | Diverge sim #2 до week 2 DD live |
| Week 2: Analyst с метриками DD | 5-месячный liveops plan |
| Week 4: 1 diverge для sim #2 если DD < pivot threshold | Ещё один mining idea |

**Pivot threshold DD (пример):** к концу нед 4 — DevEx < $150 **и** CCU peak < 500 → sim #2 PROVE на нед 5.
