# Как спроектировать и выпустить хит (процесс)

> Основано на [Dubit framework](https://dubit.io/blog/how-we-build-hit-roblox-games) + практика топ-50 Roblox 2026.

---

## Фазы (не пиши код до Phase 2)

```
Phase 0 — Idea scorecard     (1–2 дня)
Phase 1 — Core prototype     (3–7 дней)
Phase 2 — Retention layer    (2–3 недели)
Phase 3 — Polish + social    (1–2 недели)
Phase 4 — Launch + LiveOps   (ongoing)
```

---

## Phase 0: Idea (до кода)

**Выход:** заполненный [09-idea-checklist.md](./09-idea-checklist.md) с score ≥ 24/40.

Определи:
1. **Primary engine** (E1 / E2 / E5 / E4)
2. **Secondary engine** (обычно E3)
3. **Core verb** одним словом (dig, steal, sort, reject, catch…)
4. **RETURN timer** — что вернёт завтра?
5. **Thumbnail sentence** — одна фраза обещания

**Kill criteria:** не можешь объяснить игру за 10 сек → переделай hook.

---

## Phase 1: Core prototype (Dubit «base layer»)

**Цель:** проверить, приятен ли **LOOP** без прогрессии.

### Сделай
- Один verb в сером прототипе (placeholder art)
- Feedback: звук + число + particles на каждое действие
- 5–10 playtester'ов: «хочешь ещё раз?»

### Не делай
- Монетизацию
- Rebirth
- 10 видов валюты
- Лор

### Метрика успеха
- Session > 3 мин в прототипе
- Игроки повторяют action без подсказок

**Если fail → смени verb, не добавляй features.**

---

## Phase 2: Retention layer

**Цель:** D1/D7 механики.

### Минимальный набор (40 дней)

| Система | Приоритет |
|---------|-----------|
| Currency + 1 sink | P0 |
| 1 collection/rarity | P0 |
| 1 return timer (offline OR event) | P0 |
| Rebirth OR milestone unlock | P1 |
| Leaderboard | P1 |
| Trade OR co-op OR steal-lite | P2 (если scope) |

### Data-driven content
Новый предмет = **строка в таблице**, не новый код:
- `PetDatabase`, `OreDatabase`, `EventSchedule` pattern

### Метрики (soft launch)
- D1 > 20%
- 2nd session same day > 30%
- Session median > 8 min

---

## Phase 3: Polish + growth layer

**Цель:** снизить bounce, поднять shareability.

- Thumbnail set (3 шт)
- Reveal VFX (1 отполированный момент)
- Loading screen + 5 tips
- Mobile UI pass
- Sound pass (positional где нужно)
- Social: friend bonus, share milestone, Discord

**Dubit:** social features не core loop, но критичны для scale.

---

## Phase 4: Launch & LiveOps

### Launch week
- [ ] Soft launch → смотри Creator Analytics RFY
- [ ] Fix bounce > retention bugs first
- [ ] 1 scheduled event в первую неделю
- [ ] Clip seeding (TikTok / Shorts с reveal moment)

### LiveOps cadence (минимум)

| Частота | Что |
|---------|-----|
| Weekly | Мини-event, balance, 1–3 новых data entries |
| Bi-weekly | Thumbnail refresh если CTR падает |
| Monthly | Season / biome / major feature |

**99 Nights / Animal Hospital:** держат CCU при **еженедельных** апдейтах.  
**GaG 2026:** сдвиг к крупным seasonal drops — риск для копий без studio.

---

## Solo dev + Cursor: права распределения (40 дней)

| Неделя | Фокус |
|--------|-------|
| 1 | Prototype LOOP + data schema |
| 2 | Economy + collection + save |
| 3 | Return timer + rebirth/milestone |
| 4 | UI/HUD + reveal FX |
| 5 | Monetization (cosmetic-first) |
| 6 | Polish, playtest, launch |

**Cursor ускоряет:** data tables, UI components, server logic, localization.  
**Cursor не заменяет:** playtest, thumbnail art, sound design, balance feel.

---

## Scope budget (жёсткие лимиты)

| Параметр | MVP max |
|----------|---------|
| Core systems | 6–8 |
| Currencies | 1–2 |
| Enemy types | 1 (если combat) |
| Maps/biomes | 1 |
| PvP steal | только если готов к moderation |
| Full trading | v0.2 |

---

## Definition of Done (MVP ship)

- [ ] Полный цикл HOOK→RETURN за 15–30 мин
- [ ] Причина вернуться завтра работает
- [ ] Mobile playable
- [ ] No blocker bugs 30-min session
- [ ] Thumbnail + title honest
- [ ] Analytics hooked (GameAnalytics / Creator Dashboard)
- [ ] Plan first 2 weekly updates written

---

## Связанные документы

- [01-meta-pattern.md](./01-meta-pattern.md)
- [04-retention-playbook.md](./04-retention-playbook.md)
- [08-anti-patterns.md](./08-anti-patterns.md)
- [09-idea-checklist.md](./09-idea-checklist.md)
