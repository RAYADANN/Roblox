# UI Delight Spec — Breed & Raid

> **Цель:** UI, на который приятно смотреть и с которым приятно *взаимодействовать*.  
> Хит = loop + feel. UI не заменяет verb, но **убирает трение и даёт дофамин в мелочах**.  
> Стек: React-Lua + Flipper + MotionPresets + theme + useLayout (`roblox-starter`).  
> Визуальный lock: **Toybox Premium** (warm raised cards · saturated actions · light rims · deep shadows).

**Канон для агентов:** читай до правок HUD. Definition of Done — в конце.

---

## 1. Принцип

```
Красивая картинка  ≠  восторг
Восторг            =  мгновенный отклик + ясная иерархия + редкие «вау»-моменты
                     + тишина, когда не надо отвлекать
```

Каждый элемент отвечает на три вопроса:

1. **Что это?** (читается за &lt;0.5с)  
2. **Что будет, если нажму?** (до ответа сервера уже есть feedback)  
3. **Приятно ли?** (motion/sound/цвет не раздражают на 100-м нажатии)

---

## 2. Иерархия внимания (один экран — один герой)

| Приоритет | Что | Пример |
|---:|---|---|
| 1 | Главное действие / flex | `1 in X`, Hatch reveal, Buy |
| 2 | Ресурсы | Cash, Buffer, $/s |
| 3 | Навигация | Breed, Shop, Inventory |
| 4 | Хром | светлая обводка, тень, surface |

**Запрет:** два равноярких CTA на одном экране.  
**Запрет:** весь UI пульсирует всегда — пульс только на событии или 1 статус (Lock).

---

## 3. Визуальный язык (Toybox Premium)

| Token | Значение |
|---|---|
| Surface base | warm `#FFFbee`; raised `#FFFFFA`; tinted `#FFebC2` |
| Stroke | light rim `#FFFFF9`, 3–4 px |
| Shadow | deep semantic shadow, offset 4–14 px |
| Collect | saturated green `#2BBE70` |
| Buy / reward | bright gold `#FFC42D` |
| Info / lock | clear blue `#487EFF` |
| Breed | saturated purple `#B15DEE` |
| Danger / steal | coral red `#EE4C5C` |
| Text | warm ink `#3F2D36` · secondary `#715453` |
| Rarity borders | Common grey · Uncommon green · Rare blue · Epic purple · Mythic gold · Secret coral |

Не использовать glassmorphism, parchment ornaments, тонкие тёмные рамки или один нейтральный цвет для всех действий. Иконки централизованы в `IconRegistry`; временный glyph можно заменить asset id без изменения экранов.

Типографика:

- Titles: GothamBold / theme.Font.title  
- Body: GothamMedium  
- **Hero odds:** heavy + крупнее имени (`1 in X` &gt; name)

Воздух: padding **4 / 8 / 12 / 16 / 24 / 32** (через `layout.gap` / `theme.Space`).

---

## 4. Motion budget (живо, но не убивает FPS)

### Always-on (постоянно, sparingly)

| Элемент | Техника | Лимит |
|---|---|---|
| Primary buttons | `useHoverPress` spring | все CTA |
| Cash / Buffer / $/s display | `useFlipperSpring` + `SPRING_NUMBER` | **≤ 3** числа |
| Lock timer chip | мягкий pulse opacity **или** только countdown text | 1 |

### On-event only (обязательный juice)

| Событие | Motion | Sound id (завести) |
|---|---|---|
| Click CTA | press 0.94 → spring back | `ui_click` |
| Roll start | preview spin / shuffle 0.35s | `ui_roll` |
| Buy success | POP scale 1.14 + gold flash | `ui_buy` |
| Buy fail | shake X 6px | `ui_fail` |
| Collect | chip pulse + number surge | `ui_collect` |
| Breed start | parents → egg beam (simple) | `ui_breed_start` |
| Hatch | fullscreen 0.8–1.4s · big `1 in X` · POP | `ui_hatch` |
| Steal start (victim) | red vignette 0.2s + toast | `ui_steal_alert` |
| Lock on | dome chip slide-in | `ui_lock` |
| Modal open/close | `MODAL_IN` / `MODAL_OUT` | `ui_panel` |

### Запрещено (оптимизация)

- Spring на каждой карточке инвентаря в idle  
- Ререндер всего App на каждый MPS tick → обновляй только chip через контекст/мемо  
- Бесконечный particle emitter на ScreenGui  
- &gt; **12** активных Flipper motors одновременно (цель &lt; 8)  
- Постоянная анимация декоративного chrome

Пресеты: только `MotionPresets` + Flipper configs из starter. Не изобретать TweenInfo в компонентах.

