# Tech Stack — UI Templates

Урезанный стек из `roblox-starter`, только то, что нужно для UI-kit.

| Слой | Выбор | Зачем |
|------|-------|--------|
| Язык | Luau `--!strict` | Предсказуемый AI-код |
| Sync/build | Rojo | Код в git |
| Пакеты | Wally | Стандарт Luau |
| Toolchain | Rokit | Пины rojo / wally / stylua / selene |
| UI | React-Lua (`jsdotlua/react` + `react-roblox`) | Хуки, function-компоненты |
| UI-моушен | Flipper | Spring-анимации |
| События | Signal | Шины между модулями |
| Async | Promise | Async-цепочки |
| Cleanup | Trove | Connections / instances |
| Format | StyLua | Единый стиль |
| Lint | Selene | CI-friendly |

## Не входит (намеренно)

Zap, ProfileStore, Jest, server-packages, VFX — это слой игры, не UI-kit.
