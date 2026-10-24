# Studio wiring

Заполни эту таблицу под свою игру. Код ищет инстансы по этим путям; сцена без маркера — дырка, которую не закрыть «на глаз» в скрипте.

## Куда класть что

| Что | Куда |
|-----|------|
| Шаблоны моделей, FX, BillboardGui | `ReplicatedStorage.GameAssets.<Name>` |
| Плот / зона игрока | `Workspace` (не сюда шаблоны) |
| Владелец плота | атрибут `OwnerUserId` (number) |
| Луч FTUE | `Workspace.Attach.Attachment` с дочерним `Beam` |

Резолв шаблонов: `ContentRoots.resolve` — сначала `GameAssets`, потом прямой ребёнок `ReplicatedStorage`.

## Маркеры place

| Path | Role |
|------|------|
| | |

## Промпты

Сервер проверяет `PlotOwnership.owns` на каждом действии с промпта. Клиент вызывает `PromptGate.start`, чтобы чужие промпты не горели. Скрытие на клиенте не заменяет серверную проверку.

## FTUE

`TutorialLogic.STEPS` — шаги игры. `TutorialController.start({ getSnapshot, resolveTarget })` из клиентского boot, когда есть цели в мире. Пока шаги не заменены, контроллер не стартует сам.
