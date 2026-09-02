# 16 — Process & Workflow

Проф. процесс идёт от **задачи игрока**. Соблюдай лестницу **[00-priority-ladder.md](./00-priority-ladder.md)**.

---

## 6 шагов

1. **Verbs & failures** — что делает игрок? что ломается?  
2. **Information priority** — always / contextual / on-demand.  
3. **Screen brief** — `templates/screen-brief.md` (+ жанр 19/20).  
4. **Tokens** — `templates/theme-token-sheet.md` → `theme.luau`.  
5. **Hi-fi + states** — default/hover/press/disabled/error/empty/loading.  
6. **In-engine test** — `templates/playtest-scorecard.md` + метрики 21.

Не прыгай на орнамент (L7) с шага 1.

---

## Документы на проект игры

| Артефакт | Зачем |
|----------|-------|
| UI inventory | Список экранов/HUD |
| Theme token sheet | Единый theme |
| Screen briefs | Каждый новый экран |
| Component map | Variants |
| Delight spec | Когда FX позволен |
| Playtest scorecards | История качества |

---

## Critique (senior bar)

1. Top-3 за 2 секунды?  
2. Что убрать без потери решения?  
3. Empty/error/loading?  
4. Locale +30%?  
5. Grayscale / CVD?  
6. World UI = HUD?  
7. Feedback ≤100ms?  
8. Какая ступень лестницы ещё красная?

---

## Handoff к коду

- Tokens only · `useLayout` · Motion presets  
- `professional-ui.mdc` + DoD 18  
- Edge cases 22 при Roblox world/UI  

---

## Когда остановиться

Ship на зелёных L1–L4 для core loop.  
L6 delight — на ключевых моментах.  
L7 ornament — после, осознанно.
