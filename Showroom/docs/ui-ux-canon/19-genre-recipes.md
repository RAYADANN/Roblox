# 19 — Genre Recipes

Универсальный канон (01–18) = законы.  
Жанр = **какие законы давят сильнее** и какой default HUD.

Не копируй skin хита. Копируй **информационную дисциплину**.

---

## 1. Competitive FPS / extraction shooter

| | |
|--|--|
| Priority | Center clear, peripheral vitals, <100ms feedback |
| Always-on | HP/shield, ammo, ability charges |
| Hide | Flavor, large maps, chat (collapse) |
| Type | Condensed, high contrast, numeric clarity |
| Color | Cool/neutral base; danger = strong hue+shape |
| Motion | Micro only; reduce decorative |
| Study | Doom Eternal (ammo readability), Apex (squad/ability) |

**Reject:** ornate frames, centered permanent menus, low-contrast gray on gray.

---

## 2. Action-Adventure / Narrative

| | |
|--|--|
| Priority | Immersion; contextual HUD |
| Always-on | Often near-empty; vignette/meta for damage |
| Show on need | Weapon, objective flash, interaction |
| Diegetic OK | If a11y options exist |
| Study | RDR2 contextual HUD, Dead Space diegetic + a11y caution |

**Reject:** MMO-density chrome в story moments.

---

## 3. RPG / MMO

| | |
|--|--|
| Priority | Comparison, filters, bag management |
| Always-on | HP/resource, enemy nameplates (spatial), minimap |
| Menus | Heavy: inventory grid vs list, tooltips, deltas |
| Type | More roles; still one family |
| Study | Destiny 2 comparison; caution Path of Exile density |

**Reject:** tooltips without compare; unidentified walls of stats.

---

## 4. Strategy / Builder / Tycoon (PC-rooted)

| | |
|--|--|
| Priority | Selection clarity, economy readouts, build validity |
| Always-on | Resources, selection panel, build mode toggle |
| Spatial | Ghost placement, valid/invalid color+icon |
| Study | Factorio/Satisfactory selection panels (discipline) |

**Reject:** hiding cost until after place.

---

## 5. Roblox Simulator / Pet / Incremental (см. также 20)

| | |
|--|--|
| Priority | Cash/gems glanceable; one primary flex; short session UX |
| Always-on | Resource chips + bottom dock (5±2 verbs) |
| World | Pads, prompts, pet billboards = brand language |
| Mobile-first | Thumb dock; no hover-only |
| Monetization | Clear owned/price; no fake urgency |
| Study | Top Discover sims — structure only; your flex metric unique |

**Reject:** 12 dock buttons; neon prototype pads; HUD≠world style split.

---

## 6. Horror

| | |
|--|--|
| Priority | Tension; UI almost absent |
| Meta | Damage vignette, breath, film grain careful (photosensitivity) |
| Diegetic | Inventory as object (Resident Evil) |
| Study | RE4 attaché (spatial puzzle), limited ammo UI |

**Reject:** bright arcade chips; loud success confetti.

---

## 7. Sports / Racing

| | |
|--|--|
| Priority | Split-second meters, position, timers |
| Layout | Edge strips; center mostly clear |
| Type | Large numeric, often condensed/display |
| Motion | Gauge needles, not modal spam |

**Reject:** blocking center with toasts during race.

---

## 8. Party / Casual social

| | |
|--|--|
| Priority | Who’s ready, round state, big readable scores |
| Type | Larger than competitive; high chroma OK |
| Lobby | Status > cosmetics |

**Reject:** small mute/ready targets.

---

## Как выбрать рецепт

1. Назови primary verb сессии (dig / shoot / breed / place).  
2. Назови primary flex (1-in-X / KD / depth / lap time).  
3. Возьми ближайший жанр выше.  
4. Переопредели 3 поля: Always-on, Flex typography, World UI needs.  
5. Запиши в `theme` comments + screen briefs.
