# Breed & Raid — Game Design Document

> **REPO SNAPSHOT** — канон продукта **в этом репо**.  
> Obsidian mirror: `Игры/Концепты/Breed & Raid — GDD.md`  
> При конфликте во время разработки: **этот файл** + явный запрос пользователя.  
> Синхрон с Obsidian: при правке GDD обновить **оба** места.  
> **Snapshot date:** 2026-07-19

> **Статус:** Phase PROVE foundation (repo boot)  
> **MECE:** ~76/100 strict (полка 🔴 BaBaS/SAB; upside = fuse-as-core + `1 in X`)  
> **Арт-лимит соло:** 5 base meshes + 8 accessories + aura presets  
> **Трекер / план:** `docs/DEV_TRACKER.md` · `docs/IMPLEMENTATION_PLAN.md` · `docs/AGENT_BRIEF.md`  
> **BaBaS ref:** `docs/REFERENCE_BABAS_SCENE.md`  
> **Cursor rules:** `.cursor/rules/breed-raid-*.mdc`

**Канон:** этот файл = единственный источник истины для программиста.  
Все **BLOCKER**-вопросы закрыты ниже (см. также `docs/PROGRAMMER_QUESTIONS.md`). Если конфликт с чатом — побеждает GDD.

---

## 0. Elevator + feeling

| Поле | Значение |
|---|---|
| **Working title** | Breed & Raid *(финальное имя TBD)* |
| **Verb** | `breed` + `steal` |
| **Feeling (якорь)** | Жадность к hybrid + страх/кайф чужого steal |
| **One-liner** | Растишь и склеиваешь creatures на базе → они дают $/s. Рейдишь чужие гнёзда. Редкий hybrid видно всему серверу. |
| **Clip** | Fuse pop → Mythic hybrid / ор при steal hybrid |
| **Архетип** | A (Фабрика) + social raid |
| **Engines** | E2 build · E3 collection/breed · E4 steal · E1 MPS |

**Pitch 15 сек:** Роллишь creatures, ставишь на Nest, скрещиваешь двух → hybrid сильнее и редже. Строишь двор, ставишь ловушки. Воруешь чужие hybrids — они тяжелее и громче. Lock / bat / Collect All.

---

## 0A. Frozen decisions (не обсуждать в коде)

1. **Always-day** в MVP/PROVE (нет night cycle — это не Night Raid).  
2. **Parents consumed** при успешном breed; при fail — возврат (редко burn).  
3. **Look = genes pipeline**, не новые меши.  
4. **Нет** unstealable / pay-to-win lock forever.  
5. **Нет trading** в MVP.  
6. **Нет rebirth** в MVP (v1).  
7. **Offline MPS** — да, soft, с cap (MVP launch; не PROVE).  
8. **Server-authoritative** всё economy/steal/breed.  
9. **Max 6 players / 6 plots**.  
10. Steal можно **всегда** (нет raid-window), кроме Lock и safe-zone.  
11. **`oneIn` (1 in X) — первичный flex**, не «просто rarity label». Rarity = цветовая банда от `oneIn`.

---

## 1. Target / constraints

| Constraint | Value |
|---|---|
| Solo ship | ≤40 дней до soft |
| Core systems | ≤8 |
| PROVE | 3–5 дней graybox feel |
| Tier target | P2 (5–15k), stretch выше если fuse = память жанра |
| Language UI | EN primary; RU strings ok в Locales |
| Rig | R15 |
| Streaming | Весь мир в памяти (6 маленьких plot) |

### 8 systems (канон)

| # | System | Module |
|---|---|---|
| 1 | Plots Hub+Yard | `BaseService` |
| 2 | Cash + MPS buffer + Collect | `EconomyService` |
| 3 | Creatures + Nests + Look | `CreatureService` |
| 4 | Creature Roll + Block Roll | `RollService` |
| 5 | Breed + Incubator | `BreedService` |
| 6 | Steal + Lock + Bat | `StealService` |
| 7 | Build + Traps | `BuildService` |
| 8 | Tutorial + LB stub + shop stubs | `MetaService` |

**Не systems отдельным счётом:** HUD, SFX, DataStore profile (infra).

---

## 2. Core loop (точный)

```
CLAIM PLOT
  → starter: Cash + 2 Common on Nests
  → ROLL Creature → Buy → inventory / auto-Nest
  → ROLL Block → Buy → inventory += 100
  → BUILD walls/traps/incubator pads (grid)
  → PLACE / MOVE creatures on Nests → MPS → buffer
  → COLLECT ALL → Cash
  → BREED: pick 2 → Incubate → Hatch hybrid
  → STEAL: hold prompt → carry → deposit on own Nest
  → DEFEND: Lock / Bat / Traps
  → SPEND: nests, luck, rolls, incubate speed
```

