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

Коробка: форма = уровень стенда (`GameAssets.Boxes/1|2|3` + palette), rarity не красит меш. 
Герой: пул `GameAssets.Heroes/<Rarity>`. Мутация: shine + FX-парт на героя (~1.1×).

Плоты: `Base1`…`Base6` — `BaseClaimManager` (1 база / игрок); чужие промпты гасятся.

Шаблоны (не Base*): `ReplicatedStorage.GameAssets` → Boxes / Heroes / MutationFx / Mutations / Rarity / Stands.

## Эталоны AnimeTycoon

| Файл | Паттерн |
|------|---------|
| `ContainerLogic.luau` | unpack / buy / income |
| `HeroLevelLogic.luau` | уровень героя 1–50: доход и цена следующего уровня |
| `MutationLogic.luau` | rarity + mutations |
| `OfferRouletteLogic.luau` | timing рулетки |
| `ConveyorLogic.luau` | travel → payout |
| `StandManager.luau` | 5 офферов, buy |
| `RampManager.luau` | place / unpack / produce |
| `SceneBinder.luau` | Roll / Buy prompts + step-on place |
| `StandPromptBinder.luau` + `OfferRoulette.luau` | client roulette |
| `RampWorldRenderer.luau` | boxes/heroes + Billboard |
| `ConveyorVisual.luau` | mini path |
| `IndexLogic.luau` | Index: HeroCatalog × mutations + discovery keys |
| `TutorialLogic.luau` | FTUE steps (roll→buy→place→open→take→sell) |
| `LimitedLogic.luau` / `LimitedOfferDatabase` | Robux Limited → exact stand mesh+VFX + Null/Mythic rarity |
| `BoostOfferLogic.luau` / `BoostOfferDatabase` | HUD LuckyX2/X4 + MoneyX2 (24h sale, carousel) |
| `RewardTrackLogic.luau` / `RewardTrackDatabase` | Timed Rewards 12 slots (cases #3/6/10/11/12) |

## Чего НЕ делать

- Не client-trusted coins
- Не хардкодить unpack seconds в UI
- Не ECS / UI-Wally до soft launch
- Не фичи вне MVP без `docs/BACKLOG.md`
