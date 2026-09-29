# Game Architecture — как строится игра

> Конституция проекта. Cursor читает `.cursor/rules/architecture.mdc` (alwaysApply)
> и этот документ при проектировании фич.

---

## Карта слоёв

```
┌─────────────────────────────────────────────────────────────┐
│                        PLAYER                                │
└───────────────────────────┬─────────────────────────────────┘
                            │ input / render
┌───────────────────────────▼─────────────────────────────────┐
│  CLIENT (src/client/)                                        │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │ ui/ (React) │  │ core/        │  │ init.client.luau   │  │
│  │ компоненты  │  │ контроллеры,  │  │ оркестратор        │  │
│  │ без логики  │  │ рендер, FX   │  │ (тонкий)           │  │
│  └──────┬──────┘  └──────┬───────┘  └────────────────────┘  │
└─────────┼────────────────┼──────────────────────────────────┘
          │                │
          │    Zap (типизированная сеть)
          │                │
┌─────────▼────────────────▼──────────────────────────────────┐
│  SERVER (src/server/)                                        │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │ core/       │  │ economy/     │  │ init.server.luau   │  │
│  │ *Manager    │  │ feature      │  │ оркестратор        │  │
│  │ валидация   │  │ подмодули    │  │ (тонкий, ≤100 ln)  │  │
│  └──────┬──────┘  └──────────────┘  └────────────────────┘  │
└─────────┼───────────────────────────────────────────────────┘
          │
┌─────────▼───────────────────────────────────────────────────┐
│  SHARED (src/shared/) — единственный источник правды          │
│  types/   — PlayerData, HudPayload, Zap payload types       │
│  data/    — *Database, Constants (числа баланса)             │
│  util/    — *Logic (pure Luau, тестируется в CI)            │
└─────────────────────────────────────────────────────────────┘
          │
┌─────────▼───────────────────────────────────────────────────┐
│  ProfileStore (сервер) — персистентный прогресс игрока       │
└─────────────────────────────────────────────────────────────┘
```

**Золотое правило:** данные и формулы живут в `shared/`. Сервер валидирует и пишет. Клиент отображает.

---

## Структура папок

```
src/
├── shared/
│   ├── types/
│   │   ├── PlayerData.luau      # схема профиля
│   │   ├── HudPayload.luau      # проекция для клиента
│   │   └── ...
│   ├── data/
│   │   ├── Constants.luau       # глобальные числа
│   │   ├── *Database.luau       # конфиги (данные, не код)
│   │   └── ...
│   └── util/
│       ├── RebirthLogic.luau    # pure, тестируется (пример)
│       ├── UpgradeLogic.luau
│       └── ...
│
├── server/
│   ├── core/
│   │   ├── ProfileManager.luau    # ProfileStore обёртка
│   │   ├── EconomyManager.luau    # эталон фичи
│   │   ├── *Manager.luau          # фича-менеджеры
│   │   └── ...
│   ├── economy/                 # опционально: крупная фича дробится
│   │   └── BuyUpgrade.luau
│   └── init.server.luau           # DI + boot, без бизнес-логики
│
└── client/
    ├── core/
    │   ├── *Renderer.luau       # мир, не React
    │   ├── SoundManager.luau
    │   └── ...
    ├── ui/
    │   ├── App.luau             # корень React-дерева
    │   ├── theme.luau
    │   ├── hooks/
    │   ├── components/          # атомы (Button, Chip, Card)
    │   ├── panels/              # экраны (ShopPanel, Hud)
    │   └── fx/                  # imperative FX (вне React)
    └── init.client.luau         # mount React + контроллеры
```

### Куда класть новый код

| Что добавляешь | Куда |
|----------------|------|
| Формула цены / шанс дропа | `shared/util/*Logic.luau` + тест |
| Таблица контента (предметы, уровни) | `shared/data/*Database.luau` |
| Тип данных игрока | `shared/types/PlayerData.luau` |
| Серверная валидация + запись в профиль | `server/core/*Manager.luau` |
| Рендер мира | `client/core/*Renderer.luau` / `Remote*Visual` |
| Кнопка / панель / модалка | `client/ui/components/` или `panels/` |
| Сетевое событие | `net.zap` → codegen → менеджер |

