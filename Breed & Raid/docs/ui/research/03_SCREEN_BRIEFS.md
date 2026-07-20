# 03 — Screen Briefs (all B&R surfaces)

Filled from inventory + teardown. Ladder aim: **L1–L5** (L6 juice per DELIGHT_SPEC; L7 ornament deferred).

---

## HUD_IDLE / HUD_CHIPS / HUD_DOCK

**Phase:** L1–L3 · **Verb:** know wealth; collect; enter build  
**Failure if wrong:** can't find Collect; chips unreadable on sky  
**Priority:** 1 Cash+Buffer 2 $/s 3 Dirt/Spikes (build only)  
**Flex:** Cash hero chip (`emphasize`); Buffer contextual  
**Hierarchy:** Collect CTA → Cash → Buffer → $/s → Build  
**Components:** ResourceChip, OrnateButton jade/ghost/primary  
**States:** default; Collect with $; Build active primary  
**Platform:** phone — max 3 chips idle; dock bottom safe; world Collect parity **yes**  
**Motion/SFX:** chip number spring; Collect press + collect juice  
**Anti-goals:** 5+ dock icons; neon chips; equal weight Cash and Spikes always  
**DoD:** contrast AA on cream; hit ≥48 dock; Collect label shows $

---

## HUD_BUILD_HINT

**Verb:** learn place/remove  
**Failure:** mode on, no idea what keys do  
**Hierarchy:** one short caption, muted (AA)  
**Anti-goals:** modal tutorial wall

---

## HUD_TOAST

**Verb:** confirm outcome  
**Failure:** miss error; spam blocks play  
**Hierarchy:** one line; Z high; ≤2.5s  
**Motion:** fade in/out; no loop pulse  
**Anti-goals:** toast during HatchReveal competing for same message

---

## ROLL_PANEL (SUMMON)

**Phase:** L2–L5  
**Verb:** roll preview → buy creature/blocks; open breed  
**Failure:** don't see odds; don't know price; empty panel looks broken  
**Flex:** **1 in X** (OneInBadge)  
**Hierarchy:**  
1. Odds badge  
2. Primary CTA (Roll empty / Buy with cost)  
3. Meta ($ · mps · rarity) / block packs  
**Components:** PanelChrome, OneInBadge, OrnateButton  
**States:** empty · preview · can't afford (disabled Buy + caption) · block section  
**Platform:** right column; on phone keep width ≤45% viewport or accept scroll — **parity with pad billboard required**  
**Motion:** press spring; buy → JuiceLayer  
**Anti-goals:** two gold primaries; odds smaller than title; fake drop shadows  
**DoD:** empty shows one primary Roll; Buy shows `$N`

---

## BREED_MODAL (FUSE)

**Verb:** pick two → start incubate / soft-speed  
**Failure:** unclear parents; Start dead; Soft Speed no price  
**Flex:** row `1 in X`; incubating expected odds  
**Hierarchy:** title → list → Start → Soft Speed (secondary) → Close  
**States:** empty nests · one selected · two selected · incubating · error  
**Platform:** modal center; veil; world INCUBATE_BILLBOARD parity timer  
**Anti-goals:** Close cancels without copy; Soft Speed without cost on CTA  
**DoD:** Start disabled until 2; cost on Soft Speed label

---

## HATCH_REVEAL

**Verb:** celebrate flex  
**Failure:** miss rarity moment; blocks input too long  
**Flex:** parsed `Name · 1 in X`  
**Hierarchy:** veil → title → odds line → auto dismiss ~1.55s  
**Motion:** slam + MathFx; hatch SFX  
**Anti-goals:** skippable only after 0.3s min; no second toast same text

---

## JUICE_LAYER

**Verb:** — (FX host)  
**Anti-goals:** click-through blocking; particle spam

---

## NEST_BILLBOARD

**Verb:** compare pets in yard  
**Failure:** can't rank by odds at distance  
**Hierarchy:** **1 in X** → name → $/s; rarity accent bar  
**Platform:** cream card; LightInfluence 0; MaxDistance sane  
**Anti-goals:** ink on grass; AlwaysOnTop infinite

---

## PAD_CREATURE_PREVIEW / PAD_BLOCK_PREVIEW

**Verb:** know station result before buy  
**Hierarchy:** header → title → odds → meta  
**Parity:** same numbers as ROLL_PANEL / prompts  
**States:** idle “Press Roll” · live preview

---

## BUFFER_BILLBOARD

**Verb:** see uncollected $ at pad  
**Flex:** `$N`  
**Parity:** Buffer chip + Collect prompt ObjectText

---

## INCUBATE_BILLBOARD

**Verb:** know fuse status without opening modal  
**Hierarchy:** Ready vs mm:ss  
**Gap:** expected `1 in X` only in modal — optional polish add

---

## PROMPT_* (all custom)

**Verb:** do station action  
**Hierarchy:** key glyph → ActionText → ObjectText  
**Hold:** Steal 1.2 / Deposit 0.5 show progress  
**Anti-goals:** default style; UIListLayout fights; white text on mid accents without AA  
**DoD:** UiKind accent; cream card; TAP on touch

---

## References

R11 sim composite · R09 Hades reward (hatch timing) · canon 08/10/20 · BaBaS REFERENCE doc
