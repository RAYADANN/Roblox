# 09 — Menus, Modals & Navigation

Меню — место, где игроки **сравнивают и решают**. Другой режим внимания, чем HUD.

---

## Навигационные паттерны

| Паттерн | Лучше для | Пример |
|---------|-----------|--------|
| Horizontal tabs | 3–7 равных секций | Inventory \| Shop \| Pets |
| Sidebar | Много секций + subnav | RPG character |
| Radial / wheel | Быстрый выбор в геймплее | Emote / tool wheel |
| Full-screen | Сложные системы | Craft, skill tree |
| Modal overlay | Фокус на одной задаче | Buy confirm, breed |

---

## Modal anatomy (проф.)

```
Backdrop (block world input)
└─ Shell
   ├─ Header: title + close
   ├─ Body: scroll if needed
   └─ Footer: secondary | primary
```

Правила:

- Один primary CTA.  
- Close всегда доступен (кнопка + Back/B/Esc).  
- Open: fade scrim + scale 0.88→1.  
- Close: **быстрее** open.  
- Не открывай modal от modal без ясного stack (или replace).  
- Destructive: confirm step, danger styling.

Design space + `UIScale` fit (adaptivity): внутренности в design px, не «подгонка под каждое устройство».

---

## Focus & input

- Default focus на безопасном контроле (не на Delete).  
- Visible focus ring.  
- Нет focus trap без escape.  
- Confirm/Cancel позиции **стабильны** во всём продукте.  
- На gamepad: bumpers = tabs.

Roblox: мышь + touch + gamepad; тестируй tab порядок и `Selectable`.

---

## Информационная архитектура

1. Сгруппируй settings по задаче (Audio / Visual / Controls / Account).  
2. Самые частые — выше.  
3. Опасные — ниже + confirm.  
4. Preview последствий (sensitivity slider с live preview).

---

## Shop / monetization UI (этика = проф.)

Обязательно ясно:

- Баланс валюты  
- Что покупается (содержимое бандла)  
- Owned state  
- Цена  

Избегай dark patterns: fake urgency timers, скрытые цены, confusing currency math.  
Доверие магазина = часть UX hit-игры.

---

## Comparison UI

Для экипировки / pets / upgrades показывай **delta** (↑↓), не только абсолют.  
Игрок решает за секунду.

---

## Timing

| | |
|--|--|
| Input→visual | ≤16ms |
| Menu transition | ≤200ms ideally |
| Animations | 100–300ms |
| Skip | Always for long sequences |

Не блокируй input на всю анимацию без skip.

---

## DoD menus

- [ ] IA ясна новичку  
- [ ] Focus/cancel работают  
- [ ] Primary один  
- [ ] Empty/error/loading  
- [ ] Locale +30%  
- [ ] Анимации с reduce-motion path
