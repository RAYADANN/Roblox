# BREED & RAID — уточняющий опросник (программист → GD / LD)

Цель: закрыть неоднозначности до кода. Не предлагаю дизайн — только вопросы.  
**BLOCKER** = без ответа нельзя начинать graybox / data model / net.

---

## 1. World / plot / server layout

1. **BLOCKER** Максимум игроков на сервере: сколько? (например 6 / 8 / 12 / 16)
2. **BLOCKER** Один сервер = N одинаковых plot’ов? Сколько plot’ов на сервере ровно?
3. **BLOCKER** Размер одного plot в studs (длина × ширина × высота полезной зоны)?
4. **BLOCKER** Plot’ы в ряд / кольцо / сетка? Минимальный зазор между соседними plot’ами (studs)?
5. Есть ли общая «lobby / hub» зона вне plot’ов? Если да — размеры и что там можно делать (только spawn / shop / AFK)?
6. Точка spawn игрока: центр своего plot / вход / hub? Координаты относительно origin plot’а?
7. Можно ли свободно ходить по чужим plot’ам всегда, или только в режиме raid?
8. Есть ли границы plot’а с невидимыми стенами / kill volume / teleport back? Что происходит при выходе за границу?
9. Камера по умолчанию: 3rd person follow / fixed isometric / custom? Можно ли zoom? Min/max FOV и zoom distance?
10. Shift-lock / first-person разрешены? Если да — влияет ли на aim bat/steal?
11. StreamingEnabled / WorldPivot: plot’ы должны грузиться streaming’ом или весь мир в памяти?
12. Есть ли day/night cycle в мире (см. §9) или всегда одно освещение? Какие Lighting presets (Ambient, Brightness, ClockTime)?

---

## 2. Nest / pedestal / creature placement

13. **BLOCKER** Сколько nest/pedestal слотов на старте у игрока? Максимум слотов на v1?
14. **BLOCKER** Nest = только spot для creature, или ещё отдельный «income node»? Один creature = один nest?
15. Creature ставится: snap to nest only / free place на полу / grid? Если grid — размер ячейки (studs)?
16. Можно ли переставлять creature между nest’ами? Стоимость / cooldown / мгновенно?
17. Можно ли снять creature с nest в inventory без продажи? Да/нет.
18. Что отображается над nest: MPS, имя, rarity, timer breed/lock? Billboard всегда или по proximity (studs)?
19. Пустой nest vs занятый: визуальные отличия обязательны? Какие?
20. Можно ли поставить 2 creature на один nest? (ожидаю нет — подтвердите)
21. Nest разрушаем/перемещаем игроком или фиксирован LD-разметкой?
22. Если все nest заняты и приходит новый roll — куда идёт creature: overflow storage / auto-sell / block roll?

---

## 3. Creature data model

23. **BLOCKER** Список обязательных полей creature на сервере (пример для подтверждения/правки): `id`, `templateId`, `ownerUserId`, `genes[]`, `rarity`, `mps`, `level`, `bornAt`, `lockedUntil`, `isHybrid`, `visualSeed` — что убрать/добавить?
24. **BLOCKER** Сколько base species/templates в MVP? В v1? (числа)
25. Rarity tiers: точный enum и порядок (Common→…→?). Сколько тиров?
26. MPS считается: фиксированная таблица по rarity / формула от genes / сумма обоих? Если формула — напишите её.
27. Genes: дискретные аллели (список) или числа 0–100? Сколько gene slots на creature?
28. Hybrid = новый `templateId` или тот же base + gene flags? Как кодируется в save?
29. Look pipeline: приоритет слоёв (base mesh → primary color → secondary → scale → accessory A/B → aura). Подтвердите порядок и что может стакаться.
30. Scale range для hybrids: min/max multiplier (например 0.8–1.4)?
31. Accessories: сколько слотов (head/back/aura)? Один accessory на слот или несколько?
32. Creature имеет HP / durability или бессмертен до steal/sell?
33. Уникальный instance id: UUID string / incremental int? Нужен ли client-visible id?
34. Stacking одинаковых non-hybrid в inventory: stack count или всегда unique instances?

---

## 4. Roll / earn / shop economy