---

## 5. Микро-взаимодействия (мелочи, которые помнят)

### Кнопка

1. Hover (desktop): scale **1.06**  
2. Press: **0.94** + звук на down или Activated  
3. Disabled: transparency 0.4, no spring  
4. Touch target ≥ **44×44** (`layout.touch`)

### Числа

- Показываем `floor(springDisplay)`  
- Логика «хватает ли $» — по **authoritative** props, не по spring  
- При большом скачке (&gt;20%): короткий POP на chip

### Карточка creature

Порядок текста (GDD):

1. Name  
2. **`1 in X`** (цвет rarity)  
3. `$/s`  
4. Melкий rarity chip / HYBRID  

Selected (breed): jade stroke + soft scale 1.03.

### Тосты

- Max **1** toast visible  
- Auto-hide 2.2–2.8s  
- Enter: slide+fade · Exit: fade faster  
- Error = rose border; Success = jade

### Модалки

- Veil 0.45 dark  
- Panel spring/back in  
- Закрытие быстрее входа  
- Tap veil = close (где безопасно; Breed confirm — нет)

---

## 6. Звук (без звука UI мёртв)

Минимальный банк (короткие mono, &lt;200ms кроме hatch):

`ui_click` · `ui_roll` · `ui_buy` · `ui_fail` · `ui_collect` · `ui_breed_start` · `ui_hatch` · `ui_steal_alert` · `ui_lock` · `ui_panel`

Правила:

- Volume UI bus отдельно от world  
- Settings → SFX toggle уважается  
- Не спамить: roll tick max 1/80ms  

---

## 7. Окна — checklist восторга

Каждое окно должно пройти:

| # | Окно | Обязательный delight |
|---|---|---|
| 1 | HUD | spring resources · Collect juice · Summon panel chrome |
| 2 | Summon/Roll | preview drama · Buy POP · odds hero |
| 3 | Breed | select feedback · expected oneIn · start sting |
| 4 | Inventory | rarity borders · select · empty state illustration |
| 5 | Shop | tab switch fade · purchase POP / fail shake |
| 6 | Hatch | **hero moment** full attention 1s |
| 7 | Steal alert | urgency without spam |
| 8 | Lock chip | clear status |
| 9 | Settings | instant toggle feedback |
| 10 | Leaderboard | rank #1 gold accent |
| 11 | Tutorial | soft arrows · skip · never wall of text |
| 12 | Empty/Error | friendly, not broken gray box |

Empty states: одна строка + CTA («Roll your first creature»), не пустой void.

---

## 8. Производительность — Definition of Done

Перед merge UI-задачи:

- [ ] Phone mid (или Device Emulator): HUD idle **стабильный FPS**, без просадок от UI  
- [ ] Flipper motors в idle ≤ 8  
- [ ] MPS tick не реконструирует Roll/Breed деревья  
- [ ] Списки со стабильными keys  
- [ ] FX one-shot через Debris / cleanup в useEffect  
- [ ] Reduce VFX выключает hatch particles / shockwaves  

---

## 9. Порядок внедрения (не всё сразу)

| Фаза | Что |
|---|---|
| P0 | Toybox tokens · Button/Chip с hover-press · spring Cash/Buffer/MPS · звук click/buy/fail |
| P1 | Modal motion · Roll/Buy juice · Collect · Toast system |
| P1.5 | **World UI** — pet billboards · pad previews · custom ProximityPrompt · nest/pad materials (`shared/ui/WorldUi`) |
| P2 | Hatch hero · Steal alert · Breed select feel |
| P3 | Final icon atlas · Inventory polish · Shop tabs · LB |

Сначала отклик рук, потом декоративные assets. HUD без world UI = дешёвый разрыв.

---

## 10. Анти-паттерны (убивают восторг)

- Красивый статичный мокап без press/sound  
- Все кнопки одного цвета  
- Odds мельче имени  
- Toast спам  
- Анимация ради анимации в AFK  
- Разные радиусы/отступы в соседних панелях  
- Hardcode Color3 вне `theme.luau`  

---

## 11. Связь с хитом (честно)

Delight UI **усиливает** hit, если loop уже тянет («хочу ещё breed/steal»).  
Если loop мёртвый — UI станет красивой оболочкой.  
Поэтому: PROVE loop Go → затем P0–P2 delight → ornament P3.

---

## Definition of Done (игровой восторг)

Игрок после 3 минут может сказать не «понял кнопки», а:

- «приятно жать»  
- «хatch кайф»  
- «`1 in X` сразу видно»  
- не lag на телефоне  

Если нет — UI ещё не hit-grade.

#ui #delight #breed-raid #react #flipper