**Session target:** «склеить rarer hybrid / унести чужой / защитить свой».  
**Kill if:** fuse не wow **или** день = чистый BaBaS без желания breed.

---

## 3. World & level design (LD канон)

### 3.1 Server layout

| Param | Value |
|---|---|
| `maxPlayers` | **6** |
| Plots | **6** (1 на игрока) |
| Layout | кольцо / гекс в void |
| Gap plot↔plot | **≥20** studs (коридор void) |
| Shared lobby | **нет** — spawn на своём Hub |
| Lighting | Always day: `ClockTime=14`, `Brightness=2`, `Ambient=0.4,0.4,0.45` |

```
                 N
           Plot2     Plot3
       Plot1     ·     Plot4
           Plot6     Plot5
                 S
```

Plot origin = центр Yard. Соседние plot видны; billboards читаются с **≥80** studs.

### 3.2 Анатомия одного plot

```
                    −Z (тыл / safe)
     ┌──────────────────────────────────┐
     │         YARD 40×40 (grass grid)  │
     │   nests внутри ограды            │
     │   walls / traps                  │
     │              ▲ фасад открыт      │  ← воры с +Z
     └───────────────┬──────────────────┘
                     │ стык 4 studs
     ┌───────────────┴──────────────────┐
     │     HUB 24×20 (wood planks)      │
     │ Creature Roll · Block Roll       │
     │ Collect · Lock · Incubator · Shop│
     │ spawn pad                        │
     └──────────────────────────────────┘
                    +Z (raid approach)
```

| Zone | Size | Floor | CELL |
|---|---|---|---|
| **Hub** | **24×20** studs | Wood planks | visual 4 |
| **Yard** | **40×40** studs | Grass + dark grid | **4×4** |
| Full footprint | ~24×64 inkl. стык | | |

| Object (Hub) | Position (local) | Spec |
|---|---|---|
| Spawn pad | Hub center-ish `(0, 0, 8)` | Spawn; **safe zone r=8** — steal/bat **off** |
| Creature Roll | Hub left `(−6, 0, 4)` | Red/yellow mat + preview + `[E] Roll!` |
| Block Roll | Hub right `(6, 0, 4)` | Same pattern |
| Collect All | Hub front `(0, 0, 2)` | Green button / prompt |
| Lock pad | `(−8, 0, 0)` | «Base Lock» |
| Incubator station | `(8, 0, 0)` | Egg chamber + timer billboard |
| Luck boards | Hub rear wall | Stub OK in PROVE |
| Leaderboard board | optional Hub | Server top-3 stub |

| Object (Yard) | Spec |
|---|---|
| Nest pedestals | **8 hard props** в карте (см. §3.3); игрок **активирует** слоты покупкой |
| Build grid | вся Yard; place walls/traps |
| Pets wander | AABB внутри текущей ограды / PetZone |

### 3.3 Nest layout (hard props)

**8 nest sockets** в Yard, паттерн 2 ряда × 4:

| NestId | Local XZ (studs, Yard center 0,0) |
|---|---|
| N1 | (−12, −8) |
| N2 | (−4, −8) |
| N3 | (4, −8) |
| N4 | (12, −8) |
| N5 | (−12, 4) |
| N6 | (−4, 4) |
| N7 | (4, 4) |
| N8 | (12, 4) |

| Param | Value |
|---|---|
| Pedestal height | **3** studs |
| Nest snap | creature pivot на top + 1 stud |
| Start unlocked | **N1–N4** (4 nests) |
| Locked until buy | N5–N8 |
| Max nests MVP | **8** |
| One creature / nest | **строго** |
| Carry clearance | ceiling ≥8 studs в nest area |

### 3.4 Steal approach (LD числа)

| Metric | Value |
|---|---|
| Approach from +Z façade | открытый фронт **≥16** studs width |
| Entrance → nearest nest | **~18–22** studs |
| Nest ↔ nest | **8** studs centers |
| Alternate paths | **≥2** (left / right around build); LD playtest: нельзя wall-off 100% без gap |
| Chokepoint min width | **4** studs (1 cell) — traps ok |
| Mid corridor (void) | **20** studs; cover = нет (открытый пробег) |
| Fall Y | `Y < plotOrigin.Y − 40` → respawn Hub; **carry returns to victim** |

### 3.5 Permissions / boundaries

| Rule | Value |
|---|---|
| Walk to other plots | **всегда** |
| Build | **только owner** |
| Place/move creatures | только owner |
| Invisible walls | по периметру plot footprint +1 cell; void between plots walkable bridging? **Нет мостов** — прыжок/коридор на невидимой thin floor `20×4` между соседними plot по кольцу (raid path) |
| Raid path floor | тонкая платформа между plot i и i+1, width **6** studs |

---

## 4. Creatures — data & look

### 4.1 Rarity enum

`Common < Uncommon < Rare < Epic < Mythic` (5)

