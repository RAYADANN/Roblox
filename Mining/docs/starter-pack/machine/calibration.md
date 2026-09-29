# Calibration — обновление машины после проекта

> Запускай после **каждого** Phase 6 LEARN. Раз в квартал — полный pass + обновление `03-top50`.

---

## Когда калибровать

| Событие | Действие |
|---------|----------|
| После project log | Лёгкая калибровка (30 мин) |
| После 2 проектов | Пересмотр scorecard весов |
| После 3 проектов | Обновить personal engine rankings |
| Квартал | Обновить top-50 snapshot |
| Провал PROVE | Записать verb anti-pattern |

---

## 1. Scorecard calibration

После 2+ project logs сравни **score vs tier**:

| Блок | Вопрос |
|------|--------|
| A Hook | Коррелирует с D1 / bounce? |
| B Engines | Какие engines ты реально ship'ишь? |
| C Retention | Предсказывает D7? |
| D Ship | Ты стабильно укладываешься в 40d? |
| E Social | Завышали social без moderation? |

**Действие:** если блок не коррелирует 2 раза подряд — снизь вес или уточни критерии в `09-idea-checklist.md`.

Пример записи в `machine/calibration-log.md`:
```markdown
## 2026-08 — после Project 2
- Block E overvalued: E4 social scored 8 but D7 flat → require moderation plan for E4 points
- Block D undervalued: ship speed predicted tier better than scorecard total
```

---

## 2. Engine personal rankings

Веди таблицу **твоя скорость × твой tier**:

| Engine | Projects tried | Avg tier | Ship difficulty (1–5) | Keep priority |
|--------|----------------|----------|-------------------------|---------------|
| E1 | | | | |
| E2 | | | | |
| E3 | | | | |
| E4 | | | | |
| E5 | | | | |
| E6 | | | | |
| E7 | | | | |

**Правило N+1:** приоритет engines с лучшим tier/effort, не «что в моде».

---

## 3. Shelf status updates

| Полка | Твой опыт | Статус |
|-------|-------------|--------|
| | CCU / learnings | 🟢🟡🔴 |

Обновляй после каждого flagship. Личная карта полок важнее generic top-50.

---

## 4. PROVE gate tuning

Если слишком много kill или слишком мало:

| Симптом | Действие |
|---------|----------|
| 80% kill на PROVE | Gates слишком жёсткие ИЛИ diverge плохой → усиль Red Team |
| 0% kill, все BUILD fail | Gates слишком мягкие → подними session bar |
| BUILD ok, D1 мёртв | Проблема не PROVE → калибруй hook/thumbnail block A |

---

## 5. Agent prompt tuning

После проекта отметь в [agent-prompts.md](./agent-prompts.md):

- Что агенты **угадали**
- Что **оптимистично соврали** (scope, CCU)
- Какие constraints добавить в промпт

---

## 6. Quarterly market refresh

Раз в 3 месяца:
1. Обновить `03-top50-rank-analysis.md` (CCU, новинки)
2. Проверить `05-roblox-algorithm` (DevForum)
3. Пересмотреть 🔴 полки в `03`

Без этого машина предсказывает **прошлое**.

---

## Calibration log (создай и веди)

Файл: `machine/calibration-log.md`

```markdown
# Calibration Log

## YYYY-MM-DD — после Project N
### Scorecard changes
-

### Engine priority changes
-

### PROVE gate changes
-

### Agent prompt changes
-

### Shelf map changes
-
```
