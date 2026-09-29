# BACKLOG — идеи вне текущего MVP

Формат:

```markdown
## [Название]
- **Зачем:** одна строка
- **Приоритет:** после MVP / 1.1 / 1.2
- **Зависимости:** что нужно до этого
```

---

## Index / яйца / эволюции питомцев
- **Зачем:** коллекция вместо кубов; Index = base pet → owned evolutions
- **Приоритет:** 1.1 (UI shell уже есть; экономика яиц — отдельно)
- **Зависимости:** заменить ExhibitCatalog кубы → pets; Dispenser = eggs; profile `ownedEvolutions`
- **Решение UI:** яйца слева (2×2), сетка base pets, клик → эволюции; DesignRoot 1920×1080 как Tycoon

## Shop (Robux) — реальные ProductIds + PromptProductPurchase
- **Зачем:** UI shell уже есть (Aim Map layout: banners + packs); покупки пока mock
- **Приоритет:** 1.1
- **Зависимости:** `ProductIds`, ProcessReceipt, grant coins/boosts на сервере

---

## Богатый каталог форм / анимаций
- **Зачем:** редкая форма ощущается уникальной
- **Приоритет:** 1.1
- **Зависимости:** стабильный ExhibitLogic + world renderer

## Характеры экспонатов (поведение / idle anim)
- **Зачем:** personality depth
- **Приоритет:** 1.1
- **Зависимости:** каталог мешей

## Social «показать другу» / сравнение площадок
- **Зачем:** retention через социальное доказательство
- **Приоритет:** 1.2
- **Зависимости:** soft launch, analytics

## Leaderboards
- **Зачем:** соревнование по доходу / редкости
- **Приоритет:** 1.2
- **Зависимости:** стабильная экономика

## Robux shop / daily
- **Зачем:** monetization
- **Приоритет:** после playtest экономики
- **Зависимости:** ProductIds, ProcessReceipt

## Продвинутый NPC pathfinding / crowds
- **Зачем:** толпа выглядит живо
- **Приоритет:** 1.1
- **Зависимости:** простой NPC spawn MVP

## Full Rebirth loop (spend coins + profile mutate)
- **Зачем:** UI shell уже есть (`RebirthPanel`); нужен серверный акт rebirth
- **Приоритет:** 1.1
- **Зависимости:** стабильная экономика + AuctionLogic
- **Готово:** модалка (perks + progress + Skip/Rebirth), mock callbacks в HUD

## Строительство базы / редактор стен
- **Зачем:** — **out of genre** (Showroom = только выбор экспонатов)
- **Приоритет:** never (пока жанр не сменят)

## VFX Authoring Plugin (полный editor)
- **Зачем:** таймлайн / attachments удобнее ручных пресетов
- **Приоритет:** после v0.1
- **Зависимости:** LayerDef export
