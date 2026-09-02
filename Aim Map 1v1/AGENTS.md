# AGENTS.md — Aim Map 1v1

Этот репозиторий = **копия `roblox-starter` + дизайн Aim Map 1v1**.

Жанр: CS aim_map **1v1**, USP-only, rematch, cosmetic **kill-flex до смерти**.

## Читать до кода

1. [`docs/design/ONE_PAGER.md`](docs/design/ONE_PAGER.md)
2. [`docs/MVP_SLICE.md`](docs/MVP_SLICE.md)
3. [`docs/design/MONETIZATION.md`](docs/design/MONETIZATION.md)
4. [`docs/design/DUAL_ANALYSIS.md`](docs/design/DUAL_ANALYSIS.md) (если спор про scope)
5. `.cursor/rules/template.mdc` + `docs/GAME_ARCHITECTURE.md` + `docs/CLIENT_SERVER.md`

## Как писать код

1. **Стек starter:** Luau `--!strict`, Rojo, Wally, Zap, React-Lua, Flipper, ProfileStore  
2. **Паттерн фичи:** Logic (shared) → test → Manager (server) → Zap → UI/FX (client)  
3. **Hits / match state:** server authority (см. `networking.mdc`, `security.mdc`)  
4. **Kill-flex скин:** сервер выдаёт временный cosmetic; репликация через attribute/publisher (эталон `WorldCosmeticPublisher` / `RemoteCosmeticVisual`)  
5. **Не угадывай client/server** — спроси или смотри `client-server-split.mdc`

## Scope discipline

| Делать | Не делать в MVP |
|--------|-----------------|
| USP, 1 map, first-to-N, rematch, invite | FFA, 2-е оружие, P2W |
| Skins shop cosmetic | Permanent steal on kill |
| Graybox feel + hitreg | Full ranked/BP до soft signal |

Идеи вне scope → [`docs/BACKLOG.md`](docs/BACKLOG.md).

## Структура

```
.cursor/rules/     ← правила Cursor (из starter)
docs/              ← архитектура starter + design/ игры
docs/design/       ← ONE_PAGER, DUAL, MONETIZATION
src/shared|server|client
tests/
net.zap
```

## Эталоны кода (не удалять паттерн)

См. таблицу в оригинальном starter `AGENTS.md` (BuyUpgrade, ProfileManager, Zap, VFX, cosmetics).  
Для этой игры первая доменная фича: **Match/Duel + WeaponFire + KillFlexSkin**, не UpgradeRow.

## Чего НЕ делать

- Не копировать контент/ассеты чужих игр (Rivals, Deagle Arena)
- Не коммитить `build.rbxlx`, секреты, `.env`
- Не писать 1000-строчные файлы
- Не дублировать формулы client/server
- Не делать 3D/weapon cosmetic только LocalPlayer без server publish

## Документы starter (общие)

- `docs/TECH_STACK.md`
- `docs/GAME_ARCHITECTURE.md`
- `docs/CLIENT_SERVER.md`
- `docs/ui-ux-canon/`
- `docs/PLAYTEST_CHECKLIST.md`
- `docs/RELEASE_CHECKLIST.md`
