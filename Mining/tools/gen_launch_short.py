#!/usr/bin/env python3
"""Build a 9:16 launch short from static marketing assets (TikTok / Shorts / Reels)."""

from __future__ import annotations

import math
from pathlib import Path

import imageio.v3 as iio
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "marketing" / "v2"
OUT = ROOT / "assets" / "marketing" / "deep_digger_launch_short_9x16.mp4"

W, H = 1080, 1920
FPS = 30

SCENES: tuple[tuple[str, str, float], ...] = (
    ("deep_digger_thumbnail_main_1920x1080.jpg", "POV: you hit MYTHIC ore", 4.0),
    ("deep_digger_thumbnail_pets_1920x1080.jpg", "Hatch 30+ pets", 4.0),
    ("deep_digger_thumbnail_pov_1920x1080.jpg", "REBIRTH = x100 income", 4.0),
    ("deep_digger_icon_512x512.png.png", "How deep can YOU go?", 3.5),
)

FONT_CANDIDATES = (
    "C:/Windows/Fonts/arialbd.ttf",
    "C:/Windows/Fonts/segoeuib.ttf",
    "C:/Windows/Fonts/arial.ttf",
)


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in FONT_CANDIDATES:
        if Path(path).is_file():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def cover_crop(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    src_w, src_h = img.size
    scale = max(target_w / src_w, target_h / src_h)
    resized = img.resize((int(src_w * scale), int(src_h * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - target_w) // 2
    top = (resized.height - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))


def draw_scene(base: Image.Image, headline: str, subline: str | None = None) -> Image.Image:
    frame = base.copy()
    overlay = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    draw.rectangle((0, H - 420, W, H), fill=(0, 0, 0, 170))
    draw.rectangle((0, 0, W, 140), fill=(0, 0, 0, 120))

    title_font = load_font(72)
    sub_font = load_font(48)
    brand_font = load_font(40)

    draw.text((48, 36), "DEEP DIGGER", font=brand_font, fill=(255, 220, 80, 255))

    bbox = draw.textbbox((0, 0), headline, font=title_font)
    tw = bbox[2] - bbox[0]
    draw.text(((W - tw) // 2, H - 340), headline, font=title_font, fill=(255, 255, 255, 255))

    if subline:
        sb = draw.textbbox((0, 0), subline, font=sub_font)
        sw = sb[2] - sb[0]
        draw.text(((W - sw) // 2, H - 240), subline, font=sub_font, fill=(180, 255, 180, 255))

    cta = "Play on Roblox — link in bio"
    cb = draw.textbbox((0, 0), cta, font=sub_font)
    cw = cb[2] - cb[0]
    draw.text(((W - cw) // 2, H - 120), cta, font=sub_font, fill=(255, 255, 255, 220))

    return Image.alpha_composite(frame.convert("RGBA"), overlay).convert("RGB")


def ken_burns(img: Image.Image, progress: float, zoom_in: bool) -> Image.Image:
    t = progress if zoom_in else 1.0 - progress
    scale = 1.0 + 0.08 * t
    crop_w = int(W / scale)
    crop_h = int(H / scale)
    covered = cover_crop(img, crop_w, crop_h)
    return covered.resize((W, H), Image.Resampling.LANCZOS)


def render_frames() -> list[np.ndarray]:
    frames: list[np.ndarray] = []
    sublines = (None, "Eggs & rarity tiers", "Prestige loop", "Zeon Studio")

    for (filename, headline, duration), subline in zip(SCENES, sublines):
        path = ASSETS / filename
        if not path.is_file():
            alt = ASSETS / filename.replace(".jpg", ".png")
            path = alt if alt.is_file() else path
        if not path.is_file():
            raise FileNotFoundError(f"Missing asset: {filename}")

        source = Image.open(path).convert("RGB")
        base = cover_crop(source, W, H)
        composed = draw_scene(base, headline, subline)
        frame_count = max(1, int(duration * FPS))

        for i in range(frame_count):
            progress = i / max(frame_count - 1, 1)
            zoom_in = (len(frames) // FPS) % 2 == 0
            frame = ken_burns(composed, progress, zoom_in)
            frames.append(np.asarray(frame))

    return frames


def main() -> None:
    frames = render_frames()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    iio.imwrite(OUT, frames, fps=FPS, codec="libx264", pixelformat="yuv420p")
    print(f"Wrote {len(frames)} frames -> {OUT}")
    print(f"Duration: {len(frames) / FPS:.1f}s @ {W}x{H}")


if __name__ == "__main__":
    main()
