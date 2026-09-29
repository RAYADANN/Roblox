#!/usr/bin/env python3
"""One-shot splitter: MiningRenderer.lua -> mining/*.lua modules."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src/client/core/MiningRenderer.lua"
OUT = ROOT / "src/client/core/mining"

GROUPS: dict[str, list[str]] = {
    "Origin": [
        "_markerOrigin",
        "_blockWorldPos",
        "_repositionAllBlocks",
        "_resolveOrigin",
        "_fallbackOrigin",
        "_mineOrigin",
    ],
    "Raycast": [
        "_raycastParams",
        "_obstacleRayParams",
        "_playerRoot",
        "_withinMineReach",
        "_pickBlockFromHit",
        "_raycastMine",
        "_raycastBlockPart",
        "isEnabled",
        "_refreshMineRaycastSanitize",
    ],
    "Hover": [
        "_hoverEnter",
        "_hoverLeave",
        "_ensureCursorLight",
        "_applyCursorLight",
        "_destroyCursorLight",
        "_updateHover",
        "_setupInput",
        "_teardownInput",
        "_makeHPBar",
        "_updateHPBar",
        "_ensureHPBar",
        "_ensureRarityTag",
        "_dmgNumber",
        "_critEffect",
    ],
    "Decor": [
        "_decorDef",
        "_shellFaceNormal",
        "_shellOpenFaceNormals",
        "_forEachShellFace",
        "_shellHitPulse",
        "_decorVisConfig",
        "_decorCameraBasis",
        "_reconcileNeighborShells",
        "_refreshVisibleShells",
        "_addShell",
        "_reconcileShellFaces",
        "_ambientFXOrigin",
        "_detachAmbientFX",
        "_oreFXPalette",
        "_tintAmbientFXHolder",
        "_ensureAmbientFXTinted",
        "_resolveOreGlow",
        "_detachOreGlow",
        "_syncOreGlow",
        "_attachOreGlow",
        "_attachAmbientFX",
        "_detachShell",
        "_cleanupStaleOreShell",
        "_syncDecorFlag",
        "_stripFarDecorations",
        "_isFillerOre",
        "_refreshBlockDecorations",
    ],
    "Combat": ["_hitParticles", "_breakEffect", "_animateDestroy", "_onClick"],
    "Sync": [
        "_queueCreate",
        "_clearCreateQueue",
        "_clearDestroyQueue",
        "_queueFastDestroy",
        "_drainDestroyQueue",
        "_drainCreateQueue",
        "applySnapshot",
        "applyDelta",
        "syncBlocks",
    ],
    "Core": [
        "new",
        "setSwingDelay",
        "_folder",
        "_isStale",
        "_createPart",
        "_destroyPart",
        "_updateVisual",
        "toggleRarity",
        "toggleHPBar",
        "start",
        "stop",
    ],
}

MODULE_HEADERS: dict[str, str] = {
    "Origin": "--!strict\n-- Origin: MineZoneMarker anchor + block world positions.\n",
    "Raycast": "--!strict\n-- Raycast: mine targeting from camera / touch.\n",
    "Hover": "--!strict\n-- Hover: highlight, HP bars, cursor light, input, damage numbers.\n",
    "Decor": "--!strict\n-- Decor: ore shells, glow, ambient FX (proximity budget).\n",
    "Combat": "--!strict\n-- Combat: hit feedback, break FX, mine invoke.\n",
    "Sync": "--!strict\n-- Sync: snapshot/delta + create/destroy queues.\n",
    "Core": "--!strict\n-- Core: lifecycle, part create/destroy, toggles.\n",
}


def main() -> None:
    text = SRC.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    methods: list[tuple[str, int]] = []
    for i, line in enumerate(lines):
        m = re.match(r"^function MiningRenderer:([^(]+)\(", line)
        if m:
            methods.append((m.group(1), i))
    methods.append(("__END__", len(lines)))

    name_to_group: dict[str, str] = {}
    for group, names in GROUPS.items():
        for name in names:
            name_to_group[name] = group

    by_group: dict[str, list[str]] = {g: [] for g in GROUPS}
    for (name, start), (_, end) in zip(methods, methods[1:]):
        group = name_to_group.get(name, "UNASSIGNED")
        body = "".join(lines[start:end])
        by_group.setdefault(group, []).append(body)

    unassigned = [methods[i][0] for i in range(len(methods) - 1) if methods[i][0] not in name_to_group]
    if unassigned:
        raise SystemExit(f"Unassigned methods: {unassigned}")

    OUT.mkdir(parents=True, exist_ok=True)

    for group, bodies in by_group.items():
        if not bodies:
            continue
        out_path = OUT / f"{group}.lua"
        content = MODULE_HEADERS.get(group, "--!strict\n")
        content += "\nlocal MiningRenderer = {}\n\n"
        content += "".join(bodies)
        content += "\nreturn MiningRenderer\n"
        out_path.write_text(content, encoding="utf-8")
        print(f"wrote {out_path.name}: {content.count(chr(10))} lines")

    # preamble before first method (imports, constants, juice, types)
    first_method_line = methods[0][1]
    preamble = "".join(lines[:first_method_line])
    (OUT / "_preamble.txt").write_text(preamble, encoding="utf-8")
    print(f"preamble: {preamble.count(chr(10))} lines")


if __name__ == "__main__":
    main()
