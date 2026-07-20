# AGENTS.md — инструкции для Cursor

Шаблон Roblox-игры (mining/incremental-sim). **Копируй этот репозиторий** для каждого нового проекта.

## Быстрый старт нового проекта

```sh
cp -r roblox-starter ../MyGame && cd ../MyGame
# Переименовать в default.project.json и wally.toml
rokit install && rokit add lune
# Пиннуть версии в wally.toml с wally.run
wally install
# Установить Zap: см. docs/TECH_STACK.md
# Сгенерировать сеть: zap net.zap
stylua src tests && selene src tests && lune run tests && rojo build -o build.rbxlx
```

## Как писать код

1. **Читай `.cursor/rules/template.mdc`** — главный индекс
2. **Архитектура:** `docs/GAME_ARCHITECTURE.md`
3. **Client vs Server (видимость):** `docs/CLIENT_SERVER.md` + `client-server-split.mdc`
4. **UI:** `docs/ui-ux-canon/00-priority-ladder.md` → `QUICK_REFERENCE.md` → (sim: `20-roblox-sim-playbook.md`) → `professional-ui.mdc` + `theme.luau`
5. **Фича:** Logic (shared) → test → Manager (server) → Zap → UI (client)
6. **Замысел неясен?** Спроси пользователя (см. `workflow.mdc`) — не угадывай client/server

## Структура репозитория

```
.cursor/rules/     ← правила для Cursor (19 файлов)
docs/              ← архитектура, стек, чеклисты
src/shared/        ← types, data, util (*Logic), vfx (QualityLogic)
src/server/core/   ← *Manager (DI)
src/client/ui/     ← React components
src/client/core/   ← Sound, Settings, VfxController, renderers
src/client/vfx/    ← world VFX engine (см. docs/VFX_ENGINE.md)
tests/             ← Lune unit tests
net.zap            ← схема сети (Zap)
```

## Эталоны (не удалять — копировать паттерн)

| Файл | Паттерн |
|------|---------|
| `RebirthLogic.luau` | Pure logic + CI test |
| `QualityLogic.luau` | VFX tiers/budgets + CI test |
| `PlayerData.luau` | Тип профиля + TEMPLATE |
| `ProfileManager.luau` | DI, session lock |
| `buildHudPayload.luau` | Проекция для клиента |
| `PlayerAttributeSync.luau` | Репликация косметики (attribute) |
| `WorldCosmeticPublisher.luau` | Сервер: publish для других игроков |
| `RemoteCosmeticVisual.luau` | Клиент: bind всех Player |
| `VfxEngine.luau` / `VfxController.luau` | World VFX + device budgets |
| `TextureCatalog.luau` + `NeonImpact`/`SmokeDash` | Flipbook atlases + signature FX |
| `VfxLabPlayground.luau` | Live Studio playground (buttons/camera) |
| `Button.luau` | Professional UI atom |
| `Logger.luau` | Единый логгер |

## Запросы пользователя

| Пользователь говорит | Cursor делает |
|---------------------|---------------|
| «Профессиональный UI» | `docs/ui-ux-canon/QUICK_REFERENCE.md` + `professional-ui.mdc` |
| «Добавь фичу X» | Чеклист в `architecture.mdc`, scope в BACKLOG |
| «Новая игра» | MVP из `docs/MVP_SLICE.md`, не всё сразу |

## Чего НЕ делать

- Не добавлять ECS, ReplicaService, UI-Wally-пакет до релиза
- Не коммитить build.rbxlx, секреты, .env
- Не писать 1000-строчные файлы
- Не дублировать формулы client/server
- Не делать 3D-косметику только на LocalPlayer без server publish (`docs/CLIENT_SERVER.md`)

## Документы

- `docs/TECH_STACK.md` — стек и обоснование
- `docs/GAME_ARCHITECTURE.md` — слои, DI, поток данных
- `docs/CLIENT_SERVER.md` — что на клиенте/сервере, видимость другим
- `docs/UI_ADAPTIVITY.md` — адаптив без подгонки под устройства
- `docs/ui-ux-canon/` — профессиональный UI/UX канон (цвет, тип, иерархия, chrome, DoD)
- `docs/MVP_SLICE.md` — что в первом релизе
- `docs/BACKLOG.md` — идеи вне scope
- `docs/PLAYTEST_CHECKLIST.md` — перед каждым релизом
- `docs/RELEASE_CHECKLIST.md` — soft launch gate
