# Roblox thumbnail text renderer — 3D extrude, gradient fill, heavy outline.

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT_DIR = Path(os.environ.get("WINDIR", r"C:\Windows")) / "Fonts"
FONT_IMPACT = FONT_DIR / "impact.ttf"
FONT_ARIAL_BLACK = FONT_DIR / "ariblk.ttf"
FONT_ARIAL_BOLD = FONT_DIR / "arialbd.ttf"


def _hex_rgb(color: str) -> tuple[int, int, int]:
    c = color.lstrip("#")
    return int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16)


def _lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def _font(size: int) -> ImageFont.FreeTypeFont:
    for path in (FONT_IMPACT, FONT_ARIAL_BLACK, FONT_ARIAL_BOLD):
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


@dataclass(frozen=True)
class TextStyle:
    size: int
    fill_top: str
    fill_bottom: str
    stroke: int
    stroke_color: str = "#141414"
    inner_stroke: int = 0
    inner_color: str = "#FFFFFF"
    depth: int = 7
    depth_color: str = "#8B4513"
    depth_dx: int = 1
    depth_dy: int = 2
    tilt_deg: float = -4.0
    badge: bool = False
    badge_fill: str = "#E53935"
    badge_pad_x: int = 28
    badge_pad_y: int = 14


STYLE_GOLD_HOOK = TextStyle(
    size=138,
    fill_top="#FFF59D",
    fill_bottom="#FF8F00",
    stroke=11,
    inner_stroke=2,
    depth=8,
    depth_color="#6D3A10",
    tilt_deg=-5.0,
)

STYLE_WHITE_SUB = TextStyle(
    size=72,
    fill_top="#FFFFFF",
    fill_bottom="#E0E0E0",
    stroke=9,
    depth=5,
    depth_color="#333333",
    tilt_deg=-4.0,
)

STYLE_BLUE_LOGO = TextStyle(
    size=94,
    fill_top="#B3E5FC",
    fill_bottom="#1565C0",
    stroke=10,
    stroke_color="#0A1628",
    inner_stroke=2,
    inner_color="#E1F5FE",
    depth=9,
    depth_color="#0A2A5E",
    tilt_deg=0.0,
)

STYLE_RED_BADGE = TextStyle(
    size=118,
    fill_top="#FFFFFF",
    fill_bottom="#FFEBEE",
    stroke=8,
    depth=6,
    depth_color="#7F0000",
    tilt_deg=-3.0,
    badge=True,
    badge_fill="#E53935",
    badge_pad_x=34,
    badge_pad_y=16,
)

STYLE_GREEN_HOOK = TextStyle(
    size=132,
    fill_top="#CCFF90",
    fill_bottom="#43A047",
    stroke=11,
    depth=8,
    depth_color="#2E5E20",
    tilt_deg=-5.0,
)

STYLE_CYAN_HOOK = TextStyle(
    size=132,
    fill_top="#84FFFF",
    fill_bottom="#00ACC1",
    stroke=11,
    depth=8,
    depth_color="#006064",
    tilt_deg=-4.0,
)

STYLE_ORANGE_HOOK = TextStyle(
    size=140,
    fill_top="#FFE082",
    fill_bottom="#FF6D00",
    stroke=11,
    depth=8,
    depth_color="#BF360C",
    tilt_deg=-5.0,
)

STYLE_PINK_HOOK = TextStyle(
    size=132,
    fill_top="#F8BBD0",
    fill_bottom="#E91E63",
    stroke=11,
    depth=8,
    depth_color="#880E4F",
    tilt_deg=-4.0,
)

STYLE_PURPLE_HOOK = TextStyle(
    size=132,
    fill_top="#E1BEE7",
    fill_bottom="#8E24AA",
    stroke=11,
    depth=8,
    depth_color="#4A148C",
    tilt_deg=-4.0,
)

STYLE_RED_HOOK = TextStyle(
    size=132,
    fill_top="#FF8A80",
    fill_bottom="#D50000",
    stroke=11,
    depth=8,
    depth_color="#7F0000",
    tilt_deg=-4.0,
)


