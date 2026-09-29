#!/usr/bin/env python3
"""Export AI thumbnails to 1920x1080 with safe-zone padding (no edge crop)."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter

W, H = 1920, 1080
MARGIN = 0.09  # ~9% safe zone — text stays inside Roblox crop

SRC = Path(r"C:\Users\59045\.cursor\projects\c-Projects-Roblox-Mining\assets")
OUT = Path(__file__).resolve().parents[1] / "assets" / "marketing" / "thumbnails_ai"

FILES = [
    ("ai_thumb_01_pets.png", "01_pets_hatch"),
    ("ai_thumb_02_rebirth.png", "02_rebirth"),
    ("ai_thumb_03_dig.png", "03_dig_deeper"),
    ("ai_thumb_04_play.png", "04_play_now"),
    ("ai_thumb_05_rare.png", "05_rare_ore"),
    ("ai_thumb_06_pov.png", "06_pov"),
    ("ai_thumb_07_ores.png", "07_50_ores"),
    ("ai_thumb_08_layer.png", "08_new_layer"),
    ("ai_thumb_09_depth.png", "09_how_deep"),
    ("ai_thumb_10_daily.png", "10_daily"),
    ("ai_thumb_11_gift.png", "11_free_gift"),
    ("ai_thumb_12_egg.png", "12_lucky_egg"),
    ("ai_thumb_13_sell.png", "13_sell_ore"),
    ("ai_thumb_14_top.png", "14_top_10"),
    ("ai_thumb_15_vip.png", "15_vip"),
    ("ai_thumb_16_crit.png", "16_crit"),
    ("ai_thumb_17_luck.png", "17_2x_luck"),
    ("ai_thumb_18_mythic.png", "18_mythic"),
    ("ai_thumb_19_logo.png", "19_minimal"),
    ("ai_thumb_20_upd.png", "20_upd"),
]


def export_safe(img: Image.Image) -> Image.Image:
    img = img.convert("RGB")
    mx = int(W * MARGIN)
    my = int(H * MARGIN)
    inner_w, inner_h = W - 2 * mx, H - 2 * my

    scale = min(inner_w / img.width, inner_h / img.height)
    nw = max(1, int(img.width * scale))
    nh = max(1, int(img.height * scale))
    fitted = img.resize((nw, nh), Image.Resampling.LANCZOS)

    bg = img.resize((W, H), Image.Resampling.LANCZOS).filter(ImageFilter.GaussianBlur(28))
    bg = ImageEnhance.Brightness(bg).enhance(0.35)
    bg = ImageEnhance.Contrast(bg).enhance(1.1)

    canvas = bg.copy()
    canvas.paste(fitted, ((W - nw) // 2, (H - nh) // 2))
    return canvas


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for src_name, base in FILES:
        path = SRC / src_name
        if not path.exists():
            print("MISSING", src_name)
            continue
        out = OUT / f"deep_digger_thumb_{base}_1920x1080.jpg"
        export_safe(Image.open(path)).save(
            out, "JPEG", quality=92, optimize=True, progressive=True
        )
        print(f"OK {out.name} ({out.stat().st_size // 1024} KB)")
    print("done", OUT)


if __name__ == "__main__":
    main()
