# ScripterTest

Тестовое задание Roblox-скриптера на стеке **roblox-starter** (Rojo + Zap + React-Lua + ProfileStore).

## Воркфлоу

1. Открой в Studio карту задания: `C:\Users\59045\Downloads\TEST (7).rbxl`  
   (копия также в `maps/TEST.rbxl`)
2. В терминале проекта:
   ```powershell
   cd C:\Projects\Roblox\ScripterTest
   rojo serve
   ```
3. В Studio: плагин Rojo → Connect to `localhost:34872`
4. Play — код синкается в открытый плейс, карта `Workspace.Scriptabled` остаётся на месте

Перед сдачей: File → Save As → `.rbxl` в Telegram.

## Что реализовано

| Задача | Реализация |
|--------|------------|
| Монеты | `CoinManager` — ≤100/зону, жёлтые/красные, вращение на клиенте, +1 очко |
| Магазин | `ShopManager` — цены Area1 / ×2 Area2, BillboardGui, зелёный после покупки |
| Телепорт | `TeleportManager` — Custom ProximityPrompt + `RequestStreamAroundAsync` |
| Достижения | `AchievementManager` + React-панель слева |

## Архитектура

```
shared/util/*Logic  → pure + Lune tests
server/core/*Manager → DI, ProfileStore
net.zap → PlayerDataSync / Notify / AchievementUnlocked
client/ui → React HUD (очки + достижения)
```

## Команды

```powershell
zap net.zap
stylua src tests
selene src tests
lune run tests
rojo serve
```

## Hoarcekat

1. `rojo serve` → Connect (edit mode, Play не нужен).
2. Открой плагин Hoarcekat.
3. Stories в `ReplicatedStorage.UI.stories`:
   - `Hud.story` — полный HUD (очки, кнопка, окно достижений, prompt, тосты)
   - `Gallery.story` — галерея компонентов по отдельности
