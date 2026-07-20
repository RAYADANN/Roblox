# Night Raid Base — Game Design Document

> **REPO SNAPSHOT** — канон продукта **в этом репо**.  
> Источник Obsidian (для заметок): `Игры/Концепты/Night Raid Base — GDD.md`  
> При конфликте во время разработки: **этот файл** + явный запрос пользователя.  
> Синхрон с Obsidian: при правке GDD обновить **оба** места.  
> **Snapshot date:** 2026-07-17

> **Статус:** Phase 3 PROVE  
> **MECE:** 78/100 strict (см. Obsidian MECE)  
> **Pipeline:** Idea Machine Phase 0–2 complete · PROVE in progress  
> **Обновлено:** 2026-07-17 — **day loop канон = BaBaS (скрины):** dual roll, блоки с rarity, buy = ×100, traps, Collect All  
> **Сцена-референс:** `docs/REFERENCE_BABAS_SCENE.md`  
> **Код:** этот репо  
> **Трекер / план:** `docs/DEV_TRACKER.md` · `docs/IMPLEMENTATION_PLAN.md` · `docs/AGENT_BRIEF.md`  
> **Cursor rules:** `.cursor/rules/night-raid-*.mdc`

---

## 0. Pipeline snapshot

| Phase      | Status                                                 |
| ---------- | ------------------------------------------------------ |
| 0 Intake   | ✅ constraints + shelf check                            |
| 1 Diverge  | ⚠️ skipped (user-converged на 1 twist) — зафиксировано |
| 2 Converge | ✅ MECE 78 · red flags accepted                         |
| 3 PROVE    | ▶ in progress                                          |
| 4 BUILD    | blocked on PROVE Go                                    |

**Constraints (hard):**
- Solo · ≤40 дней · ≤8 systems  
- Полка 🔴 steal-clone — **разрешена только с mechanical twist** (night+light)  
- PROVE: **полный core loop** (dual roll blocks×100 + pets / build+traps / collect / steal / night shine) — **без** monetization, rebirth, lore, multi-monster  
- Target tier: **P2** (5–15k CCU), stretch P1  
- Improvement axis: **Verb/feel** (flashlight night) + retention RETURN  
- **Playtest оценивает всю сессию**, не один мини-режим 

**Frozen decisions:**
1. Pet loss = **Fog Cage** (redeem), не hard wipe  
2. Offline = pets **safe**  
3. Cycle = short scripted day/night (не real 24h)  
4. Rebirth (v0.3) = reset base+lights, keep 1 trophy pet  

---

## 1. Elevator pitch

**Title (working):** Night Raid Base  
**One-liner:** Днём строй базу и кради pets. Ночью чудище лезет за ними — отпугивай фонариком и светом на базе.

**Pitch 15 сек:**  
Роллишь блоки и pets (у обоих rarity), ставишь стены/ловушки, pets копят MPS — Collect All. Днём грабишь соседей. Ночью — монстр; свети фонариком. Утро: награда или Fog Cage.

**Verbs:** `roll` · `build` · `place` · `collect` · `steal` · `shine` · `defend`  
**Fantasy:** «Моя крепость + мой луч света против ночи»

---

## 2. Positioning

| | BaBaS / SAB | Night Raid |
|---|---|---|
| Day | Build + steal | То же |
| Night | — / ad-hoc events | **Встроенный PvE raid** |
| Defend | Walls vs players | Walls + **light** vs monster |
| Clip | Steal cry | Flashlight Fear + grab |

**Diff thesis:** ночь + свет = новый verb (`shine`), не reskin pets.

---

## 3. Core loops

### Day (3–4 мин) — **канон BaBaS-feel**

```
ROLL BLOCK (rarity) → BUY = +100 блоков в inventory
ROLL PET (rarity)   → BUY pet
    → BUILD (ghost на yard grid: стены / ловушки / лампы)
    → PLACE pets во двор → MPS в буфер
    → COLLECT ALL → wallet
    → STEAL / BAT / LOCK / TRAPS vs игроки
```

### Night (1.5–2 мин) — **наш твист**

```
DUSK warn → spawn 1 Monster/player → SHINE (+ lamps)
→ save pets OR Fog Cage → DAWN payout
```

### Meta (post-PROVE)

```
… cycles … → [ceiling] REBIRTH → …
Weekly: monster skin OR limited pet/block row
```

**Жёсткое правило продукта:** day loop = **как BaBaS** (dual gacha + inventory build + collect). Night = flashlight. Не упрощать day до «трёх слотов стен».

