# AGENTS.md — UI Templates

UI kit playground (React-Lua + Flipper + Hoarcekat), не игра.

- Код UI — `src/ui/` → `ReplicatedStorage.UI`
- Stories — `src/ui/stories/*.story.luau` (Hoarcekat)
- Новый story: `return require(script.Parent.mount)(React.createElement(...))`
- Без Zap / ProfileStore / server — вне scope
- `--!strict`, function-компоненты + hooks
- Гайд для человека: `docs/REACT_LUA.md`
- Layout: hybrid токены + **UiScaler** (`adapt/UiScaler.luau`): design @ 1920×1080, `UIScale` на ScreenGui.
- App внутри `DesignRoot` (канвас reference). Не верстать «под телефон» отдельно.

## Команды

```sh
rokit install && wally install
stylua src && selene src && rojo build -o build.rbxlx
rojo serve
```
