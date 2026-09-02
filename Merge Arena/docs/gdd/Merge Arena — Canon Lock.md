# Merge Arena — Canon Lock

> **Статус:** LOCKED · 2026-08-07  
> Это **единственный** продуктовый канон soft launch. Если конфликт с Dual / старым § игрового процесса — правда **здесь**.  
> Код и UI обязаны укладываться в рамки ниже. Импровизация «по ходу» = баг процесса.

Связь: [[Merge Arena — игровой процесс]] · [[Art Pillars]] · [[Merge Arena — визуальный стиль]] · [[Merge Arena — Universal Block Kit]] · [`../MVP_SLICE.md`](../MVP_SLICE.md)

---

## 0. One-liner (locked)

**4 игрока, твоя колода → shop из loadout → merge★ → auto fight → last standing → packs / rematch.**

Не: fair shared pool day-1 · не: cosmetics-only cash · не: TFT 25 мин · не: anime board.

---

## 1. Продуктовый режим soft launch = **A Collection**

| Решение | Значение |
|---|---|
| Soft launch mode | **Только Collection** |
| Shop pool | RNG из **личного loadout** игрока |
| Fair Fixed Set ranked | **1.1+** (`BACKLOG`) — не строить сейчас |
| Зачем A | Быстрый Roblox ARPU (packs) + балансируемо + контент = Block Kit, не VFX-фабрика |

**Принятый tradeoff:** коллекция влияет на опциональность в матче. Лечится core set + matchmaking по collection power + баланс «редкость ≠ сила».

---

## 2. Полный цикл игрока (рамки)

### 2.1 Meta loop (между матчами)

```
Login
  → Collection (roster owned)
  → Loadout builder (выбрать N юнитов в колоду)
  → Packs / Shop (gacha)          ← Robux / soft currency
  → Queue (Collection match)
  → Match (см. 2.2)
  → Results (XP, soft currency, pack pity crumbs)
  → Rematch | Open pack | Tweak loadout
```

### 2.2 Match loop (внутри матча)

```
Prepare (12–18с)
  Shop 3 slots (RNG из LOADOUT) → Buy / Reroll / Sell
  → Merge ★1+★1→★2 (и ★2+★2→★3)
  → Place / swap на доске (2 ряда)
Fight (15–25с)
  → Auto combat (сервер)
  → Losers −HP
Повтор раундов (~8–12)
  → Last standing / ranking inside match
```

### 2.3 Session feel (первые 45с must)

Buy twin → **MERGE★ wow** → auto fight читается.

---

## 3. Числа soft launch (не менять без playtest-записи)

| Param | Lock |
|---|---|
| Игроков | **4** (bots ok) |
| HP | **4** сердца |
| Длина матча | **6–10 мин** |
| Prepare / Fight | **14с / 18с** default |
| Shop slots | **3** |
| Reroll cost | **2 gold** flat (MVP) |
| Board | **2×4** слота (8 max on field) |
| Bench | **6** |
| Merge | **2 одинаковых** одного ★ → ★+1; cap **★3** |
| Traits | **4–6** на весь ростер; пороги 2/3 |
| Roster size soft | **20** юнитов total |
| **Core free** | **12** всегда owned |
| Gacha pool | **8** (остальные) |
| Loadout size | **12** (выбираешь 12 из owned) |
| Interest (TFT econ) | **OFF** в MVP |

Interest / сложная экономика = только если graybox скажет «мало решений» → запись в playtest notes, не «добавим на глаз».

---

## 4. Collection & Loadout (механика монетизации)

### 4.1 Ownership

- Профиль хранит `ownedUnits: { [unitId]: copies }` (copies для pity/dust later).  
- **Core 12** выдаются при первом входе.  
- Остальные 8 — только из packs / starter deck / season grant.

### 4.2 Loadout

- Перед queue: выбрать ровно **12** owned юнитов.  
- В матче shop роллит **только** из этих 12 (с весами по `cost` tier как обычно).  
- Нельзя менять loadout mid-match.  
- Пустой/невалидный loadout → queue blocked.

