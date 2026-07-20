# Zeon Studio — Brand & Social Starter Pack

> **Назначение:** единый источник правды про бренд, соцсети, группы и стиль общения.  
> **Обновлено:** 2026-07-13  
> **Канон:** `roblox-starter/docs/brand-and-social/` (копия также в `Mining/assets/marketing/starter_pack/`)  
> **Правило:** перед любым постом, обновлением описания или новым каналом — сверься с этим паком.

---

## Быстрый старт

| Файл | Когда открывать |
|------|-----------------|
| [01_brand_identity.md](./01_brand_identity.md) | Кто мы, слоганы, цвета, что можно / нельзя |
| [02_platforms_registry.md](./02_platforms_registry.md) | Ссылки, ID, ассеты, что куда загружать |
| [03_voice_and_behavior.md](./03_voice_and_behavior.md) | **Как писать** на каждой площадке — главный файл для единого поведения |
| [04_copy_templates.md](./04_copy_templates.md) | Готовые тексты: посты, описания, shout'ы |
| [05_visual_styles.md](./05_visual_styles.md) | Стиль картинок, thumbnail'ов, что работает / что нет |
| [MASTER.txt](./MASTER.txt) | Всё в одном файле для copy-paste |

---

## Три уровня бренда (не путать!)

```
ZEON STUDIO          → студия (группа Roblox, YouTube, «кто мы»)
ZEON NETWORK         → Discord-сообщество (лore, Wanderer, multiverse)
DEEP DIGGER          → конкретная игра (mining sim, яркий Discover-стиль)
```

| Уровень | Где живёт | Тон |
|---------|-----------|-----|
| **Zeon Studio** | Roblox Group, YouTube, описания игр | Прямой, дружелюбный, «solo indie dev» |
| **Zeon Network** | Discord | Атмосферный: Wanderer, signals, portals |
| **Deep Digger** | Страница игры, thumbnail'ы, промо | Яркий clickbait-sim, цифры, прогресс |

---

## Связанные материалы (уже в проекте)

| Путь | Содержание |
|------|------------|
| `assets/marketing/store_listing.txt` | Описание Deep Digger для Creator Hub |
| `assets/marketing/youtube/youtube_channel_pack.txt` | YouTube: баннер, описание, теги |
| `tools/discord_setup/discord_manual_pack.txt` | Discord: каналы, pin-тексты, роли |
| `assets/marketing/thumbnails_*/` | Готовые thumbnail-паки |
| `docs/starter-pack/` | Анализ рынка Roblox (не про бренд) |

---

## Чеклист перед публикацией

- [ ] Пост на правильном **уровне бренда** (Studio / Network / Game)?
- [ ] Тон совпадает с [03_voice_and_behavior.md](./03_voice_and_behavior.md)?
- [ ] Ссылки из [02_platforms_registry.md](./02_platforms_registry.md)?
- [ ] CTA: группа + избранное + игра (где уместно)?
- [ ] Картинка в правильном **визуальном стиле** ([05_visual_styles.md](./05_visual_styles.md))?
- [ ] Placeholder'ы `[TODO]` заменены на реальные ссылки?

---

## Что обновлять при изменениях

| Событие | Обновить |
|---------|----------|
| Новая игра | `02`, `04`, Discord `#portals`, YouTube «NOW PLAYING» |
| Новый Discord invite | `02`, `04`, YouTube |
| Смена соц-награды | `02`, `04`, `store_listing.txt`, `constants.lua` |
| Новый промокод | Discord `#drops`, группа shout |
| Новый визуальный стиль thumbnail | `05`, папка `thumbnails_*` |
