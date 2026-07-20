# AGENTS.md — Breed & Raid

Инструкции для Cursor / любого агента в этом репо.

## Обязательно прочитать до кода

1. `docs/AGENT_BRIEF.md`
2. `docs/DEV_TRACKER.md` — только unchecked текущей фазы
3. `docs/GDD.md` — **канон продукта**
4. `.cursor/rules/breed-raid-stack.mdc` — стек
5. `.cursor/rules/breed-raid-scope-lock.mdc` — что нельзя строить

## Tech stack (не спрашивать пользователя)

Канон: **`C:\Projects\Roblox\roblox-starter`**

| Слой | Выбор |
|------|--------|
| UI | **React-Lua** + **Flipper** (`Packages.React`, `ReactRoblox`, `Flipper`) |
| Tokens / adaptivity | `src/client/ui/theme.luau` + `useLayout()` (скопировать из starter при UI) |
| Язык | Luau `--!strict` |
| Packages | Wally (`wally.toml`) |
| Sync | Rojo |
| DI | `Module.new(deps)`, нет `_G` |

**Запрещено:** Fusion, raw Instance HUD как основной UI, Knit service locator.

Подробности: `docs/TECH_STACK.md` · правила React: `roblox-starter/.cursor/rules/ui-react.mdc`

## Product / phase

- GDD: `docs/GDD.md`
- Design anti-patterns: `C:\Projects\Roblox\Mining\docs/starter-pack/`
- Current phase: см. `docs/DEV_TRACKER.md` (сейчас PROVE foundation)

## После работы

Отметь сделанное в `docs/DEV_TRACKER.md` (+ дата).
