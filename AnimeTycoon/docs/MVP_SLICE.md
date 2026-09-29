# MVP Slice — AnimeTycoon

Жанр: **toy conveyor tycoon** — покупка контейнеров → распаковка на Ramp → герой → мини-копии по конвейеру → монеты.

## Петля (soft launch)

```
Stands: RollButton → рулетка 5 офферов (Box1–3)
  → Buy → контейнер в inventory / hand
  → поставить на Ramp.HeroPlace (10 слотов)
  → unpack (длительность = f(rarity))
  → герой появляется
  → мини-копии едут по конвейеру → coins
  → купить ещё контейнеры
```

## В scope MVP

| Система | Минимум |
|---------|---------|
| Stands | Stand1–5 + RollButton; 5 персональных офферов |
| Roulette | Клиентская анимация как Showroom; итог с сервера |
| Containers | Box1–3; rarity + mutations; BillboardGui (шаблон Box1) |
| Place | 10 слотов `Ramp.HeroPlace.Button.PlacePart` |
| Unpack | progress 0→1; затем **HeroReveal** (локальный cinematic) + hero на слоте |
| Heroes | Clone `Workspace.Secret` (MVP template) |
| Conveyor | Мини едут по path; payout на сервере после travel |
| HUD | coins + hand/inventory status |
| Save / Zap / CI | ProfileStore, Zap, зелёный CI |

## Вне scope → BACKLOG

- Несколько площадок / claim plot
- Полный каталог героев / анимации атаки
- Robux shop, daily, rebirth loop
- Удаление / продажа с Ramp
- Продвинутый pathfinding по High/LowParts

## Контракт (сервер)

1. Coins / offers / slots — только сервер.
2. Roll = `refreshOffers` (все 5); клиент крутит рулетку косметически.
3. Unpack duration из `RarityDatabase`; UI не хардкодит секунды.
4. После unpack: `produceInterval` → pending delivery → `travelSec` → +coins.
5. После unpack progress=1 → **Ready** + Open prompt; герой только после Open.
6. Мир (боксы/герои/мини) видят все: server publish → all clients render.
7. Billboard: clone шаблона `Workspace.Box1.BillboardGui` → Name / Rare / Mutation / Price.

Формулы — `ContainerLogic` / `MutationLogic` / `ConveyorLogic` + Lune-тесты.
