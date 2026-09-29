# DEEP SIGNAL — Growth MVP (Round 3, KAI / Growth Design)

> **Role:** Growth design pass on the "Deep Signal" concept — Round 3 of the design-room consensus.
> **Context locked in from Rounds 1–2:** solo dev + Cursor as engineer, reuse of the existing Mining codebase (`src/`), Fusion 0.3 HUD, monetization plumbing already built (`MonetizationManager`, `EggManager`/`PetManager`, `RebirthManager`, `DailyReward`, `Leaderboard`).
> **Premise:** DEEP SIGNAL is a re-theme + light mechanical layer on top of the current dig-sell-upgrade-rebirth loop — **not** a new engine. You are an amateur signal hunter who picked up a strange broadcast coming from underground. You dig toward it. It never stops. That's the game.
> **Reuse map (for the engineer):** `OreDatabase` → `SignalFragmentDatabase` (rename + re-palette, same shape); `PetDatabase`/`EggManager` → `DroneDatabase`/`RelayManager` (same weighted-hatch code); `RebirthManager` → same code, renamed event "Signal Reset"; `DiscoveryManager`/Journal → "Frequency Log"; `RewardFX`/`PetHatchFX`/`RebirthFX`/`OreDiscoveryFX` → reused verbatim with new palette + SFX only. **Zero new systems required for MVP.** This is a content/copy/palette pass, which is exactly why it's the right bet for a solo dev on a deadline.

---

## 1. Why DEEP SIGNAL wins for 50k CCU — honest

**The real constraint isn't mechanics, it's Discover-algorithm differentiation.** Roblox's mining/tycoon-sim category is a red ocean — dozens of near-identical dig→sell→upgrade→rebirth clones already own the search terms "mining simulator." A well-executed but *undifferentiated* clone of that loop has a low ceiling: the algorithm has no reason to surface it over the incumbents, because nothing in the thumbnail, title, or first 10 seconds tells a new visitor *why this one*.

Three options were on the table:

| Option | Cost | Ceiling | Honest risk |
|---|---|---|---|
| **A. Ship "Deep Digger" as-is** (current generic mining-sim skin) | Lowest — already built | Low. Competes on production value alone against titles with 100–1000x the dev-hours. | Highest risk of **zero traction**: nothing for the algorithm or a thumbnail-scroller to latch onto. |
| **B. Greenfield new genre** | Highest — months of new systems, throws away ~35k lines / 7 weeks sunk cost | Unknown, but timeline risk is severe for a solo dev | Could still fail for the same discoverability reasons, just later and more expensively |
| **C. DEEP SIGNAL** (re-theme + curiosity hook on existing loop) | **Low** — data/copy/palette/SFX pass, ~1–2 weeks, no new engineering | Same mechanical ceiling as A, but **materially better CTR/retention inputs** (see below) | Re-skin risk: if the theme doesn't feel cohesive it reads as "reskin" — mitigated by committing fully to the sound design + naming, not half-measures |

**Why C, specifically:**

1. **Thumbnails need a promise, not a genre.** "Dig for ore" is a category. "Something is calling from underground and it isn't stopping" is a promise — it's the same click-bait mechanism that makes horror/anomaly/mystery content dominate Roblox's front page in 2026. Deep Signal buys that promise for the cost of a rename.
2. **Curiosity gap = the #1 lever we can actually pull as a solo dev.** We can't out-produce Mining Simulator's asset budget. We *can* out-hook it with "what's down there," which costs nothing extra to build — it's the same `LayerProfile`/`DepthTracker` system, just with escalating dread instead of escalating rock color.
3. **It's the same loop, so nothing in the 7-week build is wasted.** This is the only option where the growth bet and the sunk-cost-avoidance bet point the same direction.
4. **It clips better than a generic sim** (see Section 9) — and in 2026, organic Roblox growth is disproportionately clip-driven (TikTok/YouTube Shorts → Discover impressions → CTR). Numbers-go-up VFX barely clips anymore; a scripted "signal detected" reveal does.

**The honest part:** none of this *guarantees* 50k CCU. That number is a lottery-tier outcome that depends heavily on algorithm luck, timing, and whether a UGC clip catches fire — factors outside design control. What DEEP SIGNAL does is maximize the levers that *are* in our control (reuse cost → more iteration cycles before launch, differentiation → better CTR, clippability → better organic funnel) without betting the timeline on new engineering. If it doesn't hit 50k, it still fails *cheaper* and *faster* than option B, and with a real shot at a mid-tier outcome (5k–15k CCU) that option A likely can't reach at all.

---

## 2. Thumbnail + title screen copy (exact text)

