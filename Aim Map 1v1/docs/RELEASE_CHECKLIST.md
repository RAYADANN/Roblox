# Release Checklist — soft launch gate

## Код и CI

- [ ] `stylua --check`, `selene`, `lune run tests`, `rojo build` — зелёные
- [ ] Нет `id = 0` в `ProductIds.luau` (если монетизация в билде)
- [ ] Нет `rbxassetid://0` в `SoundDatabase` для критичных звуков
- [ ] `net.zap` сгенерирован, клиент/сервер используют Net-модули

## Roblox Creator Hub

- [ ] Иконка 512×512
- [ ] Thumbnail 1920×1080 (минимум 1)
- [ ] Описание и жанр
- [ ] Game settings: возраст, доступность
- [ ] Пост в группе / Discord / YouTube — по [`brand-and-social/04_copy_templates.md`](brand-and-social/04_copy_templates.md)

## Аналитика

- [ ] `session_start` логируется
- [ ] `first_action` логируется
- [ ] Purchase events (если есть IAP)

## Документация

- [ ] `README.md` актуален (как собрать, текущий статус)
- [ ] BACKLOG не смешан с MVP

## Playtest

- [ ] `PLAYTEST_CHECKLIST.md` пройден на 3 тирах устройств
- [ ] Мультиплеер (2 Players): косметика/мир видны другим, если фича в билде

## Пост-релиз

- [ ] Мониторинг первых 24h (отзывы, retention D1)
- [ ] Hotfix process: ветка → CI → publish
