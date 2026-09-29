# AnimeTycoon

Toy conveyor tycoon: buy containers at Stands → unpack on Ramp → heroes spawn minis → coins.

- Product: [`docs/MVP_SLICE.md`](docs/MVP_SLICE.md)
- Studio markers: [`docs/STUDIO.md`](docs/STUDIO.md)
- AI: [`AGENTS.md`](AGENTS.md)

## Стек

Luau `--!strict` · Rojo · Wally · Zap · React-Lua · Flipper · ProfileStore · Lune CI

## Setup

```powershell
rokit install
wally install
zap net.zap
stylua src tests
stylua src/client/net/NetClient.luau src/server/net/NetServer.luau
selene src tests
lune run tests
rojo serve --port 34874
```

In Studio: Rojo plugin → Connect → `localhost:34874`, then Play.

## Петля

1. **Roll** на `Stands.RollButton` → рулетка на Stand1–5  
2. **Buy** контейнер (Box1–3, rarity + mutation)  
3. Встать на `Ramp.HeroPlace` Button → place  
4. Unpack → герой → мини по конвейеру → coins  

## Структура

| Путь | Роль |
|------|------|
| `src/shared/util/*Logic` | формулы + тесты |
| `src/server/core/StandManager` | офферы / buy |
| `src/server/core/RampManager` | place / unpack / income |
| `src/client/core/OfferRoulette` | рулетка |
| `src/client/core/RampWorldRenderer` | мир + BillboardGui |
