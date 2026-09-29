#!/usr/bin/env python3
"""Finalize MiningRenderer split: Shared.lua + module imports + thin facade."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src/client/core/MiningRenderer.lua"
MINING = ROOT / "src/client/core/mining"
PREAMBLE = MINING / "_preamble.txt"

SHARED_NAMES = [
    "RAYCAST_MAX_DISTANCE",
    "ORIGIN_WAIT_TIMEOUT",
    "CREATE_BUDGET_PER_FRAME",
    "DESTROY_BUDGET_PER_FRAME",
    "FAST_REMOVE_THRESHOLD",
    "PERF",
    "perfPublish",
    "parseKey",
    "BS",
    "BSv",
    "HOVER_BSv",
    "BREAK_CHUNK_COUNT",
    "BREAK_DUST_COUNT",
    "BREAK_CHUNK_SPEED",
    "SHOCKWAVE_BY_RARITY",
    "MAX_ORE_GLOWS",
    "smoothSurfaces",
    "FILLER_WEIGHT",
    "MAX_VISIBLE_SHELLS",
    "DECOR_RANGE",
    "DECOR_FOV_ATTACH",
    "DECOR_FOV_KEEP",
    "DECOR_FOV_WEIGHT",
    "AMBIENT_FX_FOLDER",
    "AMBIENT_FX_HOLDER",
    "AMBIENT_FX_RARITY",
    "AMBIENT_FX_RANGE",
    "SHELL_RANGE",
    "AMBIENT_FX_TICK",
    "MAX_AMBIENT_FX",
    "DECOR_CAM_MOVE_THRESHOLD",
    "shockwave",
    "chunkBurst",
    "dustCloud",
    "coinPop",
    "blockSquash",
    "formatHP",
    "appendMiningRaycastExcludes",
    "TweenService",
    "Debris",
    "Players",
    "RunService",
    "UserInputService",
    "ReplicatedStorage",
    "Logger",
    "Constants",
    "LayerProfile",
    "UpgradeLogic",
    "PerfBeacon",
    "OreFXPalette",
    "OreBlockDecor",
    "MutationLogic",
    "MiningBlockDecor",
    "MiningReach",
    "MineZoneWorkspace",
    "Net",
    "OreLookup",
    "NumberFormat",
    "SoundManager",
    "CameraShake",
    "Haptics",
    "UiAssets",
]

MODULE_IMPORTS: dict[str, list[str]] = {
    "Origin": ["BS", "parseKey", "ORIGIN_WAIT_TIMEOUT", "OreLookup"],
    "Raycast": [
        "RAYCAST_MAX_DISTANCE",
        "appendMiningRaycastExcludes",
        "PerfBeacon",
        "MiningReach",
        "Players",
        "UserInputService",
        "MineZoneWorkspace",
    ],
    "Hover": [
        "BS",
        "BSv",
        "HOVER_BSv",
        "Constants",
        "TweenService",
        "RunService",
        "UserInputService",
        "Players",
        "OreLookup",
        "NumberFormat",
        "PerfBeacon",
        "blockSquash",
        "formatHP",
        "shockwave",
        "chunkBurst",
    ],
    "Decor": [
        "BS",
        "parseKey",
        "FILLER_WEIGHT",
        "MAX_VISIBLE_SHELLS",
        "DECOR_RANGE",
        "DECOR_FOV_ATTACH",
        "DECOR_FOV_KEEP",
        "DECOR_FOV_WEIGHT",
        "AMBIENT_FX_FOLDER",
        "AMBIENT_FX_HOLDER",
        "AMBIENT_FX_RARITY",
        "AMBIENT_FX_RANGE",
        "SHELL_RANGE",
        "MAX_AMBIENT_FX",
        "MAX_ORE_GLOWS",
        "TweenService",
        "Players",
        "ReplicatedStorage",
        "OreBlockDecor",
        "OreFXPalette",
        "OreLookup",
        "MiningBlockDecor",
    ],
    "Combat": [
        "BS",
        "BREAK_CHUNK_COUNT",
        "BREAK_DUST_COUNT",
        "BREAK_CHUNK_SPEED",
        "SHOCKWAVE_BY_RARITY",
        "TweenService",
        "Debris",
        "LayerProfile",
        "PerfBeacon",
        "Net",
        "OreLookup",
        "SoundManager",
        "CameraShake",
        "Haptics",
        "dustCloud",
        "chunkBurst",
        "shockwave",
        "coinPop",
        "blockSquash",
    ],
    "Sync": [
        "parseKey",
        "PERF",
        "perfPublish",
        "PerfBeacon",
        "CREATE_BUDGET_PER_FRAME",
        "DESTROY_BUDGET_PER_FRAME",
        "FAST_REMOVE_THRESHOLD",
        "ORIGIN_WAIT_TIMEOUT",
    ],
    "Core": [
        "BS",
        "BSv",
        "PERF",
        "perfPublish",
        "ORIGIN_WAIT_TIMEOUT",
        "AMBIENT_FX_TICK",
        "DECOR_CAM_MOVE_THRESHOLD",
        "PerfBeacon",
        "Logger",
        "UpgradeLogic",
        "MutationLogic",
        "OreBlockDecor",
        "OreLookup",
        "Net",
        "RunService",
        "smoothSurfaces",
    ],
}


def build_shared() -> str:
    preamble = PREAMBLE.read_text(encoding="utf-8")
    lines = preamble.splitlines(keepends=True)
    start = next(i for i, l in enumerate(lines) if l.startswith("local RAYCAST_MAX_DISTANCE"))
    end = next(i for i, l in enumerate(lines) if l.startswith("local MiningRenderer = {}"))
    body = "".join(lines[start:end])

    header = """--!strict
