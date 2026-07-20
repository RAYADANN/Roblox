# Breed & Raid — Implementation Plan

> Следуй порядку. Не перескакивай в monetization до PROVE Go.

---

## Step 0 — Boot

1. Rojo project + empty `src/` trees  
2. `shared/net/Remotes` stubs per GDD §16  
3. `shared/data/*Config` / `*Database` from GDD tables  
4. Plot graybox parts in Studio OR procedural plot builder  

## Step 1 — Plots + Economy

- `BaseService`: claim plot, Hub/Yard sizes (GDD §3)  
- `EconomyService`: cash, buffer, Collect, MPS 1s tick  

## Step 2 — Creatures + Nests

- `CreatureService`: instances, genes look, nest snap, billboards `1 in X`  
- Starter grants  

## Step 3 — Roll

- `RollService`: Creature pool §4.5 + Block pool §6.2  
- Preview → Buy  

## Step 4 — Breed

- `BreedService`: incubate 120s, outcomes, oneIn mutate §7.5, hatch VFX  

## Step 5 — Steal

- `StealService`: SM, Lock, Bat  
- Fail resolves GDD §8  

## Step 6 — Build (thin)

- `BuildService`: grid 4, dirt walls, Take tool  

## Step 7 — Client

- Controllers + React HUD (cash, MPS, inventory, breed modal)  

## Step 8 — Playtest gate

GDD §21 metrics. Kill/Go → only then MVP checklist in DEV_TRACKER.

---

## Module map (target)

```
src/shared/data/CreatureDatabase.luau
src/shared/data/BlockDatabase.luau
src/shared/data/BreedConfig.luau
src/shared/data/EconomyConfig.luau
src/shared/data/PlotConfig.luau
src/shared/net/Remotes.luau
src/server/BaseService.luau
src/server/EconomyService.luau
src/server/CreatureService.luau
src/server/RollService.luau
src/server/BreedService.luau
src/server/StealService.luau
src/server/BuildService.luau
src/server/MetaService.luau
src/client/...
```

Модули ≤300 строк; дробить по ответственности.
