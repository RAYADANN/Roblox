# 17 — Anti-Patterns (Reject Always)

Список того, что **не считается** профессиональным UI/UX в этом каноне.

---

## Визуал

- [ ] Смысл только цветом (red/green без иконки/формы)  
- [ ] Всё одинакового визуального веса  
- [ ] Случайные радиусы / отступы вне шкалы  
- [ ] Glow / neon на каждом контроле  
- [ ] Разные «стили окон» в соседних панелях без theme variant  
- [ ] Орнамент до читаемости и feedback  
- [ ] TextStroke как единственный способ читать на мире  
- [ ] AI-default эстетики без системы (random purple gradients, несвязанный cream-terracotta и т.п. как единственный «стиль»)

---

## UX

- [ ] Persistent HUD элемент без оправдания  
- [ ] Нет empty / loading / error states  
- [ ] Нет мгновенного press feedback  
- [ ] Confirm/Cancel прыгают местами между экранами  
- [ ] Hover-only подсказки на mobile  
- [ ] Dark patterns в магазине (fake urgency, скрытые цены)  
- [ ] Tutorial из 10 механик за 30 секунд  

---

## World

- [ ] Default ProximityPrompt при polished HUD  
- [ ] Чёрные плоские billboards «временно» навсегда  
- [ ] Neon pads как финальный look  
- [ ] ObjectText = бесполезное «Thing»

---

## Техническое (starter)

- [ ] Хардкод `Color3` / `TextSize` / offset без `theme`/`layout`  
- [ ] `if phone then size = X` для размеров  
- [ ] `AutoButtonColor = true`  
- [ ] Flipper motor без cleanup  
- [ ] Компонент >300 строк с бизнес-логикой  

---

## Процесс

- [ ] Дизайн только на спокойном артборде  
- [ ] «Потом сделаем a11y»  
- [ ] Копирование UI кита без адаптации под verbs игры
