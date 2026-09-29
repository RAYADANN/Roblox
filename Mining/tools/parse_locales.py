"""Line-based locale block parser for strings/*.lua."""
import re
from pathlib import Path

ENTRY = re.compile(r'^\t\t\["([^"]+)"\]\s*=\s*"(.*)",?\s*$')
LOCALE_START = re.compile(r'^\t([a-z][a-z\-]*)\s*=\s*\{\s*$')

root = Path(__file__).resolve().parents[1] / "src/shared/loc/strings"
total = 0
for f in sorted(root.glob("*.lua")):
    if f.name == "init.lua":
        continue
    lines = f.read_text(encoding="utf-8").splitlines()
    locale = None
    counts: dict[str, int] = {}
    for line in lines:
        sm = LOCALE_START.match(line)
        if sm:
            locale = sm.group(1)
            counts[locale] = 0
            continue
        if locale and line.strip() == "},":
            locale = None
            continue
        if locale:
            em = ENTRY.match(line)
            if em:
                counts[locale] = counts.get(locale, 0) + 1
    for loc, n in sorted(counts.items()):
        if loc == "en":
            total += n
        print(f"{f.name:20} {loc:4} {n}")
print("total en:", total)