### 4.3 Баланс-закон редкости (критично)

| Закон | |
|---|---|
| **Редкость ≠ DPS** | Gacha-юнит не сильнее core той же cost-линии |
| Редкость даёт | другую синергию / tempo pattern / identity, не +stat wall |
| Cost 1–5 | сила растёт от **cost и ★**, не от paywall |
| Ban list | exclusive ★3-only-cash · paid shop odds · permanent +ATK от дубликатов |

Дубликаты pack → **dust / soft currency** (HS-style), не вечный power creep.

### 4.4 Matchmaking soft launch

| Bucket | |
|---|---|
| Primary | soft MMR / cups stub |
| Secondary | **collection power band** (сколько non-core owned) |
| Цель | кит не давит пустой акк в 90% матчей |

Точная формула power — в `shared/util/*Logic` + тест; не хардкод в UI.

---

## 5. Packs / Gacha (Roblox-mid, thin content)

### 5.1 Currencies

| Валюта | Откуда | Куда |
|---|---|---|
| **Gold** | только in-match | shop / reroll |
| **Stars** (soft) | wins, daily, dust | packs (slow), cosmetics tint later |
| **Robux** | IAP | packs, starter deck, VIP, XP boost |
| **Rank points** | матчи | ladder stub — **не покупаются** |

### 5.2 Pack SKUs soft launch (art-light)

| SKU | Содержание | Тип |
|---|---|---|
| **Starter Deck** | фиксированный набор 4 gacha-юнитов + title | DevProduct (один раз) |
| **Unit Pack** | 5 pulls; веса в таблицу `PackLogic` | DevProduct / Stars |
| **VIP** | badge, +Stars/матч, XP, rematch priority | Gamepass |
| **2× Stars 24h** | convenience | DevProduct |

Pity: после N pulls без Rare+ — guaranteed Rare (число в `PackLogic`, тестируется).

### 5.3 Что НЕ в soft launch

- Полный BP  
- Board skin factory  
- Уникальные cinematic Merge VFX packs (кроме **1 parametric tint** если успеем)  
- Fair Fixed ranked  
- Cups / tournaments  
- Paid +bench / pool radar в матче  

### 5.4 POI (когда показать оффер)

| Момент | Оффер |
|---|---|
| После туториала | Starter Deck |
| После первого ★3 | Unit Pack soft |
| 2-й матч session | Rematch + Pack |
| Collection screen empty slots | Pack CTA |

---

## 6. UI chrome (match) — layout lock

Из HUD concepts (Figma) + mobile:

| Зона | |
|---|---|
| Top | Gold · Round · HP · Timer PREPARE/FIGHT |
| Center | Board 2×4 |
| Right / strip | 4 opponents HP |
| Bottom dock | Shop 3 + Reroll + Lock(shop freeze) |
| Over shop | Bench row |

**Hit targets:** крупные (Punch Dock sizes).  
Вне матча: Collection · Loadout · Packs · Results · Rematch.

---

## 7. Visual canon (locked)

### 7.1 Style pick

| Поле | Значение |
|---|---|
| **Стиль** | **A — Bright Tactical Toys** |
| **Юниты** | Heroes-RNG block toy (Universal Block Kit) |
| **Merge keyword** | smash cubes → bigger cube + ★ flash |
| **Арена** | светлая, тёплый свет; не dark cinematic |
| **Thumb** | 2 block units → ★ → fight |
| **Не делать** | anime faces · PBR sculpt · Pet Sim cute · mid-gray tactics · SC red/blue 1:1 clone |

Сезоны later: brainrot/horror как *cosmetic lines*, не смена DNA.

### 7.2 Brand adjectives (ровно 3)

1. **Toy**  
2. **Punchy**  
3. **Readable**

### 7.3 Palette (hex) → `theme.luau`