def _measure(text: str, font: ImageFont.ImageFont, style: TextStyle) -> tuple[int, int]:
    tmp = Image.new("RGBA", (8, 8))
    d = ImageDraw.Draw(tmp)
    bbox = d.textbbox((0, 0), text, font=font, stroke_width=style.stroke)
    pad = style.stroke * 2 + style.depth + 28
    if style.badge:
        pad += style.badge_pad_x * 2
    return bbox[2] - bbox[0] + pad, bbox[3] - bbox[1] + pad


def _gradient_fill_mask(
    text: str,
    font: ImageFont.ImageFont,
    style: TextStyle,
    size: tuple[int, int],
    origin: tuple[int, int],
) -> Image.Image:
    w, h = size
    top = _hex_rgb(style.fill_top)
    bot = _hex_rgb(style.fill_bottom)

    grad = Image.new("RGB", (w, h))
    gp = grad.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        row = (_lerp(top[0], bot[0], t), _lerp(top[1], bot[1], t), _lerp(top[2], bot[2], t))
        for x in range(w):
            gp[x, y] = row

    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    ox, oy = origin
    md.text((ox, oy), text, font=font, fill=255, stroke_width=style.stroke, stroke_fill=255)

    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(grad, mask=mask)
    return out


def render_text(text: str, style: TextStyle) -> Image.Image:
    font = _font(style.size)
    w, h = _measure(text, font, style)
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    ox, oy = 12 + style.depth, 12 + style.depth

    if style.badge:
        bbox = draw.textbbox((ox, oy), text, font=font, stroke_width=style.stroke)
        draw.rounded_rectangle(
            (
                bbox[0] - style.badge_pad_x,
                bbox[1] - style.badge_pad_y,
                bbox[2] + style.badge_pad_x,
                bbox[3] + style.badge_pad_y,
            ),
            radius=20,
            fill=_hex_rgb(style.badge_fill),
            outline=_hex_rgb(style.stroke_color),
            width=5,
        )

    dc = _hex_rgb(style.depth_color)
    for i in range(style.depth, 0, -1):
        draw.text((ox + i * style.depth_dx, oy + i * style.depth_dy), text, font=font, fill=dc)

    sc = _hex_rgb(style.stroke_color)
    draw.text(
        (ox, oy),
        text,
        font=font,
        fill=sc,
        stroke_width=style.stroke,
        stroke_fill=sc,
    )

    fill_layer = _gradient_fill_mask(text, font, style, (w, h), (ox, oy))
    layer = Image.alpha_composite(layer, fill_layer)

    if style.inner_stroke > 0:
        draw = ImageDraw.Draw(layer)
        ic = _hex_rgb(style.inner_color)
        draw.text(
            (ox, oy),
            text,
            font=font,
            fill=(0, 0, 0, 0),
            stroke_width=style.inner_stroke,
            stroke_fill=(*ic, 200),
        )

    if style.tilt_deg:
        layer = layer.rotate(style.tilt_deg, resample=Image.Resampling.BICUBIC, expand=True)
    return layer


def paste_text(base: Image.Image, layer: Image.Image, x: int, y: int) -> None:
    base.alpha_composite(layer, (x, y))


def hook_style_for(text: str, default: TextStyle = STYLE_GOLD_HOOK) -> TextStyle:
    t = text.upper()
    if t.startswith("["):
        return STYLE_RED_BADGE
    if "HOW DEEP" in t:
        return STYLE_CYAN_HOOK
    if "DIG DEEPER" in t or "GET RICH" in t or "SELL" in t or "COINS" in t:
        return STYLE_GOLD_HOOK
    if "FREE" in t or "PLAY" in t:
        return STYLE_GREEN_HOOK
    if "REBIRTH" in t or "CRITICAL" in t or "MYTHIC" in t:
        return STYLE_ORANGE_HOOK
    if "VIP" in t or "ORES" in t:
        return STYLE_GOLD_HOOK
    if "PET" in t:
        return STYLE_PURPLE_HOOK
    if "GIFT" in t or "EGG" in t or "LUCKY" in t:
        return STYLE_PINK_HOOK
    if "TOP" in t or "2X" in t or "LUCK" in t:
        return STYLE_CYAN_HOOK
    return default