35. **BLOCKER** Список валют: Soft (имя), Premium (Robux only?), другие (incubator tokens, keys)? Точные имена для UI/DataStore.
36. **BLOCKER** Как игрок получает первую creature: free starter / first roll free / tutorial grant? Что именно выдаётся (template + rarity)?
37. Roll cost в soft: фиксированная цена или растущая? Числа для roll 1, 10, pity?
38. Roll выдаёт: creature сразу в inventory / сразу на свободный nest / в egg?
39. Soft earn sources кроме MPS: sell creature, quests, daily, steal bounty — какие включены в MVP?
40. MPS payout interval: каждую 1s / 5s / на Heartbeat batch? Округление вниз/вверх?
41. Soft cap / inventory cap / nest income soft-cap есть? Числа.
42. Shop categories в MVP: nests, incubators, luck, cosmetics, traps, bat upgrades — что из этого продаётся за soft vs Robux?
43. Цены soft на nest upgrade / extra nest slot: таблица уровней 1…N?
44. Luck: что именно меняет (roll weights / breed rare chance / steal success)? Числовые веса до/после.
45. Можно ли продавать creature? Цена = f(rarity, mps, hybrid)? Формула или таблица.
46. Refund / undo покупки soft в течение N секунд? Да/нет.

---

## 5. Breed / fuse / incubate

47. **BLOCKER** Breed = выбрать ровно 2 creature на nest’ах владельца? Можно ли с inventory без nest?
48. **BLOCKER** Длительность incubate по умолчанию (секунды). Ускорение: soft / Robux / skip ticket — что разрешено?
49. **BLOCKER** Родители: сгорают (consumed) / остаются / шанс burn %? Точные % fail / burn / success.
50. **BLOCKER** Inheritance: какие поля от A/B (rarity up-chance, gene pick rules, color lerp vs discrete, accessory inherit %). Нужна таблица правил.
51. Кто может начать breed: только owner на своём plot? Нужен ли оба nest «свободны от lock/raid»?
52. Queue: один incubate за раз на игрока / N параллельных incubators? Макс N?
53. Incubator — предмет/строение? Занимает grid slot? Сколько стартовых incubator slots?
54. Во время incubate nest’ы родителей заняты/заблокированы для steal?
55. Hybrid результат виден сразу или «egg mystery» до hatch?
56. Можно ли отменить incubate? Refund родителей / потеря?
57. Fail result: ничего / junk creature / partial genes? Что именно.
58. Cooldown между breed’ами на аккаунт / на пару parents?

---

## 6. Steal / carry / lock / bat / traps

59. **BLOCKER** Что можно steal: любой nest creature / только hybrids / только unlocked / не starter? Точный whitelist.
60. **BLOCKER** Steal flow по шагам: approach → hold interact N s → carry → reach own plot → deposit. Какие шаги обязательны и тайминги (секунды)?
61. **BLOCKER** Carry speed multiplier vs normal walk (например 0.6×). Можно ли jump/sprint while carrying?
62. **BLOCKER** Lock: длительность (s), стоимость soft, кто может lock (только owner), lock снимается автоматически или вручную?
63. Bat: range (studs), hit cooldown (s), stun duration (s), knockback studs, урон по carry (drop chance %)?
64. Bat бьёт только carriers или любого врага на plot?
65. Traps: типы в MVP (slow / snare / alarm / launch)? Радиус, duration, place limit per plot, cost.
66. Trap triggers: только enemies / также owner? Friendly fire?
67. После успешного steal: creature мгновенно у жертвы пропадает (server) — куда у вора: carry object / inventory / auto-nest?
68. Fail states steal: victim reclaim proximity, bat drop, trap, timeout carry, leave server mid-carry — что с creature в каждом случае?
69. Steal immunity после потери: сколько секунд nest/creature нельзя steal снова?
70. Можно ли steal у одного игрока несколько раз подряд в сессии? Soft limit?
71. PvP damage outside steal context существует? (ожидаю нет — подтвердите)
72. Indication «you are being robbed»: UI + SFX обязательны? Когда exactly (on interact start / on leave nest)?

---

## 7. Build / base parts

73. **BLOCKER** Build в MVP: есть / нет? Если есть — список placeable parts (wall, gate, trap pad, deco, path).
74. Placement: free move с snap / grid N studs / только preplaced sockets от LD?
75. Build inventory: лимит частей на plot? Soft cost per place? Rotate 90° only?
76. Можно ли удалить/продать поставленное? Refund %?
77. Collisions build-частей блокируют steal path by design — или LD гарантирует 2+ approach routes всегда?
78. Plot permissions: друзья могут строить? Группа? Только owner?

---

## 8. Leaderboards / visibility / billboards

79. Leaderboard метрики в MVP: richest soft / most steals / best hybrid rarity / total MPS — какие топ-N?
80. Scope: server-only / global OrderedDataStore / daily reset?
81. На plot billboard: player name + emblem + top creature? Всегда visible с какой дистанции (studs)?
82. В чужом plot UI показывает MPS/rarity жертвы всегда или только в raid mode?
83. Hide wealth / private mode существует? (монетизация?)

---

## 9. Day cycle / sessions

