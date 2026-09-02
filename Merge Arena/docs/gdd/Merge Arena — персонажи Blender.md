# Merge Arena — персонажи (простые формы → Blender)

> Стиль: Bright Tactical Toys · рефы сгенерированы 2026-07-28  
> Картинки: `assets/merge-arena-char-*.png` (Cursor project assets)  
> Связь: [[Merge Arena — визуальный стиль]]

---

## Сборка в Blender (только примитивы)

### 1. Crystal Knight (tank)
| Часть | Примитив |
|---|---|
| Торс | Cube → bevel / Subdivision лёгкий |
| Голова | UV Sphere |
| Шлем-кристалл | Cone |
| Руки/ноги | Cylinder |
| Щит | Cube (flat) или Cylinder (disk) |
| Меч | Cube тонкий + Cube рукоять |

**Палитра:** teal + cream + cyan crystal.

---

### 2. Scrap Goblin (flanker / cheap)
| Часть | Примитив |
|---|---|
| Тело | UV Sphere (squash) или Cone вверх ногами |
| Голова | UV Sphere крупнее |
| Уши | Plane / flat Cube треугольником |
| Ноги | Cylinder короткие |
| Гаечный ключ | 2 Cube буквой L |

**Палитра:** coral + dirty green.

---

### 3. Neon Beast (bruiser)
| Часть | Примитив |
|---|---|
| Туловище | Cube rounded / Capsule |
| Голова | UV Sphere + Cube челюсть |
| Ноги | Cylinder ×4 (или ×2 biped toy) |
| Шипы / рога | Cone |
| Хвост | Cylinder taper (scale cascade) |

**Палитра:** purple + magenta + yellow accents.

---

### 4. Totem Mage (support)
| Часть | Примитив |
|---|---|
| Тело-ряса | Cylinder / Capsule высокий |
| Голова | UV Sphere |
| Шляпа | Cylinder flat (disk) |
| Посох | Cylinder + UV Sphere orb |
| Руны | мелкие Cube, parent к empty, orbit

**Палитра:** cream + soft blue.

---

## Правила моделлинга под Roblox

1. Силуэт читается в 64px.  
2. Без тонких проволочек (ломаются на mobile).  
3. Merge ★2/★3 = тот же mesh + scale 1.15/1.3 + emissive trim / bigger crystal.  
4. Origin в центре базы ног; высота юнитов roughly uniform (mage чуть выше).

## Статус выбора

| ID | Имя | Роль | Ок в MVP? |
|---|---|---|---|
| 1 | Crystal Knight | Tank | ☐ |
| 2 | Scrap Goblin | Cheap / flank | ☐ |
| 3 | Neon Beast | Bruiser | ☐ |
| 4 | Totem Mage | Support | ☐ |

#gamedesign #merge-arena #art #blender
