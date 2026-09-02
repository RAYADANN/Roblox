# Generate Ben-Day overlay grids for Aim Map 1v1
# 1024² PNG — Roblox import-safe (no forced downscale), high DPI for UI.
# White dots + alpha → tint with ImageColor3.

from __future__ import annotations

import math
import os
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "ui", "benday")
OUT = os.path.normpath(OUT)
SIZE = 1024


def clamp01(x: float) -> float:
    if x < 0.0:
        return 0.0
    if x > 1.0:
        return 1.0
    return float(x)


def fade_y(y: int, mode: str, size: int, soft: float = 0.9) -> float:
    t = clamp01(y / float(size - 1))
    if mode == "top_transparent":
        a = t**1.2
    elif mode == "bottom_transparent":
        a = (1.0 - t) ** 1.2
    elif mode == "center":
        a = (1.0 - abs(t - 0.5) * 2.0) ** 0.85
    elif mode == "edges":
        a = (abs(t - 0.5) * 2.0) ** 0.9
    else:
        a = 1.0
    return clamp01(a) * soft


def stamp_dot(px, w: int, h: int, cx: int, cy: int, radius: float, alpha: float) -> None:
    ir = int(math.ceil(radius)) + 1
    r_inner = max(0.0, radius - 0.85)
    for dy in range(-ir, ir + 1):
        for dx in range(-ir, ir + 1):
            x = cx + dx
            y = cy + dy
            if x < 0 or y < 0 or x >= w or y >= h:
                continue
            d = math.hypot(dx, dy)
            if d > radius + 0.6:
                continue
            if d <= r_inner:
                edge = 1.0
            else:
                edge = clamp01(1.0 - (d - r_inner) / max(0.001, (radius + 0.6) - r_inner))
            a = int(255 * alpha * edge)
            if a <= 0:
                continue
            _r, _g, _b, oa = px[x, y]
            na = oa + a - (oa * a) // 255
            px[x, y] = (255, 255, 255, na)


def draw_grid(
    img: Image.Image,
    angle_deg: float,
    spacing: float,
    radius: float,
    fade_mode: str,
    alpha_mul: float = 0.85,
    offset: tuple[float, float] = (0.0, 0.0),
) -> None:
    w, h = img.size
    px = img.load()
    ang = math.radians(angle_deg)
    ca, sa = math.cos(ang), math.sin(ang)
    pad = spacing * 2.0 + radius * 2.0

    corners = [(0.0, 0.0), (float(w), 0.0), (0.0, float(h)), (float(w), float(h))]

    def to_uv(x: float, y: float) -> tuple[float, float]:
        return (x * ca + y * sa, -x * sa + y * ca)

    uvs = [to_uv(x, y) for x, y in corners]
    min_u = min(u for u, _ in uvs) - pad
    max_u = max(u for u, _ in uvs) + pad
    min_v = min(v for _, v in uvs) - pad
    max_v = max(v for _, v in uvs) + pad

    u0 = math.floor((min_u + offset[0]) / spacing) * spacing
    v0 = math.floor((min_v + offset[1]) / spacing) * spacing

    u = u0
    while u <= max_u + 0.001:
        v = v0
        while v <= max_v + 0.001:
            x = u * ca - v * sa
            y = u * sa + v * ca
            cx = int(round(x))
            cy = int(round(y))
            if -radius - 2 <= cx < w + radius + 2 and -radius - 2 <= cy < h + radius + 2:
                cy_fade = min(h - 1, max(0, cy))
                fa = fade_y(cy_fade, fade_mode, h) * alpha_mul
                if fa > 0.015:
                    stamp_dot(px, w, h, cx, cy, radius, fa)
            v += spacing
        u += spacing


SPECS: list[tuple[str, list[dict]]] = [
    (
        "benday_01_45_fade_top.png",
        [dict(angle=45, spacing=18, radius=4.4, fade="top_transparent", alpha=0.9)],
    ),
    (
        "benday_02_45_fade_bottom.png",
        [dict(angle=45, spacing=18, radius=4.4, fade="bottom_transparent", alpha=0.9)],
    ),
    (
        "benday_03_horiz_fade_top.png",
        [dict(angle=0, spacing=16, radius=4.1, fade="top_transparent", alpha=0.92)],
    ),
    (
        "benday_04_horiz_fade_bottom.png",
        [dict(angle=0, spacing=16, radius=4.1, fade="bottom_transparent", alpha=0.92)],
    ),
    (
        "benday_05_neg45_fade_top.png",
        [dict(angle=-45, spacing=18, radius=4.4, fade="top_transparent", alpha=0.9)],
    ),
    (
        "benday_06_neg45_fade_bottom.png",
        [dict(angle=-45, spacing=18, radius=4.4, fade="bottom_transparent", alpha=0.9)],
    ),
    (
        "benday_07_double_cross.png",
        [
            dict(angle=45, spacing=20, radius=3.7, fade="top_transparent", alpha=0.75),
            dict(angle=-45, spacing=20, radius=3.7, fade="top_transparent", alpha=0.55, offset=(10.0, 0.0)),
        ],
    ),
    (
        "benday_08_double_ortho.png",
        [
            dict(angle=0, spacing=18, radius=3.5, fade="bottom_transparent", alpha=0.72),
            dict(angle=90, spacing=18, radius=3.5, fade="bottom_transparent", alpha=0.55, offset=(0.0, 9.0)),
        ],
    ),
    (
        "benday_09_fine_double_offset.png",
        [
            dict(angle=30, spacing=12, radius=2.7, fade="top_transparent", alpha=0.78),
            dict(angle=30, spacing=12, radius=2.3, fade="top_transparent", alpha=0.48, offset=(6.0, 6.0)),
        ],
    ),
    (
        "benday_10_coarse_dual_fade.png",
        [
            dict(angle=45, spacing=28, radius=7.2, fade="top_transparent", alpha=0.82),
            dict(angle=-20, spacing=22, radius=3.3, fade="bottom_transparent", alpha=0.52, offset=(8.0, 4.0)),
        ],
    ),
]


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for name, layers in SPECS:
        img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        for L in layers:
            draw_grid(
                img,
                angle_deg=float(L["angle"]),
                spacing=float(L["spacing"]),
                radius=float(L["radius"]),
                fade_mode=str(L["fade"]),
                alpha_mul=float(L.get("alpha", 0.85)),
                offset=tuple(L.get("offset", (0.0, 0.0))),  # type: ignore[arg-type]
            )
        path = os.path.join(OUT, name)
        img.save(path, "PNG", optimize=True)
        bb = img.getchannel("A").getbbox()
        print(f"{name}  {SIZE}x{SIZE}  bbox={bb}  bytes={os.path.getsize(path)}")
    print("OUT", OUT)


if __name__ == "__main__":
    main()
