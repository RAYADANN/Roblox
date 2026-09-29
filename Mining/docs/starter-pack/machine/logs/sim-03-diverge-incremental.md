# Sim #3 — Diverge: Incremental Designer (E2 + unique verb)

> **Дата:** 2026-07-10
> **Роль:** DIVERGE — Incremental Designer (agent-prompts.md Role 2)
> **Полка:** 🟢 Incremental + unique verb (открыта, см. 03-top50-rank-analysis.md)
> **Lifecycle:** L1_BURST (4–6 нед revenue window, как DD)
> **No self-score / no CCU** per agent-roi.md protocol.

---

## SHARPEN PENCILS

**One-liner:** Hand-sharpen pencils for a satisfying curling-shaving reveal, sell full bins to the School Board, then buy Auto-Sharpeners that grind non-stop — even while you're offline.

**Engines:** E1 (automators, offline accrual) + E2 (Pencils-Sharpened counter always on screen, rebirth multiplier) + E3-light (wood-tier → cosmetic skin, no gacha egg)

**Core verb:** SHARPEN — hold pencil against spinning wheel → ribbon of shavings curls off (VFX+ASMR grind sound) → pencil pops into tray. Distinct tactile beat, not crush/smash/pop/size-runner.

**Noun:** Pencils / shavings / School Orders — mundane object turned tycoon good. Bizarre-but-instantly-clear like "lemons," zero overlap with saturated shelves (farm/mine/pet/brainrot/fish).

**Kid-safe thumbnail:** cute cartoon sharpener spraying confetti-shavings + oversized cash burst + counter "47,000,000 SHARPENED." No characters, no violence, no dark palette — school-supply bright colors.

---

## PROVE scope (3–5 days, graybox only)

- 1 hand-crank sharpener station: tap-hold → shaving-curl VFX + grind SFX → pencil → bin
- 1 Auto-Sharpener prefab, idle tick, no upgrade tree yet
- Bin → Cash counter on screen. **No shop, no rebirth, no skins yet** — verb only.
- **Gate:** session median > 3 min · "want more" > 70% · understood w/o text > 80%

---

## MVP — 8 systems (≤ 40d solo)

| # | System | Note |
|---|--------|------|
| 1 | Save + Cash / Pencils-Sharpened counter | |
| 2 | Manual sharpen loop | tap-hold, shaving VFX/SFX, reveal beat |
| 3 | Auto-Sharpener automators | tiered, offline accrual — Sell Lemons pattern |
| 4 | Shop/Upgrades | sharpen speed, bin size, wood tier |
| 5 | Wood-tier → cosmetic pencil skin | Golden/Rainbow/Diamond-tip, player picks material (not pure RNG) |
| 6 | Rebirth ("New District") | permanent multiplier, reset, unlocks sharpener skin |
| 7 | Leaderboard + visible factories | social-lite, **no trade/steal** → zero moderation debt |
| 8 | Monetization + FTUE polish | |

**Cut first if scope slips:** #7 → static top-10 snapshot instead of live world; #5 → 2 skin tiers instead of 4.

---

## Reuse from Deep Digger (DD)

| DD module | Reuse | Note |
|---|---|---|
| EconomyManager, SellInventory, BuyUpgrade | ~90% | currency/sell/upgrade math is generic |
| RebirthManager, RebirthLogic, RebirthPanel | ~85% | swap depth-tier → district-tier |
| MonetizationManager, PromoCodeManager | ~90% | gamepass/dev-product plumbing untouched |
| DailyReward, QuestManager, SocialRewardManager, AchievementManager | ~85% | content-agnostic |
| HUD shell (BottomDock, TabBar, ShopPanel, ResourceChip, Notification) | ~75% | Fusion components, re-skin only |
| WorldLeaderboard | ~90% | |
| PetManager/EggManager | ~40% | keep hatch/reveal UX + rarity table; cut PetFollowerController/RemotePetVisual (no follower AI needed) |
| MiningEngine, DepthTracker, OreLookup, LayerAmbience/Environment, DiscoveryManager | 0% | mining-identity-specific, not portable |

**Net infra reuse ≈ 60–65%** of DD's systems. New code = SharpenEngine (small state machine, ~2–3 days) + shaving VFX.

---

## F / G scores

- **Founder Fit F: 7/8** — graybox-able in Studio with spin anim + VFX; majority of backend reused; clip-bait is built into the verb (shaving-curl reveal); zero netcode/co-op risk.
- **Audience G: 8/8** — school-supply theme, no violence/gore/dark tone, thumbnail reads instantly, safe for 9–13 core demo and parents.

---

## Kill criteria

**PROVE kill (≤5 days):** session median < 2 min, OR "want more" < 50%, OR shaving-curl loop reads as a chore (not ASMR) to ≥3/5 testers → verb is dead, no shop/rebirth fixes a bad LOOP.

**Post-launch kill (anti-patterns switch):** D1 < 15% **and** 2nd-session-same-day < 20% **and** median session < 5 min → do not add content; pivot verb or hard-kill inside the L1_BURST 4–6 week window.

---

## Diff vs Sell Lemons

| | Sell Lemons | Sharpen Pencils |
|---|---|---|
| Verb | Sell (transactional, NPC walk-up) | Sharpen (tactile hold-to-grind, ASMR) |
| Noun | Lemons / lemonade stand | Pencils / shavings / school factory |
| Reveal moment | Coin / juice splash | Shaving-curl spiral + rare-tip sparkle |
| RETURN hook | Offline automators + day cycle | Offline automators + daily School Order deadline (scheduled event) |
| Rarity source | Egg/gacha-style pull | Wood-tier choice → skin (player-directed, not pure RNG) |
| Clip bait | "$ empire from $1" | ASMR shaving curl + "PENCILS SHARPENED: 47,000,000" |

---

## Monetization (full)

**Gamepasses — permanent, cosmetic/convenience only (no stat P2W):**
- **2× Sharpen Speed** — faster manual + auto-sharpen rate
- **Auto-Sell** — bins sell automatically, no manual click
- **VIP Pencil Case** — exclusive tool skin + shaving-color trail (cosmetic)
- **Extra Sharpener Slot** — +1 automator slot (capped, same pattern as tycoon extra-plot passes)

**Dev products — consumable:**
- **Rebirth Token** — instantly clears current rebirth requirement (primary time-skip)
- **Rainbow Wood Crate** — guaranteed rare cosmetic skin material
- **Cash Bundles** (S/M/L)
- **Offline Boost** — instantly claim 2× pending offline accrual

**F2P ceiling:** free players reach ~District 5–6 rebirth and ~70% of cosmetic skins through grind + daily rewards + quests. No system is content-gated behind a paywall — only time is compressed.

**Revenue driver (primary):** Rebirth Token + 2× Sharpen Speed gamepass — classic incremental "buy back the grind wall" pattern, same driver class as Sell Lemons / Pet Sim. **Secondary:** cosmetic skin crates (flex, not power).