-- Shared: constants, perf probes, juice FX, parseKey — used by mining/* modules.

local shared = game:GetService("ReplicatedStorage"):WaitForChild("shared")
local modules = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
local Logger = require(shared.util.Logger)
local Constants = require(shared.constants)
local LayerProfile = require(shared.data.LayerProfile)
local UpgradeLogic = require(shared.util.UpgradeLogic)
local PerfBeacon = require(shared.util.PerfBeacon)
local OreFXPalette = require(shared.util.OreFXPalette)
local OreBlockDecor = require(shared.util.OreBlockDecor)
local MutationLogic = require(shared.util.MutationLogic)
local MiningBlockDecor = require(script.Parent.Parent.MiningBlockDecor)
local MiningReach = require(shared.util.MiningReach)
local MineZoneWorkspace = require(shared.util.MineZoneWorkspace)
local Net = require(modules.Net)
local OreLookup = require(script.Parent.Parent.OreLookup)
local NumberFormat = require(shared.util.NumberFormat)
local SoundManager = require(script.Parent.Parent.SoundManager)
local CameraShake = require(script.Parent.Parent.CameraShake)
local Haptics = require(script.Parent.Parent.Haptics)

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UiAssets = require(ReplicatedStorage:WaitForChild("shared").data.UiAssets)

"""
    exports = [
        "RAYCAST_MAX_DISTANCE",
        "ORIGIN_WAIT_TIMEOUT",
        "CREATE_BUDGET_PER_FRAME",
        "DESTROY_BUDGET_PER_FRAME",
        "FAST_REMOVE_THRESHOLD",
        "PERF",
        "perfPublish",
        "parseKey",
        "BS",
        "BSv",
        "HOVER_BSv",
        "BREAK_CHUNK_COUNT",
        "BREAK_DUST_COUNT",
        "BREAK_CHUNK_SPEED",
        "SHOCKWAVE_BY_RARITY",
        "MAX_ORE_GLOWS",
        "smoothSurfaces",
        "FILLER_WEIGHT",
        "MAX_VISIBLE_SHELLS",
        "DECOR_RANGE",
        "DECOR_FOV_ATTACH",
        "DECOR_FOV_KEEP",
        "DECOR_FOV_WEIGHT",
        "AMBIENT_FX_FOLDER",
        "AMBIENT_FX_HOLDER",
        "AMBIENT_FX_RARITY",
        "AMBIENT_FX_RANGE",
        "SHELL_RANGE",
        "AMBIENT_FX_TICK",
        "MAX_AMBIENT_FX",
        "DECOR_CAM_MOVE_THRESHOLD",
        "shockwave",
        "chunkBurst",
        "dustCloud",
        "coinPop",
        "blockSquash",
        "formatHP",
        "appendMiningRaycastExcludes",
        "TweenService",
        "Debris",
        "Players",
        "RunService",
        "UserInputService",
        "ReplicatedStorage",
        "Logger",
        "Constants",
        "LayerProfile",
        "UpgradeLogic",
        "PerfBeacon",
        "OreFXPalette",
        "OreBlockDecor",
        "MutationLogic",
        "MiningBlockDecor",
        "MiningReach",
        "MineZoneWorkspace",
        "Net",
        "OreLookup",
        "NumberFormat",
        "SoundManager",
        "CameraShake",
        "Haptics",
        "UiAssets",
    ]
    footer = "\nreturn {\n" + ",\n".join(f"\t{name} = {name}" for name in exports) + ",\n}\n"
    return header + body + footer


def inject_imports(module_name: str, content: str) -> str:
    names = MODULE_IMPORTS.get(module_name, [])
    assigns = "\n".join(f"local {n} = Shared.{n}" for n in names)
    header = f"--!strict\n\nlocal Shared = require(script.Parent.Shared)\n{assigns}\n\n"
    body = re.sub(r"^--!strict\n.*?\nlocal MiningRenderer = \{\}\n\n", "", content, count=1, flags=re.S)
    return header + "local MiningRenderer = {}\n\n" + body


def build_facade() -> str:
    return """--!strict
-- MiningRenderer — 3D рендер шахты. Тонкий фасад: методы разнесены по mining/*.

local MiningRenderer = {}
MiningRenderer.__index = MiningRenderer

local function mergeMethods(mod: { [string]: any })
\tfor name, fn in mod do
\t\tMiningRenderer[name] = fn
\tend
end

mergeMethods(require(script.mining.Core))
mergeMethods(require(script.mining.Origin))
mergeMethods(require(script.mining.Raycast))
mergeMethods(require(script.mining.Hover))
mergeMethods(require(script.mining.Decor))
mergeMethods(require(script.mining.Combat))
mergeMethods(require(script.mining.Sync))

return MiningRenderer
"""


def main() -> None:
    shared_path = MINING / "Shared.lua"
    shared_path.write_text(build_shared(), encoding="utf-8")
    print(f"wrote {shared_path.name}: {shared_path.read_text(encoding='utf-8').count(chr(10))} lines")

    for path in sorted(MINING.glob("*.lua")):
        if path.name in ("Shared.lua",):
            continue
        if path.stem not in MODULE_IMPORTS:
            continue
        updated = inject_imports(path.stem, path.read_text(encoding="utf-8"))
        path.write_text(updated, encoding="utf-8")
        print(f"patched {path.name}")

    SRC.write_text(build_facade(), encoding="utf-8")
    print(f"wrote facade MiningRenderer.lua: {SRC.read_text(encoding='utf-8').count(chr(10))} lines")

    PREAMBLE.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