84. **BLOCKER** Always-day / day-night cycle / session timers (например raid window каждые N минут)? Выберите одну модель для MVP.
85. Если sessions: длительность peaceful vs raid (минуты), кто объявляет, что происходит с carry на границе фазы?
86. AFK income во время offline — см. §11; во время online AFK на сервере MPS идёт или пауза после N минут?

---

## 10. Tutorial / first 2 minutes

87. **BLOCKER** Строгий script первых 120 секунд: шаг1…шагK (roll → place → earn → breed → defend/steal). Перечислите обязательные шаги и что блокируется до completion.
88. Tutorial steal: против бота/NPC nest или реального игрока? Если игроков <2 — fallback?
89. Можно ли скипнуть tutorial? Да/нет; сохраняется ли flag в profile.
90. Soft/creature grants во время tutorial: точные количества, чтобы не сломать economy.

---

## 11. Progression / rebirth / offline

91. **BLOCKER** Есть ли rebirth/prestige в MVP? Если да — что сбрасывается / что остаётся / бонус за rebirth.
92. Offline earnings: % of MPS, cap часов (например 4h), collect on join — числа.
93. Progression unlock order: extra nest, incubator, traps, bat, shop tiers — дерево с порогами (soft / level / rebirth).
94. Player level существует отдельно от soft? XP source?
95. Max meaningful progression time to «full unlock» в часах (для балансировки soft sinks)?

---

## 12. Monetization (exact products)

96. **BLOCKER** Полный список GamePass / DevProduct на MVP с: именем, Robux price (или «TBD price but effect locked»), эффектом, soft-equivalent если есть.
97. Подтвердите правило: **нет** unstealable / permanent lock pass. Какие convenience-only эффекты допустимы (x2 incubate speed, +1 nest, cosmetics, luck +N%)?
98. Cosmetics: trail, nest skin, bat skin, name color, plot theme — что в MVP?
99. Gift passes? Season pass? Daily Robux pack? Да/нет для MVP.
100. Soft purchase за Robux (currency pack): тиры и amounts.
101. Что происходит с paid convenience при rebirth (если rebirth есть)?

---

## 13. HUD / UI — каждый элемент

102. **BLOCKER** Полный список HUD элементов MVP с позицией (TL/TR/BL/BR/center): soft counter, MPS, buttons (Roll/Breed/Shop/Bag/Inventory), carry bar, lock button, stun overlay, notifications, mobile buttons.
103. Inventory UI: grid size, filters (rarity/hybrid), actions (place/sell/breed-select).
104. Breed UI: pick A/B flow — modal на nest или отдельный menu?
105. Shop UI: tabs exact names.
106. Steal victim alert UI: toast / fullscreen vignette / plot arrow?
107. Settings: music, SFX, reduce VFX, trade unlock — что есть?
108. Death/respawn UI нужен? (если нет HP — подтвердите отсутствие)
109. Prompt style: ProximityPrompt only / custom billboards / both?

---

## 14. Audio / VFX checklist per action

110. Для каждого действия нужен ли SFX+VFX обязательный набор (yes/no + loops?): Roll, Place, MPS tick, Breed start, Hatch, Steal start, Carry loop, Steal success, Steal fail, Lock on/off, Bat hit, Trap trigger, Purchase, Level-up/unlock, Tutorial step.
111. Rarity-dependent juice: разные pitch/particles по rarity? С какого тира «extra»?
112. Mobile: reduce particles toggle default on low devices?

---

## 15. Networking / authority

113. **BLOCKER** Подтвердите server-authoritative для: currency, inventory, nest occupancy, breed timers, steal state machine, bat hit validation, trap trigger, shop purchase, MPS grant.
114. Client-predicted только cosmetics/VFX/animation? Или ещё move while carry?
115. Remotes: список intended events (RequestRoll, PlaceCreature, StartBreed, StartSteal, DepositSteal, UseBat, PlaceTrap, BuyProduct…) — GD подтверждает набор для MVP.
116. Rate limits: min interval per remote (ms) желаемые с GD стороны (анти-спам UX).
117. Replication: creature visuals на всех клиентах через attributes / Replica / custom — предпочтений GD нет, но нужны правила «что видит stranger» (mps hidden?).

---

## 16. Save profile schema (вопросы)

118. **BLOCKER** ProfileService/DataStore key schema: какие top-level keys обязательны? (currencies, creatures{}, nests{}, unlocks{}, settings{}, tutorial{}, purchases{}, stats{})
119. Creature save: сохраняем visualSeed или пересчитываем от genes всегда?
120. Timestamps: incubateEnd, lockEnd, offlineLeaveAt — UTC seconds?
121. Versioning: нужен ли `schemaVersion` и миграции с дня 1?
122. Что НЕ сохраняется (session carry state, temporary stun)?
123. Max creatures in profile hard cap? (анти-дуп/размер datastore)

---

## 17. PROVE / MVP cut vs v1