### 4.2 Base species (MVP = 5 meshes)

| speciesId | Mesh role | Default vibe |
|---|---|---|
| `pup` | round dog-like | starter cute |
| `cat` | round cat-like | agile |
| `fox` | fox-like | sly |
| `owl` | owl-like | wise |
| `bug` | beetle-like | weird |

Accessories budget (все species): **8** MeshParts — `horn_a`, `horn_b`, `wings_small`, `crown`, `scarf`, `antenna`, `spike_back`, `halo_ring`.

Faces: **6** decals shared.

Aura presets: по **rarity band** (см. §4.3A).

### 4.3A oneIn system (канон полки 2026)

**Игрок читает силу как `1 in X`, не как слово Common.**

| Правило | Значение |
|---|---|
| Поле на инстансе | `oneIn: number` (**integer ≥ 2**) — сохраняется в profile |
| UI везде | строка **`1 in {format(oneIn)}`** крупнее rarity |
| Rarity | **производная** от `oneIn` (банда для цвета/ауры/VFX) |
| Roll | каждый template в пуле имеет **свой** `oneIn` + `weight` |
| Hybrid | новый `oneIn` по формуле §7.5 — главный chase fuse |
| Blocks | у placeable тоже свой `oneIn` на roll preview / inventory |

**Rarity band от oneIn:**

| oneIn range | Rarity label | Aura / color |
|---|---|---|
| 2 – 9 | Common | grey/white |
| 10 – 49 | Uncommon | green |
| 50 – 199 | Rare | blue |
| 200 – 999 | Epic | purple |
| 1_000 – 9_999 | Mythic | yellow/gold |
| ≥ 10_000 | Secret* | red/black glitch |

\*Secret = тот же enum `Mythic` в логике PROVE **или** отдельный label `Secret` в MVP (UI); для кода: `rarityFromOneIn(oneIn)`.

**Format `oneIn` для UI:**

| Value | Display |
|---:|---|
| 2..999 | `1 in 2` … `1 in 999` |
| 1_000..999_999 | `1 in 1.2K` / `1 in 15K` (1 decimal if needed) |
| ≥ 1_000_000 | `1 in 1.2M` |

Функция shared: `FormatOneIn(n: number): string`.

**Billboard / inventory / roll preview / steal carry — порядок текста:**

1. Display name  
2. **`1 in X`** (самый крупный / accent)  
3. `$/s`  
4. Rarity chip (мелкий) + `HYBRID` если есть  

### 4.3 Instance fields (server)

```lua
export type CreatureInstance = {
  id: string,              -- UUID
  templateId: string?,     -- base roll row id; nil if hybrid
  speciesId: string,       -- pup|cat|fox|owl|bug
  ownerUserId: number,
  oneIn: number,           -- PRIMARY flex (integer ≥ 2)
  rarity: string,          -- derived cache from oneIn (do not balance off this alone)
  mps: number,
  isHybrid: boolean,
  generation: number,      -- 0 base roll, +1 per breed
  genes: Genes,
  nestId: string?,         -- nil = in storage
  lockedUntil: number?,    -- nest lock end utc
  bornAt: number,
}

export type Genes = {
  primaryColor: Color3,    -- stored as {r,g,b} 0–1
  secondaryColor: Color3,
  faceId: string,
  accHead: string?,        -- accessory id or nil
  accBack: string?,
  scale: number,           -- 0.85–1.45
  auraId: string,          -- from rarity band
}
```

| Rule | Value |
|---|---|
| HP | **нет** |
| Stacking | **нет** — всегда unique instances |
| Storage cap | **40** creatures (nests + storage) |
| visualSeed | **не храним** — look всегда из `genes` |
| Client-visible id | да (для prompts) |
| `oneIn` mutate | только через breed result / admin; roll копирует с template |

### 4.4 Look pipeline (порядок)

1. Base mesh `speciesId`  
2. `primaryColor` on Body  
3. `secondaryColor` on Accent parts  
4. `scale` (лёгкий bump с `log10(oneIn)`)  
5. `faceId` decal  
6. `accHead` (1)  
7. `accBack` (1)  
8. `auraId` particles по rarity band  

Стакать два aura нельзя. Два accessory одного слота нельзя.

**Scale от oneIn (доп. к genes.scale):**  
`displayScale = clamp(genes.scale * (1 + 0.04 * log10(oneIn)), 0.85, 1.55)`

### 4.5 Creature Roll pool (templates) — не «одна строка на rarity»

Каждый roll выбирает **строку template**, у каждой свой `oneIn`.

