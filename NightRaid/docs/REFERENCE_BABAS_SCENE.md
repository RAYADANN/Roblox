# BaBaS — Reference Scene & Mechanics (from screenshots)

> **Цель:** программист может **воссоздать сцену и loop** без догадок.  
> **Источник:** скриншоты Build a Base and Steal😈 (июль 2026), анализ UI/мира.  
> **Файл:** `docs/REFERENCE_BABAS_SCENE.md`  
> **Связь:** `MECHANICS_BUILD_AND_PETS.md` · Night Raid GDD (наш твист = night+light поверх этого feel)

---

## 0. Одной картинкой — что это за игра

```
ДВА GACHA на хабе:
  [E] Roll BLOCK  → стек блоков в инвентарь (Dirt x100, Wood x9…)
  [E] Roll PET    → питомец с $/s

BUILD MODE (молоток):
  ghost snap на ЗЕЛЁНОЙ сетке → ставишь блоки из инвентаря
  R rotate · T flip · G shape (куб/клин/…)

PETS живут ВНУТРИ твоей постройки на траве:
  billboard: имя · "1 in X" · Level · $value
  дают МПС (money per second)

ДОХОД копится в "сейфе":
  кнопка «Соберите все ($XX)» → в карман

BAT · Lock базы · Luck апгрейды · Events · Rebirth
```

---

## 1. Макет участка игрока (сцена целиком)

Каждый игрок = **свой floating plot** в void/небе. Plot = **две зоны**, состыкованные.

```
        ┌─────────────────────────────────────────────┐
        │         VOID / SKY (чёрный или день)          │
        │                                               │
        │   ┌──────────────┐   ┌────────────────────┐ │
        │   │  HUB WOOD    │   │  YARD GRASS GRID   │ │
        │   │  (управление)│───│  (стройка+питомцы) │ │
        │   │              │   │                    │ │
        │   │ rolls/buttons│   │  walls + pets      │ │
        │   │ collect/UI   │   │                    │ │
        │   └──────────────┘   └────────────────────┘ │
        └─────────────────────────────────────────────┘
```

| Зона | Материал пола | Назначение |
|---|---|---|
| **Hub** | Деревянный плиточный пол (planks), сетка видна | Roll block, Roll pet, кнопки unlock, Collect, boards luck, Lock |
| **Yard** | Зелёная трава с **тёмной сеткой** (grid lines) | Строительство блоков + содержание pets |

**Ориентир размеров (оценка по кадру, уточнять в Studio):**

| Элемент | Approx |
|---|---|
| Ячейка сетки yard | **~4×4 studs** (1 блок = 1 клетка) |
| Hub depth | ~20–28 studs |
| Yard size | ~32–48 studs square (хватает на ограду + внутренний двор) |
| Plot в мире | floating island; соседние plots видны вдалеке |

---

## 2. Hub — объекты сцены (что поставить в Workspace)

### 2.1 Две станции Roll (главный loop)

Рядом друг с другом на деревянном полу:

#### A) Block Roll Station

| Часть | Описание |
|---|---|
| Floor pad | Красный прямоугольник с жёлтой обводкой (~4×4–6×6) |
| Glow | Белый/жёлтый ring + vertical god-rays |
| Preview model | Парит и **медленно крутится** над pad: либо `?` куб, либо результат (Dirt block) |
| Billboard | Название (`x100 Блок грязи`) · `1 in 2` · flavor text · цена roll `$450` зелёным |
| Prompt | World UI: иконка кубика + «Прокрутите блок!» + **`[E] Roll!`** |
| Button | Опционально физ. кнопка; на скринах часто ProximityPrompt у pad |

**Покупается всегда 100 блоков** при Buy после Roll (wall/trap). Lamp grantQty=1. Блоки имеют rarity как pets. Ловушки (Spikes+) — placeables из того же пула.

См. GDD §4E–4F.


#### B) Pet Roll Station

| Часть | Описание |
|---|---|
| Floor pad | Такой же red/yellow mat |
| Preview | Яйцо `?` **или** готовый pet (кролик) с glow/sparkles |
| Billboard | `x1 Кролик` · `1 in 18` · **`$9/s`** · цена roll `$750` |
| Wire | Чёрный «кабель» по полу от pad к большой **красной кнопке** на серой базе |
| Button | Крупная red push-button + иконка лапы |
| Prompt | «Раскатайте питомца!» + `[E] Roll!` |

**Логика:** платишь cash → RNG pet → pet появляется / идёт в «Мои питомцы» → ставится в yard (или auto-place). Доход = `$/s` на billboard.

### 2.2 Floor buttons / unlock pads (tycoon style)

На hub разбросаны круглые/квадратные кнопки:

| Пример с экрана | Функция |
|---|---|
| «Блокировка базы БЕСПЛАТНО» | Lock базы (FREE) |
| Locked pad + «20M» | Unlock расширения / зоны за milestone |
| Иконки shop / OP | Unlock фич |