---

## 4. Session rhythm

| Phase | Duration | Player goal |
|---|---|---|
| DAY | 210–240s | Earn, build, raid |
| DUSK | 15s | Equip flashlight, check lamps |
| NIGHT | 90–120s | Keep pets |
| DAWN | 10s | Results |

**Full cycle ≈ 5.5–6.5 мин.**  
**Kill if:** night >180s or day >360s without agency.

Lighting: `Lighting.ClockTime` / `Brightness` tween per phase (cosmetic sync).

---

## 4A. World & platform (level design) — **для программиста**

> Полный визуальный разбор скринов: **`docs/REFERENCE_BABAS_SCENE.md`**.  
> Ниже — **канон Night Raid** (что кодить). Старые «3 wall slots / Build Shop pad only» — **устарели, не использовать**.

### Fantasy пространства

Каждый игрок = **свой floating plot** (остров). Plot = **две зоны**:

| Зона | Пол | Назначение |
|---|---|---|
| **Hub** | Деревянные плитки | Dual Roll (Block + Pet), Collect, Lock, luck boards |
| **Yard** | Зелёная трава + **тёмная сетка** | Build (стены/ловушки/лампы) + pets внутри ограды |

Сервер: **до 6 plots** в void/небе; между ними gap. Ночью темнеет; монстр у **фасада yard (+Z)**.

Вайб day = BaBaS (wood + grass). Night = soft horror (темнота, глаза монстра).

### Карта целиком (top-down)

```
                    N (−Z)
         ┌─────────────────────────┐
         │   Plot2      Plot3      │
         │                         │
   W     │  Plot1    (void gap) Plot4 │     E
 (−X)    │                         │   (+X)
         │   Plot6      Plot5      │
         └─────────────────────────┘
                    S (+Z)
```

| Параметр | Значение |
|---|---|
| Plots / server | **6** (`maxPlayers = 6`) |
| Plot footprint | **Hub ~24×20** + **Yard ~40×40** (уточнять в Studio) |
| Gap между plots | **16+** studs |
| CELL_SIZE (yard) | **4** studs |
| Roll stations | **На каждом plot Hub** (не один общий machine в центре) |

**PROVE:** минимум **2 plots**. Solo graybox = smoke, не playtest gate.

### Анатомия одного plot

```
            −Z (тыл yard)
     ┌──────────────────────────┐
     │      YARD (grass grid)   │  walls / traps / lamps / pets
     │      pets wander inside  │
     │           ▲ фасад открыт │  ← воры + монстр с +Z
     └────────────┬─────────────┘
                  │ стык
     ┌────────────┴─────────────┐
     │   HUB (wood planks)      │
     │  [Block Roll] [Pet Roll] │
     │  Collect · Lock · boards │
     └──────────────────────────┘
            +Z дальше: monster spawn, Fog Cage
```

| Объект Hub | Спека |
|---|---|
| **Block Roll pad** | Red/yellow mat + spinning preview + Billboard (`1 in X`, name, buyCost) + `[E] Roll!` |
| **Pet Roll pad** | Egg/`?` или pet preview + wire к red button + `[E] Roll!` |
| **Collect All** | Зелёная кнопка / world UI: buffer → wallet |
| **Lock pad** | «Base Lock FREE» (или cheap) |
| Luck boards | Buy 1 / Buy 15 Pet Luck & Block Luck (**stub OK в foundation**) |

| Объект Yard | Спека |
|---|---|
| Grid floor | Visible cell lines; snap build |
| Placed blocks | Walls from inventory |
| Traps | Spikes и др. (см. §4F) |
| Lamps | Placeable light (night Fear) |
| Pets | Unlimited Home в enclosure; billboards |

| Spawns | Локально |
|---|---|
| Player | Hub или край yard |
| Monster | Перед фасадом yard (+Z) |
| Fog Cage | Дальше +Z |

### Визуальный минимум (PROVE = parts OK)

| Деталь | Вид |
|---|---|
| Hub floor | Wood planks |
| Yard floor | Grass + dark grid |
| Block preview | Spinning Part / mesh |
| Pet | Ball/mesh + Neon rarity + Billboard |
| Spikes | Wedge/spike Parts на клетке |
| Ghost | Semi-transparent block |
| Lamp | Part + PointLight |
| Monster | Dark body + neon eyes |
| Flashlight | Beam cone |

Art polish — после PROVE Go.

---

## 4E. Канон day-экономики (BaBaS → Night Raid)

