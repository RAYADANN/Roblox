# SOURCES — Professional references

Канон = устоявшаяся **craft-практика** + стандарты. Не блог-списки «10 tips» и не asset-pack гайды.

---

## Primary (game UI)

| Source | Why |
|--------|-----|
| Fagerholt & Lorentzon — *Beyond the HUD* (2009) | Diegetic / non-diegetic / spatial / meta |
| UI Challenges — Game UI Design Guide | Priority principles, surfaces, readability under motion |
| StraySpark — Game UI/UX Design Principles | MVHUD, zones, feedback, juice, timing |
| ColorArchive — Game UI Color Palette | Higher contrast needs, 4-layer hierarchy |
| Sidebearings — Game UI type systems | Angular size, role scales |
| Industry writing (WANDR, Bugnet, etc.) | Hierarchy as product craft |

## Design systems

| Source | Why |
|--------|-----|
| WCAG 2.x | Contrast 1.4.3 / non-text 1.4.11 |
| Material / Fluent / Carbon | 8pt, elevation, states |
| Semantic color systems | Role tokens |

## Accessibility

| Source | Why |
|--------|-----|
| Game Accessibility Guidelines | Game-specific |
| Xbox Accessibility Guidelines | Platform bar |
| CVD-aware practice | No color-only |

## Annotated study set (structure only)

See `references/` — Doom Eternal, Apex, Dead Space, RDR2, Persona 5, Destiny 2, Nintendo 1P, TLOU2 a11y, Hades, RE4 inventory, Roblox sim composite, fair shop, breed/station parity (R13).  
Study **information design**, not skins/IP.

## Internal

| Path | Role |
|------|------|
| `docs/ui-ux-canon/` | This canon |
| `00-priority-ladder.md` | Scope control |
| `20-roblox-sim-playbook.md` | Discover genre overlay |
| `23-roblox-visual-styles.md` | Discover UI style families |
| `21-benchmarks-metrics.md` | Numbers |
| `22-roblox-edge-cases.md` | Engine traps |
| `.cursor/rules/professional-ui.mdc` | React-Lua implementation |
| `docs/UI_ADAPTIVITY.md` | Scaling model |

---

## How to extend

Добавляй только правила, которые:

1. Подтверждены shipped practice или стандартом, **и**  
2. Переводятся в DoD / reject / metric.

Новый эталон = новый `references/R##-….md` по шаблону существующих.
