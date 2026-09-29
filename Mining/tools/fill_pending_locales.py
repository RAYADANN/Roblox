#!/usr/bin/env python3
"""Fill missing locale blocks in specific files only."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sync_locales import ORDER, TARGETS, parse_locales, process_standard  # noqa: E402

ROOT = Path(__file__).resolve().parents[1] / "src/shared/loc/strings"
PENDING = [
    "panels.lua",
    "pets.lua",
    "playerTag.lua",
    "server.lua",
    "shopSections.lua",
    "stragglers.lua",
    "tutorial.lua",
    "upgrades.lua",
]

for name in PENDING:
    path = ROOT / name
    locales = parse_locales(path.read_text(encoding="utf-8"))
    key_order = list(locales["en"].keys())
    if all(all(k in locales.get(loc, {}) for k in key_order) for loc in TARGETS):
        print(f"skip {name}: complete")
        continue
    process_standard(path)
print("pending done")
