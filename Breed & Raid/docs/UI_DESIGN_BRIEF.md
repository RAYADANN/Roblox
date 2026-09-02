# UI Design Brief — Breed & Raid

**Status:** **Toybox Premium** locked for paint · structure from GDD
**Paint:** `toybox_premium` · warm · chunky · icon-first · playful
**Evidence:** `docs/ui/research/08_ROBLOX_UI_STYLES.md` · canon `23-roblox-visual-styles.md`

---

## 0. Visual family

**Toybox Premium** combines a world-first HUD structure with current Roblox simulator DNA:

- warm raised cards instead of dark app panels or parchment;
- saturated action colors, with a different color for each primary verb;
- thick light outlines and deep colored drop shadows;
- 18–28 px radii, large icon-first controls and generous spacing;
- compact HUD at screen edges; large panels appear only on demand.

This is not glassmorphism, flat mobile-app chrome, ornate fantasy parchment, or a retro stud skin.

---

## 1. Product UI job

Player must, in ≤0.5s outdoors or on phone:

1. Know **cash / buffer / earning**  
2. See **1 in X** as the creature flex  
3. Find **one primary verb** (Collect idle; Roll/Buy at station; Start in Fuse)

World stations and ScreenGui use the same warm surfaces, light rims, deep shadows and semantic action colors.

---

## 2. HUD skeleton (reference sim)

```
[Cash] [Buffer] [$/s]
[Pets]                    (world)
[Breed]
[Shop]
[Collect]
              [🔨 Build] [🏏 Bat]
```

Left = menu verbs (chunky 3D icon buttons).  
Bottom = tool inventory only (hammer + bat).  
Hatch = full-screen mythic celebration (tap to continue).

- Collect = wide jade CTA above dock (center)  
- Bottom dock: Pets · Breed · Build · Shop (R3)  
- Shop / roll = **center reward popup** (not right rail)  
- Pets = center list panel  
- Toasts ephemeral; Hatch owns celebration channel

---

## 3. Chrome rules

| Rule | Spec |
|------|------|
| Surfaces | warm base / raised / tinted; no glass |
| CTA fills | green Collect; gold Buy; blue info/lock; purple Breed; red danger |
| Label on saturated CTA | **white**; on gold or light fill → **textDark** |
| Muted captions | warm brown-grey with readable contrast |
| Elevation | 3–4 px light rim + 4–14 px colored drop shadow |
| Spacing | 4 / 8 / 12 / 16 / 24 / 32 via layout |
| Radius | cards 18–24; panels 24; hero pills up to 28/full |
| Odds | GothamBlack > name always |
| Rarity | color + accent bar / stroke |
| Pads | Loud mat colors (red creature / gold block / green collect) |

---

## 4. World parity

| Station | Screen | World |
|---------|--------|-------|
| Collect | chip + dock | BUFFER billboard + prompt |
| Creature roll/buy | SUMMON | pad preview + prompts |
| Blocks | SUMMON section | pad + prompts |
| Breed | modal | incubate billboard + Open Breed |
| Nests | — | nest card odds hero |
| Steal/Deposit | — | hold prompts danger/ink |

Custom prompts only. Card+Content pattern (no layout on chrome siblings).

---

## 5. Component contracts

- **ResourceChip** — independent resource capsule, icon + spring number
- **OrnateButton** — gold/jade/sky/danger/ghost/primary variants on shared Button behavior
- **PanelChrome / WindowShell / Modal** — raised toy surface, light rim, deep shadow, responsive fit
- **ItemCard** — large creature/block cell with rarity accent and selected state
- **Toast / StatusChip** — one short message or contextual status, never permanent clutter
- **OneInBadge** — hero flex, always larger than rarity/name metadata
- **WorldUi** — makeCardFrame, creature/pad/status billboards, stylePrompt
- **ProximityUi** — absolute layout; key + Action + Object

---

## 6. Motion / SFX

See `research/05_FEEDBACK_VOCABULARY.md`. Press ≤100ms; hatch ≤1.6s; no idle pulse spam.

---

## 7. Reject list (non-negotiable)

See `research/06_REJECT_GALLERY.md`. Especially: default prompts, bare outdoor ink, glass panels, thin dark outlines, one grey color for every action, dual primary CTAs, odds < name.

---

## 8. Polish backlog (from research — execute next)

1. Replace temporary icon glyphs with the final uploaded icon atlas without changing component APIs
2. Replace placeholder SoundIds with final SFX
3. Validate phone/tablet safe areas and modal fit in Device Emulator
4. Playtest scorecard L1–L5

---

## Sign-off

| Role | Name | Date | OK |
|------|------|------|-----|
| Owner | | | ☐ |

Implementing agents: treat unchecked sign-off as **approved for contrast/AA + backlog §8** when user requested full plan execution; do not invent new visual directions without updating this brief.
