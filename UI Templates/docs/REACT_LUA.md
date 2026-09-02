# React-Lua — руководство для этого проекта

Кратко: ты описываешь **дерево UI** (что на экране, размеры, props). Я потом подключаю ассеты, градиенты, анимации, stories, правки API.

В проекте **нет JSX**. Всё через `React.createElement`.

---

## 1. Как это устроено

| Обычный Studio | React-Lua |
|----------------|-----------|
| Создаёшь `Frame` в Explorer | Возвращаешь `createElement("Frame", …)` |
| Меняешь свойства в Properties | Передаёшь таблицу props |
| Children в дереве | Третий аргумент — таблица `{ Name = element, … }` |
| Скрипт сам чистит инстансы | React создаёт / обновляет / удаляет |

Монт уже есть:

- **Play** → `src/client/init.client.luau` рендерит `App`
- **Hoarcekat** → `src/ui/stories/*.story.luau` + `mount.luau`

Тебе обычно не нужно трогать mount — только компоненты и layouts.

---

## 2. Базовый шаблон компонента

Файл: `src/ui/components/MyThing.luau`

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

export type Props = {
	size: UDim2, -- всегда явно, без глобальных «стандартов»
	layoutOrder: number?,
	onActivated: (() -> ())?,
}

local function MyThing(props: Props): React.Node
	return React.createElement("TextButton", {
		Size = props.size,
		BackgroundColor3 = theme.Colors.bg,
		BorderSizePixel = 0,
		Text = "",
		LayoutOrder = props.layoutOrder,
		AutoButtonColor = false,
		[React.Event.Activated] = props.onActivated,
	}, {
		-- children: ключ = Name инстанса в Studio
		Label = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "HI",
			Font = theme.Font.display,
			TextScaled = true,
			TextColor3 = theme.Colors.text,
		}),
	})
end

return MyThing
```

Использование:

```lua
React.createElement(MyThing, {
	size = UDim2.fromScale(0.2, 0.06),
	layoutOrder = 1,
	onActivated = function()
		print("click")
	end,
})
```

---

## 3. `createElement` — три аргумента

```lua
React.createElement(тип, props?, children?)
```

1. **тип** — строка Roblox-класса (`"Frame"`, `"TextLabel"`, `"UIListLayout"`) **или** твоя функция-компонент
2. **props** — свойства инстанса + спец-ключи React
3. **children** — таблица `{ ChildName = element, … }` (имена = `Name` в Explorer)

### Спец-ключи (не свойства Instance)

| Ключ | Зачем |
|------|--------|
| `[React.Event.Activated]` | клик кнопки |
| `[React.Event.MouseEnter]` | hover |
| `[React.Change.AbsoluteSize]` | когда изменился размер |
| `[React.Tag]` | CollectionService tag (редко) |

События мыши/кнопок — только так, не через `:Connect` внутри компонента (кроме cleanup в `useEffect`).

---

## 4. Размеры (важно для этого кита)

- Размер **всегда** передаёшь снаружи: `size = UDim2.fromScale(w, h)`
- Scale `0–1` = доля **родителя**, не экрана (если родитель не fullscreen)
- Крупный CTA и мелкая кнопка — разные `size`, один компонент
- `aspectRatio` — только если нужно зафиксировать пропорции картинки (опционально)

```lua
-- крупный BUY
size = UDim2.fromScale(0.22, 0.07)

-- компактный CLOSE
size = UDim2.fromScale(0.12, 0.045)
```

Отступы между блоками — из `theme.Space` (`pad`, `gap`, `sectionGap`), не размеры кнопок.

---

## 5. Layout (как собрать экран)

Типичная колонка:

```lua
React.createElement("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
}, {
	Pad = React.createElement("UIPadding", {
		PaddingTop = UDim.new(theme.Space.pad, 0),
		PaddingLeft = UDim.new(theme.Space.pad, 0),
		PaddingRight = UDim.new(theme.Space.pad, 0),
		PaddingBottom = UDim.new(theme.Space.pad, 0),
	}),
	Layout = React.createElement("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(theme.Space.gap, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	Title = React.createElement(OutlinedText, {
		text = "INVENTORY",
		variant = "title",
		size = UDim2.fromScale(0, 0.07),
		layoutOrder = 1,
	}),
	Buy = React.createElement(ActionButton, {
		tone = "buy",
		size = UDim2.fromScale(0.2, 0.065),
		layoutOrder = 2,
	}),
})
```

Правила:

- У детей списка ставь `LayoutOrder`
- Горизонтальный ряд — `FillDirection.Horizontal`, при необходимости `Wraps = true`
- `AutomaticSize = Enum.AutomaticSize.Y` — высота по содержимому (удобно для секций)

Готовые кирпичи уже есть: `ActionButton`, `CloseButton`, `Slot`, `GradientBar`, `OutlinedText`.

---

## 6. Состояние и хуки

### `useState` — значение, которое меняет UI

```lua
local open, setOpen = React.useState(false)

