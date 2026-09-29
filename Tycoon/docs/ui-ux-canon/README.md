# Professional Game UI/UX Canon

> **Назначение:** единый источник правды по **профессиональному** UI/UX для игр (и Roblox-проектов на `roblox-starter`).  
> **Не для:** трендовых мокапов, AI-slop палитр, копирования UI-китов без системы.  
> **Для кого:** человек + агент Cursor — перед polish / новым экраном / theme.

**Обновлено:** 2026-07-19  
**Связано:** `.cursor/rules/professional-ui.mdc` · `.cursor/rules/ui-ux-canon.mdc` · `docs/UI_ADAPTIVITY.md`

---

## Как пользоваться (агент) — не читать всё подряд

1. **[00-priority-ladder.md](./00-priority-ladder.md)** — какая ступень сейчас.  
2. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** — решения за 2 минуты.  
3. Файл по теме / жанру (таблица ниже).  
4. При новом экране — **[templates/screen-brief.md](./templates/screen-brief.md)**.  
5. Перед merge — **[18-checklists-dod.md](./18-checklists-dod.md)** + метрики **[21](./21-benchmarks-metrics.md)**.  
6. Источники — **[SOURCES.md](./SOURCES.md)**.

Правило приоритета при конфликте:

1. Читаемость в худшей сцене  
2. Иерархия + feedback ≤100ms  
3. Консистентность токенов  
4. Стиль / орнамент  

**L7 ornament без L1–L3 = не профессионально.**

---

## Карта документов

### Навигация и закон

| # | Файл | Содержание |
|---|------|------------|
| 00 | [00-priority-ladder.md](./00-priority-ladder.md) | Порядок фаз — не утонуть |
| — | [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) | Cheat-sheet |
| 01 | [01-foundations.md](./01-foundations.md) | Принципы, 4 типа game UI |
| 02 | [02-attention-hierarchy.md](./02-attention-hierarchy.md) | Внимание, зоны, вес |
| 03 | [03-color-system.md](./03-color-system.md) | Палитра, семантика, контраст |
| 04 | [04-typography.md](./04-typography.md) | Шрифты, роли, scale |
| 05 | [05-layout-spacing.md](./05-layout-spacing.md) | 8pt grid, safe areas |
| 06 | [06-chrome-forms-frames.md](./06-chrome-forms-frames.md) | Окна, рамки, тени |
| 07 | [07-components.md](./07-components.md) | Кнопки, chips, bars… |
| 08 | [08-hud.md](./08-hud.md) | Persistent HUD |
| 09 | [09-menus-modals-nav.md](./09-menus-modals-nav.md) | Меню, модалки |
| 10 | [10-world-spatial-ui.md](./10-world-spatial-ui.md) | Billboard, prompts |
| 11 | [11-motion-feedback-juice.md](./11-motion-feedback-juice.md) | Motion, juice |
| 12 | [12-icons-imagery.md](./12-icons-imagery.md) | Иконки, rarity |
| 13 | [13-sound-haptics.md](./13-sound-haptics.md) | UI-звук |
| 14 | [14-accessibility.md](./14-accessibility.md) | A11y |
| 15 | [15-platforms-roblox.md](./15-platforms-roblox.md) | Платформы |
| 16 | [16-process-workflow.md](./16-process-workflow.md) | Процесс |
| 17 | [17-anti-patterns.md](./17-anti-patterns.md) | Reject list |
| 18 | [18-checklists-dod.md](./18-checklists-dod.md) | DoD |

### Жанр, метрики, Roblox deep

| # | Файл | Содержание |
|---|------|------------|
| 19 | [19-genre-recipes.md](./19-genre-recipes.md) | FPS / RPG / horror / sim… |
| 20 | [20-roblox-sim-playbook.md](./20-roblox-sim-playbook.md) | Discover sim / pet / incremental |
| 21 | [21-benchmarks-metrics.md](./21-benchmarks-metrics.md) | Числовые targets + playtest |
| 22 | [22-roblox-edge-cases.md](./22-roblox-edge-cases.md) | Studio/live ловушки |
| 23 | [23-roblox-visual-styles.md](./23-roblox-visual-styles.md) | Discover UI style families A–F |

### Эталоны, шаблоны, источники

| | |
|--|--|
| [references/](./references/README.md) | Annotated case studies (R01–R13) |
| [templates/](./templates/) | screen-brief · theme-token-sheet · playtest-scorecard |
| [SOURCES.md](./SOURCES.md) | Проф. источники |

---

## Связь с кодом starter

| Канон | Код |
|-------|-----|
| Tokens | `src/client/ui/theme.luau` |
| Адаптив | `ViewportLayout` + `useLayout()` |
| Слои | `UiScreen.luau` |
| Motion | `MotionPresets` · `useHoverPress` · `useFlipperSpring` |
| Компоненты | `src/client/ui/components/` |

Канон = **почему**. Код = **как**. Не хардкодь в обход `theme` / `layout`.
