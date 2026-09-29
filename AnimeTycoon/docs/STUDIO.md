# Studio wiring — AnimeTycoon

## Markers (сцена в place)

| Workspace | Role |
|-----------|------|
| `Stands` (Folder) | Магазин офферов |
| `Stands.RollButton` → `Button` | ProximityPrompt **Roll** (рулетка) |
| `Stands.Stand1`…`Stand5` → `BoxPlace` | Preview оффера + **Buy**; низ Box = низ BoxPlace, центр |
| `Box1` / `Box2` / `Box3` | Шаблоны контейнеров (clone) |
| `Box1.BillboardGui` | Шаблон world UI: `NameLabel`, `Rare`, `Mutation`, `Price` |
| `Ramp.HeroPlace` → 10× `Button` → `PlacePart` | Слоты + **Place** (пусто) / **Open** (Ready); низ модели = низ PlacePart |
| `Ramp.Spawnparts` / `LeftSlide` / `RightSlide` | Waypoints конвейера (клиент) |
| `BoxHeroStand` (Model) | Эталон ориентации Box на HeroPlace (как PlacePart) |
| `Secret` (Model) | **MVP шаблон героя / мини** |

Один Ramp = MVP (мульти-плот → BACKLOG).

## Rojo

```powershell
cd C:\Projects\Roblox\AnimeTycoon
rokit install
rojo serve --port 34874
```

Studio plugin **Rojo 7.7** → Connect → `localhost:34874`.

## Playtest loop

1. Play Solo (Rojo connected)
2. **Roll** на RollButton → рулетка на Stand1–5
3. **Buy** на стенде → контейнер в hand
4. ProximityPrompt **Place** на пустой `PlacePart`
5. Ждать unpack → Billboard **Ready** → **Open** → HeroReveal + герой
6. Мини едут по конвейеру → coins растут в HUD
