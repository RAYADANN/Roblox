# UI Adaptivity — как делать правильно

## Короткий ответ

**Нет — подгонять размеры под каждое устройство вручную неправильно.**

Правильно:
1. Рисуешь в **design space** (референс 1280×720).
2. Все размеры — **дизайн-пиксели** (`layout.px(16)`, `layout.text(14)`).
3. Один модуль (`ViewportLayout`) переводит design → screen.
4. Тир устройства (`phone` / `tablet` / `desktop`) влияет только на **структуру** (что показать/спрятать), не на пиксели в компонентах.

---

## Что пошло не так в Deep Digger (Mining)

Там адаптивность **начиналась правильно**, но со временем разрослась:

| Проблема | Следствие |
|----------|-----------|
| 4 разных множителя: `uiScale`, `textMult` (×2 desktop), `chromeMult` (×2), `dockMult` (×1.5) | Компоненты не знали, какую функцию вызывать: `px()`, `textPx()`, `chromePx()`, `gsc()` |
| Размеры конкретных виджетов в ViewportLayout: `coinChipSize()`, `dockIconPx()` | Каждый новый чип = правка центрального модуля |
| Ручные override в компонентах «на глаз» под phone/desktop | Дублирование, рассинхрон, бесконечная подгонка |
| `layoutEpoch` + subscribe в каждом компоненте | Шум в коде вместо одного хука |

Итог: пришлось «под каждое устройство подгонять» — это **симптом**, а не норма.

---

## Правильная модель (roblox-starter)

```
Design space (1280×720)
        │
        ▼
ViewportLayout.uiScale()  ← единственный масштаб геометрии
        │
        ├── layout.px(52)     → высота строки
        ├── layout.text(14)   → TextSize (с полом MIN_TEXT)
        ├── layout.gap(8)     → = px(8), алиас для читаемости
        └── layout.modalFit() → UIScale для модалки

Tier (phone/tablet/desktop)
        │
        └── ТОЛЬКО структурные решения:
            • phone: скрыть боковую панель
            • phone: модалка 92% ширины
            • desktop: модалка 52% ширины
            НЕ: if phone then iconSize = 24 else 40
```

### Два типа адаптивности

| Тип | Где решается | Пример |
|-----|--------------|--------|
| **Масштаб** | `ViewportLayout` + `useLayout()` | padding, font, icon, corner radius |
| **Структура** | Компонент/panel через `layout.tier` | скрыть QuestTracker на phone |

### Модалки

1. Задаёшь design size (например 600×450).
2. `layout.modalFitScale(designW, designH)` → `UIScale.Scale` на корне модалки.
3. Внутри модалки все размеры — **design px** (не пересчитывать под экран).
4. `UIScale` сам ужимает/растягивает.

### Touch targets

- Минимум **44×44 design px** для кликабельных зон.
- `layout.touch(minDesign)` = `math.max(layout.px(design), 44)` на phone.

### Safe area

- `layout.safeTop` / `layout.safeLeft` из `GuiService:GetGuiInset()`.
- HUD позиционируется от safe area, не от (0,0).

---

## Правила для компонентов (обязательные)

```luau
-- ✅ ПРАВИЛЬНО
local layout = useLayout()
Size = UDim2.fromOffset(layout.px(52), layout.px(52))
TextSize = layout.text(14)

-- ❌ ЗАПРЕЩЕНО
if layout.tier == "phone" then size = 32 else size = 48 end
TextSize = 14  -- хардкод без layout
Color3.fromRGB(255, 200, 0)  -- хардкод без theme
```

```luau
-- ✅ Структурная адаптивность (допустимо)
if layout.tier == "phone" then
    return nil  -- не рендерим боковую панель
end
```

---

## React-интеграция

```luau
local layout = useLayout()  -- пересчитывается при resize/rotate

return React.createElement("Frame", {
    Size = UDim2.fromOffset(layout.px(200), layout.px(48)),
})
```

Один хук на компонент. **Не** подписываться на resize вручную в каждом файле.

---

## Чеклист перед мержем UI

- [ ] Нет `if tier ==` для размеров (только для show/hide)
- [ ] Нет литералов px в компонентах (только design-числа через `layout.*`)
- [ ] Цвета из `theme.Colors`
- [ ] Модалка использует `modalFitScale` + design space
- [ ] Проверено в Studio: phone (375×667), tablet (768×1024), desktop (1920×1080)
