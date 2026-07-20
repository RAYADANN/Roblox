# Breed & Raid — Agent Brief

> Прочитай **этот файл**, `docs/GDD.md` и `docs/DEV_TRACKER.md` **до любого кода**.

---

## Игра (one-liner)

BaBaS-bones: **Creature Roll + Block Roll (Buy=+100) → Build/Traps → Nests MPS → Collect All → Steal/Lock/Bat**.  
Twist: **BREED/FUSE** двух creatures → hybrid. Flex = **`1 in X`** (rarity = band от oneIn).

**Пространство:** plots Hub wood + Yard grass; PROVE ≥2 plots.  
**Канон:** `docs/GDD.md` · сцена: `docs/REFERENCE_BABAS_SCENE.md`.

**MECE ~76** · P2 target · Art: 5 meshes + gene look pipeline (не уникальный меш на hybrid).

---

## Где правда

| Документ | Путь |
|----------|------|
| **GDD (канон)** | **`docs/GDD.md`** |
| Трекер | `docs/DEV_TRACKER.md` |
| План | `docs/IMPLEMENTATION_PLAN.md` |
| BaBaS сцена | `docs/REFERENCE_BABAS_SCENE.md` |
| Опросник (закрыт GDD) | `docs/PROGRAMMER_QUESTIONS.md` |
| Stack | `docs/TECH_STACK.md` · `AGENTS.md` |
| **UI Delight** | `docs/ui/DELIGHT_SPEC.md` (восторг + motion budget) |
| Obsidian mirror | `Игры/Концепты/Breed & Raid — GDD.md` |
| Design rules | `C:\Projects\Roblox\Mining\docs\starter-pack\` |

---

## Hard rules

- **GDD first.** Не invent механики вне GDD.
- **`oneIn` primary flex** — billboard / roll / hatch / LB. Rarity = производная банда.
- **Breed:** parents consumed on success; `childOneIn ≈ A.oneIn * B.oneIn` + jackpot mutate (§7.5).
- **Buy блока = +100** (wall/trap).
- **Look pipeline** — 5 species meshes + accessories/colors (GDD §4).
- **Always-day** — нет night cycle.
- **PROVE** = nests+MPS+roll+breed+steal/lock/bat (+ thin build). Без этого playtest невалиден.
- ≤8 systems · `--!strict` · DI · data в `shared/data/` · `:destroy()` · React-Lua HUD.
- **Не в PROVE:** Robux live, rebirth, offline, trading, BP, global LB, full luck boards.

---

## Сейчас

Стартуй с `docs/DEV_TRACKER.md` Phase PROVE — foundation.  
При конфликте чат vs GDD → **GDD**. При правке GDD синхронизируй Obsidian mirror.