124. **BLOCKER** PROVE (серая коробка, 1–2 дня): какие 5 механик must-work? (пример для confirm: place+MPS, breed timer fake, steal carry, lock, one bat)
125. MVP launch cut: systems in / out из списка: build grid, traps, rebirth, global LB, cosmetics shop, day cycle, offline earnings.
126. v1 post-launch: приоритетный backlog топ-5.
127. Art lock: 5–8 base meshes — exact count и names/roles (attacker/tank/cute…)? Accessory count budget?

---

## 18. Anti-cheat / trade / dupe

128. **BLOCKER** Trading между игроками в MVP: on/off? Если on — какие поля transferable и confirmation UI?
129. Dupe vectors GD должен закрыть правилами: leave during carry, two thieves one nest, sell while stolen, breed while locked, purchase during steal — ожидаемый resolve для каждого.
130. Teleport/noclip steal: server distance checks — max interact distance (studs) и max carry path sanity?
131. Speed exploits while carry: server max walkspeed cap?
132. Friend base abuse: can alts funnel steals? Есть ли steal value tax / diminishing returns?
133. Sold creature reappears: confirm server deletes instance id permanently.
134. Robux purchase grant: ProcessReceipt only once — GD подтверждает no manual admin grant needed for MVP?

---

## 19. Mobile controls

135. **BLOCKER** Mobile: thumb stick + какие on-screen buttons (Roll, Breed, Lock, Bat, Place Trap, Inventory)? Размеры/зоны safe area.
136. Steal interact: hold button / proximity auto / tap Confirm?
137. Bat aim on mobile: auto-target nearest carrier in radius / tap direction / virtual aim?
138. Camera default distance на телефоне vs ПК — разные значения?
139. Gyroscope? (обычно нет — подтвердите)
140. UI scale: fixed scale list для 768p / tablets?

---

## 20. Level design — plot anatomy / steal distances

141. **BLOCKER** LD: схема одного plot (сверху): spawn, nest row(s), incubator, shop NPC/pad, defense line, entrance. Нужны размеры зон в studs.
142. **BLOCKER** Количество nest позиций на типовом plot layout (не «сколько игрок купил», а hard props в карте) и их координаты/паттерн (2×3, arc…).
143. **BLOCKER** Дистанции подхода для steal: от plot entrance до ближайшего nest (studs); от nest до nest; «chokepoint» ширина прохода (studs).
144. Высота nest pedestal (studs) и carry clearance (чтобы не застрять).
145. Cover для defender: walls/props обязательный минимум; сколько alternate paths в plot (1 / 2 / 3)?
146. Safe zone у spawn: radius где steal/bat disabled? Studs.
147. Shared mid lane / void between plots: ширина corridor (studs), есть ли cover?
148. Out-of-bounds / fall kill: Y < ? → respawn; creature carry lost or kept?
149. Lighting markers / raid path arrows — LD placeable или UI only?
150. Playtest metrics LD хочет с кода: time-to-steal P50, bat interrupt rate — логировать ли с дня 1?

---

## Дополнительно (часто блокирует код на 2-й день)

151. Язык UI MVP: только EN / EN+RU? Строки в Locales module?
152. Нужен ли admin/debug panel в Studio для grant soft/creature?
153. Respawn/character: R6 или R15? Animate package constraints для bat tool?
154. Tool bat = Tool instance in Backpack или context action без Tool?
155. Max simultaneous thieves on one plot?

---

# Minimum BLOCKER set to start graybox (top 15)

Без этих 15 ответов graybox и каркас данных/net начинать нельзя:

1. Max players + plots per server + plot size (studs)  
2. Nest count start/max + placement rule (snap-only?)  
3. Creature fields + base template count + rarity enum  
4. Currencies + first creature grant + roll cost model  
5. Breed: 2 parents rules + duration + consume/fail % + inheritance table  
6. Stealable set + steal state machine timings + carry speed  
7. Lock duration/cost + bat range/CD/stun + traps in/out of MVP  
8. Build system in/out + if in: grid vs sockets  
9. Session model: always-day vs raid windows  
10. Tutorial 120s mandatory steps + empty-server fallback  
11. Offline/rebirth in or out of MVP (binary)  
12. Exact MVP pass/product list + no-P2W-unstealable confirmation  
13. Full HUD element list + mobile buttons  
14. Server-authoritative action list + remote set for MVP  
15. Plot anatomy LD: nest layout, approach distances, path count, safe zone  

---

**Как отвечать удобнее всего:** для каждого BLOCKER — однозначное число/enum/да-нет + краткая таблица; для non-blocker можно «MVP: cut / v1». После ответов на top-15 можно стартовать graybox; остальные закрывают data model, economy и anti-cheat до вертикального среза.