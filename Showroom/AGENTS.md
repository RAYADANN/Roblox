# AGENTS.md — Showroom

Idle exhibit: личная площадка (6 стендов + BuyPlace + FavoritePlace). Не строительство.

## Читать до кода

1. `docs/MVP_SLICE.md` — scope петли
2. `.cursor/rules/template.mdc` + `docs/GAME_ARCHITECTURE.md` + `docs/CLIENT_SERVER.md`
3. UI: `docs/ui-ux-canon/` → `professional-ui.mdc`; адаптив ориентир Tycoon 1920×1080
4. Рост/Highlight/NPC: контракт в `MVP_SLICE.md` + `ExhibitLogic`

## Стек

Luau `--!strict` · Rojo · Wally · Zap · React-Lua · Flipper · ProfileStore · Lune CI

## Паттерн фичи

Logic (shared) → test → Manager (server) → Zap → UI / world renderer (client)

Экспонаты в мире видят **все** (server publish). Coins — только сервер + HudPayload.

## Эталоны Showroom

| Файл | Паттерн |
|------|---------|
| `EggModel.luau` / `AnimalModel.luau` | Clone + ScaleTo eggs / pets from Workspace |
| `ExhibitLogic.luau` | duration / income / NPC / hatch egg→pet scales |
| `AuctionLogic.luau` | auction value / bids / commission |
| `RarityDatabase.luau` | таблица rarity |
| `ExhibitManager.luau` | place / tick / mutate / favorite bank |
| `AuctionManager.luau` | start / auto bids / sell / rerun |
| `FavoriteLogic.luau` | favorite slot helpers |
| `PlotManager.luau` | claim + Stand / BuyPlace / Favorite collect |
| `DispenserManager.luau` | 3 персональных оффера |
| `ExhibitWorldRenderer.luau` | модели + Highlight fade + NPC + Auction/Favorite prompts |

## Чего НЕ делать

- Не строить базу / редактор карты
- Не client-trusted coins / attention / mutation
- Не хардкодить evolve seconds в UI
- ECS / UI-Wally-пакет до soft launch
