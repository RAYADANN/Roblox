# AGENTS.md — ScripterTest

Тестовое задание на стеке roblox-starter. Карта — открытый `TEST (7).rbxl`, код — Rojo.

## Scope

Только 4 задачи ТЗ: монеты, магазин, телепорт Area1↔Area2, достижения.

## Структура

```
src/shared/   types, data, *Logic
src/server/   ProfileManager, Coin/Shop/Teleport/Achievement managers
src/client/   React HUD + CoinSpinner + CustomProximityPrompt
net.zap       PlayerDataSync, Notify, AchievementUnlocked
```

## Паттерн

Logic (shared) → Manager (server) → Zap → UI (client)

## Rojo

```
rojo serve
```
Connect в открытый TEST place. Не создавать отдельный place.