| templateId | speciesId | oneIn | weight | buyCost | mps | displayName |
|---|---|---:|---:|---:|---:|---|
| pup_c | pup | 2 | 28 | 100 | 1 | Scrap Pup |
| cat_c | cat | 3 | 22 | 120 | 1.2 | Copper Cat |
| bug_c | bug | 5 | 14 | 180 | 1.5 | Lint Bug |
| fox_u | fox | 12 | 12 | 500 | 4 | Glow Fox |
| owl_u | owl | 18 | 8 | 750 | 5 | Volt Owl |
| pup_r | pup | 50 | 6 | 3_000 | 12 | Iron Pup |
| cat_r | cat | 75 | 4 | 4_500 | 15 | Sapphire Cat |
| fox_e | fox | 200 | 3 | 25_000 | 55 | Neon Fox |
| owl_e | owl | 350 | 2 | 40_000 | 70 | Storm Owl |
| bug_m | bug | 1_000 | 0.7 | 200_000 | 220 | Void Bug |
| fox_m | fox | 2_500 | 0.25 | 500_000 | 280 | Myth Fox |
| owl_s | owl | 10_000 | 0.05 | 2_000_000 | 400 | Glitch Owl |

`weight` — относительный шанс в roll (не обязан = 1/oneIn; oneIn = **рекламный/коллекционный** номер как в BaBaS/SAB).  
Фактический roll: weighted random по `weight`; выпавший template копирует `oneIn` на instance.

**Luck:** Creature Luck 1/2 умножает weights строк с `oneIn ≥ 200` (×1.5 / ×2).

**Hybrid MPS:**  
`mps = max(A.mps, B.mps) * (1 + 0.15 * log10(childOneIn / max(A.oneIn, B.oneIn, 2)))`  
clamp: не ниже `max(A.mps,B.mps)`, не выше `max(A.mps,B.mps) * 2.5`.

### 4.6 Nest rules

| Rule | Value |
|---|---|
| Start nests | 4 (N1–N4) |
| Buy nest N5 | $5_000 |
| Buy nest N6 | $15_000 |
| Buy nest N7 | $40_000 |
| Buy nest N8 | $100_000 |
| Move nest↔nest | free, instant, owner only |
| Unequip to storage | free; MPS stops |
| Empty nest look | grey bowl + «Empty» |
| Occupied | creature + Billboard |
| Billboard | always on; text: Name · **`1 in X` (hero)** · `$/s` · rarity chip · `HYBRID` |
| 2 on one nest | **запрещено** |
| Nest destroy | **нельзя**; sockets fixed LD |
| Roll when nests full | → storage; if storage full → **block Buy** (Roll preview ok) |

---

## 5. Economy

### 5.1 Currencies

| Id | UI name | Type |
|---|---|---|
| `cash` | `$` / Cash | Soft |
| Robux | Robux | Premium products only |

Других валют в MVP **нет**.

### 5.2 Income

| Source | MVP |
|---|---|
| MPS → buffer | ✅ |
| Collect All | ✅ buffer→cash |
| Sell creature | ✅ |
| Steal bounty | ❌ (вор получает creature, не cash bonus) |
| Quests | daily breed stub v1 |
| Offline | MVP launch: **50% MPS**, cap **4h**, grant on join |

**MPS tick:** сервер раз в **1.0s** `buffer += floor(sumNestMps)`.  
Округление **вниз**.

### 5.3 Collect

Кнопка Collect All на Hub. Нет auto-collect. Buffer billboard над Collect.

### 5.4 Sell creature

`sellPrice = floor(50 * oneIn^0.65 * (isHybrid and 1.35 or 1))`  
(минимум 35). Sell только из storage или с nest. Подтверждение UI.  
**Flex в UI sell:** показать `1 in X` рядом с ценой.

### 5.5 Caps

| Cap | Value |
|---|---|
| Cash | soft soft-cap UI warning at 1e12 (анти-баг), hard нет |
| Buffer | нет cap |
| Placeables / plot | **40** |
| Creatures total | **40** |

### 5.6 Refund purchases

Soft shop: **нет** undo. Roll Buy: нет refund.

---

## 6. Roll systems

### 6.1 Creature Roll

| Step | Behavior |
|---|---|
| 1 | Prompt `[E] Roll!` у pad (spinCost = **0**) |
| 2 | RNG по `weight` таблицы §4.5 → preview: Name · **`1 in X`** · rarity · mps · buyCost |
| 3a | **Buy** → cash− → instance (`oneIn` с template) → storage / auto-nest |
| 3b | **Roll again** → old preview discarded |

Preview billboard **обязан** показывать `1 in X` как BaBaS (крупно, accent color по band).

Starter grant (не roll):

| Grant | oneIn |
|---|---:|
| Cash **500** | — |
| Scrap Pup on N1 | **2** |
| Copper Cat on N2 | **3** |
| Blocks `dirt` ×100 | 2 |

### 6.2 Block Roll (BaBaS-feel)

Как [[BaBaS — Reference Scene]]: rarity blocks, **Buy = +100** в inventory (wall/trap). Lamp/incubator parts: grantQty=1 если kind требует.

PROVE foundation placeables:

