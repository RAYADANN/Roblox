# 13 — Sound & Haptics for UI

Проф. UI имеет **звуковой словарь**, как цветовой.

---

## Vocabulary

| Событие | Характер | Пример |
|---------|----------|--------|
| Click / tap | Короткий, нейтральный | UI click |
| Confirm / buy | Чуть выше, positive | Coin / stamp |
| Open modal | Soft whoosh up | |
| Close | Soft whoosh down / shorter | |
| Error | Low, dry | Buzz |
| Reward small | Chime short | |
| Reward large | Layered sting | Hatch |
| Warning | Attention, not panic | |

Правила:

- Одна семья тембров на продукт.  
- Pitch variation ±5% против fatigue.  
- Priority: error/reward перекрывают spam clicks.  
- **Тишина** — тоже дизайн (не клик на каждый hover).

---

## Sync

0ms visual press ↔ SFX.  
Не жди сервер для простых кликов; для purchase success — отдельный success SFX после confirm.

---

## Haptics (где есть)

| Event | Haptic |
|-------|--------|
| Press | Light |
| Success | Single pulse |
| Error | Double short |
| Heavy reward | Stronger patterned |

Соблюдай Reduce / system settings.

---

## Mixing

UI bus отдельно от music/SFx world.  
UI не должно быть громче combat hits.  
Настройки: UI volume slider.

---

## DoD

- [ ] Словарь определён  
- [ ] Click без серверной задержки  
- [ ] Mute/UI volume работают  
- [ ] Нет SFX на каждый hover в списках
