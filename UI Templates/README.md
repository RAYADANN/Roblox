# UI Templates

Playground и библиотека UI-шаблонов для Roblox-игр (React-Lua + Flipper + Hoarcekat).

## Setup

```powershell
rokit install
wally install
rojo serve
```

В Studio: подключи Rojo. Плагин **Hoarcekat** должен быть установлен ([Marketplace](https://www.roblox.com/library/4621580428/Hoarcekat)).

## Hoarcekat

1. `rojo serve` → Connect в Studio (edit mode, Play не нужен).
2. Открой плагин Hoarcekat.
3. Выбери story из `ReplicatedStorage.UI.stories`:
   - `Inventory.story` — шаблон окна инвентаря
   - `ActionButton.story`
   - `CloseButton.story`
   - `Slot.story`
   - `GradientBar.story`
   - `OutlinedText.story`
   - `Motion.story` — 6 кнопок: soft / pop / tilt / lift / shake / slide
   - `Gallery.story` — галерея компонентов

Новый story: `src/ui/stories/Name.story.luau` — верни `mount(React.createElement(...))` (см. `stories/mount.luau`).

## Структура

```
src/ui/              ← ReplicatedStorage.UI (компоненты + stories)
src/ui/stories/      ← Hoarcekat *.story.luau
src/client/          ← mount App в PlayerGui (Play)
src/shared/
```

## React-Lua

Практическое руководство (как писать UI самому): [`docs/REACT_LUA.md`](docs/REACT_LUA.md).

## Адаптация (телефон / ПК)

Верстай UI **как на 1920×1080** внутри `DesignRoot`.  
`UiScaler` сам ставит `UIScale` на `ScreenGui` под viewport (`fit`, clamp 0.5–1.15).

```
src/ui/adapt/UiScaler.luau
src/ui/DesignRoot.luau
```

Play: `init.client.luau` уже вызывает `UiScaler.bind`.  
Hoarcekat: `stories/mount.luau` тоже.

## Переиспользование

Rojo `$path` на `src/ui` (или `components/`) из другой игры, либо позже Wally-пакет.
