# 01 — Foundations

## UI vs UX (игры)

| | UI | UX |
|---|----|----|
| Что | Слой, который видят и трогают: HUD, меню, иконки, layout, feedback | Понятность и удовлетворение всей операции: от первого запуска до death screen |
| Вопрос | «Как это выглядит и отвечает?» | «Может ли игрок сделать цель без трения?» |
| Ошибка | Красиво, но нечитаемо в бою | Loop понятен, но экран врёт / тормозит / путает |

UI — подмножество UX. На маленькой команде один человек делает оба; решения всё равно разделяй: сначала **задача игрока**, потом **пиксели**.

---

## Чем game UI ≠ web/app UI

| Web/App | Game |
|---------|------|
| Спокойный фон, полный фокус | Движущийся 3D, разделённое внимание |
| Курсор / один thumb | Controller + touch + M&K одновременно |
| Чтение в упор | Couch / TV / яркая комната / stream overlay |
| Статичный макет | Читаемость во время aim / dig / combat |

Тест: не Figma на белом. Тест: **самая яркая, самая тёмная, самая шумная** сцена при целевом разрешении.

---

## Четыре типа game UI (Fagerholt & Lorentzon, *Beyond the HUD*, 2009)

| Тип | В fiction? | В world space? | Пример |
|-----|------------|----------------|--------|
| **Diegetic** | Да | Да | Dead Space health spine; Metro watch |
| **Non-diegetic** | Нет | Нет | Классический HP bar, ammo, minimap overlay |
| **Spatial** | Нет | Да | Objective marker, outline врага, prompt у объекта |
| **Meta** | «Чувствует» персонаж | Screen | Damage vignette, cracked helmet |

Выбор по **задаче**, не по моде:

- Aim / dodge / timing → non-diegetic, максимальная ясность.  
- Атмосфера / horror / sim → diegetic, но с a11y (scale, contrast).  
- Привязка к объекту → spatial.  
- Состояние тела / удар → meta.

---

## Принципы в порядке боли игрока

1. **Readability** — contrast, size, silhouette; не цвет alone.  
2. **Input model match** — каждый экран проходим тем же input, что геймплей (focus, cancel, no traps).  
3. **Hierarchy & timing** — что always / contextual / on-demand; feedback ≤100ms.  
4. **Consistency** — иконка = одно значение; confirm/cancel места стабильны; один type+color ramp.  
5. **Feedback** — каждый input даёт ответ; иначе lag / miss / disabled.

Стиль и орнамент — **после** 1–5.

---

## Поверхности (surfaces) игры

Каждая поверхность — отдельная задача:

1. HUD — split-second state  
2. Inventory / loadout — сравнение  
3. Progression / skill — ветвление  
4. Menus / settings — фокус и группировка  
5. Character / stats — delta «до/после»  
6. Social / lobby — статусы и ошибки  
7. Map / minimap — ориентация + фильтры  
8. Store — ясность и доверие (без dark patterns)

Не копируй HUD-решения в store и наоборот.

---

## Minimum Viable Interface

Начни с **пустого** экрана. Добавь элемент, только если можешь ответить:

- Что сломается, если его убрать?  
- Нужен ли он **каждые** 5 секунд или 5% времени?  
- Можно ли показать по контексту / по запросу?

Если да «только 5%» — не persistent HUD.

---

## Профессиональный стандарт качества

Интерфейс **исчезает**, когда не нужен, и **кричит**, когда нужен.  
Игрок не должен «изучать UI» — должен получать state и действовать.

Критерий senior-уровня: за 2 секунды игрок называет top-3 приоритета на экране; контроллер / touch достигает всего; локаль +30% длины не ломает layout; grayscale всё ещё читается.
