import math

BASE_SWING = 0.4
MIN_SWING = 0.05
PENALTY = 0.35
POWER_PER = 1.5
SPEED_RED = 0.03

LAYER_HP_MULT = {
    "dirt": 1.0, "stone": 1.75, "limestone": 1.8, "crimson": 1.85,
    "marble": 1.9, "obsidian": 2.0, "void": 2.0,
}
DEPTH_BONUS = 0.004
LAYER_START = {"dirt": 0, "stone": 50, "limestone": 150, "crimson": 300, "marble": 500, "obsidian": 800, "void": 1200}

layers = [
    ("dirt", 0, 49, 2, 3, 1),
    ("stone", 50, 149, 8, 6, 5),
    ("limestone", 150, 299, 20, 18, 12),
    ("crimson", 300, 499, 50, 40, 22),
    ("marble", 500, 799, 80, 70, 35),
    ("obsidian", 800, 1199, 150, 150, 50),
    ("void", 1200, 99999, 300, 500, 70),
]


def pickaxe_power(l):
    return 1 + (max(1, l) - 1) * POWER_PER


def swing_delay(s):
    return max(MIN_SWING, BASE_SWING * ((1 - SPEED_RED) ** (max(1, s) - 1)))


def scaled_hp(base, layer, depth):
    lm = LAYER_HP_MULT[layer]
    din = max(0, depth - LAYER_START[layer])
    return max(1, round(base * lm * (1 + din * DEPTH_BONUS)))


def hits(hp, dmg):
    return math.ceil(hp / max(dmg, 0.001))


def effective_dmg(pickaxe, min_px):
    dmg = pickaxe_power(pickaxe)
    if pickaxe < min_px:
        dmg *= PENALTY
    return dmg


def block_time(hp, pickaxe, speed, min_px):
    return hits(hp, effective_dmg(pickaxe, min_px)) * swing_delay(speed)


print("=== NEW BALANCE: scaled filler HP (top / mid layer depth) ===")
for name, d0, d1, base_hp, val, min_px in layers:
    top = scaled_hp(base_hp, name, d0)
    mid = scaled_hp(base_hp, name, (d0 + min(d1, d0 + 50)) // 1)
    if d1 < 99999:
        bot = scaled_hp(base_hp, name, d1)
    else:
        bot = scaled_hp(base_hp, name, 1400)
    print(f"  {name:12} base {base_hp:3} -> top {top:4}  mid~{mid:4}  deep {bot:4}")

print("\n=== Time per block @ layer entry (P10/S10, min pickaxe) ===")
for name, d0, d1, base_hp, val, min_px in layers:
    hp = scaled_hp(base_hp, name, d0)
    t = block_time(hp, max(10, min_px), 10, min_px)
    cpm = val / t * 60
    print(f"  {name:12} HP={hp:4}  {t:.2f}s/block  ~{cpm:.0f} coins/min")

print("\n=== Time per block @ layer deep (P20/S20, min pickaxe) ===")
for name, d0, d1, base_hp, val, min_px in layers:
    depth = min(d1, d0 + 80) if d1 < 99999 else 1400
    hp = scaled_hp(base_hp, name, depth)
    t = block_time(hp, max(20, min_px), 20, min_px)
    print(f"  {name:12} depth {depth:4} HP={hp:4}  {t:.2f}s/block")

print("\n=== Pickaxe power milestones ===")
for l in [1, 2, 5, 10, 15, 20]:
    print(f"  L{l:2}: power={pickaxe_power(l):.1f}  swing@L{l}={swing_delay(l):.3f}s")

print("\n=== Under-leveled in stone (P3, stone entry HP) ===")
hp = scaled_hp(8, "stone", 50)
for p in [3, 4, 5]:
    t = block_time(hp, p, 1, 5)
    print(f"  pickaxe L{p}: {hits(hp, effective_dmg(p, 5))} hits, {t:.2f}s (penalty={PENALTY})")
