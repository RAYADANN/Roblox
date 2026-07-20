# 14 — Accessibility (Core Craft)

A11y проектируется **до** вёрстки, не после «polish».  
Крупный контрастный UI помогает также couch, handheld, stream, яркой комнате.

Стандарты-ориентиры: [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/), Xbox Accessibility Guidelines, WCAG contrast как baseline.

---

## Минимум для проф. продукта

| Область | Требование |
|---------|------------|
| Contrast | См. 03; high-contrast mode желателен |
| Color | Не color-only; симуляции CVD |
| Text scale | 0.75x–2.0x если возможно; иначе крупные defaults |
| Motion | Reduce motion |
| Subtitles | Если есть голос/диалоги: size, background, speaker |
| Controls | Remap где применимо; hold vs toggle |
| Photosensitivity | Избегать вспышек 3–50Hz; большие red flashes |

---

## Практические тесты

1. Без звука — critical понятен?  
2. Grayscale — hierarchy жив?  
3. CVD filters — статусы различимы?  
4. Text min — CTA читаем?  
5. Только touch / только gamepad — всё достижимо?  
6. Bright room + dark cave screenshots  

---

## Roblox specifics

- Touch targets  
- `TextScaled` осторожно  
- Не полагайся на hover  
- Safe areas / notches  
- Performance low-end: simplify FX

---

## DoD a11y

- [ ] Нет color-only  
- [ ] Contrast проверен  
- [ ] Reduce motion  
- [ ] Focus visible  
- [ ] Errors не только звуком
