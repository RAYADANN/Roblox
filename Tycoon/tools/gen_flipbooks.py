from PIL import Image, ImageDraw, ImageFilter
import math
import os

OUT_DIR = r"C:\Projects\Roblox\roblox-starter\assets\vfx"
os.makedirs(OUT_DIR, exist_ok=True)

CELL = 128
GRID = 4
SIZE = CELL * GRID


def make_neon_frame(frame: int) -> Image.Image:
	img = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	t = frame / 15.0
	if t < 0.35:
		scale = t / 0.35
		alpha = int(255 * (0.5 + 0.5 * scale))
		r = int(8 + 42 * scale)
	elif t < 0.7:
		scale = (t - 0.35) / 0.35
		alpha = int(255 * (1.0 - 0.25 * scale))
		r = int(50 + 18 * scale)
	else:
		scale = (t - 0.7) / 0.3
		alpha = int(220 * (1.0 - scale))
		r = int(68 + 20 * scale)

	cx = cy = CELL // 2
	for i in range(4, 0, -1):
		rr = r + i * 8
		a = max(0, int(alpha * 0.12 * i / 4))
		d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(255, 40, 200, a))
	d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(80, 230, 255, max(0, alpha)))
	cr = max(2, int(r * 0.35))
	d.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(255, 255, 255, max(0, min(255, alpha + 40))))
	if 0.25 < t < 0.85:
		for k in range(3):
			ang = frame * 0.7 + k * 2.1
			x2 = cx + int(math.cos(ang) * (r + 18))
			y2 = cy + int(math.sin(ang) * (r + 18))
			d.line([(cx, cy), (x2, y2)], fill=(180, 255, 255, max(0, alpha // 2)), width=2)
	glow = img.filter(ImageFilter.GaussianBlur(radius=1.5))
	return Image.alpha_composite(glow, img)


def make_smoke_frame(frame: int) -> Image.Image:
	img = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	t = frame / 15.0
	cx = cy = CELL // 2
	base_r = int(10 + 50 * t)
	alpha = int(200 * (1.0 - t * 0.85))
	offsets = [(0, 0), (-10, 6), (12, -8), (-6, -12), (8, 10)]
	for i, (ox, oy) in enumerate(offsets):
		rr = int(base_r * (0.55 + 0.12 * i))
		a = max(0, int(alpha * (0.9 - i * 0.12)))
		d.ellipse([cx + ox - rr, cy + oy - rr, cx + ox + rr, cy + oy + rr], fill=(35, 40, 48, a))
		d.ellipse(
			[cx + ox - rr + 4, cy + oy - rr + 4, cx + ox + rr - 4, cy + oy + rr - 4],
			fill=(70, 78, 88, max(0, a // 2)),
		)
	if t < 0.45:
		for k in range(5):
			ang = frame * 0.5 + k
			sx = cx + int(math.cos(ang) * (12 + t * 30))
			sy = cy + int(math.sin(ang) * (12 + t * 30))
			d.ellipse([sx - 2, sy - 2, sx + 2, sy + 2], fill=(255, 160, 60, int(180 * (1 - t))))
	return img.filter(ImageFilter.GaussianBlur(radius=1.2))


def make_spark_frame(frame: int) -> Image.Image:
	img = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	t = frame / 15.0
	cx = cy = CELL // 2
	if t < 0.2:
		a = int(255 * (t / 0.2))
		r = 4 + int(10 * t / 0.2)
	elif t < 0.55:
		a = 255
		r = 14 + int(20 * (t - 0.2) / 0.35)
	else:
		u = (t - 0.55) / 0.45
		a = int(255 * (1 - u))
		r = 34 + int(12 * u)
	for i in range(6):
		ang = i * math.pi / 3 + frame * 0.15
		x2 = cx + int(math.cos(ang) * r)
		y2 = cy + int(math.sin(ang) * r)
		d.line([(cx, cy), (x2, y2)], fill=(255, 240, 180, max(0, a)), width=2)
		d.ellipse([x2 - 2, y2 - 2, x2 + 2, y2 + 2], fill=(255, 200, 80, max(0, a)))
	d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 255, 255, a))
	return img.filter(ImageFilter.GaussianBlur(1.0))


def make_ember_frame(frame: int) -> Image.Image:
	img = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	t = frame / 15.0
	cx = cy = CELL // 2
	lift = int(t * 40)
	a = int(220 * (1 - t * 0.85))
	for i, ox in enumerate([-14, -6, 0, 7, 14]):
		yy = cy + 20 - lift - i * 3
		rr = 6 + int((1 - t) * 8 * (0.6 + 0.1 * i))
		d.ellipse([cx + ox - rr, yy - rr, cx + ox + rr, yy + rr], fill=(255, 90 + 10 * i, 30, max(0, a - i * 20)))
		d.ellipse(
			[cx + ox - rr // 2, yy - rr // 2, cx + ox + rr // 2, yy + rr // 2],
			fill=(255, 220, 120, max(0, a // 2)),
		)
	return img.filter(ImageFilter.GaussianBlur(0.8))


def build_atlas(frame_fn, path: str) -> None:
	atlas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	for i in range(16):
		fr = frame_fn(i)
		x = (i % GRID) * CELL
		y = (i // GRID) * CELL
		atlas.paste(fr, (x, y), fr)
	atlas.save(path)
	print("wrote", path, atlas.size)


build_atlas(make_neon_frame, os.path.join(OUT_DIR, "neon_burst_4x4.png"))
build_atlas(make_smoke_frame, os.path.join(OUT_DIR, "smoke_puff_4x4.png"))
build_atlas(make_spark_frame, os.path.join(OUT_DIR, "spark_burst_4x4.png"))
build_atlas(make_ember_frame, os.path.join(OUT_DIR, "ember_trail_4x4.png"))
print("done")
