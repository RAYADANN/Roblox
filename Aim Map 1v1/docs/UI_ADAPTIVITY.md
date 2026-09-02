# UI Adaptivity — `client/ui/adapt`

## Контракт

1. Весь UI — на холсте **1920×1080** (`DesignRoot`).
2. На любом устройстве раскладка **та же** — только `UIScale` = fit в safe area (`CoreUISafeInsets`) для HUD.
3. Fullscreen inventory / settings — отдельный `GameModal` ScreenGui (`IgnoreGuiInset`, profile `modal`): **scrim на весь ModalHost**, панель внутри своего `DesignRoot` (fit 1920×1080).
4. Прицел / hitmarker / combat flash — отдельный `GameAim` ScreenGui (profile `aim`, `IgnoreGuiInset`), свой `DesignRoot` для прицела. Полноэкранная вспышка (красный урон / голубой килл) сидит прямо на host, чтобы покрыть topbar.
5. Внутри холста — `UDim2.fromScale` / токены `theme.Layout`. **Без** `if isPhone` для сетки и размеров.
6. Телефон «мельче» визуально на экране, но **не другая композиция**.

## API

```luau
React.createElement(DesignRoot, { config = adapt.DEFAULT }, { ... })
Size = UDim2.fromScale(0.78, 0.74) -- centered on modal canvas; same on PC and phone
```

Тюнинг fit: `adapt/Config.luau`. Тюнинг композиции: `theme.Layout` (один набор токенов).

## Файлы

| Файл | Роль |
|------|------|
| `shared/util/UiAdaptLogic` | pure fit |
| `adapt/UiScaler` | host → scale |
| `DesignRoot` | холст + UIScale |
| `util/UiScreen` | CoreUISafeInsets (hud) / IgnoreGuiInset (aim, modal, fx) |
| `util/AimHost` | Full-bleed host for crosshair / hitmarker / combat flash |
| `theme.Layout` | доли холста (без *Phone) |
