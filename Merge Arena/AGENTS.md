# AGENTS.md — Merge Arena

Проект создан из **roblox-starter**. Стек, слои и правила Cursor — те же.

Жанр: **4p ranked merge auto-battler** (Clash Merge Tactics DNA на Roblox).  
Не копируй геймдизайн чужих игр как контент; эталон кода — файлы в этом репо.

## Как писать код

1. **Читай `.cursor/rules/template.mdc`** — главный индекс
2. **Архитектура:** `docs/GAME_ARCHITECTURE.md`
3. **Client vs Server:** `docs/CLIENT_SERVER.md` + `client-server-split.mdc`
4. **UI:** `docs/ui-ux-canon/00-priority-ladder.md` → `QUICK_REFERENCE.md` → `professional-ui.mdc` + `theme.luau`
5. **Фича:** Logic (shared) → test → Manager (server) → Zap → UI (client)
6. **Замысел неясен?** Спроси — не угадывай client/server

## Структура

```
.cursor/rules/     ← правила Cursor
docs/              ← архитектура, стек, MVP Merge Arena
src/shared/        ← types, data, util (*Logic), vfx
src/server/core/   ← *Manager (DI)
src/client/ui/     ← React
src/client/core/   ← Sound, Settings, VFX controllers
src/client/vfx/    ← world VFX engine
tests/             ← Lune unit tests
net.zap            ← схема сети
```

## Merge Arena — куда класть фичи

| Фича | Shared Logic | Server Manager | Client |
|------|--------------|----------------|--------|
| Packs / gacha | `PackLogic` | `PackManager` / Monetization | Packs + Collection UI |
| Loadout | `LoadoutLogic` | `CollectionManager` | Loadout panel |
| Shop roll / buy | `ShopLogic` | `ShopManager` | Shop panel |
| Merge ★ | `MergeLogic` | `MergeManager` | Board + merge VFX |
| Board place | `BoardLogic` | `MatchManager` | Board renderer |
| Auto fight | `CombatLogic` | `CombatManager` | Fight VFX / numbers |
| Ranked / cups | `RankLogic` | `RankManager` | Rank HUD (stub) |
| Profile / cosmetics | — | `ProfileManager` | Remote cosmetic visual |

Паттерн эталона из starter: **BuyUpgrade**  
`UpgradeLogic` → `EconomyManager` → Zap → UI.

## Чего НЕ делать

- Не добавлять ECS, ReplicaService, UI-Wally-пакет до релиза
- Не коммитить `build.rbxlx`, секреты, `.env`
- Не писать 1000-строчные файлы
- Не дублировать формулы client/server
- Не раздувать TFT-scope в MVP (см. `MVP_SLICE.md`)
- Не делать Legendary VFX на каждый Common merge

## Документы

- `docs/gdd/` — **GDD игры** (Dual, gameplay, Art Pillars, visual, roster)
- `docs/TECH_STACK.md` — стек
- `docs/GAME_ARCHITECTURE.md` — слои, DI
- `docs/CLIENT_SERVER.md` — видимость / репликация
- `docs/MVP_SLICE.md` — scope Merge Arena
- `docs/BACKLOG.md` — вне scope
- `docs/VFX_ENGINE.md` — world VFX (merge★ juice)
- `docs/ui-ux-canon/` — проф. UI

Перед фичей merge/shop/combat/collection — сначала `docs/gdd/Merge Arena — Canon Lock.md`, затем `docs/gdd/README.md`. Не выдумывай loop.
