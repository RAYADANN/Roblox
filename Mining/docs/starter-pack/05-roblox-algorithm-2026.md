# Roblox Discover & Algorithm (2026)

> Источник: [Roblox DevForum — RFY 28-day retention](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575), [Roblox Newsroom June 2026](https://about.roblox.com/en-nz/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox).

---

## Как игрок находит игру

```
Home (90%+ трафика)
    └── Recommended For You (персональный)
    └── Charts / Search / Friends
    └── Ads / Social / Creator promo
```

**Важно:** органический RFY ранжирует только игроков, пришедших **через RFY**. Трафик с TikTok/друзей помогает «explore», но RFY-expand зависит от retention **органических** RFY-игроков.

---

## RFY: два этапа

| Этап | Что делает |
|------|------------|
| **Retrieval** | Отбирает кандидатов по engagement, retention, monetization |
| **Ranking** | Персональный порядок для каждого игрока |

---

## Сигналы (окно **28 дней** с 2026)

| Сигнал | Значение для дизайна |
|--------|----------------------|
| **D1 retention** | Первый день цепляет |
| **D2–7 retention** | Первая неделя |
| **D8–28 retention** | **Главный приоритет** — долгосрок |
| Playtime | Длина сессий |
| Play days | Частота визитов |
| Qualified play sessions | Качество сессий |
| **Intentional co-play** | Invite, join friend, private server |
| Spend days | Дни с тратой Robux |
| Robux spent | Монетизация без P2W rage |
| **Play-through rate (PTR)** | Кликнул → остался играть |
| **First play bounce** | Ушёл в первые минуты — **штраф** |

### Что убрали / изменили
- **QPTR** (qualified PTR) — убран
- Добавлены **PTR** и **first play bounce** отдельно
- Окно расширено с 7 → **28 дней**

**Смысл:** thumbnail-bait без retention **больше не работает** долго. Игры с D30 побеждают однодневный hype.

---

## Что это значит для solo dev

### Делай
1. **D8–28 hook** — prestige, collection, weekly events, не только D1 wow
2. **Co-play** — хотя бы leaderboard, trade, co-op shift, «приведи друга»
3. **Честный thumbnail** — bounce rate убьёт RFY
4. **Consistent updates** — explore → expand после патча, если когорта retained
5. **Creator Analytics → Home Recommendations** — смотри RFY-воронку

### Не делай
1. Кликбейт thumbnail без gameplay truth
2. Играть только на D1 spike (одноразовый контент)
3. Игнорировать mobile (40%+ аудитории)
4. Static game без LiveOps cadence

---

## Explore → Expand

```
Content update / viral clip
        ↓
   Explore phase (RFY тестирует на когортах)
        ↓
   Хороший D7/D28 у когорты?
        ↓
   Expand (больше показов похожим игрокам)
```

**Один патч с хорошей retention-когортой** > месяц полировки без релиза.

---

## Пороги CCU и алгоритм

| CCU | Эффект |
|-----|--------|
| 10+ | Сигнал «игра жива» для retrieval |
| 1k–5k | Начало органического RFY expand |
| 50k+ | Топ-15–25, нужен viral + retention |
| 500k+ | Исключение + cultural moment |

Алгоритм **не гарантирует** 50k. Он **масштабирует** то, что уже удерживает.

---

## Чеклист перед публикацией (Discover)

- [ ] Title объясняет verb за 3 слова
- [ ] Thumbnail = реальный геймплей (не misleading)
- [ ] Первые 60 сек — gameplay, не cutscene
- [ ] Есть причина вернуться завтра (RETURN)
- [ ] Mobile UI читаем
- [ ] Like ratio >90% (где применимо)
- [ ] Description + genre tags точные
- [ ] План update cadence (хотя бы bi-weekly)

См. [06-visual-and-hook.md](./06-visual-and-hook.md)
