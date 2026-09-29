# Learning Loop — как проект улучшает машину

> Машина **не умнеет от анализа**. Она умнеет от **логов + calibration**.

---

## Цикл

```
Проект N
   │
   ├─► Predictions (scorecard, KPI target, гипотезы)
   │
   ├─► Reality (метрики, playtest, postmortem)
   │
   ├─► Delta (где ошиблись: идея / feel / launch / economy)
   │
   └─► Update machine ──► Проект N+1 точнее
```

---

## Что записывать после КАЖДОГО проекта

### 1. Predictions vs Reality

| Поле | Predicted | Actual | Delta |
|------|-----------|--------|-------|
| Scorecard /40 | | | |
| Tier | | | |
| CCU peak 30d | | | |
| D1 | | | |
| D7 | | | |
| Revenue 30d | | | |
| Phase 3 session | | | |

### 2. Где сломалось (один primary)

- [ ] Verb / feel (PROVE fail)
- [ ] Hook / thumbnail (bounce)
- [ ] Retention design (D1 ok, D7 dead)
- [ ] Economy (нет sink / inflation)
- [ ] Social / moderation
- [ ] Scope / ship late
- [ ] Launch / discover
- [ ] Полка / конкуренция
- [ ] Тайминг / E7 (вне контроля)

### 3. Что сработало (сохранить в машину)

- Engine combo:
- Verb pattern:
- RETURN mechanic:
- Monetization:
- Clip / hook:

### 4. Правило для N+1

Одно предложение: «В следующем проекте мы ___, потому что ___.»

---

## Накопление знаний по 6 проектам

| После проекта | Машина знает |
|---------------|--------------|
| #1 | Pipeline работает? PROVE gates реалистичны? |
| #2 | Какие engines ты ship'ишь быстрее |
| #3 | Калиброванный scorecard (какие блоки врут) |
| #4 | Launch playbook (thumbnail, timing) |
| #5 | Economy defaults для твоего жанра |
| #6 | Hit-rate по tier + личный «sweet spot» полки |

---

## Типы проектов в году (рекомендация)

Не все 6 = «полный MVP». Чередуй:

| Тип | Длина | Цель для машины |
|-----|-------|-----------------|
| **Calibration** | PROVE only (1 нед) | Отладить Phase 3 gates |
| **Sprint** | PROVE + mini MVP (4 нед) | Проверить engine combo |
| **Flagship** | Full pipeline (8 нед) | Максимальный tier target |

**Пример года:**
1. Calibration — Untangle graybox
2. Sprint — Pop a Puff mini
3. Flagship — лучший из #1–2
4. Sprint — новый verb
5. Flagship — удвоение down на working combo
6. Flagship — launch + LiveOps 60 дней

Так **каждый успешнее** не значит «каждый больше CCU» — иногда #2 учит больше чем #3 зарабатывает. Сравнивай **tier + learnings applied**.

---

## Метрика «машина сильнеет»

Раз в квартал ответь:

| Вопрос | Q1 | Q2 | Q3 | Q4 |
|--------|----|----|----|----|
| PROVE kill rate до BUILD | | | | |
| Средний tier проектов | | | | |
| Scorecard error (pred vs actual tier) | | | | |
| Дней от идеи до PROVE | | | | |
| Дней от PROVE go до ship | | | | |

**Цель к декабрю:**
- PROVE kill **до** BUILD > 50% (отсекаешь мусор рано)
- Scorecard error снижается
- Tier растёт проект к проекту
- Время diverge сокращается (знаешь что работает)

---

## «Предсказание будущего» — рабочее определение

К декабрю машина должна отвечать:

1. **Какой verb** ты ship'ишь с >70% шансом пройти PROVE
2. **Какие engine combos** дают тебе лучший tier / день
3. **Какие scorecard блоки** коррелируют с реальным tier (после 4+ логов)
4. **Какая полка** для тебя зелёная с учётом скорости ship
5. **Какой launch checklist** даёт лучший D1

Это **предсказательная сила** для solo dev. Не crystal ball.