| id | kind | rarity | oneIn | buyCost | grantQty | batHits | effect |
|---|---|---|---:|---:|---:|---:|---|
| dirt | wall | Common | 2 | 450 | 100 | 1 | wall |
| wood_planks | wall | Uncommon | 15 | 2_500 | 100 | 1 | wall |
| stone | wall | Rare | 50 | 12_000 | 100 | 3 | wall |
| spikes | trap | Uncommon | 20 | 3_000 | 100 | 1 | slow 0.5 |
| nest_deco | deco | Uncommon | 25 | 2_000 | 100 | 1 | visual only |

### 6.3 Luck (soft sink)

| Upgrade | Cost | Effect |
|---|---:|---|
| Creature Luck 1 | 10_000 | weights с `oneIn ≥ 200` ×1.5 |
| Creature Luck 2 | 50_000 | weights с `oneIn ≥ 200` ×2 |
| Breed Luck 1 | 20_000 | failChance ×0.8; mutate-up +5pp (см. §7.5) |

PROVE: boards stub visual; logic can hardcode Luck 0.

---

## 7. Breed / Incubate (killer system)

### 7.1 Entry rules

| Rule | Value |
|---|---|
| Parents | **ровно 2** creature **одного owner** |
| From | storage **или** nest (снимаются в incubator) |
| Same nest breed | нет — оба уходят в incubator machine |
| Start | owner only, на своём Hub incubator |
| During incubate steal | parents **не stealable** (не на nest) |
| Parallel | **1** job MVP; GamePass/soft → 2nd slot v1 |
| Cancel | да → parents back to storage; fee **25%** sum sellPrice parents (min 50) |

### 7.2 Timing

| Key | Value |
|---|---|
| `incubateSec` | **120** |
| Soft speed-up | $ = `100 + elapsed*2` → remaining /= 2 (once per job) |
| Robux skip | DevProduct full complete (см. §12) |
| Offline incubate | **идёт** по wall-clock; hatch on join |

### 7.3 Outcomes

| Roll | Chance | Result |
|---|---:|---|
| Success | **85%** | parents **destroyed**; hybrid created |
| Fail | **10%** | parents returned to storage; toast «Breed failed» |
| Burn | **5%** | parents destroyed; no hybrid; toast «Burned!» |

Breed Luck 1: Success 88% / Fail 9% / Burn 3% (renormalize).

### 7.4 Inheritance table

| Field | Rule |
|---|---|
| `speciesId` | 50/50 от A/B **или** если rarities разные — species от **более редкого** parent (tie → 50/50) |
| `generation` | `max(A,B)+1` |
| `isHybrid` | **true** |
| `primaryColor` | lerp(A,B, 0.5) ± jitter 0.05 |
| `secondaryColor` | берётся от другого parent (если A primary→B secondary) |
| `faceId` | 50/50 |
| `accHead` | 40% A · 40% B · 20% nil/roll random from unlocked pool |
| `accBack` | same |
| `scale` | average * (1 + 0.05*generation) clamp 0.85–1.45 |
| `oneIn` | **§7.5** (primary chase) |
| `rarity` | `rarityFromOneIn(oneIn)` |
| `mps` | формула §4.5 |
| `templateId` | **nil** (hybrid) |

### 7.5 oneIn mutate (core chase fuse)

База (до мутации):

```
baseOneIn = parentA.oneIn * parentB.oneIn
```

Это даёт полковый flex: `1 in 12` × `1 in 18` → `1 in 216`, `50×75` → `3750`, и т.д.

Затем **mutate roll** (один раз):

| Event | Chance | Result `childOneIn` |
|---|---:|---|
| Normal | 55% | `baseOneIn` |
| Jackpot ×2 | 25% | `baseOneIn * 2` |
| Jackpot ×5 | 12% | `baseOneIn * 5` |
| Jackpot ×10 | 5% | `baseOneIn * 10` |
| Whiff ×0.5 | 3% | `max(2, floor(baseOneIn * 0.5))` |

Breed Luck 1: Normal 50% · ×2 28% · ×5 14% · ×10 6% · Whiff 2%.

`childOneIn = max(2, floor(childOneIn))`.  
`rarity = rarityFromOneIn(childOneIn)`.

**UI breed confirm:** показать оценку  
`Expected ~ 1 in {A.oneIn * B.oneIn}` + текст «Jackpot may multiply».

**Steal priority feel:** воры целятся глазами на больший `1 in X` (billboard); AI не нужен — social readable.

### 7.6 Hatch presentation

1. Egg mystery на incubator (mesh egg; shake intensity от `log(expected oneIn)`).  
2. Timer billboard.  
3. At 0: **big pop `1 in X`** (крупнее имени) · VFX по band · scream/pitch · auto storage / nest.  
4. Camera nudge optional client.  
5. Toast: `Hatched · 1 in {X} · {Name}`.