**Реализация:** Part + BillboardGui + Touched / ProximityPrompt → сервер списывает / toggles flag.

### 2.3 World boards (3D UI щиты)

Большие деревянные щиты за станциями:

| Board | Контент |
|---|---|
| **Pet Luck** | `1.40x → 1.50x`, кнопки «Купить 1» / «Купить 15» + цены |
| **Block Luck** | аналогично для удачи блоков |
| **Base Lock / MPS** | «Общее количество МПС: $420/с» + зелёная «Соберите все ($26k)» |

### 2.4 Collect All

Крупная **зелёная кнопка** (screen UI и/или world):

- MPS тикает в **буфер** (не сразу в wallet).  
- «Соберите все ($X)» → buffer → wallet, buffer=0.  
- Рядом может быть сундук/сейф prop.

---

## 3. Yard — строительство (детальная механика)

### 3.1 Что видно на скрине

- Пол = **зелёная сетка**.  
- Игрок строит **ограду/короб** из Dirt + Wooden Planks.  
- Стены толщиной ~1 блок; внутри двор, где стоят pets.  
- Режим Build: **полупрозрачный ghost** блока перед персонажем.  
- В руках молоток/tool.  
- Inventory panel: стеки блоков с rarity `Uncommon (1 in 15)`.  
- Stats: `Размещено блоков: 173`, `Defenses Placed: 1/5`.

### 3.2 Hotbar (нижний центр) — state machine инструментов

| Slot | RU | Иконка | Режим |
|---:|---|---|---|
| 1 | Построить | Молоток | BuildMode: ghost + place from inventory |
| 2 | Взять | Урна | Remove/Pickup: удаляет блок → возвращает в inventory |
| 3 | Редактировать | Карандаш | Edit: rotate/recolor/move? |
| 4 | Деревянная бита | Бита | Combat: PvP / ломать чужое |

Слева от hotbar — иконка инвентаря / pets.

### 3.3 BuildMode — алгоритм для программиста

```
ON equip Build tool:
  show Left panel "Блоки [Player]" (grid icons + counts)
  show Right panel selected block info + R/T/G
  enable ghost

EACH frame:
  raycast from camera/tool to Yard grid
  snap to cell (floor Y + stack height if building up)
  ghost.CFrame = cellCFrame * rotation * shapeOffset
  ghost transparency ~0.5; color valid=green / invalid=red

ON click (valid):
  if inventory[blockId] > 0:
    server PlaceBlock(plotId, cell, rot, shapeId)
    inventory[blockId] -= 1
    blocksPlaced += 1

KEYS:
  R = yaw += 90°
  T = flip / mirror
  G = cycle shapes: FullCube | Wedge | Slab | Corner… (одна семья блока)
```

**Важно:** блоки **сначала роллятся** в инвентарь, потом ставятся. Не «купил и сразу поставил за $ из магазина» как единственный путь (shop может дублировать, но core = roll→inventory→build).

### 3.4 Данные блока

```lua
BlockDef = {
  id = "wood_planks",
  displayName = "Блок деревянных досок",
  rarity = "Uncommon",
  oneIn = 15,
  shapes = { "Cube", "Wedge", "Slab" }, -- G cycles
  maxStack = 999,
  -- defenseTag optional for Defenses 1/5 cap
}
```

### 3.5 Сетка и коллизия

- Yard = GridMap `cells[x][z][layerY]`.  
- Place только в bounds своего plot.  
- Stack: ray hit top of existing block → layer+1.  
- Чужой plot: Build запрещён; Bat может ломать (если PvP).

---

## 4. Pets — сцена и поведение

### 4.1 Что видно

Внутри деревянной ограды на траве:

- Несколько маленьких stylized creatures (фиолетовые и др.).  
- Над каждым **столбик BillboardGui**:
  - rarity odds (`1 in 10k`, `1 in 100`, `1 in 180`…)
  - имя (`Mew`, `Homer`, …)
  - `Level 1`
  - денежный value (`$7.11k` или `$9/s`)
- Pets **сгруппированы во дворе**, не разбегаются по хабу.
- Есть glow/trail на некоторых.

### 4.2 Логика размещения

| Правило | Из скринов |
|---|---|
| Где живут | Только **внутри yard** (за постройкой) |
| Как попадают | Roll pet → inventory «Мои питомцы» → place / auto |
| Доход | Каждый pet даёт MPS; сумма = Total MPS |
| UI pet | World billboard всегда лицом к камере |
| Follow player? | На скринах **стоят/бродят во дворе**, не за игроком на хабе |

### 4.3 Движение (реконструкция для кода)

```
PetAI Home:
  anchor = centroid of yard OR nearest "pet zone" inside walls
  OR each pet has soft leash to a spawn point inside enclosure
  wander radius small (3–8 studs)
  stay INSIDE build bounds (ray/AABB of player walls)
  Idle + short Walk loops
  CanCollide = false
```

Если игрок **не построил стены** — pets всё равно на траве yard, но без защиты (их легче украсть).

### 4.4 Данные pet

