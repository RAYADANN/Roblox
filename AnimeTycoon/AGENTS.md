# AGENTS.md — AnimeTycoon

Toy conveyor tycoon: Stands → container → Ramp unpack → hero → minis → coins.

## Читать до кода

1. `docs/MVP_SLICE.md` — scope петли
2. `docs/STUDIO.md` — маркеры Workspace
3. `.cursor/rules/template.mdc` + `docs/GAME_ARCHITECTURE.md` + `docs/CLIENT_SERVER.md`
4. UI: `docs/ui-ux-canon/` → `professional-ui.mdc`

## Стек

Luau `--!strict` · Rojo · Wally · Zap · React-Lua · Flipper · ProfileStore · Lune CI

## Паттерн фичи

Logic (shared) → test → Manager (server) → Zap → UI / world renderer (client)

Coins / offers / slots — только сервер. Контейнеры/герои/мини в мире видят **все**.

## Эталоны AnimeTycoon

| Файл | Паттерн |
|------|---------|
| `ContainerLogic.luau` | unpack / buy / income |
| `MutationLogic.luau` | rarity + mutations |
| `OfferRouletteLogic.luau` | timing рулетки |
| `ConveyorLogic.luau` | travel → payout |
| `StandManager.luau` | 5 офферов, buy |
| `RampManager.luau` | place / unpack / produce |
| `SceneBinder.luau` | Roll / Buy prompts + step-on place |
| `StandPromptBinder.luau` + `OfferRoulette.luau` | client roulette |
| `RampWorldRenderer.luau` | boxes/heroes + Billboard |
| `ConveyorVisual.luau` | mini path |

## Чего НЕ делать

- Не client-trusted coins
- Не хардкодить unpack seconds в UI
- Не ECS / UI-Wally до soft launch
- Не фичи вне MVP без `docs/BACKLOG.md`
