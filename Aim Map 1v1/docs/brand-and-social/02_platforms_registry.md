# 02 — Platforms Registry

> Все ID и ссылки — **источник правды**. При расхождении с кодом — сначала `src/shared/constants.lua`, потом этот файл.

---

## Roblox — Zeon Studio Group

| Поле | Значение |
|------|----------|
| **Name** | Zeon Studio |
| **Group ID** | `1066009408` |
| **URL** | https://www.roblox.com/communities/1066009408 |
| **Configure** | https://www.roblox.com/communities/configure?id=1066009408 |

### Ассеты группы

| Файл | Размер | Назначение |
|------|--------|------------|
| `assets/zeon_studio_group_cover_universal.png` | 512×512 | **Icon** (основной, универсальный) |
| `assets/zeon_studio_group_cover.png` | 512×512 | Icon (mining-themed, legacy — не использовать) |
| `assets/zeon_studio_cover_photo_1440x456.png` | 1440×456 | **Cover Photo** (основной) |
| `assets/zeon_studio_cover_photo_720x228.png` | 720×228 | Cover Photo (fallback) |

### Стиль группы Roblox

- **Универсальный бренд студии**, не привязан к одной игре
- Посты: прямые, с emoji-списками, CTA «играть / группа / избранное»
- Shout: короткий, 2–4 строки
- Wall posts: релизы, апдейты, промокоды

---

## Roblox — Deep Digger (игра)

| Поле | Значение |
|------|----------|
| **Name** | Deep Digger |
| **Place ID** | `77149464720360` |
| **Universe ID** | `10434759721` |
| **URL** | https://www.roblox.com/games/77149464720360 |

### Creator Hub

| Поле | Где |
|------|-----|
| Описание EN | `assets/marketing/store_listing.txt` |
| Icon 512×512 | `assets/marketing/deep_digger_icon_512x512.png` |
| Thumbnails | см. `05_visual_styles.md` → папки |

### In-game Social Reward

Источник: `src/shared/constants.lua` → `Constants.SOCIAL_REWARD`

| Условие | Награда |
|---------|---------|
| В группе Zeon Studio **+** игра в избранном | 7 500 🪙, 15 💎, x2 coins boost 15 мин |

---

## Discord — Zeon Network

| Поле | Значение |
|------|----------|
| **Server name** | Zeon Network |
| **Description** | 🌌 The official multiverse hub of Zeon Studio. Wander between worlds. Catch every signal. |
| **Accent color** | `#7C4DFF` |
| **Invite URL** | `[TODO — вставить постоянный invite]` |

### Ассеты Discord

| Файл | Назначение |
|------|------------|
| `assets/marketing/discord/zeon_discord_banner.png` | Server banner |
| `assets/zeon_studio_group_cover_universal.png` | Server icon |
| `assets/marketing/discord/zeon_discord_*.png` | Channel header images |

### Setup-документы

| Файл | Содержание |
|------|------------|
| `tools/discord_setup/discord_manual_pack.txt` | **Основной** — ручная настройка (предпочтительно) |
| `tools/discord_setup/README.md` | Bot setup (опционально) |
| `tools/discord_setup/zeon_config.py` | Конфиг bot-версии (28 ролей) |

### Роли (упрощённая модель — 10 ролей)

Zeon, Mod, Explorer, Collector, Grinder, Social, Creator, Updates, Codes, Wanderer

### Категории каналов

```
━━ THE GATE ━━   → #charter, #arrival, #signals, #drops, #portals
━━ THE NEXUS ━━   → #lounge, #help, #glitches, #beacons
━━ THE CORE ━━    → #signals (dev)
🔊 VOICE          → Voice · Nexus
```

---

## YouTube — Zeon Studio

| Поле | Значение |
|------|----------|
| **Channel name** | Zeon Studio |
| **URL** | `[TODO — вставить URL канала]` |

### Ассеты YouTube

| Файл | Размер | Назначение |
|------|--------|------------|
| `assets/marketing/youtube/zeon_youtube_banner_2560x1440.png` | 2560×1440 | Channel banner |
| `assets/marketing/youtube/zeon_youtube_profile_800x800.png` | 800×800 | Avatar |
| `assets/marketing/youtube/zeon_youtube_watermark_512x512.png` | 512×512 | Video watermark |

### Документ

`assets/marketing/youtube/youtube_channel_pack.txt` — описания, теги, шаблон видео

---

## Другие площадки (заготовки)

| Площадка | URL | Стиль | Статус |
|----------|-----|-------|--------|
| TikTok | `[TODO]` | Короткий gameplay, hook 1 сек, тренды | Не настроено |
| Twitter / X | `[TODO]` | Короткие анонсы + скрин | Не настроено |
| Telegram | `[TODO]` | Дубль кодов / апдейтов | Не настроено |
| Email (business) | `[TODO]` | Формальный, для спонсоров | Не настроено |

> Когда добавишь площадку — заполни строку и добавь секцию в `03_voice_and_behavior.md`.

---

## Thumbnail-паки (где что лежит)

| Папка | Стиль | Статус |
|-------|-------|--------|
| `assets/marketing/` | v1 cinematic | Legacy |
| `assets/marketing/v2/` | Discover bright | Актуальный base |
| `assets/marketing/thumbnails_gfx/` | GFX + текст в AI | Эксперимент |
| `assets/marketing/thumbnails_no_text/` | 3 стиля без текста | **Рекомендуется** для финала + текст в Canva |
| `assets/marketing/thumbnails_experiment/` | 10 A/B стилей | Тестирование |
| `assets/marketing/thumbnails_ai/` | 20 AI thumbnails | Архив |
| `assets/marketing/thumbnails_roblox/` | Python text overlay | **Не использовать** |
