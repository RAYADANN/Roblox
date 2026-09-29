# Pipeline — конвейер одного проекта

> **Жёсткое правило:** не переходи на следующую фазу без gate. Не больше **2 diverge-раундов** за проект.

---

## Обзор

| Phase | Название | Срок | Выход |
|-------|----------|------|-------|
| 0 | INTAKE | 0.5 дня | KPI + constraints |
| 1 | DIVERGE | 1 день | 3 one-pagers |
| 2 | CONVERGE | 0.5 дня | 1 идея + cut list |
| 3 | PROVE | 3–5 дней | verb validated / killed |
| 4 | BUILD | 25–35 дней | MVP shipped |
| 5 | LAUNCH | 14–30 дней | метрики |
| 6 | LEARN | 1 день | project log |

**Итого на проект:** ~6–9 недель (6 проектов ≈ весь год с overlap на calibration).

---

## Phase 0 — INTAKE

**Вход:** решение «начинаем проект N».

**Заполни:**
```markdown
## Project N — Intake
Дата:
Target tier: P1 / P2 / P3
Предыдущий проект tier: 
Что улучшаем vs прошлый: (engine / verb / launch / monetization / ...)

### Hard constraints
- Solo days max: 40
- Systems max: 8
- Полки 🔴 запрещены: 
- Engines приоритет (из calibration): 

### Success KPI (числа)
- CCU peak 30d: 
- D1: 
- D7: 
- Revenue 30d: 

### Kill criteria (до кода)
- Прототип session < ___ min → kill verb
- D1 < ___ после soft launch → kill или pivot hook
```

**Gate → Phase 1:** KPI записаны, constraints ясны.

---

## Phase 1 — DIVERGE

**Цель:** 3 разные идеи, не вариации одной.

**Агенты:** 3× Designer с разными углами (см. [agent-prompts.md](./agent-prompts.md)):
- Systems (E5 / co-op / session)
- Incremental (E2 + verb)
- Social economy (E1/E4)

**Каждый агент обязан:**
- Прочитать docs 01–09
- Выдать one-pager + scorecard /40
- Указать kill criteria и «что режем при slip 40d»

**Gate → Phase 2:** 3 идеи с score ≥ 28/40 (ниже — не брать в converge).

**Timebox:** 1 день. Не больше.

---

## Phase 2 — CONVERGE

**Цель:** 1 идея, не 3 «хороших».

**Агент 1 — Red Team:**
- Атакует все 3 идеи
- Fatal flaw каждой
- Ранжирует 1–3 с обоснованием

**Агент 2 — Engineer:**
- Veto по scope (solo 40d)
- Cut list: что убрать из MVP
- Вердикт: GO / GO с cuts / NO для каждой

**Ты:** финальное решение. Макс 48ч после diverge.

**Gate → Phase 3:**
- Одна идея выбрана
- Engineer GO
- Score ≥ 32/40 после cuts
- Verb проверяем за ≤ 5 дней (иначе смени идею)

---

## Phase 3 — PROVE (самая важная фаза)

**Цель:** Dubit rule — enjoyable без прогрессии?

**Делай:**
- Серый прототип, placeholder art
- Только verb + feedback (звук, число, VFX)
- 5–10 playtesters (друзья, Discord)

**Не делай:**
- Монетизацию, rebirth, pets, lore

**Метрики:**

| Метрика | Kill | Pivot verb | Go |
|---------|------|------------|-----|
| Session median | < 1.5 min | 1.5–3 min | > 3 min |
| «Хочешь ещё?» | < 50% | 50–70% | > 70% |
| Понял без текста | < 60% | — | > 80% |

**Gate → Phase 4:** Go на обеих session + понял без текста.

**Если Kill:** Phase 6 LEARN (быстрый log), взять #2 из converge или новый diverge (макс 1 retry).

---

## Phase 4 — BUILD

Следуй [07-how-to-design-a-hit.md](../07-how-to-design-a-hit.md) Phase 2–3.

**P0 systems:** currency, 1 collection/rarity, 1 return timer, save  
**P1:** rebirth OR milestone, leaderboard  
**P2:** social (если в дизайне)

**Weekly gate:** играбельный билд каждую неделю.

**Gate → Phase 5:** MVP в Studio, ≤ 8 systems, mobile smoke test ok.

---

## Phase 5 — LAUNCH

**День 0:** thumbnail A/B, описание = реальный hook  
**День 1–7:** смотри D1, first-play bounce, session length  
**День 8–30:** D7, CCU trend, revenue

**Не:** большие фичи первые 2 недели. Только fixes + 1 маленький liveops (event timer).

**Gate → Phase 6:** 30 дней данных или явный kill раньше.

---

## Phase 6 — LEARN

Заполни [project-log-template.md](./project-log-template.md).

Запусти [calibration.md](./calibration.md) pass.

**Выход:** обновлённые веса → Phase 0 проекта N+1.

---

## Анти-паттерны pipeline

| Ошибка | Fix |
|--------|-----|
| 3+ diverge раунда без PROVE | Принудительный graybox |
| Пропуск Red Team | Иллюзия 38/40 |
| BUILD до PROVE | 3 недели на мёртвый verb |
| Нет project log | Машина не учится |
| Каждый проект «главный хит» | Проект 1–2 = calibration tier P1 |
