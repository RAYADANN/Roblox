# New Project — пошаговый чеклист

Скопируй `roblox-starter` и пройди шаги **по порядку**.

## 1. Копирование

```powershell
Copy-Item -Recurse C:\Projects\Roblox\roblox-starter C:\Projects\Roblox\MyGame
cd C:\Projects\Roblox\MyGame
```

## 2. Переименование

- [ ] `default.project.json` → `"name": "my-game"`
- [ ] `wally.toml` → `name = "you/my-game"`

## 3. Toolchain

```powershell
rokit install
rokit add lune
wally install
```

## 4. Zap (сеть)

```powershell
rokit install   # zap в rokit.toml
zap net.zap
```

Сгенерированные `src/server/net/NetServer.luau` и `src/client/net/NetClient.luau` коммить в git. CI перегенерирует и проверяет diff.

## 5. Проверка

```powershell
stylua src tests
selene src tests
lune run tests
rojo build -o build.rbxlx
```

## 6. Git

```powershell
git init
git add .
git commit -m "Init from roblox-starter"
```

## 7. MVP

- [ ] Прочитай `docs/MVP_SLICE.md` — определи scope **своей** игры
- [ ] Запиши идеи вне scope в `docs/BACKLOG.md`
- [ ] Первая фича — копируй паттерн `BuyUpgrade` (Logic → Manager → Net → UI)
- [ ] Перед UI polish — `docs/ui-ux-canon/QUICK_REFERENCE.md` (палитра, иерархия, DoD)

## 8. Cursor

Скажи агенту:

> «Работай по template.mdc, GAME_ARCHITECTURE.md и docs/ui-ux-canon/»

## 9. Перед soft launch

- [ ] `docs/PLAYTEST_CHECKLIST.md`
- [ ] `docs/RELEASE_CHECKLIST.md`
- [ ] ProductIds ≠ 0, SoundDatabase assetIds ≠ 0
