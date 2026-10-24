# 20 — Roblox Sim / Pet / Incremental Playbook

Overlay канона специально под **Discover-симуляторы**, pet, mining, tycoon, breed/raid-likes.  
Читай после `00` и `19` §5.

---

## Продуктовые константы жанра

| Константа | UI-следствие |
|-----------|--------------|
| Сессия ~5–20 мин | CTA и progress видимы сразу; мало deep menus |
| Phone-heavy | Dock снизу; hit ≥48; нет hover lore |
| Flex-метрика | Одна цифра доминирует (depth, best pet `1 in X`, MPS…) |
| World stations | Roll/Sell/Collect — second HUD |
| Soft currency + Robux | Два визуальных языка валют; не путать |
| Steal / PvP light | Danger styling + hold feedback на steal |

---

## Рекомендуемый HUD skeleton

```
┌─────────────────────────────────────┐
│  [Cash] [Gems] [Buffer?]   [Quest?] │  ← chips, max 3–4
│                                     │
│            (world play)             │
│                                     │
│         (toasts / FTUE)             │
├─────────────────────────────────────┤
│  Sell  Pets  Shop  Breed  More      │  ← 4–6 dock verbs
└─────────────────────────────────────┘
```

Правила:

- Один **primary** dock verb визуально сильнее (часто Shop или Sell — по loop).  
- Quest tracker — collapsible / phone hide.  
- Не дублируй Cash в chip + world buffer + modal header без нужды (buffer world OK).

---

## Primary flex typography

Если flex = rarity odds:

| Элемент | Вес |
|---------|-----|
| `1 in X` | Largest numeric in card/billboard |
| Name | Secondary |
| $/s or power | Tertiary |
| Rarity color | Support + non-color cue |

Если flex = depth/meters:

- Depth chip крупнее gems (или наоборот — выбери **один** hero resource).

---

## World stations (обязательный паритет с HUD)

| Station | Screen cue | World cue |
|---------|------------|-----------|
| Collect | Chip buffer / toast | Billboard `$N` + prompt Collect |
| Creature roll | Modal/roll panel | Preview card Title/Odds/Meta |
| Buy | Primary button | Buy prompt Enabled + price ObjectText |
| Breed | Modal | Incubator timer card |
| Lock | Status | Lock prompt + timer copy |

**DoD sim:** если закрыть ScreenGui, станции всё ещё «говорят» языком бренда.

---

## Меню, которые почти всегда нужны

1. **Inventory / Pets** — list/grid + equip + empty state  
2. **Shop** — clear packs, owned, prices  
3. **Rebirth / Prestige** — cost, what you keep, confirm  
4. **Settings** — SFX, music, reduce motion, (HUD density optional)

Не строй skill-tree UI в первую неделю, если loop его не требует.

---

## FTUE (первые 90 секунд)

Показывать **один** глагол за раз:

1. Dig / collect →  
2. Sell / cash →  
3. First upgrade / first roll →  
4. Open pets/shop  

UI: spotlight + one sentence + disable other dock until done (optional).  
Не 6 стрелок сразу.

---

## Monetization UI (проф. этика)

- Robux button visually distinct от soft-buy.  
- Bundle contents list.  
- Owned checkmark.  
- No fake «only 3 left» unless real server stock.  
- Gameplay advantage P2W: если GDD запрещает unstealable — UI не врёт.

---

## Visual direction presets (выбери один)

Полная taxonomy Discover: **[23-roblox-visual-styles.md](./23-roblox-visual-styles.md)**.

| Preset | Family | Base | Accent | Risk |
|--------|--------|------|--------|------|
| **Arcade bright** | A | Dark navy | Gold/cyan/loud green | Neon spam |
| **Stud classic** | B | Stud tile plastic | RYGB chunky | Tile stretch; overuse |
| **Jade / parchment** | F | Cream | Jade/bronze | Looks non-Roblox on Discover |
| **Clean dark** | E | Near-black | One brand hue | Flat without flex type |
| **Candy pet** | C | Soft pastels | Pink/lilac | Contrast / CVD |
| **World-first** | D | Minimal HUD + 3D boards | Neon pads | Weak ScreenGui brand |

Зафиксируй preset + family ID в `theme` + 3 adjectives. Не миксуй семьи (например arcade+parchment).

---

## Performance budget (Discover reality)

| Budget | Target |
|--------|--------|
| Idle Flipper motors | ≤8 |
| Simultaneous toasts | ≤3 |
| Billboard pet labels on screen | soft cap ~12–20; fade by distance |
| Dock icons | single atlas if possible |

---

## Sim anti-patterns (жанр)

- Marketplace UI kit, не связанный с миром  
- «Tap to claim» overlapping critical pad  
- Pet nameplates AlwaysOnTop + huge = visual smog  
- Shop full-screen every death/rejoin  
- Rainbow rarity without hierarchy  

---

## Чеклист «Roblox sim выглядит дорого»

- [ ] L1–L4 с лестницы `00` зелёные  
- [ ] HUD и world один preset  
- [ ] Flex число читается первым на pet card  
- [ ] Dock ≤6, hit комфортный  
- [ ] Custom prompts  
- [ ] Buy/error/success feedback  
- [ ] Soft vs Robux различимы  
- [ ] Phone playtest 10 минут
