# MVP Slice — AnimeTycoon

Жанр: **toy conveyor tycoon** — покупка контейнеров → распаковка на Ramp → герой → мини-копии по конвейеру → монеты.

## Петля (soft launch)

```
Base.Stands: RollButton → рулетка на открытых падах (старт 1; до 5)
  → Buy → контейнер в inventory / hand
    → поставить на Base.Ramp.HeroPlace (10 слотов)
    → unpack (первый купленный контейнер = 3s; остальные = f(rarity))
    → герой появляется
    → мини-копии едут по конвейеру → монеты в SellBox
    → Take SellBox (если не пустой) → inventory
    → Sell у SellGuy → coins в карман
    → купить ещё контейнеры / Pad Unlock для новых стендов
```

## В scope MVP

| Система | Минимум |
|---------|---------|
| Plot | `Workspace.Base1`…`Base6`; claim на join (`BaseClaimManager`) |
| Stands | `Base.Stands` Stand1–5 + RollButton; старт 1 пад; Pad Unlock → ещё 4 по порядку (макс 5) |
| Roulette | Клиентская анимация как Showroom; итог с сервера |
| Containers | Форма = **Luck tier** (`Boxes/1|2|3` + palette); имена Brainrot; rarity **не** красит меш |
| Mutations | Макс **1**; только с покупки оффера; Open не роллит |
| Place | до 30 слотов; **Pick up** unpacked героя → inventory → Place в другой слот |
| Upgrades | Base / Pad / Luck / Cash / Time / Speed привязаны к геймплею |
| Unpack | progress 0→1; затем **HeroReveal** (локальный cinematic) + hero на слоте |
| Heroes | Пул `ReplicatedStorage.GameAssets.Heroes/<Rarity>`; Mythic-герой только из Mythic и т.д. |
| Hero level | 1–50 на открытом герое (`HeroLevelLogic`). Доход ×1.15 за уровень. Цена = прирост монет/с × окупаемость, которая тоже ×1.15. F на слоте |
| Mutation look | Billboard shine + FX-парт с `GameAssets.MutationFx` → на **коробку и героя** (scale ≈ 1.1–1.35× bbox) |
| Conveyor | Мини едут по path; payout → **SellBox**, не карман |
| SellBox | накопление + Side grow; Take → sellCrates; новый пустой на паде |
| SellGuy | Sell всех crates → coins |
| HUD | coins + hand/inventory status |
| Save / Zap / CI | ProfileStore, Zap, зелёный CI |

## Вне scope → BACKLOG

- Полный каталог героев / анимации атаки
- Robux shop, daily, rebirth loop
- Удаление / продажа с Ramp (не pickup — pickup уже в MVP)
- Продвинутый pathfinding по High/LowParts

## Контракт (сервер)

1. Coins / offers / slots — только сервер.
2. Roll = `refreshOffers` (все 5); клиент крутит рулетку косметически.
3. Unpack duration из `RarityDatabase`; UI не хардкодит секунды.
4. После unpack: `produceInterval` → pending delivery → `travelSec` → **+SellBox**, не +coins.
5. После unpack progress=1 → **Ready** + Open prompt; герой только после Open. Пока packing — billboard с оставшимся временем; **Open now** (R$) пропускает wait.
6. Unpacked герой: **Pick up** → inventory/hand; **Place** на другой слот ставит героя сразу (без повторного unpack).
7. Мир (боксы/герои/мини) видят все: server publish → all clients render.
8. Billboard: clone шаблона `Workspace.Box1.BillboardGui` → Name / Rare / Mutation / Price.
9. SellBox Take только если coins>0; SellGuy продаёт `sellCrates` → coins.

Формулы — `ContainerLogic` / `MutationLogic` / `ConveyorLogic` + Lune-тесты.

## Контракт контента (коробки / редкость / мутации / герои)

```
Roll (сервер):
  rarity        ← luck-weighted
  mutations[]   ← 0 или 1 id (только с оффера при Buy; НЕ на Open)
  heroId        ← из Герои[rarity] only
  boxModelName  ← luck tier → Boxes/1|2|3 + random palette
                 (НЕ из rarity)
  case name     ← palette DisplayName only (Menta Gelato, Nero Cappuccino, …)
```

| Stand level | Box folder |
|-------------|------------|
| 1 (обычный) | `GameAssets.Boxes.1` |
| 2 | `GameAssets.Boxes.2` |
| 3 / 4 | `GameAssets.Boxes.3` |

Мутация → look: shine + VFX (одна мутация max). Не менять меш коробки под rarity.
Luck Boost: +редкость и тир меша кейса (0–2 → Tralala, 3–5 → Bombardini, 6+ → Saturnita).