> Источник: скрины BaBaS + уточнение владельца 2026-07-17.

### Два gacha (симметричная модель)

| | **Blocks** | **Pets** |
|---|---|---|
| Rarity | ✅ Common→Mythic, `1 in X` | ✅ то же |
| Roll | Block Roll station | Pet Roll station |
| После Roll | Preview + odds + **Buy cost** | Preview + odds + Buy cost |
| **Buy** | Всегда **`+100`** штук этого блока в inventory | 1 pet instance |
| Re-roll | Да (новый spin / снова Roll) | Да |
| Зачем | Материал для Build + traps | MPS + steal target |

**Покупается всегда 100 блоков** — жёсткое правило. Не «1 блок за покупку». Не «купил стену в слот за $ без inventory».

### Flow Block (точный)

```
1. Игрок у Block Roll → [E] Roll (spinCost в data; можно 0 + только buyCost)
2. RNG по BlockDatabase weights → результат с rarity / oneIn
3. Preview крутится; Billboard: имя · "1 in X" · buyCost
4a. Buy → wallet -= buyCost → inventory[blockId] += 100
4b. Roll again → новый результат (некупленный сгорает)
5. Build tool → place по 1 с клетки; inventory--
```

### Flow Pet (точный)

```
1. Pet Roll → [E] Roll
2. RNG PetDatabase → preview (яйцо → reveal)
3. Buy → pet в MyPets / auto-place в yard → Home → +incomePerSec
4. MPS тикает в **Collect buffer** (не сразу в wallet)
5. Collect All → buffer → wallet
```

### Доход

| Правило | Значение |
|---|---|
| MPS | Sum `incomePerSec` всех Home pets |
| Куда | **Buffer** на plot |
| Claim | Кнопка **Collect All** |
| Offline | post-PROVE; pets safe |

---

## 4F. Build, Blocks, Traps (канон)

### Инструменты (hotbar)

| Slot | Режим |
|---:|---|
| 1 Build | Ghost snap; place from inventory |
| 2 Take | Убрать свой блок/trap → inventory++ |
| 3 Edit | R/T/G или recolor (минимум: R rotate) |
| 4 Bat | PvP: knockback вора + ломать **чужие** блоки |

Keys в Build: **R** rotate · **T** flip · **G** cycle shape (Cube/Wedge/Slab). Traps могут игнорить G.

### Сетка

| Param | PROVE |
|---|---|
| CELL_SIZE | 4 |
| Max placeables / plot | **40** (walls+traps+lamps) |
| Place | Только свой yard; клетка Empty |
| Stack height | PROVE default **1** слой |
| Destroy | Чужой bat: HP--; свои Take tool |

### `BlockDatabase` — блоки И ловушки

Одна таблица placeables с `kind`:

```lua
export type PlaceableDef = {
  id: string,
  kind: "wall" | "trap" | "lamp",
  displayName: string,
  rarity: string,
  oneIn: number,
  weight: number,
  buyCost: number,
  grantQty: number,     -- wall/trap: всегда 100; lamp: 1
  batHitsToBreak: number,
  slowFactor: number?,  -- trap
  damagePerSec: number?,
  lightRadius: number?, -- lamp
}
```

### PROVE набор (foundation)

| id | kind | rarity | oneIn | buyCost | grantQty | batHits | эффект |
|---|---|---|---:|---:|---:|---:|---|
| dirt | wall | Common | 2 | 450 | **100** | 1 | стена |
| wood_planks | wall | Uncommon | 15 | 2.5k | **100** | 1 | стена |
| stone | wall | Rare | 50 | 12k | **100** | 3 | стена |
| spikes | trap | Uncommon | 20 | 3k | **100** | 1 | slow 0.5 на клетке |
| lamp_t1 | lamp | Uncommon | 25 | 5k | **1** | 1 | PointLight + soft Fear ночью |

**Правило Buy:** `kind == "wall" | "trap"` → `grantQty = 100` всегда. Lamp в foundation: `grantQty = 1`.

Post-foundation: больше traps (pit, stun), defense cap `Defenses Placed: n/max`.

### Trap behavior (день)

1. Вор на клетке Spikes → WalkSpeed *= slowFactor.  
2. Триггер только для **чужих**.  
3. Монстр ночью: **игнор traps в PROVE**.  
4. Bat ломает чужие traps как блоки.

### Lamps (наш twist)

Placeable `lamp_*` из roll/buy. Ночью: Fear/slow в радиусе.

### UX Build