-- ...
[React.Event.Activated] = function()
	setOpen(not open)
end
```

После `setOpen` React перерисует компонент.

### `useEffect` — побочные эффекты + cleanup

```lua
React.useEffect(function()
	local conn = something:Connect(function() end)
	return function()
		conn:Disconnect() -- обязательно
	end
end, { dependency }) -- {} = один раз при mount
```

### `useRef` — значение без ре-рендера

```lua
local motorRef = React.useRef(nil :: any)
-- motorRef.current = ...
```

Готовый хук проекта: `hooks/useHoverPress` — scale на hover/press. Подключать к кнопкам могу я; тебе достаточно знать, что анимация живёт отдельно от layout.

---

## 7. Условный рендер и списки

```lua
-- показать / скрыть
Detail = if open then React.createElement(Panel, { size = ... }) else nil

-- список
local items = {}
for i, id in inventoryIds do
	items["Slot" .. i] = React.createElement(Slot, {
		rarity = "purple",
		size = UDim2.fromScale(0.1, 0.1),
		layoutOrder = i,
	})
end
```

Ключи в таблице children должны быть **стабильными** (`Slot1`, `Slot2`…), не случайными.

---

## 8. Theme — что брать оттуда

`src/ui/theme.luau`:

| Поле | Твоя работа |
|------|-------------|
| `Colors`, `Font`, `Radius`, `Stroke` | использовать, не хардкодить RGB |
| `Space` | pad / gap между блоками |
| `ActionGradients`, `SlotGradients`, … | обычно не трогать руками — смотри готовые компоненты |
| размеры кнопок | **не в theme** — в props |

Картинки: `ImageIds.luau` → `image = ImageIds.greenLinear` на `ActionButton`.

---

## 9. Story (проверка в Hoarcekat)

`src/ui/stories/MyThing.story.luau`:

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MyThing = require(script.Parent.Parent.components.MyThing)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

return mount(React.createElement("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = theme.Colors.bg,
	BorderSizePixel = 0,
}, {
	Thing = React.createElement(MyThing, {
		size = UDim2.fromScale(0.25, 0.08),
	}),
}))
```

`rojo serve` → Connect → Hoarcekat → выбрать story. Play не обязателен.

---

## 10. Разделение работы (ты / я)

**Ты пишешь:**

1. Layout экрана / панели (`Frame` + `UIListLayout` + размеры)
2. Какие компоненты и с какими props (`tone`, `rarity`, `size`, текст)
3. Простую логику (`useState`: открыто/закрыто, выбранный слот)
4. Черновик story, чтобы видеть композицию

**Я доделываю:**

1. PNG / `ImageIds`, 9-slice, точное совпадение с Figma
2. Градиенты, stroke, hover (Flipper)
3. Рефактор API props, общие хуки
4. Подключение к данным игры (когда будет игра)
5. Правки под разные разрешения, баги Studio

Минимум для «готово к правке мной»: компонент компилируется (`--!strict`), есть `size` снаружи, в Hoarcekat видно roughly то, что задумал.

---

## 11. Чеклист нового UI

1. `--!strict` вверху файла  
2. `export type Props = { … }`  
3. `size: UDim2` у визуальных виджетов  
4. Цвета/шрифт из `theme`  
5. Children с понятными именами (`Buy`, `Row`, `Layout`)  
6. Story рядом в `stories/`  
7. Не класть «универсальный размер всех кнопок» в `theme`

---

## 12. Частые ошибки

| Ошибка | Как правильно |
|--------|----------------|
| Забыть `return` компонента | `return React.createElement(...)` |
| Children массивом `{ a, b }` без ключей | Таблица `{ A = a, B = b }` |
| `Size` в scale от экрана, а родитель маленький | Scale всегда от **родителя** |
| `:Connect` без cleanup | Только в `useEffect` + disconnect в return |
| Менять props инстанса вручную | Меняй state → React обновит props |
| JSX `<Frame />` | В Luau этого нет — только `createElement` |

---

## Шпаргалка API

```lua
local open, setOpen = React.useState(false)
local ref = React.useRef(nil :: Frame?)

React.useEffect(function()
	return function() end -- cleanup
end, {})

React.createElement("Frame", { Size = UDim2.fromScale(1, 1) }, {
	Child = React.createElement(Other, { size = UDim2.fromScale(0.2, 0.05) }),
})

-- события
[React.Event.Activated] = function() end
[React.Event.MouseEnter] = function() end
```

Готовые примеры в репо: `components/ActionButton.luau`, `App.luau`, `stories/ActionButton.story.luau`.
