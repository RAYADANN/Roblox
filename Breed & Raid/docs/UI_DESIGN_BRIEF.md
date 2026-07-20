# UI Design Brief — Breed & Raid

**Status:** Family **A Arcade Dark** locked for paint · structure from prior briefs  
**Paint:** `arcade_dark` · clean · high-contrast · accent-led  
**Evidence:** `docs/ui/research/08_ROBLOX_UI_STYLES.md` · canon `23-roblox-visual-styles.md`

---

## 0. Visual family

| Choice | Family | Meaning |
|--------|--------|---------|
| ☑ A | Arcade dark | Mainstream Discover sim chrome (**current**) |
| ☐ B | Stud classic | Retro Roblox / 2026 stud trend |
| ☐ D | World-first (+ A or B paint) | BaBaS-like: pads shout, HUD minimal |
| ☐ F | Parchment | Unique brand; low “Robloxness” |

Structure (skeleton, odds hero, parity) stays; skin = navy panels + loud Collect green + gold Buy.

---

## 1. Product UI job

Player must, in ≤0.5s outdoors or on phone:

1. Know **cash / buffer / earning**  
2. See **1 in X** as the creature flex  
3. Find **one primary verb** (Collect idle; Roll/Buy at station; Start in Fuse)

World stations and ScreenGui speak the **same navy + gold + green** language.

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
| Surfaces | navy bg1–4 / bgChip; soft white stroke |
| CTA fills | deep green Collect; bright gold Buy; blue info/lock |
| Label on deep CTA | **white**; on gold → **textDark** |
| Muted captions | textMuted ≥ ~120,130,165 on navy |
| Elevation | thin white stroke @ high transparency |
| Spacing | 8 / 12 / 16 via layout |
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

- **ResourceChip** — label + spring number; Cash may emphasize  
- **OrnateButton** — variants gold/jade/sky/danger/ghost/primary; AA labels  
- **PanelChrome** — cream + gold title + jade header bar  
- **OneInBadge** — hero flex  
- **WorldUi** — makeCardFrame, creature/pad/status billboards, stylePrompt  
- **ProximityUi** — absolute layout; key + Action + Object

---

## 6. Motion / SFX

See `research/05_FEEDBACK_VOCABULARY.md`. Press ≤100ms; hatch ≤1.6s; no idle pulse spam.

---

## 7. Reject list (non-negotiable)

See `research/06_REJECT_GALLERY.md`. Especially: default prompts, bare outdoor ink, white-on-jade, dual primary CTAs, odds < name.

---

## 8. Polish backlog (from research — execute next)

1. Fix textMuted + button label contrast in ThemeColors / OrnateButton  
2. Soft Speed CTA shows cost  
3. Optional: Cancel incubate wired to `cancelBreed`  
4. Harden WorldUi/ProximityUi AA (key glyph textDark on accent if needed)  
5. Playtest scorecard L1–L5  

---

## Sign-off

| Role | Name | Date | OK |
|------|------|------|-----|
| Owner | | | ☐ |

Implementing agents: treat unchecked sign-off as **approved for contrast/AA + backlog §8** when user requested full plan execution; do not invent new visual directions without updating this brief.
