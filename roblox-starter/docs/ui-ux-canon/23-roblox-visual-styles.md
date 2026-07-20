# 23 — Roblox Discover UI visual styles

Канон craft (contrast, hierarchy, tokens) **универсален**.  
Визуальная *семья* на Discover — отдельный выбор. Иначе «проф. parchment» выглядит чужим рядом с hits.

Полный game-specific разбор: проекты могут вести свой `docs/ui/research/08_ROBLOX_UI_STYLES.md`.

---

## Style families (pick one)

| ID | Name | Surfaces | Accents | Genre fit |
|----|------|----------|---------|-----------|
| A | **Arcade dark** | Navy / near-black panels | Loud green/gold/cyan | Most sims, mining, pets |
| B | **Stud / classic** | Stud-tiled plastic | Primary RYGB | Sim/brainrot, retro Roblox |
| C | **Candy pastel** | Soft pink/lilac/mint | Hot pink / sky | Young pet collect |
| D | **World-first** | Minimal ScreenGui; 3D boards/pads | Neon mats + big Collect | Build/steal, tycoon pads |
| E | **Clean flat** | Flat gray/dark, thin stroke | One brand hue | Brand-forward experiences |
| F | **Themed ornate** | Parchment / custom art | Jade/bronze/etc. | Intentional non-native brand |

**Rule:** one family per product. Mixing A+F or B+C = Marketplace collage.

---

## Shared Discover DNA (all families)

1. Phone thumb-zone primary CTA  
2. 1–3 top currency chips  
3. Saturated action color vs quieter chrome  
4. Huge flex numeric  
5. Stations readable with ScreenGui closed  
6. Press juice ≤100ms  

Family changes **paint**; DNA stays.

---

## When “professional” still feels wrong

If L1–L3 pass but players say «не Roblox» — you likely shipped **F** (or E) in a genre that expects **A/B/D**.

Fix: retoken skin + CTA saturation + world pad language — not another spacing pass.

---

## DoD

- [ ] Family ID written in theme Preset / brief  
- [ ] 3 adjectives match family  
- [ ] HUD + world + prompts same family  
- [ ] No second family chrome on one screen  
- [ ] Reject list includes “wrong-family” tells
