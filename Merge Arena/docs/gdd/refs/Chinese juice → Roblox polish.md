# Chinese juice → Roblox polish

> **Назначение:** довести до совершенства слои «сочности»: свет, VFX, анимация, UI, камера, звук.  
> **Обновлено:** 2026-08-02 · **политика источников:** только **Canon / Official** (см. ниже). Beginner YouTube и блоги-пересказы **исключены**.  
> **Связь:** [[../Game Visual Language/00 — оглавление|Game Visual Language]] · [[../Game Visual Language/Референсы — на что смотреть]] · [[../Starter Pack/06 — visual and hook]] · [[../Zeon — bренд и маркетинг/05 — visual styles]] · [[../Метод Tizzy/Анализы/Merge Arena — визуальный стиль]] · [[Урок — VFX в профессиональных играх]]  
> **Правило:** сначала **один verb** (merge / hatch / hit) с полным polish → потом clone на все действия.  
> **VFX-first:** теория и ✅⚠️❌ перенос → [[Урок — VFX в профессиональных играх]]; сборка kit — секции ниже.

---

## Политика источников (профи)

| Тир | Что входит | Что нет |
|---|---|---|
| **Canon** | Книги и talks авторов, которые **создали** дисциплину / AAA pipeline | Пересказы, SEO-блоги, «30 tips» без первоисточника |
| **Official** | Creator Hub / API Roblox — как реализовать в движке | Community «how to click ParticleEmitter» |
| **Studio primary** | Talks miHoYo / NetEase / Unity Dojo от инженеров студии | «Сделай как Genshin» без tech talk |
| **Reference study** | Разбор кадров реальных игр своими глазами | Чужие «aesthetic compilations» без анализа слоёв |

**Правило учёбы:** принцип берёшь из Canon → вкус калибруешь Reference study → в Roblox кладёшь через Official docs + свои drills.

---

## Проф-канон по дисциплинам

### A. Game feel / juice (основа «сочности»)

