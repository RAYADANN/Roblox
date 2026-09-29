# Client vs Server — видимость и авторитет

Cursor и разработчик принимают решение **до кода**: кто владеет состоянием и кто что рисует.

Правило для агента: `.cursor/rules/client-server-split.mdc`.

---

## Два слоя ответственности

```
┌─────────────────────────────────────────────────────────────┐
│  ПРОГРЕСС (читы, сохранение)                                │
│  Сервер авторитетен: coins, inventory, depth, upgrades       │
│  Клиент: намерение (Zap) → результат (HudPayload / Notify)  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  МИР (что видно в Workspace)                                 │
│  Если другие игроки должны видеть → состояние на сервере     │
│  Клиент: рендер + анимация для ВСЕХ персонажей               │
└─────────────────────────────────────────────────────────────┘
```

Не смешивай: HUD-питомец (иконка в панели) ≠ 3D-питомец за спиной.

---

## Матрица (быстрый выбор)

| Вопрос | Ответ «только я» | Ответ «все видят» |
|--------|------------------|-------------------|
| Где истина? | React state / локальный контроллер | Профиль + `*Manager` на сервере |
| Как sync? | Zap → свой HUD | Attribute / Workspace / Zap broadcast |
| Где рендер? | `client/ui` или local `client/core` | `client/core/Remote*Visual` на **каждого** Player |
| Playtest | 1 игрок OK | **2+ игрока** обязательно |

---

## Эталон: косметика, видимая другим (питомец, aura, trail)

### 1. Shared — контракт репликации

`shared/util/PlayerAttributeSync.luau` — encode/decode строки для `Player:SetAttribute`.
Переименуй `ATTRIBUTE` под фичу (`DD_EquippedPets`, `RS_ToolSkin`, …).

### 2. Server — публикация после изменения профиля

```luau
-- server/core/PetManager.luau (пример)
function PetManager:equip(player, petUid)
    -- validate, mutate profile
    WorldCosmeticPublisher.publishEquipped(player, equippedSlots)
end
```

```luau
-- server/core/WorldCosmeticPublisher.luau (паттерн)
local Sync = require(shared.util.PlayerAttributeSync)

function WorldCosmeticPublisher.publishEquipped(player: Player, slots: { Sync.Slot })
    player:SetAttribute(Sync.ATTRIBUTE, Sync.encode(slots))
end
```

Вызывай `publish` после **каждой** мутации экипировки и при `PlayerAdded` (rejoin).

### 3. Client — рендер для всех игроков

```luau
-- client/core/RemoteCosmeticVisual.luau (паттерн)
-- Для каждого Player:
--   player:GetAttributeChangedSignal(Sync.ATTRIBUTE)
--   slots = Sync.decode(attribute)
--   CosmeticFollowerController:setSlots(slots)  -- 3D за Character
```

- **LocalPlayer** и **remote** используют один и тот же follower/renderer.
- Сервер **не** шлёт позицию питомца каждый кадр — клиент интерполирует за `HumanoidRootPart`.

### 4. Чего не делать

```luau
-- ❌ Только LocalPlayer — другие не увидят
if player == Players.LocalPlayer then
    spawnPetModel()
end

-- ❌ Истина только в React
setHud({ equippedPets = ... })  -- без server publish

-- ✅ Сервер опубликовал → все клиенты подписались
```

Эталон в этом репо: `PlayerAttributeSync` → `WorldCosmeticPublisher` → `RemoteCosmeticVisual` (+ follower в `client/core`).

---

## Локальный визуал (только у себя)

| Тип | Триггер | Модуль |
|-----|---------|--------|
| Screen flash, coin rain | `Notify` | `client/ui/fx/*FX.luau` |
| UI toast | ошибка Zap / Notify | `client/ui` + Notification |
| Звук клика | сразу на клиенте | `SoundManager` |

Сервер шлёт **событие** («покупка прошла»), не инструкцию «создай Part в (x,y,z)».

---

## Геймплей в мире (блоки, двери, NPC)

1. Клиент: намерение `Interact(id)` / `BuyUpgrade(id)` / своё действие
2. Сервер: validate (reach, cooldown, CPS) → mutate мир/профиль
3. Sync: Zap или реплицируемое состояние мира
4. Клиент: `*Renderer` обновляет визуал

Клиент может **предсказать** сломанный блок, но сервер — финальный судья.

---

## Когда Cursor должен спросить

См. `client-server-split.mdc`. Кратко:

- **Спроси**, если в задаче не сказано: «видят ли другие», «3D или только UI», «в MVP или BACKLOG».
- **Не спрашивай**, если ответ уже в rules/docs/эталоне (сервер для монет, Zap для сети, …).
- После ответа пользователя — при необходимости одна строка в `BACKLOG.md` или design note в `README.md`.

---

## Playtest (обязательно для «видно другим»)

См. `PLAYTEST_CHECKLIST.md` → секция **Мультиплеер**.

Минимум: Studio → Test → **2 Players** → второй аккаунт видит косметику/состояние первого.
