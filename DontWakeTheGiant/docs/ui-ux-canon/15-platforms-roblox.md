# 15 — Platforms & Roblox Constraints

## Устройства

| | Phone | Tablet | Desktop | Console/TV |
|--|-------|--------|---------|------------|
| Input | Thumb | Thumb/cursor | Mouse+kb | Gamepad |
| Session | Короче | Средне | Дольше | Couch |
| Type floor | Средний | Средний | Средний | Крупнее |
| Hover | Нет | Редко | Да | Нет |
| Hit | ≥44–56 | ≥44 | ≥36 visual ok | Focus-based |

Проектируй **mobile + desktop одновременно**, не «потом добавим».

---

## Roblox-specific

### ScreenGui layers

Раздели профили (`UiScreen`): `hud · modal · toast · fx`.  
DisplayOrder стабилен; IgnoreGuiInset осознанно.

### Адаптив

Один design space + scale (`ViewportLayout` / `useLayout`).  
Tier меняет **структуру** (скрыть secondary), не магические размеры.

См. `docs/UI_ADAPTIVITY.md`.

### Шрифты и ассеты

Встроенные Font Face; кастом — права + fallback.  
ImageRect / 9-slice для панелей.

### Performance

- Low-end Android реален  
- Меньше прозрачных blur-эффектов  
- Billboard count лимитируй  
- UI не на Heartbeat без нужды  

### ProximityPrompt

Custom Style + клиентский chrome; сервер задаёт Action/Object text.

### Safe & insets

Тестируй iPhone notch, Android gesture bar, tablet split.

---

## Input matrix (обязательный тест)

Каждый новый экран:

- [ ] Touch only  
- [ ] Mouse only  
- [ ] (Если поддерживаете) Gamepad focus  

---

## DoD platform

- [ ] Phone + desktop playtest  
- [ ] Нет hover-only affordance  
- [ ] Layers/UiScreen  
- [ ] layout.text/px everywhere
