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

## Stand tier → box shape (wired via Luck)
- **Зачем:** Luck Boost 0/3/6 → `Boxes/1|2|3` + rarity bias (`BoxVisualLogic.standLevelFromLuck`)
- **Приоритет:** done (MVP)
- **Контракт:** rarity не красит меш; hero из `Герои/<Rarity>`; mutation FX на героя 1.1×; max 1 mutation from buy only

## Sell from Ramp
- **Зачем:** продать героя/контейнер с Ramp за монеты (pickup → inventory уже есть)
- **Приоритет:** 1.1
- **Зависимости:** RampManager pickup/place

## Hero attack animations
- **Зачем:** juice при спавне мини
- **Приоритет:** 1.1
- **Зависимости:** Units meshes

## Rebirth window (HUD кнопка)
- **Зачем:** отдельное окно Rebirth; слот HUD временно открывает **Upgrades**
- **Приоритет:** после MVP / 1.1
- **Зависимости:** дизайн окна в StarterGui, RebirthLogic уже есть

## VFX Authoring Plugin (полный editor)
- **Зачем:** таймлайн / attachments / keyframes удобнее ручных пресетов
- **Приоритет:** после v0.1 exporter+timeline (см. `docs/VFX_AUTHORING_PLUGIN_v0.1.md`)
- **Зависимости:** стабильный LayerDef export, TextureCatalog
