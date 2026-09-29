# MVP Slice — ферма

Вертикальный срез: **купить героя → куб на земле → подобрать → депозит → кэш → merge**.

## В scope

- 6 плотов (`Island`), один игрок на плот
- **40 слотов** героев: `DummyItems/Floor_01…08` × 5 маркеров (см. `docs/SLOT_LAYOUT.md`)
- Пады Buy 1/5/25/100, MERGE, Sell Items, Collect Cash, process/upgrade, auto collect, X2, Finish Now, group reward
- **Production upgrade:** повышает тир покупаемых dummy; лимит = rebirths; шкала призыва 100 / 150 / 200… на billboard Upgrade (ProgressLine)
- Герой в слоте из `Workspace.Characters` (уровень = модель), кубы вместо предметов
- HUD: cash, bag, queue, multiplier (холст 1920×1080); левые pill-кнопки — DevProduct coin packs
- **Rebirth:** modal (Aim Map shell) + server reset; cash gate + permanent cash mult from `RebirthDatabase` (Chicken Farm-style; Skip Robux = BACKLOG)
- ProfileStore + Zap HUD sync
- Offline eggs (cap 2h)
- **Index:** карточки героев с ViewportFrame; открытые без фильтра, закрытые — чёрный Highlight и `???` на очках дропа
- World pads Auto Collect / X2 Items — gamepass (Robux icon on Billboard)
- Finish Now pad — DevProduct `ProductIds.FinishNow` (20 R$, flush shop queue)

## Вне scope → BACKLOG

- Скины / замена мешей дропа
- Index rewards / Lucky Block opening
- Skip rebirth product (тост «coming soon», `ProductIds.SkipRebirth` = 0)
- Окна Shop / Backpack
