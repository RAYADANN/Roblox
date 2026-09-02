# Merge Arena — Universal Block Kit

> Идея как в **Герои RNG**: один body → роли только атрибутикой.  
> Refs: [[Merge Arena — визуальный стиль]] · [[Merge Arena — персонажи Blender]]  
> Дата: 2026-07-28

---

## Принцип

```
BASE (всегда один)
  + Hat / Head
  + Hand L / Hand R
  + Back
  + Belt / Torso accent
  + Aura / Eyes material
= новый персонаж
```

Не лепим уникальный mesh на каждого.  
**16–24 юнита MVP = 1 rig + пачка аксессуаров.**

---

## BASE (mannequin)

| Часть | Форма | Цвет default |
|---|---|---|
| Head | Cube 1×1×1 | Tan |
| Torso | Cube 1.2×1.4×0.7 | Gray |
| Arm L/R | Cube 0.35×1.0×0.35 | Gray |
| Leg L/R | Cube 0.4×1.0×0.4 | Gray |
| Eyes | 2× small black rect (decals) | Black |

Реф: `merge-kit-00-base.png`

---

## Слоты атрибутики

| Slot | Attach | Примеры |
|---|---|---|
| **Hat** | Head top | helmet cube, wizard hat, crown, hood, horns |
| **Face** | Head front | eye glow color, monocle, mask cube |
| **Hand R** | Right arm | sword, staff, bow, wand, wrench |
| **Hand L** | Left arm | shield, book, second dagger |
| **Back** | Torso back | cape flat, quiver, wings cubes, backpack |
| **Belt** | Torso mid | color band, gem cube |
| **Aura** | Empty around | ring, particles (★2/★3 / rarity) |

---

## Роли = пресеты слотов

| Роль | Hat | Hand R | Hand L | Back | Палитра accent |
|---|---|---|---|---|---|
| **Warrior** | helmet | sword | — | — | teal |
| **Mage** | wide hat | staff+orb | — | — | purple/yellow |
| **Archer** | cap | bow | — | quiver | green |
| **Tank** | crown/helm | — | shield | — | blue |
| **Rogue** | hood | dagger | dagger | cape | black/red |
| **Healer** | soft hat | staff | book | — | cream/pink |
| **Berserk** | horns | axe | — | — | red |
| **Summoner** | crystal hat | tome | — | floating cubes | cyan |

Рефы: `merge-kit-01-warrior` … `04-tank.png`

---

## Редкость без нового меша

| Tier | Что меняется |
|---|---|
| Common | flat color accents |
| Rare | glow eyes + 1 particle |
| Epic | aura ring + textured material (galaxy/lava) |
| Mythic | aura + trail + louder merge VFX |

`1 in X` = billboard + material, **не** другая топология.

---

## ★ Merge

| Star | Visual |
|---|---|
| ★1 | base scale 1.0 |
| ★2 | scale 1.12 + trim glow |
| ★3 | scale 1.25 + aura slot on |

Тот же kit.

---

## Blender / Studio pipeline

1. Собрать **Base** один раз (Motor6D / Bones простые).  
2. Аксессуары = отдельные MeshParts, Weld к слоту.  
3. Юнит в таблице:

```
id | role | hatId | handR | handL | back | matPrimary | matAccent | cost | traits
```

4. Новый персонаж = **новая строка**, не новая модель.

---

## Закон kit

| ✅ | ❌ |
|---|---|
| Один силуэт человечка | Уникальный скелет на мага |
| Атрибутика читается с thumb | Мелкие детали |
| Редкость материалом | 50 уникальных мешей day-1 |

#gamedesign #merge-arena #art #kit
