# Night Raid Base — DEV TRACKER

> **Primary progress file.** Обновляй при каждом завершённом таске.  
> **Last updated:** 2026-07-17  
> **Current phase:** Phase 3 PROVE / Foundation  
> **Phase status:** GDD канон BaBaS ✅ · foundation day loop ▶ in code · playtest ⏳  
> **Progress (optional):** Hub/Yard + dual roll + Collect + stacks — smoke next

---

## Phase 3 PROVE — checklist

### A. Night / cycle (уже есть)

- [x] Plot parts + Fog Cage — `BaseBuilder`
- [x] PetDatabase + income tick — `EconomyService`
- [x] CycleService + HUD phase/lighting
- [x] Flashlight + Fear + monster chase/grab/interrupt + dawn resolve
- [x] Battery dusk/day rules + `PROVE_FAST` + tutorial arrows

### B. Foundation day loop — **MUST** (GDD §4D / §8)

Playtester: Block Roll→Buy×100 → Build/Traps → Pet Roll → Collect → Steal → Night.

**Канон GDD 2026-07-17:**
- [x] Hub wood + Yard grass **split layout** — 2026-07-17
- [x] **Block Roll** + rarity + **Buy = +100** — 2026-07-17
- [x] **Pet Roll** + Buy pet — 2026-07-17
- [x] Inventory stacks → Build ghost — 2026-07-17
- [x] Hotbar: Build / Take / Edit / Bat — 2026-07-17
- [x] **Spikes** trap + ≥2 wall types + lamp placeable — 2026-07-17
- [x] Pets wander + billboards — 2026-07-17
- [x] MPS **buffer** + **Collect All** — 2026-07-17
- [x] Steal + Lock + bat break — 2026-07-17
- [ ] Tutorial polish: dual-roll → build → collect → steal → night
- [ ] Smoke test Studio (2 players)
### C. Playtest gate

- [ ] 3–5 playtesters, **≥2 online together**
- [ ] Session median: ___ min → Kill / Pivot / **Go**
- [ ] «Want another night?» ___%
- [ ] Understood light w/o text ___%
- [ ] «Понял полный цикл» (roll/build/collect/steal/night) ___%
- [ ] Вердикт: ☐ Go ☐ Pivot ☐ Kill — дата: ____

**Не отмечать Go, пока B+C не закрыты.**

---

## Phase 4 BUILD (после PROVE Go)

- [ ] Rebirth + preview UI
- [ ] Offline income (pets safe)
- [ ] Weekly data row
- [ ] Mobile soft-aim flashlight
- [ ] Art polish / up to 6 plots tuning

---

## Phase 5 LAUNCH

- [ ] Soft launch metrics
- [ ] Thumbnails + clips
- [ ] Monetization (skins / battery convenience only)
- [ ] Final name
- [ ] LEARN log

---

## Notes / blockers

| Дата | Заметка |
|------|---------|
| 2026-07-17 | Foundation code: Hub/Yard, dual roll Buy+100, Collect buffer, Build/Take/Spikes |
| 2026-07-17 | **GDD rewrite:** blocks rarity + Buy=+100 + traps (Spikes) + Collect All + Hub/Yard — канон до кода foundation |
| 2026-07-16 | PROVE policy fix: full core loop required for playtest (user) |
| 2026-07-16 | Roll/build/steal moved PROVE ← was wrongly v0.2 |
| 2026-07-16 | Spin→Buy pets (no pad limit) + symmetric build grid / pet-zone lock |
| 2026-07-16 | Day loop implemented: BaseService 2 plots, Roll, Build/lamps, Steal/bat/Lock, React UI |
| 2026-07-16 | UI stack: React-Lua per `AGENTS.md` / `TECH_STACK.md` |
| 2026-07-16 | Канон Build+Pets: `MECHANICS_BUILD_AND_PETS.md` (grid+bat break, pet wander) |
| 2026-07-16 | Implemented: BuildService grid, PetService wander, bat breaks blocks |
| 2026-07-16 | Build = Hammer + Minecraft stack; Pet Zone = center 50% of 40×40 |
