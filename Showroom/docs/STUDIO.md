# Studio wiring — Showroom

## Markers (existing scene only)

| Workspace | Role |
|-----------|------|
| `Eggs` (Folder) → `Alien` / `Magma` / `Ocean` / `Standart` | Egg mesh templates (**skip `Noname`**). Each has a `Part` (invisible) for MutationFx + billboards. |
| `Animals` (Folder) → folders named like eggs (`Alien`, `Magma`, …) → pet Models | Hatch visual: egg shrinks → pet from matching folder grows (pick by exhibit uid). |
| `Egg` (MeshPart, legacy) | Fallback only if `Eggs` folder missing |
| `BuyPlace` (Model) → `ButtonStand.Button` | ProximityPrompt **Spin** (egg roulette + FOV zoom) |
| `BuyPlace` → `ItemPlace` / `2` / `3` | ProximityPrompt **Buy** + preview (after spin lands) |
| `Place` … `Place6` → `Teleport.EggPlace` + `Button` (`Cube.001`/`002`) | Egg sits on **EggPlace** (must stay **Anchored**; invisible marker). Teleport FX on while occupied. Stand on **Button** to place. Hand egg = server weld to **RightHand** (all clients see it). |
| `FavoritePlace` → `ItemPlace1` … `ItemPlace5` (+ `BuyPlace1`… pedestals) | Favorite stands; **Auction** prompt to sell when replacing |
| `FavoritePlace` → `Button` (`Cube.001` press) | Step on to collect `favoriteBank` into coins |

No cloned plots / no `ShowroomPlots` folder. One scene = the loop.

## Rojo live sync

Toolchain + Studio plugin: **Rojo 7.7.0** (stable).

`C:\Rojo\rojo.exe` is **7.7.0-rc.1** — different build; Connect fails with `protocolVersion`. Always use Rokit:

```powershell
cd C:\Projects\Roblox\Showroom
rokit install
& "$env:USERPROFILE\.rokit\bin\rojo.exe" serve --port 34873
```

In Studio: **Rojo 7.7.0** plugin → Connect → `localhost:34873`.

Confirms after connect:

- `ReplicatedStorage.shared`
- `ReplicatedStorage.Packages`
- `ServerScriptService.server`
- `StarterPlayer.StarterPlayerScripts.client`

## Playtest loop

1. Play Solo (Rojo connected)
2. Walk to **ButtonStand** → ProximityPrompt **Spin** (roulette cycles eggs per pad, camera zooms in, then lands)
3. Walk to **ItemPlace** pads → **Buy** (pad stays empty until next **Spin**)
4. Select inventory item → stand on a Place **Button** to place
5. Growing exhibit: egg shrinks → pet from `Animals/<EggName>` grows; NPCs gather; mutation FX
6. Grown: **Auction** or **Favorite stand** (no instant Sell on stand)
7. Favorite income accumulates on FavoritePlace bank billboard → step on **FavoritePlace.Button** to collect
8. On a Favorite stand: **Auction** frees the slot (send to auction when you have a better pet)

HUD shows coins / bank / income / holding status only — actions are world prompts.

## Build artifact

`rojo build -o build.rbxlx` — CI / offline; prefer live sync so Place art stays.
