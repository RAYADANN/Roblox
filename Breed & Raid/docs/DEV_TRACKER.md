# Breed & Raid — Dev Tracker

> Обновляй чекбоксы после работы. Фаза: **PROVE foundation**.

**Дата старта репо:** 2026-07-19

---

## Phase 0 — Repo boot

- [x] GDD канон в `docs/GDD.md`
- [x] AGENT_BRIEF / AGENTS / TECH_STACK / IMPLEMENTATION_PLAN
- [x] `wally install` (если Packages пустые/битые)
- [x] Rojo sync smoke (`default.project.json`)
- [x] Bootstrap `src/server` + `src/client` entry

---

## Phase PROVE — must-work (GDD §20)

- [x] ≥2 plots Hub+Yard claim
- [x] Nest sockets N1–N4 + MPS buffer + Collect All
- [x] Creature Roll → Buy → instance with **`oneIn`**
- [x] Nest billboard: Name · `1 in X` · $/s
- [x] Breed 120s → hatch pop `1 in X` + look pipeline
- [x] Steal hold → carry → deposit; Lock; Bat drop
- [x] Carry slow if `oneIn ≥ 200`
- [x] (Thin) Block Roll + dirt wall place/take
- [x] Tutorial stub OR hardcoded starter grants
- [x] Server-authoritative remotes (GDD §16)

### UI Delight P0 (Hatch / Buy / Collect)

- [x] Flipper springs on resource chips
- [x] Hover/press Collect + Build
- [x] Buy gold flash + burst
- [x] Collect shockwave + `+$` float
- [x] Hatch hero overlay (slam `1 in X`)
- [x] Breed chase feel: jackpot banner, Expected vs actual, FREE first Speed, egg shake, Fuse Again
- [x] Hatch roulette: rarity reel → jackpot reel → slam `1 in X` (+ fail/burn bust spin)
- [x] UiSound bus (placeholder asset ids)
- [x] Roll preview juice
- [x] Steal alert vignette
- [ ] Replace placeholder SoundIds with final SFX

### Professional UI Kit

- [x] Toybox Premium foundations: semantic colors, spacing, radii, elevation, typography
- [x] Reusable React-Lua primitives, controls, cards, modal, toast and status components
- [x] Responsive HUD and Roll / Pets / Breed / Hatch screens
- [x] Desktop / tablet / phone modal fit and safe-area layouts
- [x] World billboards and custom prompts use the same visual language
- [x] Studio-only UI catalog for component states

### Cut (не трогать в PROVE)

- [ ] Robux / ProcessReceipt
- [ ] Offline earnings
- [ ] Rebirth
- [ ] Trading
- [ ] Global LB / daily
- [ ] Full luck board numbers
- [ ] Night / monster (другая игра)

---

## MVP launch (после PROVE Go)

- [ ] 6 plots
- [ ] Nest buys N5–N8
- [x] Spikes trap (slow ×0.5 enemies while on cell)
- [ ] Soft luck
- [ ] Offline 50%/4h
- [ ] Monetization products
- [ ] Tutorial 120s + NPC steal fallback
- [ ] Server LB (MPS / oneIn / steals)

---

## Log

| Date | Note |
|------|------|
| 2026-07-19 | Repo created; GDD imported from Obsidian |
| 2026-07-19 | UI Delight P0: Hatch/Buy/Collect juice + Flipper chips |
| 2026-07-19 | Phase 0 boot + Step 1: plots claim, nests, MPS/Collect, starter grants, React HUD |
| 2026-07-19 | Fix: nest creature proxies deleted by attachBillboard→clearBillboard |
| 2026-07-19 | PROVE loop: Roll/Buy, Breed/hatch, Steal/Lock/Bat, Block Roll + dirt place/take, React panels |
| 2026-07-19 | Pets wander PetZone; build = grid click + ghost (B toggle, R rotate) |
| 2026-07-19 | Build = Minecraft voxels (4³ cubes, face place, stack, Shift+break) |
| 2026-07-19 | Spikes trap: slow ×0.5 enemies; starter spikes×25; Q cycle blocks |
| 2026-07-19 | UI visual pass: v3 cream/jade theme on HUD, Summon, Breed, Hatch |
| 2026-07-21 | Breed chase: hatch jackpot reveal + Fuse Again, incubate progress/shake, free first Speed |
| 2026-07-21 | Hatch roulette WOW: rarity + jackpot reels, bust spin on fail/burn, incubate tease |
| 2026-07-21 | Professional React-Lua UI Kit: Toybox Premium tokens/components, responsive HUD/screens, world UI parity, roll and steal feedback |
| 2026-07-21 | Professional UI runtime review: safe-area/modal fit, prompt touch hierarchy, modal input blocking, timer cleanup, carry status, and Flipper state fixes |
