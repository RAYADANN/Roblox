# Night Raid Base

Greenfield Roblox project — **Phase 3 PROVE** graybox: day/night cycle + flashlight defense vs one monster.

| | |
|---|---|
| **MECE** | 78/100 strict → PROVE |
| **One-liner** | Днём база и pets; ночью чудище — отпугивай фонариком (`shine`). |
| **Code** | `C:\Projects\Roblox\NightRaid` |

## Docs (start here)

| Doc | Path |
|-----|------|
| **Agents (stack + how to work)** | [AGENTS.md](./AGENTS.md) |
| **Tech stack** | [docs/TECH_STACK.md](./docs/TECH_STACK.md) |
| **Agent brief** | [docs/AGENT_BRIEF.md](./docs/AGENT_BRIEF.md) |
| **BaBaS reference scene (from screenshots)** | [docs/REFERENCE_BABAS_SCENE.md](./docs/REFERENCE_BABAS_SCENE.md) |
| **Build & Pets** | [docs/MECHANICS_BUILD_AND_PETS.md](./docs/MECHANICS_BUILD_AND_PETS.md) |
| **Progress tracker** | [docs/DEV_TRACKER.md](./docs/DEV_TRACKER.md) |
| **GDD (product canon in-repo)** | [docs/GDD.md](./docs/GDD.md) |
| **Implementation plan** | [docs/IMPLEMENTATION_PLAN.md](./docs/IMPLEMENTATION_PLAN.md) |
| Obsidian notes (MECE / one-pager) | `Игры/Концепты/Night Raid Base — *.md` |
| Pipeline intake | `C:\Projects\Roblox\Mining\docs\starter-pack\machine\logs\project-02-night-raid-intake.md` |
| **Code stack / UI rules** | `C:\Projects\Roblox\roblox-starter` (`docs/TECH_STACK.md`, `.cursor/rules/ui-react.mdc`) |

## Starter-pack (design rules)

**Canonical path:** `C:\Projects\Roblox\Mining\docs\starter-pack\`  
*(Note: `C:\Projects\Roblox\starter-pack` does not exist — use Mining/docs.)*

Key files: `README.md`, `08-anti-patterns.md`, `07-how-to-design-a-hit.md`, `machine/pipeline.md`.

## PROVE scope (full session)

Playtester must experience:

`ROLL → BUILD → PLACE → STEAL → NIGHT SHINE → DAWN`

**Not in PROVE:** rebirth, offline, Robux, multi-monster.  
Checklist → [docs/DEV_TRACKER.md](./docs/DEV_TRACKER.md) §B.

## Run

```bash
cd C:\Projects\Roblox\NightRaid
rojo serve
```

Open the place in Roblox Studio and connect the Rojo plugin to sync.

**After `wally install` or changing `default.project.json`:** stop and restart `rojo serve`, then reconnect the plugin. Otherwise `ReplicatedStorage.Packages` (React) may be missing and the client will hang.

## Architecture (PROVE)

```
src/shared/data/     PetDatabase, CycleConfig, CombatConfig
src/shared/net/      Remotes
src/server/core/     CycleService, EconomyService, BaseBuilder, MonsterService
src/client/core/     FlashlightController
src/client/ui/       React App (theme, useLayout, components)
Packages/            React, ReactRoblox, Flipper, …
```

**Stack canon:** `C:\Projects\Roblox\roblox-starter` (React-Lua UI, DI, `--!strict`).  
Cursor agents: `.cursor/rules/night-raid-*.mdc` (alwaysApply).
