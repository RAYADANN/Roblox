# Retention Playbook — D1 / D7 / D30

> Что **реально** возвращает игрока. Не «интересный сюжет», а **конкретные механики**.

---

## Матрица: механика × день

| Механика | D1 | D3 | D7 | D30 |
|----------|----|----|----|----|
| Offline / passive (E1) | ✅✅✅ | ✅✅ | ✅✅ | ✅ |
| Scheduled event (timer) | ✅✅ | ✅✅✅ | ✅✅✅ | ✅✅ |
| Collection chase (E3) | ✅✅ | ✅✅✅ | ✅✅✅ | ✅✅✅ |
| Social / trade (E4) | ✅ | ✅✅ | ✅✅✅ | ✅✅✅ |
| Session stakes (E5) | ✅✅✅ | ✅✅ | ✅✅ | ✅✅ |
| Prestige stack (E2 reset) | ✅ | ✅✅ | ✅✅✅ | ✅✅✅ |
| Skill mastery (E6) | ✅✅ | ✅✅ | ✅✅ | ✅✅ |
| Story / lore | ✅ | ❌ | ❌ | ❌ |

**Правило:** D1 можно купить hook'ом. **D30 покупается только** collection + social + prestige + events.

---

## Grow a Garden — разбор retention (эталон E1)

| Слой | Механика | RETURN |
|------|----------|--------|
| E1 | Растения растут offline | «Созрело 12 морковок» |
| Timer | Restock 5/10/30 мин | «Новые семена через 4 мин» |
| E3 | Weather mutations | «Blood moon = rainbow шанс» |
| E4 | Steal/gift crops | Драма, TikTok |
| E2 | Rebirth | Permanent multiplier |
| LiveOps | Weekly events | Appointment play |

**Почему НЕ сюжет:** нет сюжета. Только системы.

---

## Animal Hospital — разбор retention (эталон E5, 2026)

| Слой | Механика | RETURN |
|------|----------|--------|
| E5 | Shift # растёт | «Дойду до shift 10» |
| E4 | Co-op 4 роли | Друзья в Discord |
| E6 | Skill detection | «Научился ловить аномалии» |
| E3 | Новые типы аномалий | Коллекция знаний |
| Stakes | Sanity, skinwalker | Нельзя AFK |

**Сессия:** 20–40 мин. Не check-in на 30 сек.

---

## Steal a Brainrot — разбор retention (E1 + E4 loss)

| Слой | Механика | RETURN |
|------|----------|--------|
| E1 | $/sec пассивно | Забрать накопленное |
| E4 | Steal / defend | «Меня ограбят» |
| E3 | Rarity brainrots | Mythic chase |
| E2 | Rebirth 18 lvl | Новые floors |
| E7 | Brainrot memes | Cultural FOMO |

**Риск:** токсичность, rage quit у детей. Retention высокий, репутация спорная.

---

## Типы RETURN-таймеров

### 1. Предсказуемый (будильник)
- GaG restock 5 мин
- Blox fruit spawn 60 мин
- Keyboard Admin Abuse (суббота)

**Создаёт привычку.** GaG породил third-party countdown trackers.

### 2. Случайный (FOMO-мониторинг)
- GaG weather mutation
- Brainrot conveyor rare spawn

**Дополняет**, не заменяет предсказуемый.

### 3. Страх потери
- Brainrot steal
- 99 Nights (база)

**Сильный D1, риск churn** если слишком punishing.

### 4. Социальный
- «Друг в игре»
- Trade deal в Discord

**Лучший D30**, сложнее спроектировать с нуля.

---

## Session length vs retention (Roblox 2026)

| Тип | Avg session | D7 | Примеры |
|-----|-------------|-----|---------|
| Check-in 2–5 мин | Короткая | Средний | GaG casual |
| Grind 15–25 мин | Средняя | Высокий | Blox Fruits, Keyboard |
| Deep 45–60 мин | Длинная | Очень высокий | Brookhaven voice, 99 Nights |
| Round 5–10 мин | Короткая × много | Высокий | MM2, Evade |

**Алгоритм 2026** смотрит **play days** и **D8–28**, не только длину одной сессии.

---

## Минимальный retention-набор для MVP

Для solo dev (40 дней) нужно **минимум 3 из 5**:

- [ ] **Visible progress** каждые 30–120 сек (LOOP + GROW)
- [ ] **Chase target** с % или числом (CHASE)
- [ ] **Return timer** ≤ 24ч (offline ИЛИ event ИЛИ fear)
- [ ] **Prestige или collection tier** (RESET или E3)
- [ ] **Social hook** (trade, co-op, leaderboard, steal-lite)

Без 3+ — игра умрёт на D3–D7.

---

## Метрики для отслеживания (Day 1 после launch)

| Метрика | Хороший ориентир (sim/tycoon) |
|---------|-------------------------------|
| D1 retention | >25% |
| D7 retention | >8–12% |
| Median session D1 | 12–20 мин |
| % 2nd session same day | >35% (ключевой!) |
| First play bounce | <40% |
| Intentional co-play days | растёт |

См. [05-roblox-algorithm-2026.md](./05-roblox-algorithm-2026.md)

---

## Формула retention (кратко)

```
D1  = HOOK + LOOP pleasure
D7  = RETURN timer + first prestige/collection milestone
D30 = CHASE (∞) + SOCIAL economy + live ops cadence
```

История — **масло на D1**, не двигатель D30.
