# Night Raid Base — Agent Brief

> Прочитай **этот файл** и `docs/DEV_TRACKER.md` **до любого кода**.

---

## Игра (one-liner)

Днём как BaBaS: **Block Roll (rarity → Buy = +100) + Pet Roll → Build/Traps на yard → Collect All → steal/bat**. Ночью: **shine** + monster + Fog Cage.

**Пространство:** ≥2 plots; Hub wood + Yard grass. Канон: `docs/GDD.md` + `docs/REFERENCE_BABAS_SCENE.md`.

**MECE 78** · P2 target · Twist = night+light (не reskin pets).

---

## Где правда

| Документ | Путь |
|----------|------|
| Трекер | `docs/DEV_TRACKER.md` |
| **GDD (канон)** | **`docs/GDD.md`** |
| BaBaS сцена | `docs/REFERENCE_BABAS_SCENE.md` |
| Build & Pets кратко | `docs/MECHANICS_BUILD_AND_PETS.md` |
| План | `docs/IMPLEMENTATION_PLAN.md` |
| Stack UI | `docs/TECH_STACK.md` · `AGENTS.md` |
| Design rules | `C:\Projects\Roblox\Mining\docs\starter-pack\` |

---

## Hard rules

- **GDD first.** Неверный day loop (слоты стен, один pet-roll, income без Collect) = не та игра.
- **Buy блока = +100.** Всегда.
- **Блоки и pets — оба с rarity + Roll→Buy.**
- **Traps в foundation** (минимум Spikes).
- **PROVE = полный сессионный цикл.** Playtest без dual-roll/build/steal **невалиден**.
- ≤8 systems · не invent вне GDD.
- **Не в PROVE:** Robux, rebirth, offline, weekly ops, multi-monster, full trap roster.
- Code: `--!strict`, DI, data in `shared/data/`, `:destroy()`, React-Lua HUD.

---

## Сейчас

Foundation по GDD §4D / §8. Night graybox уже есть — **не ломать**; выровнять day под канон.
