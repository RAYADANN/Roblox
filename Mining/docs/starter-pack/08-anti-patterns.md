# Anti-patterns — что убивает Roblox-игры

> Ошибки, которые повторяются у solo dev и не видны в «красивом GDD».

---

## 🔴 Критические (часто fatal)

### 1. GaG / Mining clone без twist
**Симптом:** «underwater garden», «space mining», «pet mine sim»  
**Почему смерть:** полка переполнена, Discover не даст expand  
**Альтернатива:** новый verb (reject, sort, +1 X) или engine combo E5+E3

### 2. Story как основной retention
**Симптом:** 50 journal entries, one-time lore, «последний шахтёр»  
**Почему:** D1 hook, D7 пусто — игрок «прошёл сюжет»  
**Альтернатива:** lore как optional flavor; retention = CHASE + RETURN

### 3. Thumbnail bait
**Симптом:** обещание ≠ первые 60 сек  
**Почему:** first play bounce → RFY штраф (2026)  
**Альтернатива:** [06-visual-and-hook.md](./06-visual-and-hook.md)

### 4. Scope creep до Phase 1
**Симптом:** pets + rebirth + 6 eggs + trading + combat в MVP  
**Почему:** 40 дней → 6 месяцев → мёртвый проект  
**Альтернатива:** 6–8 systems max, [07-how-to-design-a-hit.md](./07-how-to-design-a-hit.md)

### 5. PvP steal без moderation plan
**Симптом:** копия Brainrot steal на day 1  
**Почему:** griefing, reports, exploiters, bad reviews  
**Альтернатива:** NPC raiders OR steal-lite OR v0.2 после retention proof

---

## 🟠 Серьёзные (D7/D30 bleed)

### 6. Нет RETURN timer
Игроку нечего ждать завтра. Только grind.

### 7. Одна валюта, некуда тратить
Earn без spend loop = boredom.

### 8. Редкость раздаётся слишком часто
Legendary каждые 5 мин → нет CHASE.

### 9. Игнор mobile
UI мелкий, perf плохой → 40% аудитории отвал.

### 10. Static launch
Нет update plan → RFY expand останавливается.

### 11. Real 24h day/night only
2 окна в сутки в плохое время → глобальная аудитория страдает.  
**Fix:** accelerated in-game clock (каждые 20–30 мин).

### 12. Full trading day 1
Dupes, scams, support hell для solo.

---

## 🟡 Частые ошибки дизайна

| Ошибка | Fix |
|--------|-----|
| Слишком много туториала текстом | Show don't tell |
| Combat в MVP когда hook — collection | Combat v0.2 |
| Open world без direction | Zones + gates |
| Копировать Blox Fruits depth day 1 | Sailor Piece lesson: fast early, depth later |
| «Уникальность» только в арте | Verb + thumbnail + loop должны отличаться |
| Переиспользовать старый код с чужой identity | Rebrand или new place |

---

## Ловушка «переиспользования кода»

Иметь codebase ≠ иметь **market positioning**.

| Имеешь | Рынок видит |
|--------|-------------|
| Mining + pets + rebirth | Pet/mining sim |
| Reskin на horror | «Mining with monsters» |
| New place + new hook | Шанс на Discover |

**Правило:** reuse infrastructure, not identity.

---

## Красные флаги на idea pitch

- «Как GaG, но…» без чёткого «но»
- Нет ответа на «зачем вернуться завтра?»
- Нет clip moment
- 50k CCU как единственная цель без viral plan
- «Сделаем всё как в топ-10» в одной игре

---

## Когда убить идею (kill switch)

После soft launch, если **все три**:
- D1 < 15%
- 2nd session same day < 20%
- Median session < 5 min

→ Не добавляй контент. **Чини LOOP или HOOK** или pivot verb.

---

## Связанные документы

- [09-idea-checklist.md](./09-idea-checklist.md)
- [03-top50-rank-analysis.md](./03-top50-rank-analysis.md) — переполненные полки
