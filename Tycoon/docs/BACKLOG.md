# BACKLOG — идеи вне текущего scope

Записывай сюда всё, что **не** входит в текущую задачу / MVP.
Cursor не реализует без явного запроса.

Формат:

```markdown
## [Название]
- **Зачем:** одна строка
- **Приоритет:** после MVP / 1.1 / 1.2
- **Зависимости:** что нужно до этого
```

---

## Пример: Социальные награды
- **Зачем:** retention через Discord/Twitter
- **Приоритет:** после MVP
- **Зависимости:** soft launch, аналитика

## Пример: Промокоды
- **Зачем:** маркетинг
- **Приоритет:** 1.1
- **Зависимости:** ProfileManager, admin tooling

---

## Exclusive offers (spin HUD)
- **Зачем:** второе предложение + реальные DevProduct id (`ProductIds.ExclusivePink`)
- **Приоритет:** 1.1
- **Зависимости:** Creator Hub products, grant wiring in MonetizationManager


## Dummy skins / item meshes
- **Зачем:** заменить R15 stub и кубы на контент
- **Приоритет:** сразу после играбельной петли
- **Зависимости:** FarmManager spawn API (`WorldFarmFactory`)

## Stand MeshPart PreciseConvexDecomposition
- **Зачем:** сейчас дропы едут по box-коллизии жёлоба; PCD даст V-форму как визуал
- **Приоритет:** polish 1.1
- **Зависимости:** `Stand` MeshParts в IslandMain

## Rebirth Skip (Robux)
- **Зачем:** Skip rebirth requirement за Robux (`ProductIds.SkipRebirth`); UI уже тостит «coming soon» пока id = 0
- **Приоритет:** 1.1 / monetization
- **Зависимости:** реальный DevProduct id, MonetizationManager grant → `FarmManager` skip-apply (без cash gate)

## Index / Lucky Block open
- **Зачем:** длинная прогрессия как в Chicken Farm (Index UI + Lucky Block opening)
- **Приоритет:** 1.1
- **Зависимости:** стабильный buy/merge/sell; Rebirth window уже в игре
- **Сейчас:** Index показывает героев из `HeroDatabase` / `Workspace.Characters` (viewport + locked Highlight/`???`). Unlock пишется в `indexMaxTier` при buy/merge. Lucky Block open / награды Index — ещё нет.

## Shop / Backpack windows
- **Зачем:** UI Aim Map (SimPop) вместо только 3D-падов
- **Приоритет:** после петли
- **Зависимости:** DesignRoot уже в HUD; Rebirth modal — эталон shell

## VFX Authoring Plugin (полный editor)
- **Зачем:** таймлайн / attachments / keyframes удобнее ручных пресетов
- **Приоритет:** после v0.1 exporter+timeline (см. `docs/VFX_AUTHORING_PLUGIN_v0.1.md`)
- **Зависимости:** стабильный LayerDef export, TextureCatalog
