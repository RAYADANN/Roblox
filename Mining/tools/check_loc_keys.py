import re
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "src/shared/loc/strings"
LOCALE_START = re.compile(r"^\t([a-z][a-z\-]*)\s*=\s*\{\s*$")
ENTRY_RE = re.compile(r'^\t\t\["([^"]+)"\]\s*=')

catalogs: dict[str, dict[str, str]] = {}

for f in sorted(root.glob("*.lua")):
    if f.name == "init.lua":
        continue
    locale = None
    for line in f.read_text(encoding="utf-8").splitlines():
        sm = LOCALE_START.match(line)
        if sm:
            locale = sm.group(1)
            catalogs.setdefault(locale, {})
            continue
        if locale and line.strip() == "},":
            locale = None
            continue
        if locale:
            em = ENTRY_RE.match(line)
            if em:
                catalogs[locale][em.group(1)] = f.name

base = catalogs.get("en", {})
print(f"en keys: {len(base)}")
for loc, keys in sorted(catalogs.items()):
    if loc == "en":
        continue
    missing = sorted(set(base) - set(keys))
    extra = sorted(set(keys) - set(base))
    print(f"{loc}: {len(keys)} missing={len(missing)} extra={len(extra)}")
    for k in missing[:5]:
        print(f"  MISSING {loc}: {k} ({base[k]})")
    if len(missing) > 5:
        print(f"  ... +{len(missing)-5} more")
