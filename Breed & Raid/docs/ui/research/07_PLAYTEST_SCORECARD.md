# Playtest scorecard — Breed & Raid UI

Date: 2026-07-19  
Brief: `docs/UI_DESIGN_BRIEF.md`  
Preset: jade_parchment  
Studio playtest: «Разведение и рейды» — boot clean; AA labels verified on jade CTAs (fg textDark); Breed ghost when SUMMON empty; Collect/Roll jade hierarchy OK.

## L1 Read (≤0.5s)

| Check | Pass |
|-------|------|
| Cash / Buffer / $/s readable on outdoor | ☑ (chips on cream) |
| Collect CTA finds instantly | ☑ |
| Nest **1 in X** larger than name | ☑ (order + size in WorldUi) |
| Cream cards (no bare ink on grass) | ☑ |

## L2 Respond

| Check | Pass |
|-------|------|
| Button press feel ≤100ms | ☑ (spring unchanged) |
| Collect juice + SFX | ☑ (existing) |
| Buy disabled when can't afford | ☑ (disk; sync Rojo for full) |
| Custom prompt key readable (textDark) | ☑ |

## L3 System

| Check | Pass |
|-------|------|
| textMuted captions AA | ☑ (~4.98:1) |
| Filled CTA labels textDark | ☑ verified in Play |
| Tokens only (no rogue Color3 in polish) | ☑ |
| Soft Speed shows `$` on CTA | ☑ (BreedModal + startedAt) |

## L4 World

| Check | Pass |
|-------|------|
| Pad preview matches SUMMON odds/price | ☑ structure |
| Prompt accent by UiKind | ☑ |
| Buffer billboard ↔ chip | ☑ |

## L5 Genre

| Check | Pass |
|-------|------|
| One primary dock verb idle (Collect) | ☑ |
| Fuse: Start / Speed+$ / Cancel when incubating | ☑ |
| No dual gold primaries on SUMMON empty | ☑ Breed=ghost |

## Bugs / notes

- Studio DataModel was behind disk until MCP multi_edit; **resync Rojo** so place matches repo.
- Graybox world still undercuts “expensive” feel — art, not chrome.
- Owner visual sign-off still required before extracting kit to roblox-starter.

## Sign-off эталон

Owner: __________ Date: __________ ☐ Ready to extract kit to starter