### 7.7 Cooldown

Только занятость incubator. Отдельного account cooldown **нет**.

---

## 8. Steal / Lock / Bat / Traps

### 8.1 Stealable whitelist

| Can steal? | |
|---|---|
| Creature on nest | ✅ |
| In storage / incubator | ❌ |
| Tutorial protect first **180s** after join (own nests) | ❌ чужие могут |
| During Lock | ❌ |
| Safe zone Hub r=8 | prompts off |

Starter creatures **можно** steal после protect window.

### 8.2 State machine

```
IDLE → (hold Prompt 1.2s in range ≤8 studs) → CARRYING
CARRYING → (deposit prompt on own empty nest 0.5s) → IDLE (success)
CARRYING → (bat hit / trap launch / victim reclaim) → DROP
CARRYING → (thief leaves server / fall) → RETURN_TO_VICTIM
```

| Param | Value |
|---|---|
| Interact hold | **1.2s** |
| Interact max dist | **8** studs |
| Deposit hold | **0.5s** |
| Carry WalkSpeed | **0.55 ×** default (16→8.8) |
| Sprint while carry | **запрещён** |
| Jump while carry | ✅ JumpPower ×0.75 |
| Hybrid / high oneIn carry | if `oneIn ≥ 200` OR hybrid: WalkSpeed extra ×0.85 + louder SFX; if `oneIn ≥ 1000`: ×0.75 и screen shout для жертвы |
| Max carry time | **90s** → auto RETURN_TO_VICTIM |
| Max thieves / plot | **2** |

### 8.3 Drop / fail resolves

| Event | Creature goes to |
|---|---|
| Bat hit thief | nearest free nest victim **else** victim storage |
| Trap snare expire without bat | stays carrying |
| Victim ProximityPrompt «Reclaim» 1.0s on thief | back victim nest/storage |
| Thief killed/reset | RETURN_TO_VICTIM |
| Successful deposit | thief nest; victim instance removed |
| Sell while stolen | **impossible** (server flag `isBeingStolen`) |
| Breed while on nest stolen | impossible |

### 8.4 Post-steal immunity

Nest socket (not creature): **20s** cannot be stolen from again after successful loss.

### 8.5 Lock

| Param | Value |
|---|---|
| Duration | **45s** |
| Cost | `$500 * (1 + timesLockedToday)` cap cost 5_000 |
| Who | owner only |
| Effect | blocks **player** steal prompts; bat всё ещё работает на воров уже в CARRY |
| End | auto; manual unlock free |
| VFX | blue dome / pad flash |

### 8.6 Bat

| Param | Value |
|---|---|
| Tool | Tool in Backpack slot |
| Range | **12** studs |
| Cooldown | **1.2s** |
| Effect on carrier | **100% drop** + knockback 20 studs |
| Effect on non-carrier | knockback only (no damage HP — нет HP) |
| Break walls | batHits as Block table (чужие only) |
| Mobile aim | auto-target nearest carrier in 12 studs else forward swing |

### 8.7 Traps MVP

| id | Effect | Duration | Owner trigger |
|---|---|---|---|
| spikes | WalkSpeed ×0.5 | while on cell | ❌ только enemies |

Place limit: within 40 placeables total. Cost via Block Roll.

### 8.8 PvP

Нет оружия/HP. Только bat knockback + traps + steal.  
Indication robbed: **toast + SFX + arrow to nest** on interact start.

---

## 9. Build

| Param | Value |
|---|---|
| Grid | 4 studs |
| Hotbar | 1 Build · 2 Take · 3 Edit(R) · 4 Bat |
| Rotate | R = 90° |
| Max placeables | 40 |
| Friends build | ❌ |
| Delete own | Take tool → inventory++ |
| Refund | 100% parts to inventory (не cash) |
| Paths | LD требует ≥2 подхода; полный seal невозможен (фасад gap enforced? **soft**: server не enforce; design guidance + playtest) |

---

## 10. Session model

**Always-day. Always-raid.** Нет фаз day/night.  
Online AFK: MPS **продолжает** (анти-AFK kick — Roblox default).

---

## 11. Tutorial (first 120s)

| t | Step | Gate |
|---|---|---|
| 0–15 | Arrow Collect / Nest: «Your creatures earn $» | — |
| 15–40 | Arrow Creature Roll → Buy | must Buy ≥1 |
| 40–70 | Arrow Incubator: select 2 → Start Breed | must StartBreed |
| 70–100 | Wait hatch **or** skip with soft speed once free | hatch once |
| 100–120 | Arrow to neighbor plot / dummy: «Steal» | see §11.1 |

| Flag | `profile.tutorialCompleted: boolean` |
|---|---|
| Skip button | ✅ after 30s; sets completed |
| Grants | already in starter; +`$200` on tutorial complete |

### 11.1 Steal tutorial fallback