| #   | Источник                                     | Кто                                             | Почему это профи                                                         | Ссылка                                                                                                                   |
| --- | -------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| 1   | **Game Feel** (книга, 2008)                  | Steve Swink                                     | Единственная серьёзная таксономия virtual sensation; 6 компонентов feel  | [Elsevier / книга](https://shop.elsevier.com/books/game-feel/swink/978-0-12-374328-2) · ISBN 978-0-12-374328-2           |
| 2   | **Juice it or Lose It**                      | Martin Jonasson & Petri Purho (GDC Europe 2012) | Живой эталон: та же механика → мёртвая vs сочная                         | [YouTube](https://www.youtube.com/watch?v=Fy0aCDmgnxg) · [GDC Vault](https://gdcvault.com/play/1016487/juice-it-or-lose) |
| 3   | **The Art of Screenshake** (~30 tiny tricks) | Jan Willem Nijman, Vlambeer (INDIGO 2013)       | Практика от автора Nuclear Throne / Super Crate Box; индустриальный must | [YouTube](https://www.youtube.com/watch?v=AJdEqssNZ-U) · alt [SkgkIXZ_13Y](https://www.youtube.com/watch?v=SkgkIXZ_13Y)  |
| 4   | **Secrets of Game Feel and Juice**           | Mark Brown, Game Maker's Toolkit                | Разбор канона для практиков; не замена Swink/Vlambeer, а карта           | [YouTube](https://www.youtube.com/watch?v=216_5nu4aVQ)                                                                   |
| 5   | **Designing Game Feel: A Survey** (2020)     | академический survey                            | Карта литературы / практик feel (для глубины, не для первого дня)        | [arXiv PDF](https://arxiv.org/pdf/2011.09201)                                                                            |

**Порядок:** Juice it (1×) → Screenshake (1× с конспектом трюков) → Swink (чтение + упражнения) → GMTK как повторение.

**Drill A:** выпиши из Screenshake 15 трюков → отметь, какие применимы к merge/hatch в Roblox (не все action-shooter трюки нужны).

---

### B. Анимация (вес, timing, readable motion)

| # | Источник | Кто | Почему это профи | Где |
|---|---|---|---|---|
| 1 | **The Illusion of Life** | Frank Thomas & Ollie Johnston (Disney) | 12 принципов анимации — мировой стандарт | книга |
| 2 | **The Animator's Survival Kit** | Richard Williams | Timing, spacing, weight от оскароносного аниматора | книга |
| 3 | **12 Principles** (применение в играх) | Disney principles → interactive | Anticipation / follow-through / squash = твой tween language | после Illusion of Life |

**Что вынести в Roblox (не «нажми Tween»):**
- Anticipation → wind-up scale перед merge
- Squash & stretch → impact punch
- Follow-through → linger VFX / settle tween
- Timing & spacing → длительности 80–200ms, не Linear на живое
- Exaggeration → rarity tiers читаются без текста
- Staging → один фокус на экране reward

**Drill B:** один prop, 3 версии анимации: Linear / с anticipation / с anticipation+overshoot+settle. Blind A/B.

**Roblox Official (реализация, не вкус):** [UI animation/tweens](https://create.roblox.com/docs/ui/animation) · [Character animations](https://create.roblox.com/docs/animation)

---

### C. Свет и цвет (дорогое ощущение кадра)

| # | Источник | Кто | Почему это профи | Где |
|---|---|---|---|---|
| 1 | **Color and Light** | James Gurney | Индустриальный стандарт понимания света/цвета для художников | книга |
| 2 | **Key / Fill / Rim** (трёхточечный свет) | классика cinematography / lighting | Любая «сочная» сцена = направленный свет + fill + rim, не flat ambient | теория + практика в Studio |
| 3 | **miHoYo — Genshin console rendering** | Zhenzhong Yi, Studio Technical Director | Как студия думает PBR-stylized, tone, pipelines (не копировать код — копировать *решения*) | [Docswell slides](https://www.docswell.com/s/UnityJapan/KWRPQ5-210617-unity-dojo20211mihoyozhenzhongyi) · [summary EN](https://nugglet.github.io/posts/2022/12/console_graphics_rendering_pipeline_genshin_impact) |
| 4 | **Genshin: Crafting an Anime Style Open World** | Haoyu Cai (Producer/CEO), GDC 2021 | Art pillars / composition / почему anime open world читается | [GDC Vault](https://gdcvault.com/play/1027539/-Genshin-Impact-Crafting-an) |

**Что вынести в Roblox:**
- Стилизация ≠ «всё яркое»; = **контроль value + accent**
- Bloom / emission — акцент, не ковёр
- Day/Night = разные mood presets, не один слайдер
- Silhouette first (читается на телефоне)

**Roblox Official:** [Post-processing](https://create.roblox.com/docs/environment/post-processing-effects) · [Outdoor lighting](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments) · [BloomEffect](https://create.roblox.com/docs/reference/engine/classes/BloomEffect) · [SurfaceAppearance](https://create.roblox.com/docs/art/modeling/surface-appearance)

**Drill C:** одна сцена, только свет (без VFX). День + ночь. Скрин с телефона: силуэты читаются?

---

### D. VFX (слои feedback, не «частицы ради частиц»)

Проф-подход: VFX = **информация + вес удара**, синхрон с animation contact frame и SFX.

| # | Источник | Зачем |
|---|---|---|
| Juice it + Screenshake | Слои feedback: flash → burst → linger |
| Frame study (§F) | Как AAA режет один impact на 3–5 слоёв |
| Roblox Official particles | Сборка в движке | [curriculum](https://create.roblox.com/docs/tutorials/curriculums/artist/work-with-particle-emitters) · [API](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter) · [guide](https://create.roblox.com/docs/effects/particle-emitters) |

**Канон слоёв impact:**

| Слой | Роль | Lifetime | Roblox |
|---|---|---|---|
| Core flash | подтверждение hit | 0.05–0.15s | 1 emitter, мало частиц, Size pop, LightEmission 1 |
| Burst sparks | направление силы | 0.2–0.5s | SpreadAngle, Speed высокий, `:Emit` |
| Smoke / mist | follow-through | 0.5–1.2s | медленный, Acceleration вверх/вниз, fade |
| Lingering glow | rarity residue | 0.8–2s | только Rare+ |
| PointLight pulse | свет в мире | 0.1–0.25s | tween Brightness → 0 |

#### VFX-first: сегодня (День 1)

1. Открой [Juice it or Lose It](https://www.youtube.com/watch?v=Fy0aCDmgnxg).  
2. Пиши только про **visual layers** (particles, flash, trails, permanence) — остальное потом.  
3. Не открывай Studio в День 1. Цель — язык, не кнопки.

#### VFX-first: День 4–6 Studio skeleton

```
ImpactVFX (Model)
└── Attachment
    ├── PE_Core      (Enabled=false)
    ├── PE_Sparks    (Enabled=false)
    ├── PE_Mist      (Enabled=false)
    └── PointLight   (Brightness=0)
```

`Play(rarity)`:
- Common → Emit core only (+ tiny light)
- Rare → core + sparks
- Epic → + mist
- Mythic → + linger counts + stronger light + optional screen flash later

**Drill D:** common vs mythic отличимы на телефоне **без текста и без UI**.

---

### E. UI (иерархия, punch, readable)

| # | Источник | Кто | Почему это профи | Где |
|---|---|---|---|---|
| 1 | **Refactoring UI** | Adam Wathan & Steve Schoger | Практический канон визуальной иерархии для людей, которые делают продукт | книга / [refactoringui.com](https://www.refactoringui.com/) |
| 2 | Disney staging + juice reward moment | Illusion of Life + Juice it | Reward screen = staging одного субъекта + feedback stack | книги/talks выше |
| 3 | Roblox Official UI | Creator Hub | Реализация tweens / layout | [UI](https://create.roblox.com/docs/ui) · [UI animation](https://create.roblox.com/docs/ui/animation) |

**Что вынести:**
- Один фокус, contrast, spacing, rarity tokens
- Button states = Idle / Hover / Pressed / Disabled
- Reward ceremony = flash + punch + stinger + hold (не «TextLabel появился»)

**Drill E:** RewardToast с count-up; сравнить с мгновенным set text.

---

### F. Reference study (как учатся в студиях)

Не смотреть «красиво», а **разбирать слои**.

| Реф | Что снимать на паузе |
|---|---|
| Genshin / WuWa / ZZZ | 1 удар / 1 gacha reveal: сколько VFX-слоёв? цвет? timing flash? |
| Hades | hit confirm stack (звук + частицы + shake + реакция врага) |
| Celeste | jump/dash: минимум эффектов, максимум точности |
| Peggle | «мелочь» сделана momentous (fanfare) — урок для rarity |
| Топ Roblox (твой niche) | что *реально* читается на телефоне в Discover |

**Шаблон разбора (1 страница на момент):**
1. Anticipation (есть/нет, мс)  
2. Impact layers (перечисли)  
3. Camera (shake / FOV / hold)  
4. Audio layers (сколько звуков)  
5. UI (что всплыло)  
6. Что перенесёшь в Roblox kit на этой неделе  

---

## Порядок обучения (проф-трек)

### Активный трек: **VFX-first** (выбран 2026-08-02)

Свет/UI/анимацию не игнорировать навсегда — но **ядро сейчас = impact VFX language**. Минимум feel-канона нужен, иначе частицы будут «красивым шумом».

| День | Что | Canon / Official | Критерий |
|---|---|---|---|
| 1 | Feel → зачем слои | [Juice it](https://www.youtube.com/watch?v=Fy0aCDmgnxg) (целиком) | 10 пунктов: что даёт каждый слой feedback |
| 2 | Impact language | [Screenshake](https://www.youtube.com/watch?v=AJdEqssNZ-U) — только трюки про particles / freeze / shake / permanence | Конспект: что переносится в merge/hatch |
| 3 | Frame study #1 | 1 удар / 1 reveal в Genshin или Hades, пауза по кадрам | Заполнен шаблон §F (слои + timing) |
| 4 | Roblox particles API | [Particle curriculum](https://create.roblox.com/docs/tutorials/curriculums/artist/work-with-particle-emitters) + [API](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter) | Умеешь Sequences + Emit vs Rate |
| 5–6 | Kit: 3-layer impact | Studio drill §2 | `Core / Sparks / Mist` + PointLight на Attachment |
| 7 | Rarity language | Тот же kit × 4 rarity | Отличимы **без текста** на телефоне |
| 8 | Sync | Contact frame (даже простой tween) + SFX whoosh/impact | 1 Module `VFX.Play(rarity)` |
| 9 | Frame study #2 | Другой реф (WuWa / ZZZ / Celeste dash) | 3 отличия от study #1 |
| 10 | Ship в проект | Подключи к реальному verb (merge/hatch) | Клип 5 сек → Definition of Done §Master |

**После VFX-first:** свет (чтобы FX «сели» в кадр) → motion/UI → camera tiers.

### Полный трек (после VFX)

| Фаза | Фокус | Canon | Критерий «готово» |
|---|---|---|---|
| 0 | Feel language | Juice it + Screenshake + Swink start | Конспект 20 принципов |
| 1 | **VFX** ← сейчас | Frame study + Official particles | 3-layer impact kit по rarity |
| 2 | Свет | Gurney + miHoYo talks + Lighting | FX читаются, bloom не убивает |
| 3 | Motion | Illusion of Life → Tween | Anticipation + contact frame |
| 4 | UI | Refactoring UI | Reward ceremony |
| 5 | Camera + audio | Screenshake + layered SFX | Shake tiers + 3-layer SFX |
| 6 | Vertical slice | всё вместе | `Feedback.Play(verb, rarity)` |

Каждый день: **1 час** — 30 мин canon/reference + 30 мин Studio drill.

---

## Главная идея (для Roblox)

```
КАЖДОЕ важное действие =
  anticipation
  → impact (flash / particles / light)
  → follow-through (camera / UI / sound)
  × минимум 3 канала (visual + motion + audio)
```

```
PREMIUM FEEL =
  style lock
  × lighting/post
  × layered VFX
  × tween weight
  × UI punch
  × camera language
  × SFX layers
```

---

## 1) Свет и пост-обработка — чеклист Roblox

### Объекты
`Lighting` · `Atmosphere` · `Sky` · `BloomEffect` · `ColorCorrectionEffect` · `DepthOfFieldEffect` · `SunRaysEffect` · `PointLight` / `SpotLight` / `SurfaceLight`

### Чеклист

- [ ] `Lighting.Technology = Future` (или ShadowMap, если целевой девайс не тянет)
- [ ] **ClockTime** / mood зафиксирован (не дефолт «плоско»)
- [ ] `Ambient` / `OutdoorAmbient` из art bible, не серая грязь
- [ ] `Brightness` + `ExposureCompensation` → midtones читаются
- [ ] `EnvironmentDiffuseScale` / `EnvironmentSpecularScale` ≈ 1 для PBR
- [ ] **Key + fill + rim** на hero subjects
- [ ] Локальный `PointLight` на portal / hatch / merge flash
- [ ] Neon / Emission sparingly — rarities и FX
- [ ] Atmosphere (Density / Haze / Glare / Color)
- [ ] Bloom: высокий Threshold, умеренный Intensity (акцент, не ковёр)
- [ ] ColorCorrection = один mood LUT-эквивалент
- [ ] DepthOfField точечно (shop / reveal), не always-on
- [ ] Проверка на **телефоне / low quality**
- [ ] День и ночь — **два пресета**

### Стартовые значения (тюнить)

| Эффект | Старт |
|---|---|
| Bloom.Threshold | 0.8–1.2 |
| Bloom.Intensity | 0.3–0.7 |
| Bloom.Size | 12–24 |
| ColorCorrection.Saturation | 0.05–0.25 |
| ColorCorrection.Contrast | 0.05–0.2 |
| Atmosphere.Density | 0.2–0.4 |
| Impact PointLight | Brightness 2–6, Range 8–20, 0.1–0.25s |

### Источники вкуса / реализации
→ §C Canon · Roblox Official в §C

---

## 2) VFX — чеклист Roblox

- [ ] На `Attachment`, не на огромном Part
- [ ] Своя текстура (soft circle / spark), не дефолт-квадрат
- [ ] Color / Transparency / Size = Sequences
- [ ] `LightEmission` высокий для magic; низкий для пыли
- [ ] Impact = `:Emit(n)`, ambient = Rate
- [ ] SpreadAngle / Acceleration = направление силы
- [ ] Бюджет: impact ≤ ~3 emitters
- [ ] Цвет = rarity tokens из art bible
- [ ] Sync с contact frame анимации и SFX (±2–3 кадра)

### Rarity language

| Rarity | VFX | Light |
|---|---|---|
| Common | 1 burst | нет / слабый |
| Rare | burst + sparks | короткий pulse |
| Epic | + smoke + ring | цветной |
| Mythic | 3–4 слоя + linger + flash | сильный |

### Источники
→ §D Canon · Official particles

---

## 3) Анимация / weight — чеклист Roblox

### Object tween
- [ ] Anticipation (scale ~0.92, 50–100ms)
- [ ] Impact punch (→ ~1.12 → 1.0), Back/Quad Out
- [ ] Gameplay UI durations 0.12–0.35s
- [ ] Не Linear на «живое»
- [ ] Цепочки `Completed`; старый tween `:Cancel()`
- [ ] Корректный Pivot / PrimaryPart

### Character / unit
- [ ] Idle с дыханием / weight shift
- [ ] Явный **contact frame** для VFX/SFX
- [ ] Shared rig + accessories (kit)
- [ ] Priority / FadeTime осознанны
- [ ] Rarity-up = clip + VFX, не только UI

### Easing

| Feeling | EasingStyle |
|---|---|
| Soft UI | Quad / Cubic Out |
| Playful pop | Back Out |
| Heavy impact | Quad + hit-stop |
| Snappy | Exponential Out |

### Источники
→ §B Canon · Official animation/tween docs

---

## 4) UI — чеклист Roblox

- [ ] Scale layout; safe areas на телефоне
- [ ] Один визуальный фокус
- [ ] Контраст читается на ярком солнце
- [ ] Rarity Color3 tokens единые
- [ ] 1–2 шрифта; Title > Body > Meta
- [ ] Модалка: Blur на Camera + panel pop
- [ ] Button states полные
- [ ] Reward: punch + banner + count-up + SFX
- [ ] UI SFX отдельно от world
- [ ] Анимация UI ≤ ~0.4s для gameplay

### Reward / rarity moment
- [ ] Flash / ColorCorrection 50–100ms
- [ ] Banner + icon pop (Back Out)
- [ ] World/UI VFX sync
- [ ] Stinger по rarity
- [ ] Hold 0.3–0.6s

### Источники
→ §E Canon · Official UI docs · [[../Starter Pack/06 — visual and hook]]

---

## 5) Камера и hit-feel — чеклист

| Tier | Когда | Duration |
|---|---|---|
| Light | ordinary merge | 0.05–0.1s |
| Medium | rare / solid | 0.1–0.18s |
| Heavy | epic | 0.18–0.3s |
| Mega | mythic reveal | 0.25–0.4s |

- [ ] Shake = additive на Camera (не на character)
- [ ] Trauma → decay (не random forever)
- [ ] Accessibility toggle
- [ ] FOV punch 1–3° на heavy
- [ ] Hit-stop 40–100ms **локально** (не весь сервер)
- [ ] Clamp при стаке событий

### Источники
→ Screenshake (Nijman) · Juice it · Swink (polish / juiciness)

---

## 6) Звук — чеклист

- [ ] Whoosh + impact + optional chime на verb
- [ ] Rarity stingers разные
- [ ] Pitch variation ±5–10%
- [ ] Sound groups: Master / SFX / UI / Music
- [ ] Один `PlayFeedback` синхронизирует VFX+UI+SFX

**Проф-метод калибровки:** frame study §F — считай слои на ударе в рефе, потом строй столько же (упрощая под Roblox).

---

## 7) Материалы — чеклист

- [ ] SurfaceAppearance на hero meshes
- [ ] Контраст matte / metal / emissive
- [ ] Emission только на глазах / рунах / rarity
- [ ] Силуэт важнее densе topology
- [ ] Единый scale kit ([[../Метод Tizzy/Анализы/Merge Arena — визуальный стиль]])

Official: [SurfaceAppearance](https://create.roblox.com/docs/art/modeling/surface-appearance)

---

## Master drill — один verb до совершенства

| t (ms) | Visual | Motion | Audio | UI |
|---|---|---|---|---|
| 0 | anticipation pose | scale 0.94 | whoosh | — |
| 80 | — | move/impact | — | — |
| 100 | core flash + Emit | scale 1.12 + hit-stop | impact | — |
| 100 | sparks | camera shake tier | — | — |
| 120 | PointLight | FOV punch | — | number start |
| 180 | mist linger | settle 1.0 | chime | rarity banner |
| 400–800 | glow fade | — | — | hold |

### Definition of Done
- [ ] Клип 5 сек с телефона — хочется пересмотреть
- [ ] Rarity отличимы **без текста**
- [ ] Low graphics не разваливается
- [ ] `Feedback.Play("Merge", rarity)` вызывает всё
- [ ] Второй verb клонируется из kit < 1 дня

---

## Анти-паттерны

| ❌ | ✅ |
|---|---|
| Учиться с random Roblox YouTube | Canon → Official → drill |
| Bloom на всё | Bloom на акценты |
| 1 particle на mythic | 3–4 слоя |
| Linear везде | Anticipation + easing из 12 principles |
| Копировать Genshin меши 1:1 | Копировать **принципы** timing/слоёв/читаемости |
| Полировать всю карту | Vertical slice → clone |
| Читать только чеклисты | Сначала Swink / Nijman / Disney, потом чеклист |

---

## Трекер мастерства

| Слой | L1 | L2 | L3 |
|---|---|---|---|
| Feel language | Juice it понял | Screenshake законспектирован | Swink: диагнозы feel |
| Свет | Future + Bloom | Day/Night + rim | Mood library |
| VFX | 1 emitter | 3-layer kit | Rarity language |
| Анимация | Tween move | Anticipation+overshoot | Contact-frame sync |
| UI | Static | States + tweens | Reward ceremony |
| Камера | Default | Shake tiers | Trauma + FOV + hit-stop |
| Звук | 1 SFX | Layered groups | Rarity stingers |

---

## Weekly ритуал

1. 1 verb / 1 экран.  
2. 30 мин Canon или frame study.  
3. 30–60 мин Studio по чеклисту.  
4. Before/after клип.  
5. Удачное → в **kit**. Новый стиль не начинать, пока kit не закрывает ~80% контента.

---

## Связанные заметки

- [[00 — фундамент]]
- [[../Starter Pack/06 — visual and hook]]
- [[../Starter Pack/07 — процесс создания хита]]
- [[../Zeon — bренд и маркетинг/05 — visual styles]]
- [[../Метод Tizzy/Анализы/Merge Arena — визуальный стиль]]
- [[../Метод Tizzy/Анализы/Merge Arena — персонажи Blender]]

#gamedesign #roblox #polish #vfx #ui #lighting #animation #juice #canon
