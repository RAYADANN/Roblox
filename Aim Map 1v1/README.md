# Aim Map 1v1

CS-style **aim_map 1v1** на Roblox (USP-only, **first-person**, rematch, cosmetic kill-flex).  
Стек и правила разработки — из [`roblox-starter`](../roblox-starter) (скопированы в этот репо).

### Graybox сейчас

- Solo: 4 practice-dummy + **vs Bot** + стена прицелов (выстрел = выбор, как CS custom)
- Единое тело: Studio `Workspace.R15 Dummy` → все игроки + practice + duel bot
- USP visual: мировое тело для других; локально **ViewModel** (руки+USP на камере)
- Анимации R15: **Idle** + **Shoot2** на viewmodel (локально) и на теле (репликация)
- FP: мировое тело скрыто себе; камера на точке глаз (HRP + eye height), viewmodel к камере
- SFX: `usp-s_fire` / `cs-go-headshot-sound` / `Bodyshot` → SoundDatabase + shoot/hit
- Take-damage UI (Valorant-style): React + Flipper vignette/chevron (`TookDamage`) + full-bleed red/blue screen flash (`IgnoreGuiInset`)
- Bullet tracer цвет из скина (`SkinDatabase.tracer` + kill-flex skin id)
- CS-style death ragdoll (impulse от выстрела) на игроках, duel bot и practice dummy
- Sens (K) и crosshairId → ProfileStore
- Auto-queue 1v1 при заходе (2 клиента → дуэль); один игрок → practice или vs Bot
- Server-authoritative USP fire: origin = Part `Shoot` (Handle.Shoot on dummy USP), direction = muzzle → camera aim; first-to-5 + rematch (бот принимает rematch сам)
- Kill-flex skin id (attribute) до смерти; shop — позже
- Arena `AimArena` создаётся сервером, если карты нет в place
- **HUD:** SimPop style (`client/ui/simpop`) + flat esports icons (`UiImageCatalog.hud`) — rails shop/inventory/invite + settings, VS BOT / REMATCH CTAs
- **Inventory:** SimPop window (GUN / CASE tabs); slot color = rarity via `RarityLogic` + `SimPopBlock` (incl. purple for rare/cases)

| | |
|---|---|
| **Dual** | Tizzy **34**/40 · MECE **81**/100 · **Prioritize** |
| **Studio** | Zeon |
| **Path** | `C:\Projects\Roblox\Aim Map 1v1` |

## Документы игры (читай сначала)

| Файл | Содержание |
|------|------------|
| [`docs/design/ONE_PAGER.md`](docs/design/ONE_PAGER.md) | Pitch, scope, gates |
| [`docs/design/DUAL_ANALYSIS.md`](docs/design/DUAL_ANALYSIS.md) | MECE × Tizzy полный разбор |
| [`docs/design/MONETIZATION.md`](docs/design/MONETIZATION.md) | Skins + kill-flex |
| [`docs/MVP_SLICE.md`](docs/MVP_SLICE.md) | Вертикальный срез |
| [`docs/BACKLOG.md`](docs/BACKLOG.md) | Вне scope |

## Стек / правила (из starter)

- Cursor: `.cursor/rules/` + [`AGENTS.md`](AGENTS.md)
- Архитектура: `docs/GAME_ARCHITECTURE.md`, `docs/CLIENT_SERVER.md`
- Стек: `docs/TECH_STACK.md` — Luau strict, Rojo, Wally, Zap, React-Lua, ProfileStore
- UI: `docs/ui-ux-canon/` + `professional-ui.mdc`

## Быстрый старт

```powershell
cd "C:\Projects\Roblox\Aim Map 1v1"
rokit install
wally install
zap net.zap
stylua src tests
selene src tests
lune run tests
rojo build -o build.rbxlx
```

### Hoarcekat (UI stories)

1. `rojo serve` → Connect в Studio (edit mode, Play не нужен).
2. Плагин **Hoarcekat** → stories в `ReplicatedStorage.UI.stories`:
   - `DuelHud` — duel HUD (иконки + SimPop CTAs)
   - `Inventory` — GUN/CASE inventory + rarity blocks
   - `SimPopButton` — палитра кнопок

В Cursor:

> Работай по `AGENTS.md`, `template.mdc`, `docs/design/ONE_PAGER.md` и `docs/MVP_SLICE.md`. Это Aim Map 1v1, не sim.

## Правило №1

Graybox дуэли → soft → контент апдейтами.  
Не расползаться во второе оружие до сигнала rematch.