```
Equip Build → выбрать placeable в inventory
Raycast yard grid → ghost
R/T/G → transform
Click valid → RequestPlace → inventory[id] -= 1
```

---

## 4G. Pets (канон)

### Жизненный цикл

```
ROLL → Buy → Home в yard (MPS)
    → STEAL Carried → deposit на базе вора
    → NIGHT grab → FogCage → Reclaim
```

| Param | PROVE |
|---|---|
| Slots | Unlimited в yard |
| Income | Только Home |
| AI | Wander внутри enclosure / Pet Zone AABB |
| Billboard | `1 in X` · name · Level · `$/s` |
| Steal | Prompt → weld carry → slow → deposit |
| Defend | Owner bat → drop |

Стартер: 1–2 Common Home + cash + стек dirt (≥100).

### Steal / Lock / Bat

Фасад → pet → carry; Lock блокирует **игроков**, не монстра; bat ломает чужие placeables + knockback.

---

## 4H. Playtester day script

| Мин | Действие |
|---:|---|
| 0–1 | Claim: hub wood + yard grass; starter pet гуляет |
| 1–3 | Block Roll → Buy → **+100**; видит rarity |
| 3–5 | Build: ghost + стены; опционально Spikes |
| 5–7 | Pet Roll → Buy → MPS; **Collect All** |
| 7–12 | Steal / bat / traps (2 игрока) |
| 12+ | Lamps → Dusk → Shine |

**Kill-feel если сделали не то:** слоты стен без roll блоков; доход сразу в wallet без Collect; pets-статуи; один roll только pets.

---

## 4B. Session script (программист)

### Первый вход (0–2 мин)

1. Claim plot (Hub+Yard).  
2. Starter cash + 1–2 pets Home + dirt ≥100.  
3. HUD: Wallet, MPS, Buffer/Collect, Phase DAY, Battery.  
4. Tutorial: (1) Block Roll (2) Build (3) Pet Roll / Collect (4) flashlight.

### Day actions (PROVE)

| Действие | Как | Сервис |
|---|---|---|
| Roll block | Hub pad → Roll → Buy (+100) | `RollService` |
| Roll pet | Hub pad → Roll → Buy | `RollService` |
| Build / trap / lamp | Hotbar Build → ghost → place | `BuildService` |
| Take | Hotbar Take | `BuildService` |
| Collect | Collect All | `EconomyService` |
| Steal / Lock / Bat | фасад / pad / tool | `StealService` |

### Dusk / Night / Dawn

Fear, grab, Fog, interrupt — без смены смысла. Цель монстра = highest $/s Home pet.

### Пути

```
Monster: spawn +Z → target pet → grab → FogCage
Thief:   фасад → (traps slow) → steal pet → свой yard
```

Монстр **не** pathfind стены/traps в PROVE.

---

## 4D. Чеклист foundation (агент)

| # | Задача | PROVE |
|---|---|---|
| 1 | Plot Hub wood + Yard grass grid | ✅ |
| 2 | ≥2 plots + claim | ✅ |
| 3 | Block Roll + rarity + Buy=+100 | ✅ |
| 4 | Pet Roll + Buy pet | ✅ |
| 5 | Inventory stacks + Build/Take/Bat hotbar | ✅ |
| 6 | Ghost place + R (минимум) | ✅ |
| 7 | Spikes trap + ≥2 wall types | ✅ |
| 8 | Lamp placeable + night Fear | ✅ |
| 9 | Pets wander + billboards + MPS buffer + Collect All | ✅ |
| 10 | Steal + Lock + bat break | ✅ |
| 11 | Cycle + flashlight + monster + Fog | ✅ |
| 12 | Rebirth / offline / Robux / full trap roster | ❌ post |

---

## 5. Systems

### 5.1 Base + Build (`BaseService` / `BuildService`)

См. **§4A, §4F** + `docs/REFERENCE_BABAS_SCENE.md`.

- Plot = **Hub + Yard**; ≥2 plots PROVE, до 6  
- Snap grid 4×4; max **40** placeables  
- Inventory stacks; hotbar Build / Take / Edit / Bat  
- Bat ломает **чужие** placeables  

| Part | Day | Night |
|---|---|---|
| Wall block | Лабиринт; bat-break | Визуал (монстр не ломает) |
| Trap (Spikes) | Slow вора на клетке | Игнор монстром (PROVE) |
| Lamp | Prep | Fear/slow zone |
| Pets Home | MPS + steal target | Цель монстра (highest $/s) |

### 5.2 Dual Roll (`RollService`)

