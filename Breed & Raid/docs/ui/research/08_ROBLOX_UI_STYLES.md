# 08 — Roblox UI Visual Styles (research)

**Date:** 2026-07-19  
**Question:** Какие *визуальные* языки UI реально живут на Discover — и почему наш jade/parchment сейчас «не Roblox».  
**Scope:** ScreenGui + world prompts/billboards. Не GFX-thumbnails, не 3D art.

Скрины референс-игр желательны для annotated teardown; ниже — устойчивые **семьи стилей** по hits, asset-pack рынку 2025–26, Creator Hub и BaBaS scene doc.

---

## 1. Что игроки называют «Roblox UI»

Не «красивый game UI из AAA», а узнаваемый пакет:

| Сигнал | Типично на Discover |
|--------|---------------------|
| Поверхность | Тёмная панель **или** яркий stud/plastic |
| Кнопка | Толстый fill + stroke + **крупный** радиус или stud-edge |
| Акцент | Высокая насыщенность (зелёный Collect, жёлтый Cash, красный Danger) |
| Иконка | Простой glyph / emoji-like / ImageLabel, не thin line-icon |
| Числа | Крупные, часто с обводкой или на контрастной плашке |
| Мир | Pad glow, default или custom prompt, иногда 3D-кнопка |
| Motion | Scale pop, bounce, color flash |

**Parchment / cream / bronze / muted jade** читается как *indie cozy / board-game* — профессионально по craft, но **вне мейнстрим-словаря Discover**. Отсюда ощущение «не стиль Roblox».

---

## 2. Семьи стилей (taxonomy)

Зафиксируй **одну** семью на продукт. Микс stud + parchment + neon = «Marketplace kit».

### A. Arcade Dark (самый частый «современный sim»)

| Свойство | Значение |
|----------|----------|
| Base | Near-black / navy (`#0A0E18`…`#1A2238`) |
| Panel | Чуть светлее navy + white stroke 1–2 @ 20–40% |
| CTA | Saturated green / gold / cyan |
| Text | Near-white primary; muted blue-gray secondary |
| Radius | 10–16, pill chips |
| Depth | UIStroke + optional soft UIGradient; редко drop-shadow image |
| Где | Pet sims, mining, clickers, большинство «UI pack for simulator» |

**Steal structure:** dark HUD не спорит с ярким миром; CTA светится.  
**Don't:** rainbow neon на всём; 6 равноярких dock icons.

### B. Stud / Classic Block (тренд 2025–26)

| Свойство | Значение |
|----------|----------|
| Base | Plastic colors + **stud texture** (ImageLabel ScaleType Tile) |
| Edge | Толстый stroke / stud rim; «кирпич» |
| CTA | Chunkу buttons, often primary colors (red/green/yellow) |
| Text | Bold Gotham / black outline sometimes |
| Feel | Retro Roblox DNA, brainrot/sim packs на itch |

**Steal:** мгновенная «это Roblox» идентичность; хорошо с graybox.  
**Don't:** tile-stretch (Scale вместо Tile); stud на каждом toast.

### C. Candy / Pastel Pet

| Свойство | Значение |
|----------|----------|
| Base | Soft pink / lilac / mint panels |
| CTA | Hot pink / sky |
| Radius | Very round |
| Где | Pet/collectible, younger skew |

**Risk:** контраст и CVD; легко «детский kit» без иерархии.

### D. World-first / Tycoon boards (BaBaS-family)

| Свойство | Значение |
|----------|----------|
| ScreenGui | Часто **минимальный** (cash + Collect) |
| World | Красные pads, god-rays, **3D щиты**, огромная зелёная Collect |
| Billboards | Яркий текст, `1 in X`, `$/s` |
| Prompts | Громкий verb + `[E]` |

Это не «chrome theme», а **распределение UI в мир**. Hits жанра build/steal часто здесь.  
B&R loop ближе сюда по **механике**, чем к parchment modal culture.

### E. Clean Flat / Soft Material

| Свойство | Значение |
|----------|----------|
| Base | Flat mid-dark or light gray |
| Stroke | Thin; little ornament |
| Feel | «Indie polished», ближе к мобильным казуалкам вне Roblox |

Реже доминирует на Discover sims; чаще в experience с сильным brand.

### F. Ornate / Themed (наш текущий jade parchment)

| Свойство | Значение |
|----------|----------|
| Base | Cream / parchment |
| Accent | Jade, bronze, gold |
| Feel | Warm, readable, non-Roblox-native |
| Где | Намеренный brand (xianxia / cozy) — **не дефолт жанра** |

Craft может быть выше arcade dark. **Genre fit** для BaBaS-like — слабый, если цель = «как топ Discover».

---

## 3. Общий DNA (независимо от семьи)

То, что копируют хиты — **структура**, не обязательно stud:

1. Top-left currency chips (1–3)  
2. Bottom thumb-zone primary verb  
3. One loud CTA color (Collect/Hatch/Roll)  
4. Flex number huge (`1 in X`, eggs, depth)  
5. Progressive disclosure (не весь dashboard сразу)  
6. World station must shout without opening menu  
7. Juice on earn/buy (scale + SFX)

Creator Hub: color/size/proximity для внимания; buttons in containers with depth cues.

---

## 4. Карта: B&R сейчас vs жанр

| Ось | B&R сейчас (parchment) | BaBaS / typical sim |
|-----|------------------------|---------------------|
| Panel | Cream | Dark navy **or** stud / world board |
| Collect | Muted jade | Loud green |
| Pads | Soft colored plastic | Red/yellow neon mats |
| SUMMON | Persistent cream rail | World-first + optional panel |
| «Robloxness» | Low | High |

Вывод исследования: проблема не только в AA/spacing — в **выборе семьи**. Parchment = валидный premium brand, но не «стиль Roblox».

---

## 5. Рекомендации (выбор — за владельцем)

| Цель | Семья | Действие |
|------|-------|----------|
| Максимально «как Discover hit» | **A Arcade Dark** или **B Stud** | Сменить skin tokens + CTA saturation; сохранить структуру briefs |
| Как BaBaS feel | **D World-first** + A или B chrome | Уменьшить persistent SUMMON; усилить pads/prompts |
| Уникальный brand, не гнаться за «роблоксностью» | **F Parchment** | Оставить; принять non-native look |
| Детский pet skew | **C Candy** | Отдельный skin |

**Не делать:** parchment panels + stud buttons + neon pads в одном кадре.

---

## 6. Что улучшить в research дальше (со скринами)

На каждый референс (3–5 игр): HUD idle, pad+prompt, одно модальное окно — в `research/refs/` с подписью семьи A–F.

Пока скринов нет — taxonomy выше достаточна для **решения семьи**; annotated pixel-teardown усиливает, но не блокирует выбор.

---

## 7. Связь с каноном / brief

- Canon presets table → расширить Stud + World-first (см. `23-roblox-visual-styles.md` в starter).  
- `UI_DESIGN_BRIEF.md` — добавить fork «Visual family» до следующего polish skin.  
- Код theme не менять, пока владелец не выберет A/B/D/F.
