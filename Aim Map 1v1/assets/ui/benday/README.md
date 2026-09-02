# Ben-Day overlays — Aim Map 1v1

10 halftone grids for comic / combat / plate polish.  
**Size:** `1024×1024` PNG (Roblox-safe max without forced downscale; high DPI for UI).  
**Format:** white dots + alpha → tint via `ImageColor3` (`primary` / `sky` / navy).

Regen: `python tools/gen_benday.py`

## Set

| File | Grid | Fade |
|------|------|------|
| `benday_01_45_fade_top.png` | 45° | top more transparent |
| `benday_02_45_fade_bottom.png` | 45° | bottom more transparent |
| `benday_03_horiz_fade_top.png` | 0° rows | top more transparent |
| `benday_04_horiz_fade_bottom.png` | 0° rows | bottom more transparent |
| `benday_05_neg45_fade_top.png` | −45° | top more transparent |
| `benday_06_neg45_fade_bottom.png` | −45° | bottom more transparent |
| `benday_07_double_cross.png` | 45° + −45° | top fade |
| `benday_08_double_ortho.png` | 0° + 90° | bottom fade |
| `benday_09_fine_double_offset.png` | fine 30° doubled offset | top fade |
| `benday_10_coarse_dual_fade.png` | coarse 45° + fine −20° | opposite fades |

## Use

- Overlay on plates / hit FX / banners (multiply or ImageTransparency).
- Prefer these over inventing a new blue for “texture”.
- Not wired in catalog yet — draft pack.
