# 08 — HUD

HUD = persistent слой real-time state.  
Проф. HUD показывает **минимум**, который окупает экранное место.

---

## Minimum Viable HUD

Добавляй элемент только с обоснованием:

| Always-on | Только если |
|-----------|-------------|
| Resources (cash) | Меняются часто / нужны для решений каждую минуту |
| Vitals | Урон/ресурс реально давит |
| Objective | Игрок регулярно теряется без него |
| Shortcut dock | Core verbs без меню |

| Contextual | |
|------------|--|
| Prompts | У объекта |
| Buffs | Пока активны |
| Danger vignette | Пока critical |
| Build ghost | В режиме build |

| On-demand | Inventory, settings, map, craft |

---

## Simulator / tycoon / pet-game HUD (Roblox)

Типичный проф. каркас:

```
Top:     Resource chips (cash, gems, buffer) — мало, крупно
Left/Right: Progress / quest (optional, collapsible)
Bottom:  Dock — Sell | Pets | Shop | Rebirth | Settings
Center:  Toasts / tutorial only when needed
```

Не:

- Дублировать cash в chip + toast + world + modal header одновременно без нужды.  
- Вешать 12 кнопок dock.  
- Держать shop open поверх dig без pause-состояния.

---

## Читаемость поверх мира

Текст/иконки HUD должны переживать:

1. Яркий sky / snow  
2. Тёмную пещеру  
3. Particle spam  

Средства: panel backplate, stroke, shadow **или** достаточный solid chip bg.  
Не полагайся на TextStroke alone.

---

## Hierarchy внутри HUD

1. Ресурс, от которого зависят покупки  
2. Primary flex метрика (depth, 1-in-X best, MPS)  
3. Navigation dock  
4. Всё остальное

Анимация чисел — да; анимация декоративных рамок idle — нет (бюджет motors).

---

## Customization

Проф. продукты дают:

- HUD scale  
- Opacity  
- Hide non-essential  

Даже 2 уровня (Full / Minimal) повышают ощущение качества.

---

## Performance budget (Roblox)

- Idle Flipper motors ≤8 (см. delight rules проекта)  
- MPS tick не пересоздаёт деревья  
- Toasts через Debris/pool  
- Reduce motion выключает shake/particles

---

## DoD HUD

- [ ] Каждый элемент оправдан  
- [ ] Worst-case scene test  
- [ ] Phone dock usable thumb zones  
- [ ] Нет color-only alerts  
- [ ] Density не мешает gameplay silhouette