| Players on server | Behavior |
|---|---|
| ≥2 | arrow to nearest other plot nest |
| 1 | spawn **NPC Dummy Nest** на empty plot slot with Common; steal works; despawn after success |

---

## 12. Progression / offline / rebirth

| Feature | PROVE | MVP launch | v1 |
|---|---|---|---|
| Offline 50% / 4h | ❌ | ✅ | ✅ |
| Rebirth | ❌ | ❌ | ✅ reset nests/build keep best hybrid + permanent +5% mps / rebirth |
| Player level/XP | ❌ | ❌ | optional |
| Full unlock estimate | — | ~6–10h meaningful nests+luck | — |

Unlock order soft: Nest5→6→Luck1→Nest7→BreedLuck→Nest8→Luck2.

---

## 13. Monetization (exact MVP list)

**Закон:** нет unstealable pets, нет permanent lock pass, нет delete- чужой-hybrid.

| Product | Type | Robux | Effect |
|---|---|---:|---|
| Starter Pack | DevProduct | 149 | +$5_000 + 1 Uncommon parent + nest skin Common |
| Skip Incubate | DevProduct | 49 | finish current incubate |
| Double Incubator | GamePass | 399 | 2 parallel breed jobs |
| +1 Nest (N9 cosmetic pad?) | **cut** — nests max 8 soft-only |
| VIP Aura | GamePass | 299 | trail + name color (flex) |
| Bat Skin Pack | DevProduct | 99 | cosmetic |
| Nest Skin Pack | DevProduct | 99 | cosmetic |
| Cash Pack S | DevProduct | 79 | +$10_000 |
| Cash Pack M | DevProduct | 199 | +$40_000 |
| Cash Pack L | DevProduct | 499 | +$150_000 |
| Season Pass | | — | **не MVP** |
| Gift | | — | **не MVP** |

Convenience OK: skip incubate, 2nd incubator, cash packs.  
Power edge small; steal skill remains.

Rebirth (v1): GamePasses **сохраняются**.

---

## 14. HUD / UI (полный список MVP)

| Element | Position | Notes |
|---|---|---|
| Cash | TL | |
| MPS + Buffer | TL under cash | |
| Collect shortcut | TL button | also world |
| Buttons: Inventory, Breed, Shop | BL | |
| Mobile: Jump | BR | default |
| Mobile: Bat | BR | |
| Mobile: Lock | BR | |
| Carry bar | Center bottom | only CARRYING |
| Lock timer | TR | when active |
| Toast notifications | TR | |
| Tutorial arrows | world | |
| Settings | TR ⚙ | music/SFX/reduce VFX |

**Inventory:** grid 5×8 · filters All/Hybrid/Rarity · actions Place / Sell / Select for Breed.  
**Breed UI:** modal — pick A, pick B, confirm odds text (Success 85%…).  
**Shop tabs:** `Nests` · `Luck` · `Cash` · `Cosmetics` · `Passes`.  
**Prompts:** ProximityPrompt + billboard support.  
**Death UI:** нет (нет HP).  
**Gyroscope:** нет.

### Mobile

| Control | |
|---|---|
| Move | thumb stick |
| Steal | hold Proximity button on screen |
| Bat | button → auto-target carrier else swing |
| Camera distance | +4 vs desktop default |

---

## 15. Audio / VFX checklist

| Action | SFX | VFX | Required |
|---|---|---|---|
| Roll spin | ✅ | preview spin | ✅ |
| Buy creature | ✅ | burst | ✅ |
| Place nest | ✅ | puff | ✅ |
| MPS tick | soft loop optional | — | ❌ |
| Breed start | ✅ | beam parents→egg | ✅ |
| Hatch | ✅ rarity pitch | explosion tier | ✅ |
| Steal start | ✅ | red ring | ✅ |
| Carry loop | ✅ louder if hybrid | trail | ✅ |
| Steal success | ✅ | | ✅ |
| Steal fail/drop | ✅ | | ✅ |
| Lock on/off | ✅ | dome | ✅ |
| Bat hit | ✅ | swing | ✅ |
| Trap | ✅ | | ✅ |
| Purchase Robux | ✅ | | ✅ |

Extra juice с **Rare+**.  
`Reduce VFX` default **on** if low-end (TouchEnabled & low gfx).

---

## 16. Networking / authority

Server-authoritative: cash, buffer, inventory, nests, breed timers, steal SM, bat validation, traps, shop, MPS, rolls.

Client-predicted: animations, local VFX, camera. Carry movement = server WalkSpeed set.

### Remotes MVP

```
RequestCreatureRoll / ConfirmCreatureBuy
RequestBlockRoll / ConfirmBlockBuy
RequestPlaceCreature / RequestMoveCreature / RequestUnequip
RequestCollect
RequestStartBreed / RequestCancelBreed / RequestSoftSpeedBreed
RequestStartSteal / RequestDepositSteal / RequestReclaim
RequestLock
RequestBatSwing
RequestPlaceBlock / RequestTakeBlock
RequestBuyNest / RequestBuyLuck
```