| Token | Hex | Роль |
|---|---|---|
| `arenaSky` | `#A9D4F0` | фон мира / clear |
| `boardFelt` | `#DCECC8` | доска |
| `boardLine` | `#3E6B45` | обводка доски |
| `bg1` | `#EAF3FA` | UI furthest |
| `bg2` | `#F7FBFF` | panels |
| `bg3` | `#FFFFFF` | cards / dock |
| `bg4` | `#D5E4F2` | chips inset |
| `ink` | `#1A2233` | textMain |
| `inkSub` | `#5A6B84` | textSub |
| `inkMuted` | `#8B9BB3` | muted |
| `primary` | `#3D7CFF` | CTA / reroll |
| `primaryHi` | `#6B9BFF` | hover |
| `coral` | `#FF6B5A` | brand accent (sparingly) |
| `teal` | `#2BB8A6` | secondary accent / traits |
| `gold` | `#F0C01A` | soft currency / cost |
| `goldHi` | `#FFE066` | |
| `danger` | `#FF4D5E` | HP / error |
| `success` | `#2ECC71` | sell / ok |
| `outline` | `#1A2233` | thick toy stroke |

**Rarity (UI + unit rim):**

| Tier | Hex | Extra cue |
|---|---|---|
| Common | `#9AA3B5` | flat |
| Rare | `#3D7CFF` | light rim |
| Epic | `#B15CFF` | aura ring |
| Mythic | `#FF4FA3` | aura + louder merge |

**Currency dual:** Stars/gold = gold chip; Robux CTA = Roblox-standard + distinct button variant (не красить gold под Robux).

### 7.4 Type / chrome

| Role | Font (Roblox) | Notes |
|---|---|---|
| display / timer | GothamBlack | numeric punch |
| title | GothamBold | |
| body | GothamMedium | |
| caption | Gotham | |

| Token | Value |
|---|---|
| Radius card | 16 |
| Radius chip/pill | full / 999 |
| Radius board | 20 |
| Stroke toy | **3–4px** (не hairline) |
| Elevation | stroke + soft shadow max 1; без glow-спама |

### 7.5 HUD visual = Variant A + touch D

- Light panels, thick outline (Toys)  
- Dock hit-targets как Compact Punch  
- ★ читается на unit и в merge FX  

Figma ref: [HUD UI Concepts](https://www.figma.com/design/Qq5GjLztn0OJjkAQC7YaZ5) · frames A + D.

---

## 8. Контент soft launch (рамки производства)

| Слой | Lock |
|---|---|
| Юниты | 20 через **Block Kit** (1 base + accessories) |
| Traits | 4–6 |
| Maps | **1** bright arena |
| Merge VFX | **1** juice language; rarity = amplitude, не новый стиль |
| Music/SFX | stub ok; merge SFX must |

Новый юнит = row в database + kit accessories. Не уникальный mesh.

---

## 9. Analytics (обязательные события)

`session_start` · `tutorial_complete` · `loadout_saved` · `match_start` · `first_merge` · `match_end` · `rematch` · `pack_open` · `starter_purchase` · `vip_owned`

Kill/Go — см. `MVP_SLICE.md` (+ pack open rate как soft signal, не kill gate day-1).

---

## 10. Hard NO (process + product)

- Менять shop на shared fair pool без обновления этого файла  
- Бафф gacha-юнита «потому что плохо покупают»  
- Орnamент UI до readable shop/board  
- Dark cinematic theme  
- God-файлы / фичи вне MVP_SLICE  
- ProductIds = 0 в билде, где продаём  
- Додумывать economy mid-implementation без записи сюда  

---

## 11. Порядок внедрения (инженерия)

1. Profile: owned + loadout + currencies  
2. PackLogic + ProductIds (Starter, Pack, VIP)  
3. Match: shop from loadout  
4. Merge★ juice + board HUD (theme bright)  
5. Collection / Loadout / Packs UI  
6. Soft launch metrics  

Fair Fixed ranked → BACKLOG после Go-gates.

---

## Changelog

| Date | Change |
|---|---|
| 2026-08-07 | Initial lock: Collection A, numbers, Roblox-mid packs, Bright Tactical Toys palette |
