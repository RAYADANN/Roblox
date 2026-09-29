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

## Multi-plot claim
- **Зачем:** несколько игроков со своими Ramp
- **Приоритет:** после MVP
- **Зависимости:** soft launch одной площадки

## Sell / remove from Ramp
- **Зачем:** освободить слот, продать контейнер
- **Приоритет:** 1.1
- **Зависимости:** RampManager place

## Hero attack animations
- **Зачем:** juice при спавне мини
- **Приоритет:** 1.1
- **Зависимости:** Units meshes

## Rebirth window (HUD кнопка)
- **Зачем:** кнопка REBIRTH на HUD уже есть, окна в StarterGui/React ещё нет
- **Приоритет:** после MVP / 1.1
- **Зависимости:** дизайн окна в StarterGui, RebirthLogic уже есть

## VFX Authoring Plugin (полный editor)
- **Зачем:** таймлайн / attachments / keyframes удобнее ручных пресетов
- **Приоритет:** после v0.1 exporter+timeline (см. `docs/VFX_AUTHORING_PLUGIN_v0.1.md`)
- **Зависимости:** стабильный LayerDef export, TextureCatalog
