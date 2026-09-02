# UI / combat image pack — Aim Map 1v1

Generated for graybox polish. Wire via `rbxassetid://` after upload to Roblox (Creator Dashboard or Studio MCP `upload_image`).

Tintable combat sprites are white (or precolored) on **transparent** PNG so HUD can use `ImageColor3`.

## Mechanics → assets

| Mechanic (in code) | Asset | Use |
|--------------------|-------|-----|
| HitMarker body / head / kill | `combat/hitmarker_*.png` | Replace Frame ticks in `HitMarker.luau` |
| DamageFeedback chevron | `combat/damage_chevron.png` | Replace Frame wings in `DamageFeedbackLayer.luau` |
| Kill / headshot feedback | `hud/icon_kill.png`, `icon_headshot.png` | Toast / kill feed / damage numbers |
| Kill-flex skin steal | `hud/icon_flex.png` | Flex toast when you take opp skin |
| Rematch CTA | `hud/icon_rematch.png` | Rematch button icon |
| HP / ammo HUD | `hud/icon_health.png`, `icon_ammo.png` | HealthBar / future ammo chip |
| Match end | `hud/icon_win.png`, `icon_defeat.png` | Ended phase overlay |
| vs Bot | `hud/icon_vs_bot.png` | Practice CTA |
| Account level | `hud_icons_flat_esports/icon_level.png` | Profile / XP chip |
| Rank ladder | `hud_icons_flat_esports/icon_rank_*.png` | Iron→Elite (7) |
| Skin cases (draft) | `cases/case_*.png` | Roulette/shop — BACKLOG |
| Ben-Day overlays | `benday/benday_*.png` | 10 grids 1024², tintable |
| Skin shop (4 ids) | `skins/skin_usp_*.png` | Shop cards / SkinDatabase.icon |
| FP muzzle / impact | `vfx/muzzle_flash.png`, `impact_spark.png` | Weapon flash + world hit spark |

## Files

```
assets/ui/
  combat/   hitmarker_body, hitmarker_head, hitmarker_kill, damage_chevron
  hud/      icon_kill, icon_headshot, icon_flex, icon_rematch, icon_health,
            icon_ammo, icon_win, icon_defeat, icon_vs_bot
  skins/    skin_usp_default, skin_usp_slate, skin_usp_crimson, skin_usp_neon
  vfx/      muzzle_flash, impact_spark
```

## After upload

1. Paste ids into `shared/data/UiImageCatalog.luau` (create when wiring).
2. Hit markers: one ImageLabel + `ImageColor3` from `HitMarkerLogic.rgb` (body white / head gold / kill red) — or use the three precolored variants.
3. Do **not** commit `rbxassetid` secrets; ids are public asset refs, OK in repo.

## Out of scope (still code / later)

- Crosshair presets — already Frame-based (`CrosshairDatabase`); keep unless you want image crosshairs.
- Particle flipbooks in `assets/vfx/*_4x4.png` — starter VFX pack, separate.
- Real USP mesh / kill-flex 3D materials — not 2D HUD.
