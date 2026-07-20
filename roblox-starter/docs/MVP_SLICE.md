# MVP Slice — первый релиз

Вертикальный срез: **одна петля прогресса за 15 минут**.
Всё остальное — `BACKLOG.md` / апдейты 1.1+.

## Петля MVP (mining/incremental)

```
Копать → получить ресурс → продать → купить апгрейд → копать глубже → rebirth
```

## В scope MVP

| Система | Минимум |
|---------|---------|
| Mining | Клик/авто, 3–5 руд, глубина |
| Economy | Монеты, продажа, 3–5 апгрейдов |
| Rebirth | 1 tier, multiplier |
| HUD | Монеты, глубина, кнопка sell, панель апгрейдов |
| Save | ProfileStore, session lock |
| Network | Zap: sync + buy + notify |
| UI | React HUD, professional Button/Chip/Modal |
| Analytics | session_start, first_action, rebirth |
| CI | Зелёный на каждый merge |

## Вне scope MVP (→ BACKLOG)

- Петы / яйца / gacha
- Квесты / daily rewards
- Shop за Robux (можно заглушку UI)
- Локализация (если только EN на старте)
- Leaderboard
- Tutorial (минимум: 3 подсказки OK)
- Social rewards / promo codes

## Критерий готовности soft launch

- [ ] 15-минутная петля проходима без багов
- [ ] Работает phone + desktop
- [ ] CI зелёный
- [ ] ProductIds ≠ 0 (если есть монетизация)
- [ ] `PLAYTEST_CHECKLIST.md` пройден
- [ ] `RELEASE_CHECKLIST.md` пройден
