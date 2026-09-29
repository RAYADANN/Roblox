#!/usr/bin/env python3
"""Compose Roblox-style thumbnails with styled 3D gradient text."""

from __future__ import annotations

import sys
from dataclasses import dataclass, replace
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from roblox_text import (  # noqa: E402
    STYLE_BLUE_LOGO,
    STYLE_WHITE_SUB,
    hook_style_for,
    paste_text,
    render_text,
)

OUT_DIR = ROOT / "assets" / "marketing" / "thumbnails_roblox"
BG_DIR = ROOT / "assets" / "marketing" / "thumbnails_roblox" / "_backgrounds"
W, H = 1920, 1080


@dataclass(frozen=True)
class ThumbSpec:
    bg_name: str
    out_name: str
    main: str
    sub: str | None
    center_title: bool = False


SPECS: list[ThumbSpec] = [
    ThumbSpec("bg_pets.png", "01_pets_hatch", "30+ PETS!", "HATCH & COLLECT"),
    ThumbSpec("bg_rebirth.png", "02_rebirth", "REBIRTH!", "x10 INCOME"),
    ThumbSpec("bg_bright_mine.png", "03_dig_deeper", "DIG DEEPER", "GET RICH"),
    ThumbSpec("bg_bright_mine.png", "04_play_now", "PLAY NOW", "FREE TO PLAY"),
    ThumbSpec("bg_face.png", "05_rare_ore", "RARE ORE!", "WOW!"),
    ThumbSpec("bg_pov.png", "06_pov_mine", "DIG!", None),
    ThumbSpec("bg_ores.png", "07_50_ores", "50+ ORES!", "COLLECT ALL"),
    ThumbSpec("bg_void.png", "08_new_layer", "[NEW LAYER!]", "VOID ZONE"),
    ThumbSpec("bg_depth.png", "09_how_deep", "HOW DEEP?", "9999m"),
    ThumbSpec("bg_daily.png", "10_daily", "FREE DAILY", "REWARDS!"),
    ThumbSpec("bg_group.png", "11_free_gift", "FREE GIFT", "JOIN GROUP"),
    ThumbSpec("bg_eggs_shop.png", "12_lucky_egg", "LUCKY EGG", "OPEN NOW!"),
    ThumbSpec("bg_sell.png", "13_sell_ore", "SELL ORE", "GET COINS"),
    ThumbSpec("bg_leaderboard.png", "14_top_10", "TOP 10", "LEADERBOARD"),
    ThumbSpec("bg_vip.png", "15_vip", "VIP", "+10% COINS"),
    ThumbSpec("bg_crit.png", "16_crit", "CRITICAL!", "2x DAMAGE"),
    ThumbSpec("bg_boost.png", "17_2x_luck", "2x LUCK", "BOOST!"),
    ThumbSpec("bg_mythic.png", "18_mythic", "MYTHIC!", "ORE FOUND"),
    ThumbSpec("bg_minimal.png", "19_minimal", "DEEP DIGGER", None, center_title=True),
    ThumbSpec("bg_update.png", "20_upd", "[UPD!]", "NEW CONTENT"),
]


def _top_vignette(img: Image.Image) -> Image.Image:
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.rectangle((0, 0, W, 340), fill=(0, 0, 0, 100))
    d.rectangle((0, H - 160, W, H), fill=(0, 0, 0, 70))
    return Image.alpha_composite(img.convert("RGBA"), overlay)


def compose(spec: ThumbSpec) -> None:
    bg_path = BG_DIR / spec.bg_name
    if not bg_path.exists():
        print(f"SKIP missing bg: {spec.bg_name}")
        return

    base = Image.open(bg_path).convert("RGB").resize((W, H), Image.Resampling.LANCZOS)
    img = _top_vignette(base)

    margin_x, margin_y = 48, 36

    if spec.center_title:
        logo_style = replace(STYLE_BLUE_LOGO, size=128, depth=10)
        layer = render_text(spec.main, logo_style)
        x = (W - layer.width) // 2
        y = (H - layer.height) // 2 - 30
        paste_text(img, layer, x, y)
    else:
        main_style = hook_style_for(spec.main)
        main_layer = render_text(spec.main, main_style)
        paste_text(img, main_layer, margin_x, margin_y)

        if spec.sub:
            sub_y = margin_y + main_layer.height - 10
            sub_layer = render_text(spec.sub, STYLE_WHITE_SUB)
            paste_text(img, sub_layer, margin_x + 8, sub_y)

        logo = render_text("DEEP DIGGER", STYLE_BLUE_LOGO)
        paste_text(img, logo, W - logo.width - 42, H - logo.height - 38)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / f"deep_digger_thumb_{spec.out_name}_1920x1080.jpg"
    img.convert("RGB").save(out, "JPEG", quality=93, optimize=True, progressive=True)
    print(f"OK {out.name} ({out.stat().st_size // 1024} KB)")


def main() -> None:
    if not BG_DIR.exists() or not any(BG_DIR.glob("*.png")):
        print(f"No backgrounds in {BG_DIR}")
        return
    for spec in SPECS:
        compose(spec)
    print(f"\nDone -> {OUT_DIR}")


if __name__ == "__main__":
    main()
