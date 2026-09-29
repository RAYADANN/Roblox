# UI Adaptivity — `client/ui/adapt`

## Единый design standard: **1920×1080**

Все design px / Scale-токены авторятся в пространстве **1920×1080**. Других reference size нет.

| Путь | Масштабирование |
|------|-----------------|
| `DesignRoot` + `UIScale` | Fit холста 1920×1080 в host |
| `ViewportLayout` + `useLayout()` | `REF_W/H = 1920/1080` → screen px |
| `FarmHud` (StarterGui.HUD) | Screen `UDim2.fromScale` на весь `GameUI` |

## Контракт

1. **Модалки / панели на холсте** — `DesignRoot` + `UIScale` fit.
2. **HUD из Studio (`StarterGui.HUD` → `FarmHud`)** — screen Scale на весь `GameUI` (`CoreUISafeInsets`). Без `DesignRoot`: иначе letterbox 16:9 даёт огромные поля на телефоне.
3. **Starter-компоненты** (`Button`, `ModalChrome`, …) — design px через `layout.px()` / `layout.text()` @ 1920×1080.
4. Внутри композиции — `UDim2.fromScale` / токены. **Без** `if isPhone` для сетки.
5. Телефон «мельче» только через fit холста (модалки) или через доли экрана (HUD).

## API

```luau
-- Screen HUD (FarmHud)
React.createElement(FarmHud)

-- Canvas panel
React.createElement(DesignRoot, {}, { ... })
Size = UDim2.fromScale(0.22, 0.075) -- fraction of 1920×1080 canvas

-- Starter component
local layout = useLayout()
Size = UDim2.fromOffset(layout.px(theme.Design.ROW_H), layout.px(180))
```

Тюнинг fit: `adapt/Config.luau`. Тюнинг HUD: Scale-позиции как в `StarterGui.HUD`.
