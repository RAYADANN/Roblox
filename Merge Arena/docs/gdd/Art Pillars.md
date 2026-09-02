# Merge Arena — Art Pillars

**One-liner вайба:** игрушечная ranked-арена — яркие block-юниты, тяжёлый merge★, чистый бой.  
**Не:** anime board · dark cinematic · Pet Sim cute · mid gray tactics.

Связь: [[Merge Arena — визуальный стиль]] · [[Merge Arena — Universal Block Kit]] · [[Merge Arena — игровой процесс]]

---

## 8 столпов

| # | Pillar | Значит на экране |
|---|---|---|
| 1 | **Toy** | Cube-тела, flat color, 2 rectangle eyes. Герой = игрушка, не скульптура |
| 2 | **Readable** | Силуэт + ★ читаются с телефона за 1 сек. Outline толстый |
| 3 | **Smash** | Merge = столкновение кубов → больший куб. Не dissolve, не soft glow-only |
| 4 | **Star** | ★ — главный визуальный бог. Вспышка звезды > частицы ради частиц |
| 5 | **Punchy** | Короткий удар: flash / shake / hitstop. Сок = миллисекунды, не 2-сек катсцена |
| 6 | **Bright arena** | Светлая доска, тёплый свет, холодные тени только для контраста юнитов |
| 7 | **Rarity = voltage** | Common почти сухо. Rare заметно. Epic/Mythic взрывают экран |
| 8 | **One language** | Merge / Hatch / Sell / Win / Rank — один feedback-диалект, разные амплитуды |

---

## Эмоция по rarity

| Rarity | Feeling | Экран |
|---|---|---|
| Common | ритм, темп | почти без shake |
| Rare | «есть» | flash + short punch |
| Epic | азарт | star burst + camera |
| Mythic | гордость / «иначе нельзя» | full stack: freeze + star + board react |

---

## Палитра-правило

- База юнита: **1–2 локальных цвета** + 1 accent
- ★ / merge flash: отдельный «электрический» акцент
- UI: нейтраль + rarity color только на награде/merge
- **Макс 3 активных цвета** в одном VFX-событии

---

## НЕ делать

- sculpt / PBR armor / anime faces
- bloom на каждый merge
- shake чаще, чем rarity позволяет
- Legendary-сок на Common
- разные стили VFX на Merge vs Win (ломает язык)
- тёмный cinematic lighting на thumb/FTUE

---

## Тест столпов (3 секунды)

1. Это **игрушки на арене** или «ещё auto chess»?
2. Где **★**?
3. Хочется ли **слить ещё раз**?

Если хоть на один ответ «нет» — столп нарушен.
