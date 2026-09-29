# Pipeline — полный цикл одного проекта

> **Timebox:** 4–8 недель на проект при 6 проектах/год.  
> **Правило:** не переходи на следующую фазу без exit criteria текущей.

---

## Обзор фаз

| Phase | Название | Дней | Exit criteria |
|-------|----------|------|---------------|
| 0 | Intake | 0.5–1 | Constraints + полка проверена |
| 1 | Diverge | 1 | 3 идеи с one-pager |
| 2 | Converge | 1 | 1 идея, red team пройден |
| 3 | Validate | 3–5 | Session median > 3 min ИЛИ kill |
| 4 | Build | 15–25 | MVP 6–8 systems, D1 testable |
| 5 | Ship | 3–7 | Public + week 1 LiveOps |
| 6 | Learn | 1–2 | Project log + calibration |

**Kill разрешён на Phase 3 и 4** — это успех машины, не провал.

---

## Phase 0: Intake

**Вход:** желание нового проекта / завершение предыдущего.

**Действия:**
1. Прочитать актуальные веса из [04-calibration.md](./04-calibration.md) (`machine-state.md` когда появится)
2. Сверить полки в [03-top50-rank-analysis.md](../03-top50-rank-analysis.md)
3. Записать constraints:

```markdown
## Project #N Intake
- Дедлайн ship: 
- Max systems: 8
- Запрещённые полки: 🔴 из top50
- Мои слабые зоны (из прошлых логов): 
- Target SIS (из year plan): 
```

**Exit:** constraints записаны, top-50 не старше 3 мес (или пометка «устарело»).

---

## Phase 1: Diverge (генерация)

**Цель:** 3 **разных** engine combo, не 3 варианта одной идеи.

### Роли агентов (запускать параллельно)

| Агент | Фокус | Пример полки |
|-------|-------|--------------|
| **Systems** | E5 session / co-op work | Animal Hospital-like |
| **Incremental** | E2 + unique verb | Sell Lemons-like |
| **Social Economy** | E1 + E4 | Brainrot-like но новый noun |

### Обязательный блок в промпте (копируй всегда)

```
NON-NEGOTIABLE:
- Retention-first, not story
- NOT GaG / mining / brainrot clone
- MVP ≤ 40 days, ≤ 8 systems
- Scorecard self-assess /40
- Kill criteria: when idea is dead
- What to cut first if schedule slips
- Verb must be graybox-testable in 3 days
```

**Выход Phase 1:** 3 one-pager (шаблон в [09-idea-checklist.md](../09-idea-checklist.md)).

---

## Phase 2: Converge (отбор)

**Не пропускать.** Самая важная фаза для машины.

### Шаг 2a: Red Team (1 агент)

Промпт:
```
Вот 3 идеи. Для каждой: fatal flaw, shelf risk, solo feasibility.
Убей 2. Оставь 1. Если все три мертвы — скажи что менять в constraints.
Не будь вежливым.
```

### Шаг 2b: Engineer Veto (1 агент)

Промпт:
```
Вот победитель. Режь до 6 systems для 35 дней solo.
Что убрать из MVP? Co-op → solo v0.1? Trading → gift-only?
```

### Шаг 2c: Human pick (ты)

Финальное решение за тобой. Запиши **почему 1, почему не 2 другие** — это данные для calibration.

**Exit:** 1 идея, scorecard ≥ 24 (цель ≥ 32), engineer sign-off, kill criteria записаны.

---

## Phase 3: Validate (graybox)

**Только verb + feedback.** См. [07-how-to-design-a-hit.md](../07-how-to-design-a-hit.md) Phase 1.

| Метрика | Kill | Go |
|---------|------|-----|
| Session median | < 2 min | ≥ 3 min |
| Repeat without prompt | < 50% | ≥ 70% |
| «Понятно что делать» | < 4/5 playtesters | ≥ 4/5 |

**Если kill:** project log за 1 день → Phase 0 с новой идеей (не новый diverge с нуля, бери #2 из Phase 1).

**Если go:** freeze verb, не менять до ship.

---

## Phase 4: Build

Retention layer по [04-retention-playbook.md](../04-retention-playbook.md).

**Порядок систем (всегда):**
1. Save + currency
2. Collection OR chase counter
3. Return timer (offline OR event)
4. Shop / upgrades
5. Prestige OR milestone
6. Social-lite OR leaderboard
7. Monetization
8. FTUE polish

**Mid-build gate (день 14):** внутренний D1 smoke test. Если session < 5 min с прогрессией — режь scope, не добавляй фичи.

---

## Phase 5: Ship

- Thumbnail A/B (2 варианта)
- Week 1 LiveOps event (1 строка в DB)
- Записать baseline metrics: D1, session, CCU day 1/7

---

## Phase 6: Learn

Заполни [03-project-log-template.md](./03-project-log-template.md).  
Примени [04-calibration.md](./04-calibration.md).

**Exit:** machine-state обновлён, прогноз vs факт записан.

---

## Agent prompt cheat sheet

| Задача | Агентов | Параллельно? |
|--------|---------|--------------|
| 3 идеи | 3 designers | Да |
| Kill 2 | 1 red team | Нет |
| Cut scope | 1 engineer | Нет |
| Competitive shelf 5 игр | 1 analyst | Нет |
| Economy table | 1 systems | Нет |

**Макс 2 раунда ideation без graybox.** Третий раунд = процесс сломан.