| Pool | Buy result |
|---|---|
| **Blocks/Traps** (`BlockDatabase`) | `inventory[id] += 100` (wall/trap); lamp += 1 |
| **Pets** (`PetDatabase`) | 1 pet → Home |

Оба пула: rarity + `oneIn` + weights + `buyCost`. Flow: Roll → preview → Buy | Re-roll.

### 5.3 Pets (`PetService` / `EconomyService`)

| Rarity | Rel $/s | PROVE count |
|---|---:|---:|
| Common | 1 | 3 |
| Uncommon | 3 | 2 |
| Rare | 10 | 2 |
| Epic | 40 | 1 |
| Mythic | 200 | 1 |

**Home:** wander в yard. **Carried:** weld. Income → **buffer** → Collect All. Без pedestal-лимита.

### 5.4 Day/Night Cycle (`CycleService`)

Server-authoritative phase + remaining time.  
On `NIGHT` → `MonsterService.spawnForAll()`.  
On `DAWN` → Fog resolve + bonuses.

### 5.5 Flashlight (`shine`)

| Param | MVP |
|---|---|
| Cone angle | ~35° |
| Range | 28 studs |
| Battery | Full at dusk; drains while shining; day recharge |
| Fear fill | ~3.5s continuous → Retreat |
| Mobile | Hold / soft-aim 60° |

### 5.6 Monster (1 type)

| Param | Value |
|---|---|
| Count | 1 per player per night |
| Target | Highest $/s **Home** pet |
| Speed | Base; ×0.5 in light |
| Fear | 0–1 → retreat |
| Grab | reach pet → `grab` → after `grabCarrySec` → Fog Cage |
| Interrupt | Fear≥1 during grab → pet returns Home |

### 5.7 Fog Cage

- Fog pet tagged to owner  
- DAY: redeem cash **or** free reclaim once/dawn (newbie)  
- Offline: **no** night wipe  

### 5.8 Steal + bat + Lock (**PROVE**)

Carry pet; bat knockback + break enemy placeables; Lock = players only.

### 5.9 Offline / Rebirth / Live ops

**post-PROVE.** Rebirth preview UI; offline pets safe; weekly cosmetic/data rows.

---

## 6. Economy (high-level)

**Soft:** Credits (wallet) + **Collect buffer**  

**Sources:** pet MPS → buffer → Collect All · dawn bonus · Fog redeem fees  

**Sinks:** Block Buy (×100) · Pet Buy · luck upgrades (stub) · Fog redeem  

**Не sink:** «покупка стены в слот без inventory» — запрещено каноном.

**Robux (post-PROVE):** flashlight/lamp skins, battery — **no** pay-to-skip nights, no unstealable PvE pets.

---

## 7. UX / HUD

| Element | Always |
|---|---|
| Wallet + MPS + Collect buffer/button | ✅ |
| Phase chip (DAY/NIGHT + timer) | ✅ |
| Hotbar Build/Take/Edit/Bat | ✅ |
| Battery | Night / while shining |
| Fear (on monster) | Billboard |
| Roll preview billboards | At pads |

Tutorial arrows: Block Roll → Build → Pet/Collect → flashlight. No walls of text.

---

## 8. MVP roadmap

### PROVE / Foundation — полный core loop

```
ROLL BLOCK (+100) → BUILD/TRAPS/LAMPS → ROLL PET → COLLECT ALL
→ STEAL/LOCK/BAT → DUSK → SHINE → Fog/save → DAWN
```

| # | Система | В foundation? |
|---|---|---|
| 1 | Hub+Yard plots ≥2 + claim | ✅ |
| 2 | Block Roll (rarity) + Buy=+100 | ✅ |
| 3 | Pet Roll + Buy | ✅ |
| 4 | Inventory + Build/Take/Bat + ghost | ✅ |
| 5 | Spikes + ≥2 walls + lamp | ✅ |
| 6 | Pets wander + MPS buffer + Collect All | ✅ |
| 7 | Steal + Lock + bat break | ✅ |
| 8 | Cycle + flashlight + monster + Fog | ✅ |

**Не в foundation:** rebirth, offline, Robux, full trap roster, luck boards (stub OK), trading, multi-monster.

**Почему:** playtest без dual-roll/build/collect оценивает не ту игру.

### После PROVE Go

Больше traps, luck boards live, rebirth, offline, polish, Discover.

---

## 9. PROVE gates