---

## Паттерн фичи (Feature Module)

Каждая игровая система = **менеджер на сервере** + **логика в shared** + **UI на клиенте**.

### 1. Shared Logic (pure)

```luau
-- shared/util/UpgradeLogic.luau
--!strict
-- НЕ трогает game/workspace/Players

export type UpgradeId = "pickaxe" | "backpack"

function UpgradeLogic.cost(level: number, baseCost: number): number
    return math.floor(baseCost * 1.15 ^ level)
end

function UpgradeLogic.canAfford(coins: number, cost: number): boolean
    return coins >= cost
end

return UpgradeLogic
```

→ Тест в `tests/UpgradeLogic.test.luau`

### 2. Server Manager (Roblox-coupled, thin)

```luau
-- server/core/UpgradeManager.luau
--!strict

export type Deps = {
    getProfile: (player: Player) -> PlayerData?,
    saveProfile: (player: Player, data: PlayerData) -> (),
    notify: (player: Player, payload: NotifyPayload) -> (),
}

local UpgradeLogic = require(shared.util.UpgradeLogic)

local UpgradeManager = {}
UpgradeManager.__index = UpgradeManager

function UpgradeManager.new(deps: Deps)
    return setmetatable({ _deps = deps }, UpgradeManager)
end

function UpgradeManager:buyUpgrade(player: Player, upgradeId: string): BuyResult
    -- 1. валидация типа/права
    -- 2. читаем профиль
    -- 3. UpgradeLogic.canAfford / cost
    -- 4. применяем, saveProfile
    -- 5. notify клиенту
end

return UpgradeManager
```

### 3. Client UI (React, props only)

```luau
-- client/ui/components/UpgradeRow.luau
-- props: { upgradeId, level, cost, coins, onBuy }
-- onBuy → Zap invoke → сервер решает
-- optimistic: press feedback мгновенно, результат по ответу
```

### 4. Сеть (Zap)

```zap
-- net.zap
event BuyUpgrade = {
    from: Client,
    type: Reliable,
    call: SingleAsync,
    data: (upgradeId: string.utf8),
    ret: BuyUpgradeResult,
}
```

---

## Поток данных

### Загрузка игрока

```
PlayerAdded
  → ProfileManager:load(player)
  → ProfileStore session lock
  → TEMPLATE :Reconcile()
  → buildHudPayload(player, data)  -- shared/types
  → Zap: PlayerDataSync(payload)
  → Client: setState → React re-render
```

### Игровое действие (пример: покупка апгрейда)

```
Client: press Buy
  → Zap: BuyUpgrade(upgradeId)       -- намерение
  → Server EconomyManager:
      validate (afford, cooldown)
      UpgradeLogic.cost / canAfford
      mutate profile
      saveProfile
  → Zap: PlayerDataSync + Notify
  → Client: HUD update (+ optional FX)
```

**Клиент НЕ меняет валюту/инвентарь/прогресс напрямую.**

### Косметика в мире (видно другим)

```
PetManager.equip (server)
  → mutate profile
  → WorldCosmeticPublisher.publish(player, slots)
  → Player attribute replicates
  → RemoteCosmeticVisual (each client) → 3D follower
```

Подробно: `docs/CLIENT_SERVER.md`. Локальный HUD-питомец (иконка) ≠ 3D за спиной.

---

## Boot sequence

### init.server.luau (≤100 строк)

```luau
-- 1. require менеджеры
-- 2. ProfileManager.new() — первым
-- 3. Остальные Manager.new({ deps }) — граф зависимостей
-- 4. Zap:Connect handlers → делегируют в менеджеры
-- 5. PlayerAdded / PlayerRemoving → ProfileManager
-- 6. BindToClose → release sessions
```

