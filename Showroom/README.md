# Showroom

Idle exhibit: personal plot (6 stands + dispenser), growth via attention, sell shop.

- Product: [`docs/MVP_SLICE.md`](docs/MVP_SLICE.md)
- AI: [`AGENTS.md`](AGENTS.md)
- Studio markers / Rojo: [`docs/STUDIO.md`](docs/STUDIO.md)

```powershell
rokit install
wally install
zap net.zap
stylua src tests
selene src
lune run tests
rojo serve --port 34873
```

In Studio: Rojo plugin → Connect → `localhost:34873`, then Play.

### Hoarcekat (UI stories)

1. Install [Hoarcekat](https://github.com/Kampfkarren/hoarcekat) Studio plugin
2. Rojo sync
3. Open Hoarcekat → `ReplicatedStorage.UI.stories`:
   - **Hud** — full HUD (BalanceChip + bank/income + bottom inventory hotbar + Index/Shop/Rebirth)
   - **Index** — Index modal (top-right egg tabs → pets → evolutions)
   - **Shop** — Shop modal (Luck/Gold banners + coin packs)
   - **Rebirth** — Rebirth modal (perks + progress + Skip/Rebirth; mock spend)
   - **BalanceChip** — coins bar only (bottom-left)

New story: `src/client/ui/stories/Name.story.luau` → `return mount.screen(React.createElement(...))`.
