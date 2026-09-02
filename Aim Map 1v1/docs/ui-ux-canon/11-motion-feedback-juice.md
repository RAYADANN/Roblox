# 11 — Motion, Feedback & Juice

Motion в проф. UI — **коммуникация**, не декор.  
Каждое движение отвечает: «принято», «меняется», «важно», «ошибка».

---

## Feedback loop

```
Player action → Visual (± Audio ± Haptic) within ~100ms
             → Pending (если ждём сервер)
             → Success / Error resolution
```

Нет ответа 300–500ms → игрок думает, что input потерян.

---

## Timing bands

| Тип | Длительность | Easing |
|-----|--------------|--------|
| Micro (press) | 60–120ms | Spring / Quad Out |
| Control hover | 80–160ms | Spring |
| Panel / modal in | 150–250ms | Spring from 0.88 |
| Modal out | 100–160ms | Faster than in |
| Number settle | 200–400ms | Spring |
| Toast in | 150–200ms | Slide+fade |
| Attention pulse | sparingly | Never infinite на idle critical без причины |

**Появление = slightly playful. Исчезновение = быстрее.**

---

## Juice toolkit (дозировано)

| Эффект | Когда | Осторожность |
|--------|-------|--------------|
| Scale press | Любой button | Обязательный минимум |
| Number spring | Currency / score | Не на каждый MPS tick visual spam |
| Hitstop | Combat impact | 1–3 frames |
| Screen shake | Heavy events | Small, damped; reduce-motion off |
| Flash / vignette | Damage / danger | Не seizure frequencies |
| Particles | Reward / hatch | Skip button; pool/Debris |
| Confetti | Rare celebration | Rare |

Juice без иерархии = шум.

---

## Приоритет событий

1. Critical system (error purchase)  
2. Reward (hatch mythic)  
3. Standard confirm (buy)  
4. Ambient (chip tick)

Одновременно не запускай 3 full-screen FX.

---

## Reduce motion

Если включено:

- Убрать shake / large particles  
- Заменить spring на короткий fade  
- Сохранить **clarity** feedback (color/state change остаётся)

---

## Sound sync

Visual press и click SFX стартуют вместе.  
Не задерживай звук до ответа сервера для простых UI clicks.

---

## Performance

- Ограничь idle motors  
- Один FX layer ScreenGui  
- Cleanup обязателен  
- Не Animate всё через Heartbeat без нужды

---

## DoD motion

- [ ] Press feedback мгновенный  
- [ ] Modal in/out пресеты  
- [ ] Reduce-motion path  
- [ ] Нет infinite idle pulses на всём  
- [ ] Skip на long celebrations
