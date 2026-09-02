# Skin cases — draft art (roulette / shop)

Flat esports cases for a future **cases + roulette** loop (BACKLOG — not MVP).  
Palette: [`../PALETTE.md`](../PALETTE.md) + `theme.Rarity`.

## Set

| File | Role | Accent |
|------|------|--------|
| `case_standard.png` | Default / Armory case | brand `sky` + `primary` |
| `case_rare.png` | Rare pool | `rare` blue |
| `case_epic.png` | Epic pool | `epic` purple `#B464FF` |
| `case_legendary.png` | Legendary pool | `gold` / `goldArt` |
| `case_mythic.png` | Mythic / flex pool | `mythic` `#FF5078` |
| `case_open.png` | Open state / reveal shell | brand blue + empty slot |

## Style notes

- One **master** silhouette (`case_master.png` / `case_standard`) → rarity = recolor accents only.
- Same content bbox / scale for all (normalized ~78% of 1024²).
- RIGHT-facing (mirrored from left master; flip again if regenerating).
- No baked text. Not uploaded / wired yet.

## Regen pipeline

1. Generate `case_master_v2` (or replace master).
2. `ImageOps.mirror` → left face.
3. Normalize bbox fill 0.78.
4. Recolor chromatic accents for rare/epic/legendary/mythic.
5. Open: separate art, same normalize.

## Intended use (later)

Shop grid → closed case art · Roulette open → `case_open` + skin reveal over slot · optional plate behind = `shop_plates/*`.