Порядок создания (зависимости сверху вниз):
1. `ProfileManager`
2. `EconomyManager` (deps: profile)
3. Остальные `*Manager` (deps: profile, economy, notify, …)

### init.client.luau (≤80 строк)

```luau
-- 1. ViewportLayout.start()
-- 2. require контроллеры (SoundManager, VfxController, Remote*Visual)
-- 3. Zap:Connect → обновление стейта / FX
-- 4. ReactRoblox.createRoot → render(App)
-- 5. App получает state через context/props
```

---

## DI — как связывать модули

```luau
-- ✅ Конструктор с deps
local economy = EconomyManager.new({
    getProfile = function(p) return profileManager:get(p) end,
    saveProfile = function(p, d) profileManager:save(p, d) end,
})

-- ❌ Запрещено
local economy = require(...).getInstance()
_G.EconomyManager = economy
Knit.GetService("Economy")
```

Менеджер знает только свои `Deps` — не require'ит соседей напрямую.

---

## HUD Payload — проекция, не профиль

```luau
-- shared/types/HudPayload.luau
export type HudPayload = {
    coins: number,
    depth: number,
    upgrades: { [string]: number },
    -- только то, что нужно UI
    -- НЕ весь PlayerData
}
```

- Сервер строит payload из профиля при каждом sync.
- Клиент хранит payload в React state / context.
- `coinsDisplay` (spring) ≠ `coins` (authoritative) — см. `professional-ui.mdc`.

---

## Размер и границы модулей

| Тип | Макс строк | Ответственность |
|-----|-----------|-----------------|
| `*Logic.luau` | 200 | одна формула/домен |
| `*Manager.luau` | 300 | одна фича, CRUD профиля |
| `*Renderer.luau` | 400 | визуал мира (допустимо больше) |
| UI component | 200 | один виджет |
| UI panel | 300 | один экран |
| `init.*.luau` | 100 | только boot |

Перевалил → дроби **в этой же задаче**.

---

## Чеклист: добавление новой фичи

1. [ ] Есть ли она в scope / BACKLOG? (см. `workflow.mdc`)
2. [ ] `shared/types` — новые поля в `PlayerData` + `TEMPLATE`
3. [ ] `shared/data` — конфиги/константы
4. [ ] `shared/util/*Logic` — формулы + **тест**
5. [ ] `server/core/*Manager` — валидация + запись
6. [ ] `net.zap` — события + codegen
7. [ ] `client/ui` — компоненты (props, без логики)
8. [ ] `init.server` / `init.client` — wire up
9. [ ] CI зелёный, playtest в Studio

---

## Связанные правила

| Тема | Rule |
|------|------|
| Модули, DI, размер файлов | `architecture.mdc` |
| Scope, MVP, DoD | `workflow.mdc` |
| Zap, сервер авторитетен | `networking.mdc` |
| Client/Server, видимость | `client-server-split.mdc` |
| ProfileStore | `data-persistence.mdc` |
| Античит, монетизация | `security.mdc` |
| Тесты pure logic | `testing.mdc` |
| React UI | `ui-react.mdc` |
| Polish UI | `professional-ui.mdc` |
| Типизация | `luau.mdc` |
| CI | `git-ci.mdc` |

---

## Антипаттерны (reject)

| Было | Правильно |
|------|-----------|
| `init.server` god-файл | Тонкий boot + менеджеры |
| Renderer / UI 1000+ строк | Дробить на sub-модули |
| `any` на DI и payload | `export type Deps`, `HudPayload` |
| Логика в RemoteEvent handler | Manager → Logic |
| Клиент меняет leaderstats | Сервер → sync payload |
| 3D-косметика только на LocalPlayer | Server publish → all clients render |
| Дублирование формул client/server | Один `shared/util` |
| Фича «на будущее» в профиле | BACKLOG, не в TEMPLATE |
| 0 тестов | Тест на каждый `*Logic` |
