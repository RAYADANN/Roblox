# Chosen art — Aim Map 1v1

Единственный список **зафиксированных** ассетов/решений. Всё остальное в `assets/ui/` — черновики / варианты на выброс.

## Palette

Единая система: [`PALETTE.md`](PALETTE.md) (art + UI roles) → код в `theme.luau`.

**Brand chrome (иконки / акценты):** `white` · `silver` · `steel` · `sky` `#3EA5E8` · `skyHi` `#73C7FF` · `primary` `#527EFF` · `primaryHi` · `deepBlue` · `navyOutline` `#000D28`

**Не делать:** новый «красивый синий» вне tokens; чёрная обводка HUD-иконок вместо `navyOutline`.

Rank metals: `bronze` / `goldArt` / `steel` — см. PALETTE rank table.

## Style language

- HUD icons: **flat esports** (white / sky / navy outlines) — style inventory **#01**
- Combat / screen FX art: **comic Ben-Day** is the main accent (thick black outline + visible circular halftone dots). Do not drop Ben-Day on “polish” passes.
- Crystal geometry where noted (hitmarker E, damage dir boomerang)
- Chrome HUD = white–silver–sky–primary; outline = navyOutline; combat confirm = same blues via tint; skins/shop = rarity layer only

## Locked assets

### Hitmarker
- **Geometry:** crystal (E)
- **Body master:** `hitmarker_masters/hm_master_e_crystal.png` → `rbxassetid://139885055386985`
- **Head master:** `hitmarker_masters/hm_master_e_crystal_head.png` → `rbxassetid://100039292895912`
- **Kinds:** body = white master; head(=kill) = gradient head master
- True alpha (no baked white/checkerboard). Opaque backups: `*.png.bak_opaque`
- No ImageColor3 tint — show asset as authored
- Wired: `HitMarker.luau` + `UiImageCatalog.combat`

### Damage direction
- **Chosen:** solid boomerang (variant 03)
- **Master:** `damage_dir_masters/dmg_dir_master.png` → `rbxassetid://116669273647796`
- Source fix: `damage_dir_solid/dmg_dir_boomerang-Photoroom.png` (true alpha)
- No ImageColor3 tint — show asset as authored
- Wired: `DamageFeedbackLayer.luau`

### Damage vignette
- **Chosen:** soft red edge Frames + UIGradient (Valorant-like), **not** image asset
- Wired: `DamageFeedbackLayer.luau`

### Kill banner (two parts)
- **Icon:** `kill_banner_parts/kill_icon_master.png` → `rbxassetid://128738184961434`
- **Ring:** `kill_banner_parts/kill_ring_master.png` → `rbxassetid://113386266501596`
- Source fix: `damage_dir_solid/kill_ring_val_02-Photoroom.png` (true alpha)
- Wired: `KillBanner.luau` + `KillBannerState` on local elim

### HUD icon set
- **Folder:** `icons/` (Photoroom transparent masters) + `cases/`
- Inventory style #01 + full set (shop, settings, sens, rematch, vs bot, health, ammo, coins, diamonds, robux, flex, win, defeat, close, invite, crosshair)
- **Rank ladder + level:** `icon_rank_*` + `icon_level` — uploaded; wired in `UiImageCatalog.ranks` / `.hud.level`
- **Skin cases:** `cases/case_*` — uploaded; wired in `UiImageCatalog.cases` (roulette BACKLOG)
- **Wired HUD chrome:** `DuelHud` + `HudIconButton` + SimPop CTAs (`client/ui/simpop`)
- Hex not pixel-audited against PALETTE — visual match only; regen if strict lock needed

### Uploaded rbxassetids (2026-08-23)

See `src/shared/data/UiImageCatalog.luau` — source of truth for `hud` / `ranks` / `cases`.

## Out of scope / owner

- Sound / mesh skins — not this art pass

## Draft folders (do not ship)

`hitmarker_options`, `hitmarker_geo_options`, `hitmarker_shards_heat`, `hitmarker_shards_ice`, `hitmarker_benday_picks` (if present), `combat/`, `hud/` (early), `kill_confirm_options/`, `hud_icon_inventory_options/` (02–10 rejects), `damage_dir_solid/` (non-chosen), unused vignette_a–d / ice_gradient_*, early `skins/` / `vfx/` icons

Safe to delete drafts after soft lock + backup.

## Update rule

При новом выборе — править **этот файл** в том же шаге, не плодить параллельные CHOSEN.md без ссылки сюда.
