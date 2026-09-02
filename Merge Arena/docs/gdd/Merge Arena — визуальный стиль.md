# Merge Arena — визуальный стиль

> Refs: [[Merge Arena — Dual]] · [[Merge Arena — игровой процесс]] · [[../../Zeon — bренд и маркетинг/05 — visual styles]] · [[../../Starter Pack/06 — visual and hook]] · [[../../Фундамент/Chinese juice → Roblox polish]]  
> Статус: **LOCKED = A Bright Tactical Toys** · 2026-08-07  
> Палитра / UI tokens: [[Merge Arena — Canon Lock]] §7  
> Правило: стиль должен читать **merge ★** с телефона за 1 сек на thumb.

---

## Зачем стиль решать сейчас

| Без стиля | С каноном |
|---|---|
| Серый mid «ещё anime board» | Узнаваемый бренд на годы |
| Thumb не продаёт merge | Icon = два юнита → ★ |
| Арт дрифтует каждый патч | Roster = одна скульптура |

**Закон Discover:** bright, readable silhouette, merge moment. Не dark cinematic.

---

## Канон стиля (зафиксировано по рефу «Герои RNG»)

**Выбранный стиль:** Ultra-simple Roblox blocks — cube head, block torso, block limbs, 2 rectangle eyes, flat colors, rarity via glow/texture not mesh complexity.

Рефы юнитов: `merge-heroes-style-knight/goblin/mage/beast.png`

### Формула персонажа (Blender = 5–8 Cube)

```
Head     = Cube
Torso    = Cube (чуть шире)
Arm L/R  = Cube тонкий
Leg L/R  = Cube
Accessory = 1–3 Cube (шлем / посох / ключ / шипы)
Eyes     = Emission на UV или 2 маленьких Cube
```

★2 / ★3 = тот же rig + scale + glow / particles / 1 in X billboard — не новый topology.

| Поле | Значение |
|---|---|
| **Выбранный стиль** | Heroes-RNG block toy |
| **Не делать** | sculpt, PBR wood/clay, anime, detailed armor |
| **Merge VFX keyword** | smash cubes + star flash |
| **Thumb formula** | 2 block units → ★ → fight |

---

## 5 стилей × 1 рыцарь (архив сравнения, не канон)

Сгенерировано 2026-07-28 — один архетип, разные стили:

| # | Стиль | Файл | Blender-сложность | Discover | Long factory |
|---|---|---|---|---|---|
| 1 | **Toy Plastic** | `merge-style-01-toy-plastic.png` | низкая | высокая | высокая |
| 2 | **Wood Miniature** | `merge-style-02-wood-miniature.png` | средняя | средняя | очень высокая |
| 3 | **Roblox Blocky** | `merge-style-03-roblox-blocky.png` | очень низкая | средняя | средняя |
| 4 | **Soft Clay** | `merge-style-04-soft-clay.png` | средняя (sculpt) | высокая | средняя |
| 5 | **Low-Poly Neon** | `merge-style-05-lowpoly-neon.png` | низкая–средняя | высокая | высокая |

**Выбор:** напиши номер 1–5 → зафиксируем канон стиля и нагенерим полный roster в нём.

---

## Критерии выбора

| Критерий | Вес |
|---|---|
| Читаемость юнита + ★ на mobile | must |
| Отличие от Anime Auto Chess / сырого MT | must |
| Подходит **long ranked factory** (не одноразовый meme) | high |
| Стоимость продакшна (16–24 юнита MVP) | high |
| Thumb CTR потенциал 2026 | medium |
| Сезоны/скины легко наращивать | medium |

---

## 4 кандидата

### A. Bright Tactical Toys *(рекомендация desk)*

**Вайб:** игрушечная арена, как Clash Merge Tactics / Clash Mini — но **своя** палитра (не копировать красно-синий SC 1:1).  
Чёткие силуэты, толстый outline, «пластиковые» герои на ярком поле.

| | |
|---|---|
| ✅ | Mobile proven; merge читается; ranked выглядит «серьёзно-весело» |
| ❌ | Риск «Clash clone» на ощупь — лечится уникальными фракциями/формой |
| Продакшн | Средний: low-poly + bright materials |
| Thumb | Два toy-юнита сливаются, вспышка ★, фон арены |

**Фракции-пример:** Crystal Knights / Scrap Goblins / Neon Beasts — не anime faces.

---

### B. Board-Game Diorama

**Вайб:** настолка: деревянный/каменный борд, миниатюры, кубики★, «премиум toys».

| | |
|---|---|
| ✅ | Сильная identity; long brand; мало на Roblox |
| ❌ | Может быть менее «кричащим» в Discover vs brainrot |
| Продакшн | Чуть выше (материалы дерева/камня + миниатюры) |
| Thumb | Рука сливает две фигурки на доске |

Хорошо, если хочешь **не** выглядеть как ещё один mobile fighter.

---

### C. Roblox Brainrot / Meme Cast

**Вайб:** абсурдные мем-юниты, кричащие цвета, TikTok-native.

| | |
|---|---|
| ✅ | Макс CTR 2025–26; легко клипы |
| ❌ | Слабее «билет в жизнь»; быстрее выгорает; ranked выглядит шуточно |
| Продакшн | Быстро, но бренд нестабилен |
| Thumb | Два brainrot merge → ★ |

**Компромисс:** core стиль A/B, **season skins** brainrot — не база.

---

### D. Anime Chibi Board

**Вайб:** big eyes, anime roster, как соседи Auto Chess.

| | |
|---|---|
| ✅ | Понятный фандом |
| ❌ | Полка уже шумная; ты хотел *пустую* нишу продукта — визуал вернёт в «ещё anime» |
| Продакшн | Средний, много конкуренции по артам |
| Thumb | Сложно отличить от Anime Auto Chess |

**Desk: не брать как primary.**

---

## Сравнительная матрица

| | A Toys | B Diorama | C Brainrot | D Anime |
|---|---|---|---|---|
| Mobile read | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| Identity vs полка | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐ |
| Long factory | ⭐⭐⭐ | ⭐⭐⭐ | ⭐ | ⭐⭐ |
| Discover spike | ⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| Prod cost MVP | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Desk pick** | **1** | 2 | skins only | no |

---

## Рекомендация

**Канон MVP = A Bright Tactical Toys**  
- Палитра своя (например: teal + coral + cream, не SC default)  
- Юниты = toy/fighter silhouettes, толстый rim  
- Merge = обязательный «toy smash → bigger toy» VFX  
- Поле = яркая арена с читаемыми 2 рядами  

**Сезоны:** C brainrot / horror / freeze как *cosmetic lines*, не смена DNA.  
**Alt если хочешь премиум-бренд:** B Diorama (чуть тише Discover, сильнее uniqueness).

---

## Канон (LOCKED)

| Поле | Значение |
|---|---|
| **Выбранный стиль** | **A Bright Tactical Toys** |
| **Референсы** | Heroes RNG blocks · Clash Merge Tactics readability · Figma HUD A/D |
| **Палитра** | Canon Lock §7 (`#A9D4F0` sky · `#3D7CFF` primary · `#FF6B5A` coral · `#F0C01A` gold) |
| **Не делать** | anime default · dark cinematic · Pet Sim cute · SC red/blue 1:1 |
| **Merge VFX keyword** | **smash cubes + ★ flash** |
| **Thumb formula** | 2 block units → ★ → fight readable |
| **HUD** | Light toys chrome + punch dock hit-targets |

Сезоны later: brainrot / horror как cosmetic lines, не смена DNA.

#gamedesign #merge-arena #visual #style
