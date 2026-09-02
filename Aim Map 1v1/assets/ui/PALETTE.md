# Shared color palette — Aim Map 1v1

Профессиональный подход: **одна система ролей (tokens)** на весь продукт.  
Окна, HUD chrome, иконки, combat tint — из одной палитры. Не «красивый hex на глаз» на каждый ассет.

| Слой | Источник правды |
|------|-----------------|
| **UI в коде** (панели, кнопки, текст) | `src/client/ui/theme.luau` |
| **Art / генерация / аудит иконок** | этот файл |
| **Combat tint (hitmarker)** | `HitMarkerLogic.rgb` → те же brand hex |

Расхождение art ↔ theme = баг: либо правим ассет, либо поднимаем token в `theme.luau` **в том же изменении**.

---

## Brand chrome (иконки + акценты UI)

Измеренные материалы `hud_icons_flat_esports` + lock под `theme`.  
Новые HUD/rank иконки — **только** эти роли (не изобретать третий синий).

| Token | Hex | RGB | Роль |
|-------|-----|-----|------|
| `white` | `#FFFFFF` | 255,255,255 | Основной fill иконок / яркий UI |
| `silver` | `#C5CDD5` | 197,205,213 | Металл, bevel, «chrome» (health / vs_bot / win cup) |
| `steel` | `#8B95A3` | 139,149,163 | Тёмный металл (Iron / Silver ranks, тени chrome) |
| `sky` | `#3EA5E8` | 62,165,232 | Главный cyan-акцент на иконках (панели, блики) |
| `skyHi` | `#73C7FF` | 115,199,255 | Светлый sky / head hitmarker tint |
| `primary` | `#527EFF` | 82,126,255 | Brand blue — CTA, kill confirm, gem core |
| `primaryHi` | `#709AFF` | 112,154,255 | Hover / lighter primary |
| `deepBlue` | `#0060AE` | 0,96,174 | Тень синих вставок на иконках |
| `navyOutline` | `#000D28` | 0,13,40 | **Обводка иконок** (не чистый чёрный) |
| `outlineDark` | `#000000` | 0,0,0 | Comic/combat stroke где нужен чистый black |

**Важно:** обводка HUD-иконок = `navyOutline`, не `#000000`.  
`#000000` оставляем для Ben-Day / combat masters, если нужен comic punch.

---

## Surfaces (окна / панели) — тёмный UI

Держат layout модалок и dock. Не красить иконки в эти цвета как fill.

| Token | Hex | RGB | Роль |
|-------|-----|-----|------|
| `bg1` | `#080A12` | 8,10,18 | Самый глубокий холст |
| `bg2` | `#0E111E` | 14,17,30 | Base |
| `bg3` / `panelBody` | `#161A2C` | 22,26,44 | Панель |
| `bg4` | `#1E243A` | 30,36,58 | Raised |
| `panelBg` | `#121626` | 18,22,38 | Modal shell |
| `dockBg` | `#0B0D18` | 11,13,24 | Bottom dock |
| `dockBorder` / `tabBorder` | `#262E4A` / `#323A58` | 38,46,74 / 50,58,88 | Рамки |
| `btnBg` | `#242A44` | 36,42,68 | Кнопка |
| `textMain` | `#E4EAFF` | 228,234,255 | Основной текст |
| `textSub` | `#949EC3` | 148,158,195 | Вторичный |
| `textMuted` | `#4C5878` | 76,88,120 | Muted |

---

## Status & economy

| Token | Hex | RGB | Роль |
|-------|-----|-----|------|
| `gold` | `#FFD426` | 255,212,38 | Soft currency UI / Gold rank metal target |
| `goldHi` | `#FFEE82` | 255,238,130 | Gold highlight |
| `goldArt` | `#E6B63E` | 230,182,62 | Запечённое золото на rank/win art |
| `bronze` | `#B57847` | 181,120,71 | Bronze rank metal |
| `bronzeDeep` | `#7A4A2F` | 122,74,47 | Bronze shadow |
| `sell` / `success` | `#2CD26C` / `#50DC78` | … | Positive |
| `error` | `#FF6450` | 255,100,80 | Damage / fail |

`icon_coins` в сете — **chrome white/blue**, не золотой слиток.  
Золото в UI = `theme.Colors.gold`; золото на rank art = `goldArt` / `gold`.

---

## Rank materials (только ladder)

| Rank | Primary metal | Accent |
|------|---------------|--------|
| Iron | `steel` | `navyOutline`, `sky` tip |
| Bronze | `bronze` / `bronzeDeep` | `sky` gem |
| Silver | `silver` / `steel` | `sky` gem |
| Gold | `goldArt` / `gold` | `primary` / `sky` gem |
| Platinum | `white` + `silver` | `sky` / `primary` |
| Diamond | `sky` / `skyHi` facets | `navyOutline` frame |
| Elite | `white` + `silver` + `goldArt` | `primary` core |
| Level (XP) | `white` + `primary` | `navyOutline` |

---

## Правила (обязательные)

1. **Один продукт — одна палитра.** Новый экран / иконка / FX tint → token из этого файла.
2. **Не плодить синие.** Нужен «ещё один голубой» → сначала докажи, что `sky` / `skyHi` / `primary` / `deepBlue` не покрывают роль.
3. **UI код** берёт `theme.Colors.*`. Хардкод `Color3.fromRGB` в компонентах — reject.
4. **Art / GenerateImage** — перечисляй token hex явно в промпте; reference = `hud_icons_flat_esports/icon_inventory.png` + `icon_diamonds.png`.
5. **Скины оружия / shop plates** могут уйти в rarity hues (`theme.Rarity`) — это отдельный слой, не ломает brand chrome окон.
6. После генерации: быстрый пиксель-чек — доминирующие non-white кластеры должны попадать в таблицу выше (±8 на канал ок).

---

## Combat / vignette

- Body hitmarker → `white`
- Head → `skyHi` (`#73C7FF`)
- Kill → `primary` (`#527EFF`)
- Vignette: края `white` → soft `primary`/`sky` к центру → прозрачная середина

---

## DoD перед merge арта

- [ ] Hex из этого файла (или осознанный rarity layer)
- [ ] Outline иконок = `navyOutline`, не случайный black/grey
- [ ] True alpha (без baked checkerboard)
- [ ] При новом token — запись сюда **и** в `theme.luau` в одном коммите
