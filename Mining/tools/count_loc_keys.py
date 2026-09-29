import re
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "src/shared/loc/strings"
en: dict[str, str] = {}
for f in sorted(root.glob("*.lua")):
    if f.name == "init.lua":
        continue
    text = f.read_text(encoding="utf-8")
    m = re.search(r'\["en"\]\s*=\s*\{(.*?)\n\t\}', text, re.S)
    if not m:
        continue
    for key in re.findall(r'\["([^"]+)"\]\s*=', m.group(1)):
        en[key] = f.name
print("en keys:", len(en))