Rate limits (UX): roll confirm ≥300ms · bat = CD · steal prompt server-validated.

Stranger sees: creature mesh/look, **`1 in X`**, rarity chip, mps, hybrid badge. Cash hidden.

---

## 17. Profile schema

```lua
profile = {
  schemaVersion = 1,
  cash = 0,
  buffer = 0,
  creatures = { [id]: CreatureInstance },
  nestsUnlocked = 4,
  blockInventory = { [blockId]: number },
  placeables = { ... }, -- plot build save
  luckCreature = 0,
  luckBreed = 0,
  incubatorSlots = 1,
  incubateJob = nil | { parentA, parentB, endsAt, ... },
  tutorialCompleted = false,
  settings = { music=true, sfx=true, reduceVfx=false },
  stats = { steals=0, bred=0, lost=0 },
  purchases = { gamepasses={}, productsProcessed={} },
  offlineLeaveAt = nil,
  cosmetics = { nestSkin="default", batSkin="default", trail=false },
}
```

| Save | |
|---|---|
| Timestamps | UTC seconds |
| Session carry | **не** сохранять |
| Stun | не сохранять |
| Max creatures | 40 hard |

---

## 18. Anti-cheat resolves

| Vector | Resolve |
|---|---|
| Leave mid-carry | RETURN_TO_VICTIM |
| Two thieves one nest | first hold wins; second prompt blocked while contested |
| Sell while stolen | rejected |
| Breed while locked/stolen | rejected |
| Noclip steal | server dist ≤8 + line-of-sight optional ray |
| Speed carry | server caps WalkSpeed |
| Alt funnel | diminishing: after 3 steals from same victim / 10min → immunity 60s on that victim |
| Dupe instance | id deleted on transfer; never copy |
| ProcessReceipt | once; grant idempotent |

Trading: **OFF** MVP.

---

## 19. Leaderboards

| Board | Scope | Metric |
|---|---|---|
| Top MPS | server | sum nest mps |
| Top oneIn | server | highest creature `oneIn` on nests |
| Top Hybrid | server | highest hybrid `oneIn` then mps |
| Top Steals | server | session steals |

Global ODS: v1. Daily reset: v1.  
Plot billboard: player name + best creature icon. Visible 80+ studs.  
Hide wealth: нет MVP.

---

## 20. PROVE / MVP / v1 cuts

### PROVE (3–5d) must-work

1. 2 plots claim  
2. Nests + MPS + Collect  
3. Creature Roll Buy с preview **`1 in X`**  
4. Breed → hatch pop **`1 in X`** + look pipeline  
5. Steal carry + Lock + Bat (slow если oneIn≥200)  
6. Nest billboard: Name · `1 in X` · $/s  
7. (Optional thin) Block Roll + `1 in X` на блоках  

**Cut PROVE:** luck live, offline, Robux, full 6 plots, traps variety, LB global, rebirth, cosmetics shop polish.

### MVP launch in

All 8 systems · traps spikes · nest buys · soft luck · offline · monetization products · tutorial · server LB.

### v1 backlog

1. Rebirth  
2. Global LB + daily  
3. 2nd species wave accessories  
4. Season / BP  
5. Dual incubator default balance pass  

### Art lock

5 bodies + 8 acc + 1 egg + 5 auras + 6 faces.

---

## 21. PROVE gates (feeling)

| Metric | Kill | Go |
|---|---|---|
| Session median | &lt;1.5m | &gt;3m |
| «Want to breed again?» | &lt;50% | &gt;70% |
| Understood fuse w/o wall text | &lt;60% | &gt;80% |
| «Just BaBaS?» | majority yes | majority no — fuse remembered |

---

## 22. Tech sketch

```
src/shared/data/{CreatureDatabase,BlockDatabase,BreedConfig,EconomyConfig,PlotConfig}
src/server/{BaseService,EconomyService,CreatureService,RollService,BreedService,StealService,BuildService,MetaService}
src/client/{BreedController,StealController,BuildController,RollPresentation,HUD}
```

`--!strict` · DI · modules ≤300 lines · destroy() · React-Lua HUD.

---

## 23. Open (non-blocking naming only)

1. Final marketplace title  
2. Exact Robux prices may tune ±20% at launch  
3. Whether Mythic×Mythic gets cosmetic «Legendary sheen» only  

---

## 24. One-line canon

> BaBaS bones (dual roll, yard build, nests MPS, steal/lock/bat) + **breed/fuse as the chase and clip**, **`1 in X` primary flex** (rarity = band), hybrids via gene-look pipeline (5 meshes), always-day raids.

#gamedesign #roblox #gdd #breed-raid #babas
