# MVP Slice — Merge Arena

Вертикальный срез soft launch: **Collection match 6–10 мин** → rematch / pack.  
Канон чисел и запретов: [`gdd/Merge Arena — Canon Lock.md`](./gdd/Merge%20Arena%20—%20Canon%20Lock.md).  
Всё остальное → `BACKLOG.md`.

## One-liner

4 игрока: **своя колода** → shop из loadout → merge★ → auto fight → last standing → packs.

## В scope graybox / soft launch

| Система | Минимум |
|---------|---------|
| Collection | owned units, **12 core free**, **8 gacha**, loadout **12** |
| Packs | Unit Pack + Starter Deck + pity (`PackLogic`) |
| VIP / XP boost | thin Robux SKUs (gamepass / DevProduct) |
| Match loop | 4p (bots ok), rounds, last standing |
| Shop | 3 слота из **loadout**, buy, reroll (сервер) |
| Merge ★ | ★1+★1→★2 (+★3) + **juice VFX** |
| Board | 2×4, place/swap, bench 6 |
| Combat | Auto fight, серверный resolve |
| HUD | Gold, shop, board, timer, opponents, rematch |
| Meta UI | Collection · Loadout · Packs · Results |
| Save | ProfileStore: owned, loadout, Stars, MMR stub |
| Network | Zap: match + shop/merge/place + pack intents |
| Analytics | session, first_merge, match_end, rematch, pack_open |
| Visual | Bright Tactical Toys (`theme.luau` tokens) |
| CI | Зелёный на каждый merge |

### First 45s (must)

Buy twin → **MERGE★ wow** → auto fight читается.

## Вне scope (→ BACKLOG)

- Fair Fixed Set ranked (общий shop pool)
- Полный TFT-trait web / 50+ юнитов
- Tournaments / cups UI
- Board skin / Merge VFX factory
- Полный Battle Pass
- Spectate, replay, custom lobbies
- Локализация beyond EN
- Mythic-only cinematic на каждый merge
- Paid +bench / pool radar в матче

## Kill / Go gates (playtest)

| Metric | Kill | Go |
|--------|------|-----|
| «Ещё матч?» | <60% | >80% |
| Merge назвали wow | <50% | >75% |
| Finish match rate | <55% | >75% |
| «Скучный auto chess» | majority | majority «merge / collection» |
| Starter/Pack interest (soft) | 0 opens after CTA | хоть какой-то open/purchase signal |

## Критерий soft launch

- [ ] Collection match с ботами на phone + desktop
- [ ] Loadout → shop только из loadout (сервер валидирует)
- [ ] Pack open + Starter (реальные ProductIds если продаём)
- [ ] Merge★ juice обязателен
- [ ] Theme bright toys, не navy starter
- [ ] CI зелёный
- [ ] `PLAYTEST_CHECKLIST.md` / `RELEASE_CHECKLIST.md`
