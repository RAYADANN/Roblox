# 21 — Benchmarks & Metrics

Числа ниже — **рабочие ориентиры** проф. практики, не законы физики.  
Используй как acceptance targets в playtest.

---

## Timing

| Метрика | Target | Fail if |
|---------|--------|---------|
| Input → first visual change | ≤100ms (ideal ≤16–33ms) | >200ms без pending UI |
| Button press spring | 60–160ms | >300ms «ватность» |
| Modal open | 150–250ms | >400ms без skip |
| Modal close | faster than open | Close slower than open |
| Toast dwell | 2–4s (error up to 5s) | <1s unreadable / sticky forever spam |
| Number spring settle | 200–400ms | Every MPS tick hard-pops chip |
| Hold prompt feedback | continuous bar | No bar on HoldDuration>0 |
| Menu perceived freeze | show pending ≤200ms | Blank >500ms |

---

## Contrast & type

| Метрика | Target |
|---------|--------|
| Body text contrast | ≥4.5:1 |
| Critical HUD numeric | ≥7:1 preferred |
| Non-text UI (icon/border/focus) | ≥3:1 |
| Glance parse (top-3) | ≤2s cold viewer |
| Critical peripheral read | ≤500ms |
| Phone body design px | ≥14 (after layout.text floor) |
| TV/couch body (if relevant) | often 20–28 @1080p equivalent |

---

## Touch & layout

| Метрика | Target |
|---------|--------|
| Hit area | ≥44×44 (sim phone: ≥48) |
| Gap between hits | ≥8 (comfort ≥12) |
| Dock verbs | 4–6 (hard fail ≥9 without overflow) |
| Resource chips always-on | ≤4 |
| Hierarchy levels on one view | ≤4 |
| Locale expansion budget | +30–40% width |

---

## Density & attention

| Метрика | Target |
|---------|--------|
| Persistent HUD elements | Justify each; start from 0 |
| Simultaneous full-screen FX | ≤1 |
| Idle animation motors (Flipper) | ≤8 |
| Toasts stacked | ≤3 |
| World billboards competing | soft ≤20; distance fade |

---

## Playtest protocol (30 min)

1. **Cold glance (2s):** show screenshot → list top-3.  
2. **Bright scene:** place UI on brightest map area.  
3. **Dark scene:** cave/night.  
4. **Busy:** particles + 3 pets + toast.  
5. **Thumb-only phone:** complete buy/sell/collect.  
6. **Mute:** complete same without audio.  
7. **Grayscale:** still know primary CTA.  
8. **Stopwatch:** tap → visible press (aim <100ms feel).

Запиши fails в tracker; не спорь вкусом, пока метрика красная.

---

## Analytics hooks (optional but pro)

| Event | Use |
|-------|-----|
| `ui_button` (id) | Dead controls |
| `ui_open` / `ui_close` (screen) | Drop-off |
| `ui_error_shown` (code) | Friction |
| `ftue_step_complete` | Tutorial length |
| `purchase_ui_confirm` | Shop trust funnel |

Не оптимизируй vanity clicks; смотри completion verbs.
