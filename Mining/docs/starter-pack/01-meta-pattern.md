# Мета-паттерн: архитектура хита на Roblox

> Повторяется в ~90% топ-50 игр (июль 2026). Различаются **обёртка** и **комбинация engines**, не каркас.

---

## Семь слоёв (все хиты имеют минимум 4 из 7)

```
┌─────────────────────────────────────────────────────────┐
│  HOOK (0–10 сек)     Понятно ЧТО делать без туториала  │
├─────────────────────────────────────────────────────────┤
│  LOOP (каждые 3–30с) Одно действие + feedback           │
├─────────────────────────────────────────────────────────┤
│  GROW                Валюта → сильнее loop               │
├─────────────────────────────────────────────────────────┤
│  CHASE               Цель, которую нельзя закончить      │
├─────────────────────────────────────────────────────────┤
│  SOCIAL              Другие игроки = часть прогресса     │
├─────────────────────────────────────────────────────────┤
│  RESET               Rebirth/prestige → новый chase      │
├─────────────────────────────────────────────────────────┤
│  RETURN              Причина зайти завтра                │
└─────────────────────────────────────────────────────────┘
```

---

## Расшифровка слоёв

### HOOK
Игрок понимает verb из **названия + thumbnail** за 10 секунд.

| Хорошо | Плохо |
|--------|-------|
| Steal a Brainrot | Epic Mining Adventure RPG |
| +1 Speed Keyboard Escape | Deep Underground Simulator |
| 99 Nights in the Forest | The Last Expedition |

### LOOP
Одно действие, повторяемое с **мгновенным** откликом:
- звук (ASMR клик, hatch pop)
- число (+1 speed, +$50)
- VFX (частицы, screen flash)

**Правило Dubit:** если core action не enjoyable в прототипе без прогрессии — игра мертва.

### GROW
Награда тратится на **увеличение мощности loop**, не на декор ради декора:
- больше урона → быстрее копаешь
- больше слотов → больше пассива
- trail ×2 → быстрее speed

### CHASE
Что-то **никогда не 100%**:
- mythic pet 0.01%
- speed 999,999,999
- shift 47 / ∞
- коллекция 847/∞

**D30 живёт здесь**, не в сюжете.

### SOCIAL
| Тип | Примеры |
|-----|---------|
| Trade | Adopt Me, Pet Sim, Brainrot |
| Steal / PvP loot | Brainrot, Merge a Nuke |
| Co-op roles | Animal Hospital, 99 Nights |
| Vote / flex | Dress To Impress |
| Hangout | Brookhaven |

### RESET
Prestige сбрасывает прогресс, но даёт **permanent multiplier** + иногда новый контент (зона, sea, world).

Типичный стек: `Rebirth → Evolution → Ascension`

### RETURN
Минимум **одна** причина вернуться в течение 24 часов:
- offline accumulation («накопилось»)
- scheduled event («через 20 мин restock»)
- fear of loss («меня ограбят»)
- co-op appointment («друзья в 8 вечера»)

---

## Формула (для оценки идеи)

```
ПОТЕНЦИАЛ =
  Hook(10с)           ×  понятен ли verb?
× Loop(каждые N сек)  ×  приятен ли feedback?
× Grow                ×  виден ли прогресс?
× Chase               ×  есть ли ∞ цель?
× (Social ИЛИ Session stakes)
× Return timer        ×  есть ли причина завтра?
× Mobile polish
× Thumbnail = правда о геймплее
```

| Цель CCU | Нужно |
|----------|-------|
| 5k–15k | 5–6 множителей |
| 50k+ | 6–7 + удача / viral |
| 500k+ | все 8 + cultural moment (E7) |

---

## Три архетипа (как комбинируют слои)

### A — «Фабрика» (~28 из топ-50)
**E1 IDLE + E2 NUMBER + E3 COLLECTION**  
GaG, Brainrot, Pet Sim, Sell Lemons, Keyboard Escape…

### B — «Арена» (~14 из топ-50) — **быстрейший рост 2026**
**E5 SESSION + E6 SKILL (+ E4 co-op)**  
Animal Hospital, 99 Nights, MM2, RIVALS, Evade…

### C — «Площадь» (~8 из топ-50)
**E4 SOCIAL** (почти без win condition)  
Brookhaven, Berry Avenue, Bloxburg…

---

## Связанные документы

- Engines: [02-seven-engines.md](./02-seven-engines.md)
- 50 игр: [03-top50-rank-analysis.md](./03-top50-rank-analysis.md)
- Чеклист: [09-idea-checklist.md](./09-idea-checklist.md)