**Roblox game title** (search + Discover):
> `Deep Signal 📡 - Dig Until It Answers`

**Roblox game description** (page blurb, ≤500 chars):
> `You picked up a signal. It's coming from underground. Every block you break gets you closer — and every layer down, it gets stranger. Dig. Sell. Upgrade. Recalibrate. Find out what's answering.`

**Genre tags:** Simulator, Adventure, Mining *(keep "Mining" in tags for search even though it's not in the title — captures existing search demand while the title differentiates)*.

**Icon (512×512):** No text (Roblox best practice at small size). Composition: half-buried glowing relay/antenna fragment in dark dirt, single pulsing red/cyan light source, dramatic rim lighting, dark background for contrast in the grid.

**Thumbnail set (3 required):**

| # | Overlay text (exact) | Composition notes |
|---|---|---|
| 1 (key art) | `SOMETHING IS SIGNALING FROM BELOW` | POV over shoulder, dark mineshaft, distant pulsing red glow far below — the "hook" shot. |
| 2 (pets/drones) | `RECRUIT A DRONE 📡` | 3-4 drones in a rarity lineup, mythic one glowing/foregrounded, same visual grammar as the existing `PetsPanel` cards. |
| 3 (chase/depth) | `HOW DEEP DOES IT GO?` | Vertical cross-section shot of the shaft showing layer transition (dirt → stone → glowing void), depth number overlay like `1,247m`. |

**Title/loading screen copy** (`LoadingScreen.lua`):
- Logo: `DEEP SIGNAL`
- Tagline under logo: `Something is calling from underground.`
- Rotating tip lines (5, no more — text-light per Section 3 principle even here):
  1. `The signal gets louder the deeper you dig.`
  2. `Drones can sense fragments before you break the block.`
  3. `Every Reset, the frequency changes.`
  4. `Rare fragments don't sell for coins. They sell for answers.`
  5. `Nobody's coming down here with you.`

---

## 3. Onboarding flow — 0 text-heavy tutorials, show don't tell

The existing `Tutorial.lua`/`TutorialDialog.lua` typewriter-dialog system stays wired for *server-side step tracking* (that plumbing is fine), but for Deep Signal the **player-facing layer is diegetic, not text bubbles.** Replace dialog text with light/sound/motion cues that reuse `TutorialArrow`'s positioning logic minus the text.

| Time | Beat | What the player sees/hears (no words) | System reused |
|---|---|---|---|
| 0–5s | Drop-in | Ambient static crackle, a **diegetic signal-strength bar** (like a Geiger counter, not a UI label) ticking up near one glowing block | `LayerAmbience` + new diegetic HUD widget (reuse `BuffChip`-style small widget) |
| 5–15s | First hit | Only the glowing block is clickable (universal golden-glow affordance already in `MiningRenderer`); on break: static pitch drops, a number pops, first Fragment lands in inventory | `MiningEngine`, `MiningRenderer` hover glow — unchanged |
| 15–30s | Directional pull | A pulsing chevron beacon (visual only, `TutorialArrow` reused with text stripped) points toward the surface console; signal-strength bar fills a notch | `TutorialArrow` (text removed) |
| 30–45s | Sell | Universal `[E]` prompt at the Relay Console (existing sell hub); coins count up (`AnimatedNumber`, already built) | `SellButton.activate()`, `AnimatedNumber` |
| 45–75s | Upgrade | Cheapest upgrade icon pulses gold on its own (no tooltip forced open); buying it is immediately felt on the next hit (bigger damage number) | `UpgRow` pulse state (new, trivial), `UpgradeLogic` |
| 75–90s | The hook | A **distant flashing red glow** appears deeper in the shaft, out of reach — no text, just a promise of what's coming (foreshadows the first Signal Spike, Section 9 #1) | `LayerEnvironment` fog + a single scripted light |

**Rule for this build:** if a tutorial beat needs a sentence to explain it, the affordance is wrong — fix the light/sound/motion, don't add a text bubble. `TutorialDialog` text stays available as a fallback/skip-accessible option (for accessibility), but is **off by default**.

---

## 4. Session design

**Target session length (median):**

| Cohort | Target median session |
|---|---|
| D1 new players | **12–14 min** |
| D7 returning | **18–22 min** (Rebirth/Drone systems now visible/desired) |
| D30 core loop players | **25–30 min**, 2+ sessions/day |

**Hook density (any positive-feedback event — loot ≥ rare, purchase, discovery, milestone, spike event):**

| Window | Target hook rate | Example |
|---|---|---|
| Minute 0–5 | ~4 hooks/min | fragment pop, first sell, first upgrade, foreshadow glow |
| Minute 5–15 | ~2 hooks/min | rare fragment, layer transition, drone hatch |
| Minute 15+ | ~1–1.5 hooks/min | Signal Spike event (every 6–8 min), milestone/journal fill |

**Never end a session at 0% or 100% of a visible bar.** `DepthBar` and the Frequency Log's "discovered X/Y" should always be mid-fill on logout where possible — this is a config choice, not new code: bias milestone thresholds so the *typical* session length lands mid-bar, and use the existing `dailyState`/leaderboard payload to give a concrete "so close" callback in the return-to-game push (see Section 5).

---

## 5. Retention hooks — D1, D7

**D1 (must happen in the first session):**
- **Guaranteed common Drone hatch within the first ~5 minutes** — not gacha-gated on day 1. First egg is free/cheap and always hits. Hooks the collection loop immediately instead of asking a brand-new player to gamble.
- **Signal Spike preview** at end of onboarding (Section 3, beat 6) — a locked, visible "there's more" moment that closes the session on a cliffhanger instead of a plateau.
- **Rebirth preview screen** (reuse `RebirthConfirmModal` structure) shown once, read-only, the first time the player is nowhere near affording it — shows a locked "what's beyond" card. Curiosity gap, zero pressure.
- **Day 1 Daily Reward claim** on the existing 7-day cycle — already built, just re-skinned copy ("Signal Log — Day 1").

**D7 (the week-one return loop):**
- **Day 7 Daily Reward payout stays big** (existing `+50k` equivalent + `x2, 30 min` boost) — re-skin copy to `SIGNAL BOOST — 2x Fragments, 30 min`.
- **Week-1 milestone: second "Frequency Band" (biome) unlock**, gated on total depth reached — gives returning players a concrete new-content reason to come back around day 5–7, not just a bigger number.
- **Leaderboard rank exposure**: first time a player's rank appears in the top-50 (or "you: #N"), fire a one-time celebratory notify — social proof pulls people back to defend/improve rank.
- **Weekly Signal Event** (reuses `LEADERBOARD`/`Notify` infra): a 48-hour "anomaly layer" with boosted rare-fragment weights, server-wide countdown visible in HUD. This is the *return* hook — it must be time-boxed and announced, not always-on.

---

## 6. Monetization MVP — no P2W

**Principle:** there is no PvP and no leaderboard-locked competitive mode, so the P2W bar is "does a purchase make a non-payer feel cheated," not "does it win a match." MVP monetization is split cleanly into **cosmetic**, **convenience**, and **time-limited economy boosts** — nothing permanent that widens a skill/power gap. This reuses `MonetizationManager`/`MonetizationLogic` byte-for-byte; only names/values change.

**Gamepasses:**

| Name | Price | Effect | Category |
|---|---|---|---|
| VIP Signal Badge | 399 R$ | Gold nametag + chat tag + cosmetic "static" chat bubble skin + **+10% fragments sold** | Mild boost (industry-standard, no PvP to "win") |
| Auto-Relay | 599 R$ | Auto-sell when inventory fills | Pure convenience |
| +2 Drone Slots | 799 R$ | Equip more Drones at once | Convenience/collection, not power |
| Drill Skins (bundle, 3 skins) | 149–249 R$ each | Pure cosmetic drill/pickaxe reskins, zero gameplay effect | Cosmetic — best margin, zero fairness risk |
| Static Trail / Aura cosmetic | 149 R$ | Visual particle trail while digging | Cosmetic |

**Dev products:**

| Name | Price | Effect |
|---|---|---|
| Fragment Pack — Small | 99 R$ | +10k coins equivalent |
| Fragment Pack — Medium | 399 R$ | +100k coins equivalent |
| Drone Hatch x10 | 199 R$ | 10 Drone hatches |
| Signal Boost (30 min, x2) | 149 R$ | Same shape as the existing Daily Reward boost — **time-limited, stacks with Daily boost, never permanent** |

**Explicitly excluded (flagged as P2W risk, not shipping in MVP):** permanent damage/power purchases, Rebirth-skip tokens, "pay to unlock next layer." If a future patch wants a power-adjacent pass, cap it at the same +10% class as VIP and keep it visible/known so it doesn't read as pay-to-win by omission.

---

## 7. Metrics dashboard — track from Day 1

| Metric | Why | Day-1 rough benchmark to compare against |
|---|---|---|
| CCU curve (hourly) | Direct read on Discover placement health | n/a — baseline only |
| D1 retention | Single biggest predictor of whether the hook works | 25–30% is healthy for a casual sim on Roblox |
| D7 retention | Tests whether Section 5 hooks land | 8–12% healthy |
| Median session length | Session design validation (Section 4) | Target 12–14 min D1 |
| Sessions/DAU | Are people coming back same-day | >1.3 is a good early sign |
| Funnel: tutorial completion % | Where onboarding (Section 3) leaks | Watch step-by-step drop-off, not just total |
| Funnel: first-sell %, first-upgrade %, first-hatch % | Core loop engagement depth | — |
| Signal Spike engagement rate | Validates the differentiator mechanic specifically | — |
| Payer conversion (% of DAU) | Monetization health | 1–3% typical for this genre |
| ARPDAU / ARPPU | Revenue efficiency | — |
| Gamepass vs dev-product revenue split | Which SKUs to double down on | — |
| Like/favorite ratio | Discover algorithm input, also sentiment proxy | >85% like ratio is the threshold to stay favored |
| Discover impressions → visit CTR | Validates thumbnail/title bet (Section 2) directly | — |
| FPS/crash/error rate | Perf gate — a hook doesn't matter if the game stutters | 0 mining-loop errors, stable 60fps target |
| Drop-off point inside onboarding | Exact beat where players quit (Section 3 instrumentation) | — |

Instrument the funnel and the Signal Spike engagement rate *before* soft launch — these are the two numbers that tell us whether the growth bet in Section 1 is actually working, separate from general retention noise.

---

## 8. Launch checklist (10 items)

1. **Rename/re-palette pass complete**: `OreDatabase` → Fragment data, `PetDatabase` → Drone data, all Notify/UI copy updated to Signal vocabulary — no leftover "ore/pet/mining" strings in player-facing text.
2. **Onboarding beats (Section 3) implemented and text-free** — verified with a friend who's never seen the game, silently, no questions asked in the first 90 seconds.
3. **Real monetization IDs in Creator Hub** — current known blocker (`id = 0` placeholders) resolved for every gamepass/dev product in Section 6.
4. **Server-authoritative depth** — close the known client-trusted depth gap before any leaderboard/quest is exposed publicly (existing P0 in `MVP.md`).
5. **Signal Spike event wired end-to-end** — server trigger → client FX → clip-worthy payoff (Section 9 #1) — this is the differentiator, it cannot be the thing that's half-finished at launch.
6. **Thumbnails + icon + title screen assets uploaded** exactly per Section 2 copy.
7. **Funnel + Signal Spike instrumentation live** (Section 7) before any traffic push — can't learn from launch day without it.
8. **Unlisted playtest with 10–20 outside players**, 3+ days, watching for onboarding drop-off and perf issues specifically.
9. **Daily Reward + Weekly Signal Event content pre-loaded for at least 2 real weeks** so D7/D14 returning players hit real new content, not a repeat.
10. **Public launch timed with a same-day clip post** (Section 9 moment, screen-recorded from the playtest) to seed the first wave of Discover impressions — don't launch into silence.

---

## 9. What makes a TikTok clip — 3 scripted moments in MVP

Each of these reuses an existing FX module almost verbatim — new palette/SFX/copy only, no new engineering.

1. **"The First Signal Spike."** Scripted to trigger reliably early (first Frequency Band transition, ~50–100m depth). Full-screen red flash, camera judder, a bold banner `SIGNAL DETECTED`, ambient audio spikes to a screech-then-silence beat, screen goes momentarily dark before the next layer's lighting kicks in. *Reuses:* `LayerEnvironment` transition + `RewardFX`-style full-screen burst, new palette/copy only.
2. **"Mythic Fragment Pull."** The Drone-hatch reveal (existing `PetHatchFX`) re-skinned: egg shake → rarity shockwave → slow-motion reveal card for the top-tier Drone, with a distinct "signal lock" chime on mythic. This is the same gacha dopamine beat every pet-sim clip already exploits — we already have the module built.
3. **"Signal Reset Blackout."** The Rebirth burst (existing `RebirthFX`) re-skinned as a full blackout beat: screen goes black, banner `SIGNAL LOST... RECALIBRATING`, then the existing golden shockwave-ring burst plays as the "signal" comes back stronger. Turns a mechanical reset (already unpleasant to explain in text) into the single most shareable "oh that's cool" moment in the loop.

**Why these three specifically:** all three already exist as coded FX (`OreDiscoveryFX`/`RewardFX`, `PetHatchFX`, `RebirthFX`) — the entire "TikTok strategy" for MVP is a copy/palette/SFX pass on systems that are done. That's the whole point of the DEEP SIGNAL bet: the clip potential was sitting in the codebase already, it just needed a hook that makes it make sense.
