# MVP Slice — Aim Map 1v1

Вертикальный срез: **одна дуэль aim_map за минуты**, не «шутер со всеми фичами».

Стек/правила — из `roblox-starter` (`.cursor/rules/`, `AGENTS.md`). Жанр — этот файл + `docs/design/`.

## Камера

**First-person only** (Scriptable camera at eye height). Aim = центр экрана / crosshair.

## Петля MVP (~first session)

```
Lobby / invite
  → spawn на aim_map с USP (FPS)
  → 1v1 first-to-N
  → kill → flex скин жертвы до своей смерти
  → match end → Rematch
Лобби: shop skins (cosmetic)
```

## В scope soft / graybox

| Система | Минимум |
|---------|---------|
| Core duel | USP hits server-authoritative, first-to-N |
| Map | 1 aim_map |
| Rematch | &lt; ~5с |
| Invite | challenge друга / pad в shared lobby |
| Kill-flex | скин до смерти (репликация другим) |
| Skins | data table + shop stub / 5–15 ids |
| HUD | HP/ammo или минимальный duel HUD + rematch CTA |
| Save | ProfileStore: owned skins, W/L |
| Network | Zap: shot intent, hit confirm, match state, cosmetics |
| Analytics | session_start, duel_start, duel_end, rematch, shop_open |

## Вне scope → [`BACKLOG.md`](BACKLOG.md)

Второе оружие, FFA, ranked elo full, BP, много карт, P2W, навсегда steal skin.

## DoD graybox (3–5 дней)

- [ ] Два игрока (или Studio 2 клиента) играют first-to-N
- [ ] Понятно без text wall
- [ ] «Хочешь ещё?» — цель &gt; 70%
- [ ] Feel терпимый (не идеальный)

## DoD soft

- [ ] Publish
- [ ] Клип 60–90с (kill-flex + rematch)
- [ ] Phone + desktop playable
- [ ] CI зелёный
- [ ] ProductIds ≠ 0 если продажи включены

## Критерий kill / park (14 дней)

Нет rematch-ямы **или** hitreg/feel ломает доверие — не раздувать скоуп, park и вернуться к другой ставке.
