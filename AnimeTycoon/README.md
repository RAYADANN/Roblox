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

1. **Roll** на `Base.Stands.RollButton` → рулетка на Stand1–5  
2. **Buy** контейнер (Box1–3, rarity + mutation)  
3. Встать на `Base.Ramp.HeroPlace` Button → place  
4. Unpack (billboard = remaining time; **первый купленный контейнер = 3s**, остальные = f(rarity); **Open now** R$ to skip) → Open → герой → мини → SellBox → Take → SellGuy → coins  
5. **Level up** (клавиша F на открытом герое): уровень 1–50, +15% к монетам за уровень. Цена следующего уровня = прирост монет/с × окупаемость, которая тоже растёт на 15% за уровень. Прокачанный Common обгоняет свежий Mythic. Уровень едет вместе с героем при Pick up.  

## Структура

| Путь | Роль |
|------|------|
| `src/shared/util/TutorialLogic` | FTUE steps + advance (новички only; Studio **T** = full profile reset) |
| `src/client/core/TutorialController` | beam + near spotlight + hint |
| `src/server/core/StandManager` | офферы / buy |
| `src/server/core/RampManager` | place / unpack / income |
| `src/client/core/OfferRoulette` | рулетка |
| `src/client/core/RampWorldRenderer` | мир + BillboardGui |