| Metric | Kill | Pivot | Go |
|---|---|---|---|
| Session median | <1.5m | 1.5–3 | >3 |
| «Want another night?» | <50% | 50–70 | >70% |
| Understood light w/o text | <60% | — | >80% |
| «Понял полный цикл» (roll/build/steal/night) | <50% | — | >70% |

**Playtest size (PROVE):** **3–5** человек, **минимум 2 одновременно** (иначе steal не оценить).

**Kill if:** flashlight = chore OR night = AFK wait OR day loop скучен OR «это просто BaBaS без twist».

---

## 10. Soft launch (post-MVP)

| Metric | Kill | Target |
|---|---|---|
| D1 | <15% | >20% |
| Like ratio | <70% | >85% |
| Median session | <5m | >8m |

---

## 11. Discover

1. Thumb: night base + cone + monster with pet  
2. Clip: Fear full → retreat scream  
3. Clip: dark corner → Mythic grabbed  

Working title OK for PROVE; finalize before Discover ads.

---

## 12. Data tables

### PetDatabase (PROVE)

| id | rarity | oneIn | buyCost | incomePerSec |
|---|---|---:|---:|---:|
| scrap_pup | Common | 2 | 100 | 1 |
| copper_cat | Common | 4 | 150 | 1.2 |
| glow_fox | Uncommon | 18 | 750 | 9 |
| volt_owl | Rare | 100 | 5k | 10 |
| night_hound | Epic | 500 | 40k | 40 |

### BlockDatabase (PROVE placeables)

| id | kind | rarity | oneIn | buyCost | grantQty | batHits | note |
|---|---|---|---:|---:|---:|---:|---|
| dirt | wall | Common | 2 | 450 | **100** | 1 | |
| wood_planks | wall | Uncommon | 15 | 2.5k | **100** | 1 | |
| stone | wall | Rare | 50 | 12k | **100** | 3 | |
| spikes | trap | Uncommon | 20 | 3k | **100** | 1 | slow 0.5 |
| lamp_t1 | lamp | Uncommon | 25 | 5k | **1** | 1 | light R=14 |

### CycleConfig

| key | value |
|---|---|
| daySec | 220 |
| duskSec | 15 |
| nightSec | 100 |
| dawnSec | 10 |

### MonsterConfig

| key | value |
|---|---|
| fearSeconds | 3.5 |
| speed | 12 |
| speedInLight | 6 |
| grabCarrySec | 10 |

### LightConfig

| key | value |
|---|---|
| coneDeg | 35 |
| range | 28 |
| lampRadius | 14 |
| lampFearPerSec | 0.15 |

---

## 13. Tech architecture (PROVE)

```
src/
  shared/
    data/ (PetDatabase, BlockDatabase, CycleConfig, MonsterConfig, LightConfig)
    Net/
    util/
  server/
    CycleService
    EconomyService      -- wallet + MPS buffer + Collect All
    BaseService         -- plots Hub+Yard claim
    RollService         -- dual pool Block/Pet
    BuildService        -- inventory place/take/bat-break + traps
    PetService          -- Home wander / carried / Fog
    StealService        -- steal + Lock
    MonsterService
    LightService        -- shine authority + lamp zones
  client/
    FlashlightController
    BuildController     -- ghost + hotbar
    CyclePresentation
    RollPresentation
```

**Rules:** `--!strict` · DI · modules ≤300 lines · destroy() cleanup · no `_G` · React-Lua HUD.

---

## 14. Risks

| Risk | Mitigation |
|---|---|
| 🔴 shelf | PROVE must prove new feel |
| Dual mode scope | Strict PROVE cut list |
| Mobile aim | Soft assist |
| Toxicity | Fog Cage, offline safe |
| SAB copycat | Ship night feel fast; weekly skins |

---

## 15. Open (non-blocking)

1. Final marketplace name  
2. Mythic immunity after night save? (default: no)  
3. SpinCost отдельно от buyCost на Block/Pet pads? (default: spinCost=0, платишь только Buy)  
4. Больше traps post-foundation (pit, stun) — список позже  
5. Luck boards live numbers — stub в foundation OK  

---

## 16. Success tiers

| Tier | CCU 30d |
|---|---:|
| P3 learning | 1k+ |
| **P2 target** | **5–15k** |
| P1 stretch | 50k+ |

---

## Appendix — One-line

> BaBaS day (dual roll blocks×100 + pets, grid build, traps, Collect All, steal) + night flashlight Fear + Fog Cage.  
> MECE 78 → PROVE the **full session**; day must match BaBaS feel, not wall-slots.

#gamedesign #roblox #gdd #night-raid
