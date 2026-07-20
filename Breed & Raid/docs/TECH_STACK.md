# Breed & Raid — Tech Stack

> Канон стека: **`C:\Projects\Roblox\roblox-starter`**.  
> Локальный снимок для агентов в этом репо.

Cursor rules: `.cursor/rules/breed-raid-stack.mdc`

---

## Подключено

| Слой | Выбор | Где |
|------|-------|-----|
| Luau `--!strict` | да | `src/` |
| Rojo | да | `default.project.json` |
| Wally | да | `wally.toml` → `Packages/` |
| React-Lua | `jsdotlua/react@17.2.1` | UI |
| ReactRoblox | `jsdotlua/react-roblox@17.2.1` | mount |
| Flipper | `reselim/flipper@2.0.0` | UI motion |
| Trove / Promise | Packages | cleanup / async |

## UI правила

1. Только React function-компоненты + хуки.  
2. Размеры через `useLayout()`, цвета через `theme` (из starter).  
3. Не строить основной HUD на `Instance.new` деревьях.  
4. **Не Fusion**.  
5. Эталон паттернов: `C:\Projects\Roblox\roblox-starter\src\client\ui\`

## По фазе (не раньше PROVE Go без нужды)

| Из starter | Когда |
|------------|--------|
| ProfileStore | MVP persist |
| Zap | когда разрастётся сеть |
| Jest-Lua | опц. |

## Смена стека

Только явным запросом пользователя + правка этого файла + `breed-raid-stack.mdc` + `wally.toml`.
