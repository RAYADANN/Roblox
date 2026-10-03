# Studio wiring — AnimeTycoon

## Markers (сцена в place)

Площадка игрока = `Workspace.Base1`…`Base6` (или `Workspace.Bases/*`). Сервер назначает свободную базу через `BaseClaimManager`; клиент резолвит свою через `BaseLayout.getLocal()` / `getPrimary()`.

| Path | Role |
|------|------|
| `Workspace.Attach.Attachment` (+ `Beam`) | FTUE guide: clone на игрока; второй Attachment на цель |
| `Base1`…`Base6` (Folder) | Корень плота; атрибут `OwnerUserId` = владелец |
| `ReplicatedStorage.GameAssets.Stands.Stand2LVL`…`Stand4LVL` | Визуалы Pad Upgrade (tier 2–4); BoxPlace остаётся на `Base.Stands.StandN` |
| `Base.Stands.RollButton` → `Button` | ProximityPrompt **Roll** (рулетка) — только владелец базы |
| `Base.Stands.Stand1`…`Stand5` → `BoxPlace` | Preview оффера + **Buy**; низ Box = низ BoxPlace, центр |
| `Base.Ramp` | Конвейер + слоты героев |
| `Base.Ramp.HeroPlace` → `Button1`…`Button10` → `PlacePart` | Слоты 1–10 (старт открыты) |
| `Base.SecondFloor` / `ThirdFloor` | Этажи 2–3; Base Expansion → drop-катсцена при первом открытии |
| `Base.ThirdFloor` / `Ramp3.HeroPlace` → `Button1`…`Button10` | Слоты 21–30; этаж скрыт пока unlocked≤20 |
| `Ramp` / `Ramp2` / `Ramp3` → `Center.Start` → 2× `Arrow` (Beam) | Клиент: beams Ramp2/Ramp3 off пока этаж locked |
| Upgrades → Base Expansion | +1 слот за уровень (старт 10 → макс 30); ButtonN по порядку |
| Upgrades → Luck / Cash / Time / Speed | Roll rarity / sell mult / unpack time / WalkSpeed |
| `Base.Ramp.Spawnparts` / `LeftSlide` / `RightSlide` / `Center` | Waypoints конвейера (клиент) |
| `Base.SellTable` → `Money` | Показывает ожидаемый `$/s` игрока (сумма по producing heroes) |
| `Base.SellBox` → all `Side` / `SidePart` (incl. under Belt) | Банк игрушек; Side растут в небо (ось ≈ world +Y); +1 ступень каждые **5** игрушек |
| `Base.SellGuy` | **Sell** — продаёт все sell crates из инвентаря → coins в карман |
| `Base.LuckyX2` / `LuckyX4` / `MoneyX2Gold` | HUD right-rail: 24h sale R$10 (was 49) → затем R$49 без таймера, крутит до покупки |
| `Base.Limited` → `RobStand1`…`RobStand3` | Robux Limited: **authored** герой+VFX на стенде клонируется 1:1 на Ramp (`templateId=limited_*`); **Buy** / `R$…` на `Price` |
| `ReplicatedStorage.GameAssets.Boxes` | Шаблоны контейнеров (`1|2|3` + `Box1` billboard) |
| `GameAssets.Boxes.Box1.BillboardGui` | Шаблон world UI: `NameLabel`, `Rare`, `Mutation`, `Price` |
| `GameAssets.Stands.BoxHeroStand` | Эталон ориентации Box на HeroPlace |
| `GameAssets.Heroes/<Rarity>` | Каталог героев (runtime) |
| `GameAssets.MutationFx` | Mutation FX bank |
| `GameAssets.Mutations` / `Rarity` | Reference meshes для shine-палитр |
| `GameAssets.Stands.Secret` | Fallback герой |

### Multi-base claim

- Сервер: `BaseClaimManager` — свободная `BaseN` → `OwnerUserId` + teleport к Stands; leave → release.
- Промпты Roll/Buy/Place/Open/Take/Sell/Limited: Trigger только если игрок владеет базой (`ownsInstance`).
- Клиент: `BasePromptGate` гасит чужие ProximityPrompts; world visuals на `ownerUserId` place parts.
- Полный сервер (6/6) → Kick `"Server is full (no free bases)."`.

## Rojo

```powershell
cd C:\Projects\Roblox\AnimeTycoon
rokit install
rojo serve --port 34874
```

Studio plugin **Rojo 7.7** → Connect → `localhost:34874`.

## Playtest loop

1. Play Solo (Rojo connected) — тебя кинет на свободную BaseN
2. **Roll** на `Base.Stands.RollButton` → рулетка на Stand1–5
3. **Buy** на стенде → контейнер в hand
4. ProximityPrompt **Place** на пустой `PlacePart`
5. Ждать unpack → Billboard показывает **оставшееся время** (`12s` / `1:05`) → **Ready** → **Open** → HeroReveal + герой
6. Пока packing: ProximityPrompt **Open now** / `R$49` на `PlacePart` → SkipUnpack (в Studio при `ProductIds.SkipUnpack=0` открывает сразу)
7. Unpacked герой: **Pick up** → в hand/inventory; пустой слот → **Place** (герой ставится сразу, без unpack заново)
8. Мини → SellBox (монеты в ящик, не в карман); Take → inventory; SellGuy → coins
9. `Base.Limited.RobStand*` → **Buy** (R$) → unpacked герой в hand (Studio: `ProductIds.LimitedRobStand*=0` сразу выдаёт)
10. 2+ players: чужие базы без промптов; герои/мини видны на чужих площадках
