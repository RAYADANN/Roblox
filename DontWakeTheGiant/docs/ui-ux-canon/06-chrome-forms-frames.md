# 06 — Chrome: Forms, Frames, Shadows, Elevation

Chrome = оболочка UI: панели, рамки, углы, глубина.  
Проф. chrome **поддерживает** иерархию; любительский chrome **украшает всё одинаково**.

---

## Формы окон и панелей

### Геометрия

| Форма | Когда |
|-------|-------|
| Скруглённый прямоугольник | Default panels, cards, buttons |
| Pill / capsule | Chips, tags, soft CTA |
| Circle | Icon buttons, avatars |
| Hard rect (radius 0–2) | Tactical / competitive / retro-tech |
| Ornate / custom mesh | Только brand moments (title, premium shop) — не каждый toast |

Выбери **один** язык углов на продукт. Смешение pill + sharp + ornate = «ассет-пак с Marketplace».

### Радиусы (токены)

Ограниченный набор, например:

`radius.xs=4 · sm=8 · md=12 · lg=16 · pill=999`

Правило: вложенная панель имеет **меньший или равный** радиус, чем родитель (иначе «мыло»).

---

## Рамки (strokes)

| Тип | Толщина | Роль |
|-----|---------|------|
| Hairline | 1px | Default card border |
| Strong | 2px | Primary panel / focus |
| Accent bar | 3–4px **с одной стороны** | Selected / rarity / CTA |

Правила:

- `BorderSizePixel = 0` + `UIStroke` (контролируемый).  
- Не обводи всё gold. Accent stroke = редкий сигнал.  
- Контраст stroke к fill ≥3:1 если stroke несёт shape identity.  
- Inner highlight (верхняя 1px светлая) — опциональный polish на raised surfaces; не обязателен.

---

## Тени и elevation

Проф. системы моделируют **слои**, не «красивую тень».

### Уровни (пример)

| Level | Использование | Тень |
|-------|---------------|------|
| 0 | Встроенный в фон HUD chip | Нет / едва |
| 1 | Card на panel | Soft, small blur, low opacity |
| 2 | Dropdown / popover | Medium |
| 3 | Modal shell | Stronger; + dim backdrop |

Параметры тени (концепт): `offsetY`, `blur`, `spread`, `color` (обычно чёрный 20–50% opacity).  
На Roblox: нет CSS box-shadow — имитируй через:

- затемнённый sibling frame со смещением,  
- или мягкий `ImageLabel` 9-slice shadow asset,  
- или отказ от тени + stroke + bg separation (часто чище на mobile).

**Запрет:** три цветных glow-слоя на каждой кнопке; drop-shadow на каждом label.

### Backdrop

Модалка: scrim `overlay` 40–60% opacity. Блокирует клики миру.  
Не делай scrim ярким — он должен приглушать мир, не конкурировать.

---

## Поверхности и материалы

Слои фона:

`bg1 (app) → bg2 (dock) → bg3 (card) → bg4 (inset well)`

Каждый шаг — заметный, но спокойный (ΔL примерно равномерный).

Материалы:

- Flat + stroke = современный clean.  
- Soft gradient (90°, white→subtle gray на face кнопки) = лёгкий объём без реализма.  
- Texture parchment/metal = brand; **снижай контраст текстуры**, чтобы текст не дрожал.  
- Neon emissive pads в мире — почти всегда выглядят прототипными; лучше SmoothPlastic + PointLight soft.

---

## Акцентные детали (дозировка)

Допустимые «мелочи» проф. UI:

- 3px accent bar top/left на active tab / selected card  
- Corner flourish **только** на hero modal (1 ассет)  
- Divider hairline между секциями  
- Focus ring снаружи контрола  

Недопустимо:

- Рамки с 8 декоративными уголками на каждом toast  
- Анимированный gradient border idle  
- Разные стили окон в Shop vs Inventory без theme variant

---

## Состояния chrome

| State | Chrome change |
|-------|---------------|
| Default | Base surface + hairline |
| Hover | Slight lift / brighter fill (desktop) |
| Pressed | Inset feel (darker) + scale down |
| Selected | Accent bar or stronger stroke |
| Disabled | ↓ opacity, no hover lift |
| Error | Danger stroke + optional shake |
| Success | Brief success flash, потом normalize |

---

## World vs Screen chrome

ScreenGui и Billboard должны **узнаваться как одна семья**:

- Те же cream/ink или те же dark/cyan tokens.  
- Те же радиусы (визуально).  
- World: чуть крупнее type, AlwaysOnTop осторожно, MaxDistance.

Разрыв «красивый HUD + чёрный дефолтный prompt» убивает ощущение AAA.

---

## DoD chrome

- [ ] Radius/stroke/elevation только из tokens  
- [ ] ≤1 accent treatment на компонент  
- [ ] Modal имеет scrim + focus trap behavior  
- [ ] Нет glow-спама  
- [ ] World UI в том же языке
