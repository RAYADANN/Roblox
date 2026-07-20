# Night Raid — Tech Stack

> Канон стека: **`C:\Projects\Roblox\roblox-starter`** (`docs/TECH_STACK.md` там = полный текст и обоснование).  
> Этот файл — **локальный снимок для агентов**: что уже подключено в Night Raid и чего не делать.

Cursor rules (alwaysApply): `.cursor/rules/night-raid-stack.mdc`

---

## Подключено сейчас

| Слой | Выбор | Где |
|------|-------|-----|
| Luau `--!strict` | да | `src/` |
| Rojo | да | `default.project.json` |
| Wally | да | `wally.toml` → `Packages/` |
| React-Lua | `jsdotlua/react@17.2.1` | UI |
| ReactRoblox | `jsdotlua/react-roblox@17.2.1` | mount |
| Flipper | `reselim/flipper@2.0.0` | UI motion |
| Trove / Promise | в Packages | cleanup / async по мере нужды |
| theme + useLayout | скопированы из starter | `src/client/ui/` |
| Remotes | тонкий слой | `src/shared/net/Remotes.lua` (PROVE) |
| Signal (локальный) | `src/shared/util/Signal.lua` | cycle events |

## UI правила (кратко)

1. Только React function-компоненты + хуки.
2. Размеры через `useLayout()`, цвета/шрифты через `theme`.
3. Не строить HUD на `Instance.new` деревьях.
4. **Не Fusion** (отвергнут в roblox-starter).
5. Эталон: `src/client/ui/App.luau`, `GameRoot.luau`; паттерны — `roblox-starter/src/client/ui/`.

Полные правила: `C:\Projects\Roblox\roblox-starter\.cursor\rules\ui-react.mdc`

## Ещё не в этом репо (подключать по фазе, не вместо React)

| Из starter | Когда |
|------------|--------|
| Zap | после PROVE / когда разрастётся сеть |
| ProfileStore | персист игрока |
| Lune + CI | когда заведём GitHub Actions |
| Jest-Lua | опц. Studio tests |

## Смена стека

Только явным запросом пользователя + правка **этого файла** + `night-raid-stack.mdc` + `wally.toml`.  
Агент **не** меняет UI-фреймворк «по удобству».
