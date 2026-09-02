# 05 — Visual Styles

> Что работает для Deep Digger promo и что **не повторять**.

---

## Решения из практики (важно!)

| ✅ Делать | ❌ Не делать |
|-----------|-------------|
| AI-генерация **без текста** → текст в Canva/Figma | Python text overlay (`tools/roblox_text.py`) — выглядит плохо |
| Center crop 3:2 → 16:9 **без blur** | `export_thumbnails_safe.py` с blur-фоном — только если текст у края |
| Яркий Discover / Simulator GFX | Dark cinematic caves для thumbnail |
| Текст крупный, 15% отступ от краёв | Мелкий текст на 512×512 icon |
| A/B 2–5 thumbnail за раз | 10 активных сразу — нет данных |
| Скриншоты из Studio (FOV 25–40, bright) | Случайный dark lighting |

---

## Три стиля thumbnail (актуальный пак)

Папка: `assets/marketing/thumbnails_no_text/`

### 1. `style_reference/` — твой референс

| | |
|---|---|
| **Референс** | High-angle, bacon hair, yellow vest, black conveyors on green grass |
| **Объекты** | Glowing red lava orb, cyan bubble gems on belts |
| **Настроение** | «Я только что нашёл mythic!» |
| **Когда** | Primary thumbnail, YouTube, ads |

### 2. `style_cave_mining/` — Mining Simulator конкуренты

| | |
|---|---|
| **Стиль** | Dark cave, neon crystal walls, pickaxe, minecart |
| **Цвета** | Purple/magenta/cyan gems on dark stone |
| **Настроение** | «Rare ore in deep mine» |
| **Когда** | A/B для grinder-аудитории |

### 3. `style_tycoon_bright/` — Pet Sim / Factory Tycoon

| | |
|---|---|
| **Стиль** | Sunny outdoor, factory, multiple conveyors |
| **Композиция** | Rich vs poor split (без текста!) |
| **Настроение** | «Progression / get rich» |
| **Когда** | A/B для casual / pet-sim crossover |

---

## Стиль с текстом (если нужен AI-текст)

Папка: `assets/marketing/thumbnails_gfx/`

| Элемент | Спецификация |
|---------|--------------|
| Font | Bold rounded sans-serif |
| Money text | Lime green `#00FF00` area |
| Outline | White thick + black shadow |
| Формат | `+$100,000`, `SELL = RICH`, `+MYTHIC!` |
| Проблема | AI режет текст + crop 3:2 → **проверять каждый** |

---

## Стиль Zeon Studio (бренд, не игра)

| | |
|---|---|
| **Где** | Group icon, Discord, YouTube banner |
| **Цвета** | Cyan → purple gradient, gold edges |
| **Фон** | Cosmic, stars, geometric grid |
| **Лого** | «Z» monogram + play button |
| **НЕ использовать** | Pickaxe, cave, gems на studio assets |

Файлы: `assets/zeon_studio_group_cover_universal.png`, `assets/zeon_studio_cover_photo_1440x456.png`

---

## Стиль Discord

| | |
|---|---|
| **Accent** | `#7C4DFF` purple |
| **Banner** | `assets/marketing/discord/zeon_discord_banner.png` |
| **Channel headers** | `assets/marketing/discord/zeon_discord_*.png` |
| **Tone visual** | Space / multiverse, не mining |

---

## Стиль YouTube

| Asset | Safe zone |
|-------|-----------|
| Banner 2560×1440 | Logo/text в **центральной полосе** (mobile crop) |
| Watermark 512×512 | Bottom-right, простой лого |
| Thumbnail видео | Face/action + 3–4 слова max |

---

## Roblox technical specs

| Asset | Size | Max | Format |
|-------|------|-----|--------|
| Game Icon | 512×512 | 1 MB | PNG |
| Thumbnail | 1920×1080 | 3 MB | JPG preferred |
| Group Icon | 512×512 | 1 MB | PNG |
| Group Cover | 1440×456 or 720×228 | — | PNG/JPG |

---

## A/B test plan (рекомендация)

```
Week 1 — Slot #1 rotate:
  Day 1-2: style_tycoon_bright #01
  Day 3-4: style_reference #01
  Day 5-7: style_cave_mining #01

Week 2 — Top 2 + challenger (pets/rebirth hook)

Analytics: Creator Hub → Deep Digger → Thumbnails → visit rate
```

Подробнее: `assets/marketing/thumbnails_experiment/README.txt`

---

## Workflow для нового thumbnail

1. Выбери **стиль** из таблицы выше
2. Сгенерируй **без текста** (16:9 prompt, но expect 3:2 output)
3. Center crop → 1920×1080 JPG (no blur)
4. Добавь текст в **Canva** (если нужен) — контроль safe zone
5. Проверь на телефоне: читается ли в маленькой сетке?
6. Upload 1 slot, смотри Analytics 48–72h
