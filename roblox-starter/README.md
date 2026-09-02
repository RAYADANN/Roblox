# roblox-starter

**Стартовый набор систем и правил** для новых Roblox-игр — не готовая игра и не эталон жанра.

Копируй → переименуй → `wally install` → собирай **свою** петлю. Cursor следует `.cursor/rules/`.

Эталон кода — модули в `src/` этого репо (BuyUpgrade, ProfileStore, Zap, VFX core). Не тяни контент/геймдизайн чужих игр.

> Инструкции для AI: [`AGENTS.md`](AGENTS.md)

## Что внутри

### Правила Cursor (19 файлов)

| Rule | Назначение |
|------|------------|
| `template.mdc` | **Главный индекс** (alwaysApply) |
| `architecture.mdc` | Слои, DI, паттерн фичи |
| `client-server-split.mdc` | Что на клиенте/сервере, видимость другим |
| `workflow.mdc` | MVP, scope, DoD |
| `professional-ui.mdc` | Polish UI по элементам |
| `ui-ux-canon.mdc` | Теория проф. UI/UX → `docs/ui-ux-canon/` |
| `ui-react.mdc` | React-Lua + Flipper |
| `networking.mdc` | Zap, server authority |
| `data-persistence.mdc` | ProfileStore |
| `security.mdc` | Античит, монетизация |
| `testing.mdc` | Lune CI |
| `luau.mdc` | Strict types |
| `git-ci.mdc` | Коммиты, CI gate |
| `docs.mdc` | Синхронизация доков |
| `analytics.mdc` | AnalyticsService |
| `audio.mdc` | SoundManager |
| `performance.mdc` | Пулинг, бюджеты |
| `monetization.mdc` | ProcessReceipt |
| `accessibility.mdc` | Settings, reduce motion |
| `fx.mdc` | VFX Engine + FxKit |
| `localization.mdc` | L("key") |

### Документация

| Документ | Содержание |
|----------|------------|
| [`docs/TECH_STACK.md`](docs/TECH_STACK.md) | Стек и обоснование |
| [`docs/GAME_ARCHITECTURE.md`](docs/GAME_ARCHITECTURE.md) | Архитектура игры |
| [`docs/CLIENT_SERVER.md`](docs/CLIENT_SERVER.md) | Client vs Server, репликация косметики |
| [`docs/VFX_ENGINE.md`](docs/VFX_ENGINE.md) | World VFX — ядро + демо-пресеты (см. doc) |
| [`docs/UI_ADAPTIVITY.md`](docs/UI_ADAPTIVITY.md) | Адаптив без подгонки |
| [`docs/ui-ux-canon/README.md`](docs/ui-ux-canon/README.md) | **Проф. UI/UX канон** — цвет, тип, chrome, HUD, attention, DoD |
| [`docs/NEW_PROJECT.md`](docs/NEW_PROJECT.md) | Пошаговый чеклист копирования шаблона |
| [`docs/BACKLOG.md`](docs/BACKLOG.md) | Идеи вне scope |
| [`docs/PLAYTEST_CHECKLIST.md`](docs/PLAYTEST_CHECKLIST.md) | Перед релизом |
| [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) | Soft launch gate |
| [`docs/brand-and-social/README.md`](docs/brand-and-social/README.md) | Архив промо (заменить под свою игру) |

### Эталонная фича end-to-end: BuyUpgrade

```
UpgradeLogic (shared) → EconomyManager (server) → NetServer → NetClient → UpgradeRow (UI)
```

| Файл | Роль |
|------|------|
| `shared/util/UpgradeLogic.luau` | Формулы + тест |
| `server/core/EconomyManager.luau` | Валидация, профиль, sync |
| `shared/net/NetTypes.luau` | HUD-типы + конвертация Zap ↔ app |
| `net.zap` → `server/net/NetServer.luau`, `client/net/NetClient.luau` | Zap codegen |
| `client/ui/GameRoot.luau` | React state + сеть |
| `client/ui/components/UpgradeRow.luau` | UI atom |

### Эталон: косметика, видимая другим игрокам

```
*Manager (server) → WorldCosmeticPublisher → Player attribute → RemoteCosmeticVisual (all clients)
```

| Файл | Роль |
|------|------|
| `shared/util/PlayerAttributeSync.luau` | Encode/decode attribute |
| `server/core/WorldCosmeticPublisher.luau` | Публикация после mutate |
| `client/core/RemoteCosmeticVisual.luau` | Подписка на всех Player |

Подробно: [`docs/CLIENT_SERVER.md`](docs/CLIENT_SERVER.md).


```sh
cp -r roblox-starter ../MyGame && cd ../MyGame
# Переименовать name в default.project.json и wally.toml

rokit install && rokit add lune
# Пиннуть @LATEST в wally.toml → wally install
zap net.zap

stylua src tests
selene src tests
lune run tests
rojo build -o build.rbxlx
```

## Как работать с Cursor

| Запрос | Cursor использует |
|--------|-------------------|
| «Добавь фичу X» | `architecture.mdc` + эталоны |
| «Профессиональный UI» | `professional-ui.mdc` + `Button.luau` |
| «Новая игра» | `MVP_SLICE.md` + `BACKLOG.md` |

## Правило №1

Вертикальный срез MVP → soft launch → контент апдейтами.
См. [`docs/MVP_SLICE.md`](docs/MVP_SLICE.md).
