# 01 — Surface Inventory

Complete list of Breed & Raid UI surfaces (2026-07-19). Source: codebase audit.

## ScreenGuis

| Name | Profile | Order | Role |
|------|---------|-------|------|
| `BreedRaidUI` | hud | 20 | React HUD |
| `BreedRaidPrompts` | toast | 100 | Custom proximity chrome |

## Composition

```
GameRoot → HudProvider → App
  Top chips · Dock · Build hint · Toast
  RollPanel (always) · BreedModal · JuiceLayer · HatchReveal
ProximityUi (parallel) → custom prompt billboards
```

## ScreenGui surfaces

| ID | Job | Primary CTA | Flex |
|----|-----|-------------|------|
| HUD_IDLE | Resources + dock | Collect when buffer > 0 | Cash / Buffer / $/s |
| HUD_CHIPS | Glance economy | — | shortNumber |
| HUD_DOCK | Collect + Build toggle | Collect (jade) | Buffer in label |
| HUD_BUILD_HINT | Teach build keys | — | — |
| HUD_TOAST | Ephemeral feedback | — | hatch / $ / error |
| ROLL_PANEL | Creature + block gacha | Roll → Buy | **1 in X** hero |
| BREED_MODAL | Fuse two pets | Start | 1 in X rows |
| HATCH_REVEAL | Hatch celebration | auto-dismiss | Name · 1 in X |
| JUICE_LAYER | Non-interactive FX | — | +N float |

## World billboards

| ID | Shows | Flex |
|----|-------|------|
| NEST_BILLBOARD | Name · 1 in X · $/s | oneIn |
| PAD_CREATURE_PREVIEW | CREATURE ROLL + preview | oneIn + $ |
| PAD_BLOCK_PREVIEW | BLOCK ROLL + preview | oneIn + $ |
| BUFFER_BILLBOARD | $N | buffer |
| INCUBATE_BILLBOARD | Ready / timer | — |

## Prompts (custom)

| ID | ActionText | ObjectText role | Hold |
|----|------------|-----------------|------|
| PROMPT_COLLECT | Collect All | $ ready | 0 |
| PROMPT_ROLL_CREATURE | Roll Creature | Free preview | 0 |
| PROMPT_BUY_CREATURE | Buy Creature | $cost | 0 |
| PROMPT_ROLL_BLOCKS | Roll Blocks | Free preview | 0 |
| PROMPT_BUY_BLOCKS | Buy Pack | $ · +qty | 0 |
| PROMPT_LOCK | Lock Base | duration | 0 |
| PROMPT_BREED | Open Breed | Fuse / timer | 0 |
| PROMPT_STEAL | Steal | Take creature | 1.2s |
| PROMPT_DEPOSIT | Deposit | Empty nest | 0.5s |
| PROMPT_TAKE | Take | blockId | 0 |

## Code gaps (research → polish)

| Gap | Impact |
|-----|--------|
| `cancelBreed` unused in BreedModal | No cancel incubate CTA |
| `lockUntil` not on HUD | Lock only on pad/toast |
| RollPanel always visible | Competes with world; phone clutter |
| Soft Speed CTA no cost on button | Ambiguous price |
| textMuted contrast fail AA on bg3 | Captions hard to read |
| white on jade/sky/danger fail AA | CTA labels weak |

## Key paths

- `src/client/ui/App.luau`, `theme.luau`, `components/*`
- `src/shared/ui/WorldUi.luau`, `ThemeColors.luau`
- `src/client/core/ProximityUi.luau`
