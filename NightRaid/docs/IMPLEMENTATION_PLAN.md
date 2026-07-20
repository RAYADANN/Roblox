# Night Raid Base — План реализации

> **Статус:** Phase 3 PROVE / Foundation  
> **MECE:** 78/100 strict  
> **Обновлено:** 2026-07-17  
> **Трекер:** [DEV_TRACKER.md](./DEV_TRACKER.md) · **Бриф:** [AGENT_BRIEF.md](./AGENT_BRIEF.md) · **GDD:** [GDD.md](./GDD.md)

---

## Принципы

1. **GDD = продукт.** Новый фич → правка GDD + явный запрос.
2. Day loop = **BaBaS-канон** (GDD §3–4F): dual roll, Buy block=+100, traps, Collect All.
3. Gates. PROVE → BUILD только после Go (§9 GDD).
4. ≤8 systems · ≤40 дней · solo.
5. **Код:** `--!strict`, DI, ≤~300 строк, `:destroy()`, data в `shared/data/`, React-Lua HUD.
6. Playtest оценивает **всю сессию**.

---

## Источники истины

| Что | Где |
|-----|------|
| Продукт | `docs/GDD.md` |
| Сцена BaBaS | `docs/REFERENCE_BABAS_SCENE.md` |
| Прогресс | `docs/DEV_TRACKER.md` |
| Rules | `.cursor/rules/night-raid-*.mdc` |

---

## Phase 3 Foundation (current)

```
ROLL BLOCK (+100) → BUILD/TRAPS → ROLL PET → COLLECT ALL
→ STEAL/BAT/LOCK → NIGHT SHINE → DAWN
```

### Уже сделано

- Night graybox: cycle, flashlight, monster, Fog

### Осталось (канон GDD) — блокер playtest

| Task | Модули |
|------|--------|
| Hub+Yard plot layout | `BaseBuilder` / `BaseService` |
| Block Roll + rarity + Buy=+100 | `RollService` + `BlockDatabase` |
| Pet Roll + Buy | `RollService` |
| Inventory + Build/Take/Bat + ghost | `BuildService` |
| Spikes + walls + lamp | `BlockDatabase` + `BuildService` |
| MPS buffer + Collect All | `EconomyService` |
| Steal/Lock align | `StealService` |
| Tutorial full loop | client |

### Не в foundation

Rebirth · offline · Robux · full trap roster · live luck boards · multi-monster

### Exit gates

| Metric | Go |
|--------|-----|
| Session median | >3 min |
| Want another night | >70% |
| Light w/o text | >80% |
| Понял полный цикл | >70% |

---

## Phase 4 BUILD (после Go)

Rebirth · offline · more traps · luck boards · polish · Discover
