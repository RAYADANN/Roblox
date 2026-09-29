# MVP Slice — Showroom

Жанр: **idle exhibit** — не строительство. У каждого игрока своя площадка (6 пьедесталов + диспенсер). Игрок только выбирает, что показать.

## Петля (цель ~15 мин soft launch)

```
Диспенсер даёт 3 оффера → выбрать → поставить на Stand
  → рост/эволюция (длительность = f(rarity); rare медленнее); no pocket income while growing
  → NPC-толпа = f(rarity); egg mesh (`Workspace.Egg`) растёт по progress
  → incomeRate растёт во время роста (display / Favorite only)
  → в конце mutation roll
  → Grown → Auction **или** Favorite stand
       → Auction: автоставки NPC → Sell / Run again
       → Favorite: пассив в bank на FavoritePlace → наступить на Button → coins; favorite bank only
```

Эмоции: находка → наблюдение роста → чужое внимание → редкая форма → выбор «забрать ставку или рискнуть ещё раз».

## В scope MVP

| Система | Минимум |
|---------|---------|
| Plot | Claim одной площадки / игрок; 6 `Stand` маркеров |
| Dispenser | 3 персональных оффера |
| Place / Remove | На пьедестал / снять |
| Exhibit params | rarity, baseIncome, attention, mutationChance; style/character как данные |
| Income | No pocket income while growing; rate растёт по progress; favorite bank only |
| Growth | `evolveDuration(rarity)`; progress 0→1 |
| NPC | Толпа вокруг растущего слота, size = f(rarity) |
| Egg visual | Clone `Workspace.Egg`; scale by size/progress; no Highlight |
| Mutation | Roll в конце окна по rarity |
| React | 1 кнопка от других игроков → +attention (rate-limit) |
| Favorite | Grown → FavoritePlace (5 слотов); income → `favoriteBank`; collect на Button |
| Auction | Grown only: auto NPC bids; rarity×size×mutations×rebirth; max 3 runs; rerun fee |
| HUD | coins, favorite bank, inventory, auction overlay |
| Save / Zap / CI | ProfileStore, Zap sync, зелёный CI |

## Вне scope → BACKLOG

- Богатые характеры / полный каталог мешей и анимаций
- Social «показать другу», leaderboards
- Robux shop, daily
- Продвинутый pathfinding толпы
- Строительство базы

## Контракт роста (сервер)

1. No pocket income while growing; favorite bank only. `incomeRate` = f(progress, rarity, attention) still updates for display / Favorite.
2. NPC count = random `[npcMin, npcMax]` на place; live crowd ramps with progress and **stays busy after evolve**. Client continuously retires old visitors (walk away) and spawns new ones. Soft caps: ~14/stand, ~48 total (cheap anchored Noob clones — fine on phone at this scale).
3. Egg → pet: clone `Workspace.Eggs/<variant>`; at hatch (~52% progress) egg shrinks away and `Workspace.Animals/<variant>/*` grows (`ExhibitLogic.hatchEggScale` / `hatchPetScale`).
4. Длительность: common ~25s; выше rarity → дольше (до ~90s legendary).
5. Mutation rolls **during growth** (named stacks, e.g. `Spark-Neon`); eggs may already carry a growth mutation from the dispenser; final roll at end if empty.
6. Chance NPCs **avoid** the exhibit → `npcBase=0` → lonely mutations (`Forsaken` / `Hollow` / `Ghosted`).
7. On new mutation, NPCs celebrate (jump + hype emotion) for a few seconds.
8. Exhibit anim (`spin|bounce|tumble|sway|pulse`) rolled on place; BlockItem Billboard on egg/pet shows Rarity + name + Mutation (only when present).
9. Size tier rolled on offer (Small 50% / Medium 30% / Large 18% / Giant 2%): model scale only (not in `displayName`); Giant size = **2× Large**. Buy price = `ExhibitLogic.buyPrice`. Billboard: rarity + name + mutation (if any) + price. **Giant mutation** also scales to 2× Large (no particle FX).
10. **Auction** (grown only): pet stays on stand (no income); crowd rushes in (~7s); NPC billboards show rising bids; then decision UI Sell / Run again (1st free; 2nd/3rd commission; max 3). Value = rarity × size × mutation count × rebirth mult.
11. **Favorite** (grown only): move to `FavoritePlace.ItemPlace*`; passive income accumulates in `favoriteBank` (not pocket); step on `FavoritePlace.Button` to collect. Grown stands no longer drip to pocket (encourage Favorite / Auction). Instant sell prompt removed from stands. Favorite stands expose **Auction** so a better pet can free the slot.

Формулы — `ExhibitLogic` / `MutationLogic` / `AuctionLogic` + Lune-тесты. UI не хардкодит секунды.

## Критерий soft launch

- [ ] Common: рост без pocket coins → мало NPC → egg mesh + FX → быстрее rare
- [ ] Rare: дольше рост, больше NPC
- [ ] Снять + продать; релог сохраняет слоты/монеты
- [ ] Другой игрок видит экспонат/яйцо/толпу и может среагировать
- [ ] Phone + desktop HUD
- [ ] CI зелёный
