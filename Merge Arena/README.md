# Merge Arena

Roblox ranked auto-battler: **shop → merge★ → place → auto fight → last standing**.

Стек и архитектура скопированы из [`roblox-starter`](../roblox-starter). Cursor следует `.cursor/rules/` и [`AGENTS.md`](AGENTS.md).

## Стек

| Слой | Инструмент |
|------|------------|
| Sync | Rojo |
| Packages | Wally (React, Flipper, ProfileStore, …) |
| Network | Zap (`net.zap`) |
| UI | React-Lua + Flipper |
| Persist | ProfileStore |
| Format / lint / test | StyLua · Selene · Lune |
| World FX | VFX Engine (`docs/VFX_ENGINE.md`) |

## Быстрый старт

```powershell
cd C:\Projects\Roblox\Merge Arena
rokit install
rokit add lune
wally install
zap net.zap
stylua src tests
selene src tests
lune run tests
rojo build -o build.rbxlx
rojo serve
```

## GDD / продукт

Вся информация об игре: [`docs/gdd/`](docs/gdd/README.md)

Dual · Depth Probe · игровой процесс · Art Pillars · визуальный стиль · Block Kit · персонажи.

## MVP

См. [`docs/MVP_SLICE.md`](docs/MVP_SLICE.md) + канон [`docs/gdd/Merge Arena — Canon Lock.md`](docs/gdd/Merge%20Arena%20—%20Canon%20Lock.md): Collection loadout + packs + merge★.

## Архитектура

- [`docs/GAME_ARCHITECTURE.md`](docs/GAME_ARCHITECTURE.md)
- [`docs/CLIENT_SERVER.md`](docs/CLIENT_SERVER.md)
- [`docs/TECH_STACK.md`](docs/TECH_STACK.md)
- [`docs/NEW_PROJECT.md`](docs/NEW_PROJECT.md) — чеклист (уже пройден при init)
