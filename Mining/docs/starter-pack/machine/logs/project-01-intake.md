# Project 01 — Intake + Phase 2 Converge

> **Тип:** Calibration  
> **Дата Phase 2:** 2026-07-09  
> **Цель:** отработать pipeline diverge → converge → PROVE

---

## Intake

| Поле | Значение |
|------|----------|
| Target tier | P1 (calibration) |
| KPI PROVE | session > 3 min OR clean kill ≤ 5 дней |
| KPI ship (если GO) | D1 > 15%, CCU 500–2k |
| Constraints | solo, ≤40d, ≤8 systems, greenfield verb test |
| Improvement axis | Pipeline end-to-end |

---

## Phase 1 — Diverge (3 идеи)

| # | Идея | Score | Design |
|---|------|-------|--------|
| 1 | Cargo Catchers | 38/40 | 8/10 |
| 2 | Untangle Co. | 34/40 | 8/10 |
| 3 | Pop a Puff! | 37/40 | 8/10 |

---

## Phase 2 — Red Team

| Идея | Fatal flaw (кратко) | PROVE? | Вердикт |
|------|---------------------|--------|---------|
| Cargo Catchers | 3 unproven systems, co-op untestable solo, 0 buffer | Maybe/No | **Kill** (park for P2+) |
| Untangle Co. | Нет tension/failure, fidget not game | Maybe/No | **Kill** |
| Pop a Puff! | Shared burst снимает steal-tension; cold start | Maybe/Yes | **→ PROVE** |

**Red Team winner:** Pop a Puff!  
**Caveat:** все три «8/10» — inflated; scorecard недооценивает scope risk.

---

## Phase 2 — Engineer

| Идея | Verdict | Реальные дни | Co-op risk |
|------|---------|--------------|------------|
| Cargo Catchers | NO | ~60d | 5/5 |
| Untangle Co. | **GO** | ~38d | 1/5 |
| Pop a Puff! | NO | ~62d | 5/5 |

**Engineer winner:** Untangle Co. (единственный в 40d; PROVE 3–5d)  
**Note:** reuse patterns из codebase ускоряет BUILD, но PROVE = greenfield verb.

---

## Split decision

| Роль | Pick | Логика |
|------|------|--------|
| Red Team | Pop a Puff | Сильнее verb, тестируется solo (inflate/vent/ride) |
| Engineer | Untangle Co. | Единственный full ship в бюджете; дешёвый PROVE |

---

## Рекомендация Phase 3

**Primary PROVE: Bury the Dead** (урезанный scope)

**Retry if Kill:** Absorb: Power Arena

**Killed:** Cell Siege, Untangle, Pop a Puff

---

## Phase 3 PROVE scope — Bury the Dead (CUT)

**Build:**
- [ ] Копание могилы + 1 tier качества (shallow vs deep)
- [ ] 1 ночная волна (3 revenant + 1 из shallow grave)
- [ ] Shovel melee (reuse mining swing feel)
- [ ] Day/night timer
- [ ] NO fence, NO lantern, NO shop

**Gates:** session > 3 min, «хочешь ещё?» > 70%

---

## Status

- [x] Phase 0 Intake
- [x] Phase 1 Diverge (round 1 + 2)
- [x] Phase 2 Converge (Red Team diverge #2)
- [ ] Phase 3 PROVE — Bury the Dead
- [ ] Phase 4+ (if GO)
