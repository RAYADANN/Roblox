# 02 — Competitive / Genre Teardown

Structure-only. Not IP/skin copy. Primary reference: BaBaS screenshots in `docs/REFERENCE_BABAS_SCENE.md` + Roblox sim composite (canon R11) + breed/fuse information design (SMT/Persona fusion clarity, Pokémon breed rarity communication).

**Note:** Full photographic annotation awaits extra reference screenshots. Patterns below are grounded in BaBaS scene doc + shipped sim conventions.

---

## Surface A — Idle HUD

| Game pattern | 0.5s hero | Primary CTA | Flex | World parity |
|--------------|-----------|-------------|------|--------------|
| BaBaS | Cash / MPS boards | Collect All (green, big $) | MPS + buffer $ | World board + screen button |
| Strong pet sims | Soft currency chips top | Dock Sell/Collect | One hero resource | Pads match chip colors |
| B&R today | Cash chip (gold accent) | Collect dock | Cash / Buffer / $/s equal weight | Buffer billboard yes |

**Steal**
- Collect label embeds live `$` (already).
- One hero chip slightly larger (Cash) — keep; don't grow dock to 6 icons.

**Don't**
- BaBaS neon red pads + default yellow prompts as our chrome.
- Duplicate Collect as equally loud screen + world without shared language.

---

## Surface B — Station prompt (Roll / Buy)

| Pattern | Hero | CTA | Flex |
|---------|------|-----|------|
| BaBaS | Billboard `1 in X` + name + $/s | `[E] Roll!` then buy | Odds + price green |
| Hit sims | Custom prompt card | Verb + ObjectText price | Odds on pad preview |
| B&R | Custom cream card | Roll Creature / Buy | Pad preview + SUMMON panel |

**Steal**
- ActionText = verb; ObjectText = money/odds (already).
- Pad preview hierarchy: header → title → **odds** → meta (already in WorldUi).

**Don't**
- Default Roblox ProximityPrompt forever.
- Two primary filled CTAs same frame (Roll + Buy both gold) — Buy only when preview exists; Roll is free preview (B&R does this).

---

## Surface C — Roll / shop modal

| Pattern | Hero | CTA |
|---------|------|-----|
| BaBaS | Physical pad + billboard; less modal | World-first |
| Pet egg shops | Odds + rarity color + Buy | One Buy |
| B&R SUMMON | OneInBadge hero | Roll → Buy |

**Steal**
- Odds larger than name (GDD flex) — enforce in brief.
- Empty state: single primary “Roll Creature”, not empty chrome.

**Don't**
- Always-on huge right panel eating phone FOV without collapse (B&R risk).
- Ornament L7 before L1 readable odds.

---

## Surface D — Creature / pet card (world)

| Pattern | Hierarchy |
|---------|-----------|
| BaBaS | `1 in X` dominant; name; Level; $value |
| B&R nest | Name (± hybrid); **1 in X**; $/s |

**Steal**
- Odds-as-hero; rarity via stroke/accent not color alone.
- Cream card on grass (ink-on-grass fails contrast — measured).

**Don't**
- Black translucent billboards.
- Name larger than odds.
- Neon rarity fills that fight parchment.

---

## Surface E — Toast / hatch

| Pattern | Behavior |
|---------|----------|
| Hades / juice games | Short celebration, then silence |
| B&R | HatchReveal ~1.55s + toast |

**Steal**
- One celebration channel at a time (hatch OR toast, not both screaming).
- Instant press feedback before network.

**Don't**
- Permanent pulse on all chips.
- Long modal after every common hatch.

---

## Non-Roblox information design (breed/fuse)

| Source | Steal structure |
|--------|-----------------|
| SMT / Persona fusion | Clear parents → result preview → confirm; cost visible |
| Pokémon breed | Odds/IV communication separate from cosmetics |
| Monster Rancher | Result reveal as event, not spreadsheet |

**Don't copy** anime chrome, trademarked layouts, or pay-dark-patterns.

---

## Summary for B&R brief

1. **World-first stations** (BaBaS) + **ScreenGui SUMMON** as secondary — keep parity, reduce phone clutter later.  
2. **1 in X** is the only numeric hero on creature surfaces.  
3. **Collect** is the only jade-filled dock verb at idle.  
4. **Cream cards everywhere** outdoors — never bare ink on grass.  
5. **Custom prompts** mandatory; accent by UiKind.
