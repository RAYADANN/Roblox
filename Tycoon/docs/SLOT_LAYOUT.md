# Slot layout — 8 floors × 5 heroes

Live capacity = number of **Model** markers under `Island*.DummyItems`.  
Target: **40** (`Constants.SLOT_FLOORS × SLOTS_PER_FLOOR` = 8 × 5).

## Folder layout (required)

```
IslandMain/
  DummyItems/
    Floor_01/   -- 5 Model markers (ground / first filled)
    Floor_02/
    Floor_03/
    Floor_04/
    Floor_05/
    Floor_06/
    Floor_07/
    Floor_08/   -- top
```

Names: `Floor_01` … `Floor_08` (also accepts `Floor1`).  
Order in code: **floor ascending**, then **X**, then **Z**. Higher-tier units still sort to the front of `units[]` → they occupy lower floors first.

## Checklist (Studio)

1. Open `Workspace.IslandMain.DummyItems`.
2. Create folders `Floor_01` … `Floor_08`.
3. Put **exactly 5** slot Models in each folder. They may be **empty pivot markers** (Model + CFrame only) or full dummy clones — code uses the first marker with parts, otherwise `Island*.R15 Dummy`.
4. Place markers on the matching tower floor; within a floor, space them in a clear row (left→right).
5. Do **not** leave loose Models as direct children of `DummyItems` once Floor folders exist (they are ignored).
6. Playtest: Output should **not** warn `DummyItems has N slots (expected 40)`.
7. Buy past 5 units — heroes appear on Floor_02+, not only the first row.

## Code

- Sort / parse: `shared/util/SlotLayoutLogic`
- Collect markers: `server/core/WorldFarmFactory.slotMarkers`
- Cap fallback: `Constants.MAX_SLOTS` (= 40)
