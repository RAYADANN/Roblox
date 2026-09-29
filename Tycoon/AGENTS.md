# AGENTS.md — Tycoon (Chicken Farm loop)

Этот репозиторий = **копия `roblox-starter` + ферма на 6 плотах**.

Жанр: idle-merge ферма. Герои — модели из `Workspace.Characters` (по одному на merge-уровень), вместо яиц — **кубы**.

## Читать до кода

1. `docs/MVP_SLICE.md`
2. `docs/SLOT_LAYOUT.md` — 40 heroes, 8×5 floors in `DummyItems`
3. `.cursor/rules/template.mdc` + `docs/GAME_ARCHITECTURE.md` + `docs/CLIENT_SERVER.md`
4. `docs/UI_ADAPTIVITY.md` — холст 1920×1080 как в Aim Map 1v1

## Как писать код

1. **Стек starter:** Luau `--!strict`, Rojo, Wally, Zap, React-Lua, Flipper, ProfileStore
2. **Паттерн фичи:** Logic (shared) → test → Manager (server) → Zap / world pads → UI
3. **Петля и пады** — server authority (`FarmManager` + `PadBinder`)
4. Герои и кубы в Workspace реплицируются всем игрокам
5. Не угадывай client/server — смотри `client-server-split.mdc`

## Roblox Studio MCP

Place file: **`Tycoon (3).rbxl`** in this folder (`build.rbxlx` = Rojo build artifact).

Before any Studio MCP tool: `list_roblox_studios` → pick instance whose name/path contains **Tycoon** under `C:\Projects\Roblox\Tycoon`. Never reuse old `studio_id`. See `.cursor/rules/roblox-studio-mcp.mdc`.

## Scope

| Делать | Пока не делать |
|--------|----------------|
| Buy / collect cubes / deposit / cash / merge | Модели предметов / Lucky Block open |
| Process speed, production, auto collect / x2 gamepass | Index rewards beyond unlock reveal |
| HUD (FarmHud, screen Scale @ 1920 fractions) | Полный shop-модал |
| Rebirth modal + server reset (cash table) | Skip rebirth Robux (`ProductIds.SkipRebirth`) |
| Exclusive Heart Skin DevProduct → Stand tint + FX | Clear only via Studio `/clearheart` (not `/reset`) |
| Exclusive carousel (Heart Skin + Rebirth pack UI) | Rebirth pack product grant (`ExclusiveRebirthCoins`) |
| Index: Characters viewport, locked Highlight + `???` | Index catalog rewards |

Идеи вне scope → `docs/BACKLOG.md`.