```lua
PetDef = {
  id = "rabbit",
  displayName = "Кролик",
  oneIn = 18,
  incomePerSec = 9,
  model = "...",
}
-- Instance attributes when placed:
-- OwnerUserId, Level, IncomePerSec, RarityOneIn
```

Billboard text format (как на скрине):

```
1 in 18
Кролик
Level 1
$9/s
```

---

## 5. Экономический loop (точный)

```
1. Collect buffer → Wallet
2. Spend Wallet on:
   - Roll Block ($450…)
   - Roll Pet ($750…)
   - Luck upgrades (Buy 1 / Buy 15)
   - Unlock pads (20M…)
3. Roll Block → Inventory stacks
4. Build tool → place stacks on grass grid → fortress
5. Roll Pet → place in yard → +MPS
6. MPS fills Collect buffer every second
7. Steal/defend with bat (PvP) — optional tension
8. Mystery Event timer (live ops)
9. Rebirth (sidebar) — reset for mult
```

**Критично:** MPS ≠ мгновенный wallet. Нужен **accumulator + Collect All**.

---

## 6. Screen HUD (полный чеклист UI)

### Left sidebar (вертикаль)

| Кнопка | RU |
|---|---|
| Shop | Магазин |
| Index | Индекс (коллекция блоков/pets) |
| Rebirth | Возрождение |
| Co-op | Совместная игра |
| Saves | Saves |
| My Pets | Мои питомцы |

### Bottom-left

- Wallet `$1.11m` + `+` (Robux top-up)  
- Luck clover `x1`  
- Mystery Event countdown  

### Bottom-center

- Hotbar 1–4 (Build / Take / Edit / Bat)  

### Bottom-right / mid-right

- Total MPS `$420/s`  
- Collect All `$XX`  
- Base Lock control  

### Top-right

- Robux luck products: Double Roll, Lucky +100%, Super Lucky +300%  
- Dice / Fast throw 199 R$  

### Build mode overlays

- Left: block inventory grid + counts + placed stats  
- Right: selected block card + rarity + R/T/G buttons  

---

## 7. Lighting / VFX / Atmosphere

| Элемент | Спека |
|---|---|
| World | Floating plots in **black void** OR bright sky (time/biome) |
| Hub pads | Strong PointLight + beam/godrays on active roll result |
| Pet egg | Aura rings + upward particles |
| Ghost block | Semi-transparent + outline |
| Billboard | AlwaysOnTop / max distance cull |

---

## 8. Модульная карта для воссоздания сцены (порядок работ)

| Step | Что сделать | Acceptance |
|---:|---|---|
| 1 | 1 floating plot: Hub wood + Yard grass grid | visually matches split |
| 2 | Block Roll pad + Prompt + preview spin + billboard | E roll gives inventory stack |
| 3 | Pet Roll pad + red button + wire + egg preview | E roll gives pet |
| 4 | Wallet + MPS buffer + Collect All button | numbers update |
| 5 | Luck boards Buy 1/15 | multipliers affect weights |
| 6 | Hotbar tools state machine | 1 Build 2 Take 3 Edit 4 Bat |
| 7 | BuildMode ghost + R/T/G + place/consume stack | walls on grass |
| 8 | Pets in yard + billboards + wander in enclosure | MPS sums |
| 9 | Lock free pad | toggles raid lock |
| 10 | Event timer UI | countdown only OK for PROVE |

---

## 9. Что это меняет для Night Raid (наш проект)

BaBaS на скринах = **двойной gacha (blocks + pets) + inventory build + Collect buffer**.

| Было у нас в GDD (упрощение) | Референс BaBaS |
|---|---|
| Покупка стен за cash в слоты | **Roll блоков → стек → Build tool** |
| Pets как static markers | Pets во дворе + billboard + wander |
| Income сразу в credits | **Буфер + Collect All** |
| Один Roll | **Два Roll: Block и Pet** |

**Рекомендация для Night Raid PROVE:** копировать **feel и сцену** BaBaS (hub+yard, dual roll, grid build, collect), наш твист оставить: **ночь + flashlight + monster**. Не изобретать третью экономику.

Открытые правки Night Raid GDD после этого дока:
1. Добавить Block Roll + inventory stacks  
2. Collect All buffer  
3. Hub wood / Yard grass split layout  
4. Hotbar Build/Take/Edit/Bat  
5. R/T/G ghost build  

---

## 10. Чеклист «сцена воссоздана»

- [ ] Две зоны пола (wood / grass grid)  
- [ ] Block roll station с `1 in X` + spinning preview  
- [ ] Pet roll station с яйцом/pet + red button + wire  
- [ ] Collect All + MPS readout  
- [ ] Luck boards  
- [ ] Hotbar 4 tools  
- [ ] Ghost place + R/T/G  
- [ ] Inventory stacks of blocks  
- [ ] Pets inside built walls with multi-line billboards  
- [ ] Lock free  
- [ ] Event timer  

#reference #babas #gamedesign #leveldesign
