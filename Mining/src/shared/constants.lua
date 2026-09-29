--!strict
-- constants.lua — общие константы

local Constants = {}

export type LayerId = "dirt" | "stone" | "limestone" | "crimson" | "marble" | "obsidian" | "void"

Constants.LAYERS = {
    { id = "dirt" :: LayerId, name = "Grassland", depthStart = 0, depthEnd = 49, bgColor = Color3.fromRGB(150, 190, 120), blockColor = Color3.fromRGB(96, 158, 64) },
    { id = "stone" :: LayerId, name = "Stone Layer", depthStart = 50, depthEnd = 149, bgColor = Color3.fromRGB(74, 74, 74), blockColor = Color3.fromRGB(128, 128, 128) },
    { id = "limestone" :: LayerId, name = "Limestone Layer", depthStart = 150, depthEnd = 299, bgColor = Color3.fromRGB(212, 197, 169), blockColor = Color3.fromRGB(232, 213, 176) },
    { id = "crimson" :: LayerId, name = "Crimson Layer", depthStart = 300, depthEnd = 499, bgColor = Color3.fromRGB(74, 0, 0), blockColor = Color3.fromRGB(139, 0, 0) },
    { id = "marble" :: LayerId, name = "Marble Layer", depthStart = 500, depthEnd = 799, bgColor = Color3.fromRGB(232, 232, 232), blockColor = Color3.fromRGB(242, 242, 242) },
    { id = "obsidian" :: LayerId, name = "Obsidian Layer", depthStart = 800, depthEnd = 1199, bgColor = Color3.fromRGB(13, 0, 26), blockColor = Color3.fromRGB(26, 26, 46) },
    { id = "void" :: LayerId, name = "Void Layer", depthStart = 1200, depthEnd = math.huge, bgColor = Color3.fromRGB(0, 0, 0), blockColor = Color3.fromRGB(13, 0, 26) },
}

-- Phase 14 (визуальная идентичность): профиль освещения на слой — ощущение
-- «спуска вглубь». Данные (не формулы), читаются client/core/LayerEnvironment,
-- который твинит Lighting.Brightness / ClockTime / FogEnd + Atmosphere.Density.
-- dirt = яркая поверхность (полдень), void = почти полная тьма (полночь).
Constants.LAYER_LIGHTING = {
    dirt      = { brightness = 2.2,  clockTime = 14.0, fogStart = 120, fogEnd = 900, atmosphereDensity = 0.30, atmosphereHaze = 1.0 },
    stone     = { brightness = 1.7,  clockTime = 10.0, fogStart = 100, fogEnd = 700, atmosphereDensity = 0.35, atmosphereHaze = 1.4 },
    limestone = { brightness = 1.4,  clockTime = 8.0,  fogStart = 80,  fogEnd = 600, atmosphereDensity = 0.40, atmosphereHaze = 1.8 },
    crimson   = { brightness = 0.85, clockTime = 5.5,  fogStart = 40,  fogEnd = 380, atmosphereDensity = 0.62, atmosphereHaze = 3.0 },
    marble    = { brightness = 1.5,  clockTime = 7.0,  fogStart = 90,  fogEnd = 650, atmosphereDensity = 0.38, atmosphereHaze = 1.8 },
    obsidian  = { brightness = 0.55, clockTime = 2.0,  fogStart = 25,  fogEnd = 300, atmosphereDensity = 0.68, atmosphereHaze = 3.2 },
    void      = { brightness = 0.28, clockTime = 0.0,  fogStart = 15,  fogEnd = 220, atmosphereDensity = 0.78, atmosphereHaze = 3.8 },
}

-- Шахтёрский фонарик (client/core/Headlamp). PointLight на персонаже —
-- всегда освещает блоки рядом, не убивая атмосферу «спуска во тьму».
-- baseRange/baseBrightness — на поверхности; глубже свет чуть ярче и дальше
-- (depthBonus * нормализованная глубина), чтобы во тьме void было видно.
-- Один источник света — дёшево по перфу (важно после фикса фризов).
Constants.HEADLAMP = {
    enabled = false, -- выкл: свет перенесён на курсор (CURSOR_LIGHT)
    color = Color3.fromRGB(255, 244, 214), -- тёплый белый, как лампа накаливания
    baseRange = 26,
    maxRange = 42,
    baseBrightness = 1.6,
    maxBrightness = 3.0,
    -- глубина (в метрах), на которой фонарик достигает max-значений
    fullPowerDepth = 1200,
    shadows = false, -- тени дороги; держим выкл для производительности
}

-- Свет фонарика на курсоре (client/core/MiningRenderer). Небольшой PointLight
-- следует за лучом мыши в шахте — освещает блок под прицелом, не персонажа.
Constants.CURSOR_LIGHT = {
    brightness = 0.45,
    range = 9,
    color = Color3.fromRGB(255, 248, 230),
    -- если луч не попал в блок — свет вдоль луча на этой дистанции (студы)
    fallbackDistance = 14,
}

Constants.BLOCK_SIZE_STUDS = 4.5
-- Макс. дистанция копания от персонажа (в блоках сетки).
Constants.MAX_MINE_REACH_BLOCKS = 6

-- P0.3 (server-authoritative depth): клиент шлёт depth через "UpdateDepth",
-- но это client-trusted (спуф maxDepthReached / лидерборда / квестов). Сервер
-- пересчитывает «правдоподобную» глубину из Y персонажа (LayerUtil.depthFromY,
-- та же формула что у клиента) и клампит заявленную глубину к serverDepth +
-- slackBlocks. slackBlocks покрывает джиттер репликации и то, что игрок копает
-- на пару блоков ниже корня. Спуф «я на 9999м» обрезается до реальной глубины.
Constants.DEPTH_VALIDATION = {
    slackBlocks = 6,
}

-- P2.9 (Ore Mutation / Variant): «трейлерный» момент. С маленьким шансом
-- свежесгенерированный блок руды становится мутировавшим вариантом — светится
-- в стене своим оттенком, а при добыче даёт бонусные монеты = (valueMult-1) *
-- базовая ценность руды + нотификацию. Полностью data-driven; логика ролла и
-- lookup'ы — shared/util/MutationLogic.lua (единый источник клиент+сервер).
--   rollChance — шанс что блок руды мутирует (на каждый сгенерированный блок).
--   variants   — варианты с весами (внутри ролла), множителем ценности и
--                визуальным оттенком (Neon-tint у блока в стене).
Constants.MUTATIONS = {
    rollChance = 0.004,
    variants = {
        { id = "shiny", name = "mutation.shiny.name", valueMult = 5, weight = 100, tint = Color3.fromRGB(150, 235, 255) },
        { id = "golden", name = "mutation.golden.name", valueMult = 15, weight = 32, tint = Color3.fromRGB(255, 205, 55) },
        { id = "rainbow", name = "mutation.rainbow.name", valueMult = 50, weight = 5, tint = Color3.fromRGB(255, 110, 225) },
    },
}
Constants.SURFACE_W = 15
Constants.SURFACE_D = 15
Constants.SURFACE_H = 10
Constants.SHAFT_W = 5
Constants.SHAFT_D = 5
Constants.SHAFT_H = 5

Constants.RARITY_CHANCES = { common = 0.50, uncommon = 0.30, rare = 0.15, epic = 0.04, legendary = 0.009, mythic = 0.001 }
-- Fallback-вес спавна по rarity, если у руды нет явного weight в OreDatabase.
Constants.RARITY_DEFAULT_WEIGHT = {
    common = 100,
    uncommon = 22,
    rare = 5,
    epic = 1.2,
    legendary = 0.3,
    mythic = 0.08,
}
Constants.RARITY_COLORS = {
    common = Color3.fromRGB(180, 180, 180),
    uncommon = Color3.fromRGB(100, 200, 100),
    rare = Color3.fromRGB(60, 140, 255),
    epic = Color3.fromRGB(180, 60, 220),
    legendary = Color3.fromRGB(255, 160, 0),
    mythic = Color3.fromRGB(255, 50, 50),
}
Constants.RARITY_LABELS = {
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary",
    mythic = "Mythic",
}
-- Скрытые комнаты (MiningEngine.hitBlock):
--   шанс комнаты = SHAFT_BASE_CHANCE + depth * SHAFT_DEPTH_BONUS
--   на каждом шаге каверны 3x3x3 кубик становится air с вероятностью SHAFT_EXPAND_CHANCE
--   редкость сундука бустится на (1 + math.random(0, SHAFT_RARITY_BOOST_MAX)) ступеней
Constants.SHAFT_BASE_CHANCE = 0.08
Constants.SHAFT_DEPTH_BONUS = 0.0001
Constants.SHAFT_EXPAND_CHANCE = 0.7
Constants.SHAFT_RARITY_BOOST_MAX = 2
Constants.SHAFT_RARE_BOOST = 0.25
Constants.SHAFT_PERMANENT_BONUS = 0.005

Constants.UPGRADES = {
    -- powerPerLevel 1.5 (было 2): урон растёт медленнее, mid-game не one-shot.
    pickaxe = { baseCost = 50, exponent = 1.5, maxLevel = 100, powerPerLevel = 1.5 },
    -- reductionPct 0.03 (было 0.04): скорость копания не улетает к полу на L20+.
    speed = { baseCost = 100, exponent = 1.3, maxLevel = 50, reductionPct = 0.03 },
    fortune = { baseCost = 500, exponent = 1.6, maxLevel = 30, chancePerLevel = 0.02 },
    inventory = { baseCost = 150, exponent = 1.4, maxLevel = 20, slotsPerLevel = 5 },
    crit = { baseCost = 400, exponent = 1.6, maxLevel = 15, chancePerLevel = 0.03, baseChance = 0.05 },
    multiSell = { baseCost = 800, exponent = 1.8, maxLevel = 10, bonusPerLevel = 0.05 },
}

Constants.STONE_PICKAXE_MIN_LEVEL = 5
-- 0.35 = −65% урона (было 0.5): дольше «не готов» к новому слою.
Constants.STONE_DAMAGE_PENALTY = 0.35
-- Мин. уровень кирки по слою (ниже — штраф урона STONE_DAMAGE_PENALTY).
Constants.LAYER_PICKAXE_MIN_LEVEL = {
	dirt = 1,
	stone = 5,
	limestone = 12,
	crimson = 22,
	marble = 35,
	obsidian = 50,
	void = 70,
} :: { [LayerId]: number }

-- Множитель HP блоков по слою (база — OreDatabase). Dirt не трогаем (онбординг).
-- Глубина внутри слоя: +DEPTH_HP_BONUS_PER_LAYER_BLOCK за каждый блок ниже
-- depthStart слоя (на дне crimson ~+80% HP).
Constants.LAYER_HP_MULTIPLIER = {
	dirt = 1.0,
	stone = 1.75,
	limestone = 1.8,
	crimson = 1.85,
	marble = 1.9,
	obsidian = 2.0,
	void = 2.0,
} :: { [LayerId]: number }
Constants.DEPTH_HP_BONUS_PER_LAYER_BLOCK = 0.004

-- P0.2 (early-loop juice): стартовая ёмкость рюкзака. С inventoryLevel = 1
-- (старт) ёмкость = BASE + 1 * slotsPerLevel = 25 + 5 = 30 — игрок продаёт
-- реже (раз в ~30 блоков, а не каждые 6 секунд) и видит крупнее число продажи.
Constants.BASE_INVENTORY_SLOTS = 25
Constants.BASE_SWING_DELAY_MS = 400
Constants.MIN_SWING_DELAY_SECONDS = 0.05
Constants.MAX_CLICKS_PER_SECOND = 20
Constants.MAX_MINE_BATCH_SIZE = 16
Constants.AUTOSAVE_INTERVAL = 60

-- Phase 8: стартовый баланс на pickaxe L2 (50). Выдаётся TutorialManager (firstSession).
Constants.STARTER_COINS = 75

-- Шаги туториала (server validates monotonic growth in {0,1,2,3}).
Constants.TUTORIAL_STEPS = {
    NOT_STARTED = 0,
    MINED_FIRST_BLOCK = 1,
    SOLD_FIRST_ORE = 2,
    COMPLETED = 3,
}

-- Phase 9 / P1.4 (Rebirth / Prestige rework): долгосрочная петля.
--   baseCost              — стоимость первого ребёрта.
--   exponent              — множитель цены на каждый следующий ребёрт
--                            (cost = baseCost * exponent^rebirths).
--   multiplierBase        — P1.4: МУЛЬТИПЛИКАТИВНАЯ награда. Множитель к value
--                            руд = multiplierBase ^ rebirths (компаундится):
--                            R1 ×1.6, R3 ×4.1, R5 ×10.5, R10 ×110. Раньше было
--                            линейно (1 + r*0.1) → prestige умирал к R3-R5.
--   multiplierPerRebirth  — legacy fallback (используется только если
--                            multiplierBase не задан).
--   pickaxeMaxBonusAt     — пороги ребёртов, на которых maxLevel pickaxe +1.
--   petSlotBonusAt        — P1.4: пороги, на которых открывается +1 слот пета
--                            (через PetLogic.maxEquipped). Долгосрочный анлок.
--   inventorySlotsPerRebirth — P1.4: +N слотов рюкзака за каждый ребёрт
--                            (через UpgradeLogic.inventoryCapacity).
-- Кривая: цена растёт ×3.5/ребёрт, доход ×1.6/ребёрт + анлоки — prestige
-- остаётся выгодным в долгую (множитель компаундится, гриндить быстрее).
-- Формулы — единый источник в shared/util/RebirthLogic.lua.
Constants.REBIRTH = {
    baseCost = 25000,
    exponent = 3.5,
    multiplierBase = 1.6,
    multiplierPerRebirth = 0.1,
    pickaxeMaxBonusAt = { 5, 10, 25 },
    petSlotBonusAt = { 3, 8, 15 },
    inventorySlotsPerRebirth = 5,
}

-- Phase 10 (Daily Reward + Leaderboard): retention-петля.
--
-- DAILY:
--   cycleDays                   — длина цикла (7 в стандартных Roblox-симах).
--   grantBoostAtDay7            — Day 7 выдаёт coins + x2 boost; флаг для
--                                  будущего A/B-теста.
--   streakResetAfterMissedDays  — если игрок пропустил N+ дней подряд, streak
--                                  обнуляется в 1 (= Day 1).
--   rolloverCheckInterval       — сколько секунд между проверками «у кого
--                                  наступил новый день» в серверном task.spawn.
--                                  60с — компромисс: точность тикает чаще,
--                                  чем игрок успевает кликнуть, но не сжигает
--                                  CPU при 50 одновременных игроках.
-- Формулы дней — shared/util/DailyLogic.lua. Сетка наград — DailyRewardDatabase.lua.
Constants.DAILY = {
    cycleDays = 7,
    grantBoostAtDay7 = true,
    streakResetAfterMissedDays = 2,
    rolloverCheckInterval = 60,
}

-- LEADERBOARD:
--   COINS_MAP / DEPTH_MAP        — ключи MemoryStoreSortedMap. Версионируем
--                                   суффиксом _v1 чтобы при изменении схемы
--                                   можно было ввести _v2 без удаления данных.
--   topSize                      — длина leaderboard'a, который кэшируется
--                                   на сервере и рассылается клиенту.
--   refreshIntervalSeconds       — сервер тянет свежий top из MemoryStore
--                                   раз в N секунд. 30с — это compromise:
--                                   игрок видит «обновление через 28с» в UI,
--                                   а нагрузка на MemoryStore — раз в 30с/сервер,
--                                   не на каждого игрока.
--   expirationSeconds            — TTL для записей в MemoryStore. 30 дней —
--                                   неактивные игроки выпадают из топа.
--   writeThresholdCoins / Depth  — минимальный шаг изменения метрики, чтобы
--                                   записать в MemoryStore. Без порога каждая
--                                   продажа дёргала бы SetAsync — это съело бы
--                                   квоту MemoryStore на сервере. 100 монет /
--                                   5 м глубины — игрок не замечает «лага»,
--                                   но кол-во записей падает на порядок.
Constants.LEADERBOARD = {
    COINS_MAP = "Leaderboard_Coins_v1",
    DEPTH_MAP = "Leaderboard_Depth_v1",
    topSize = 50,
    refreshIntervalSeconds = 30,
    expirationSeconds = 60 * 60 * 24 * 30,
    writeThresholdCoins = 100,
    writeThresholdDepth = 5,
}

-- Phase 11 (Pets MVP): жанро-определяющая механика.
--
-- PETS:
--   slots             — сколько петов можно держать экипированными
--                        одновременно (единый источник правды, читается через
--                        PetLogic.maxEquipped, не хардкодим числа в логике):
--                          base     — базовые слоты для всех (3);
--                          vipBonus — доп. слоты владельцам VIP-геймпасса (+2).
--                        Итог: обычный игрок — 3 слота, VIP — 5 (потолок).
--                        VIP определяется через MonetizationLogic.isVip.
--   hatchBatchMax     — макс. яиц за один Net:Handle("HatchEgg", count)
--                        («open 10x»). Античит на сервере клампит count.
--   multiMineMaxChance — потолок суммарного шанса multiMine, чтобы стек из
--                        нескольких multiMine-петов (после gamepass slots)
--                        не давал гарантированный второй блок каждый удар.
--   luckMaxMultiplier  — потолок множителя шанса скрытых комнат (luckBoost),
--                        чтобы не сломать экономику комнат на стеках.
--   eggs              — определения яиц (цена, иконка, модель).
--                        Пул питомцев каждого яйца — shared/data/EggPoolDatabase.lua.
--                        cost — цена в монетах за ОДНО яйцо.
-- Формулы (weighted roll, аккумуляция эффектов) — в shared/util/PetLogic.lua.
-- Сами питомцы и их эффекты — в shared/data/PetDatabase.lua (30 playable).
Constants.PETS = {
    slots = { base = 3, vipBonus = 2 },
    hatchBatchMax = 10,
    -- Магазин/наборы могут выдавать больше яиц за одну покупку (egg25, bundleMega).
    shopGrantMax = 25,
    -- Явный порядок «лучшего» яйца для shop-grant без eggId (слева→справа хуже→лучше).
    eggTierOrder = { "basic", "desert", "mine", "candy", "ocean", "lava", "explosive_hydro" },
    multiMineMaxChance = 0.9,
    luckMaxMultiplier = 3.0,
    eggs = {
        basic = {
            id = "basic",
            name = "Basic Egg",
            icon = "icon_egg",
            modelName = "Basic",
            cost = 1000,
            accent = Color3.fromRGB(120, 220, 100),
        },
        desert = {
            id = "desert",
            name = "Desert Egg",
            icon = "icon_egg",
            modelName = "Desert",
            cost = 7500,
            -- P1.6 (gem sink) + P2.8 (2-е яйцо): Desert Egg покупается за
            -- КРИСТАЛЛЫ (из квестов/достижений). gemCost — цена за 1 яйцо.
            -- Свой пул питомцев — EggPoolDatabase.desert.
            gemCost = 100,
            accent = Color3.fromRGB(255, 180, 70),
        },
        mine = {
            id = "mine",
            name = "Mine Egg",
            icon = "icon_egg",
            modelName = "Basic",
            cost = 8000,
            accent = Color3.fromRGB(90, 200, 110),
        },
        candy = {
            id = "candy",
            name = "Candy Egg",
            icon = "icon_egg",
            modelName = "Candy",
            cost = 35000,
            accent = Color3.fromRGB(255, 120, 200),
        },
        ocean = {
            id = "ocean",
            name = "Ocean Egg",
            icon = "icon_egg",
            modelName = "Ocean",
            cost = 150000,
            accent = Color3.fromRGB(70, 170, 255),
        },
        lava = {
            id = "lava",
            name = "Lava Egg",
            icon = "icon_egg",
            modelName = "Lava",
            cost = 750000,
            accent = Color3.fromRGB(255, 90, 45),
        },
        explosive_hydro = {
            id = "explosive_hydro",
            name = "Explosive Hydro Egg",
            icon = "icon_egg",
            modelName = "Explosive Hydro",
            cost = 3000000,
            accent = Color3.fromRGB(60, 240, 255),
        },
    },
}

-- Phase 12 (Монетизация): revenue stream после запуска.
--
-- GAMEPASSES — одноразовые покупки (Robux), проверяются через
--   MarketplaceService:UserOwnsGamePassAsync (source of truth) и кэшируются
--   в playerData.gamepasses[key]. Эффекты применяет MonetizationManager,
--   формулы (coinBoost / petSlotBonus) — единый источник в
--   shared/util/MonetizationLogic.lua.
--
--   key        — внутренний ключ (НЕ id). Используется в playerData.gamepasses,
--                DevCommands /grantpass <key>, ShopPanel.
--   id         — реальный Gamepass ID из Creator Hub. 0 = ПЛЕЙСХОЛДЕР, заменить
--                после создания пасса (в Studio реальные покупки невозможны —
--                эмуляция через /grantpass).
--   priceRobux — справочная цена для UI (фактическую берёт Roblox из Hub).
--   coinBoost  — VIP: аддитивный бонус к продаже (+0.10 = +10%), ложится в ту
--                же boost-стадию SellInventory, что daily/pet coinBoost.
--   slotBonus  — legacy-поле. Слоты питомцев теперь считаются по модели
--                Constants.PETS.slots (base 3 + VIP +2). Это поле больше НЕ
--                участвует в PetLogic.maxEquipped — оставлено, чтобы не ломать
--                конфиг геймпасса; при желании владельца петслот-пасс можно
--                перепрофилировать или убрать (см. отчёт).
Constants.GAMEPASSES = {
    vip = {
        key = "vip",
        id = 1898251109,
        name = "shop.vip.name",
        icon = "icon_crown",
        priceRobux = 399,
        desc = "shop.vip.desc",
        coinBoost = 0.10,
        title = "shop.vip.title",
        nameColor = Color3.fromRGB(255, 210, 50),
    },
    autoSell = {
        key = "autoSell",
        id = 1899583024,
        name = "shop.autoSell.name",
        icon = "upg_autosell",
        priceRobux = 120,
        badge = "shop.autoSell.badge",
        desc = "shop.autoSell.desc",
    },
    petSlots = {
        key = "petSlots",
        id = 1899829027,
        name = "shop.petSlots.name",
        icon = "tab_pets",
        priceRobux = 799,
        desc = "shop.petSlots.desc",
        slotBonus = 2,
    },
}

-- DEVPRODUCTS — повторяемые покупки (Robux), обрабатываются через
--   MarketplaceService.ProcessReceipt в MonetizationManager. Защита от
--   двойного начисления — DataStore purchase history по PurchaseId.
--
--   key           — внутренний ключ (DevCommands /grantproduct <key> [N], ShopPanel).
--   id            — реальный DeveloperProduct ID из Creator Hub. 0 = ПЛЕЙСХОЛДЕР.
--   kind          — "coins" | "eggs" | "egg_hatch" | "boost" | "bundle".
--   amount        — для coins/eggs.
--   wasPriceRobux — зачёркнутая «старая» цена в UI (скидка).
--   badge         — лента на карточке («СТАРТ», «-50%», «ХИТ»).
--   oneTime       — true → shopPurchases[key], повторная покупка не выдаёт награду.
--   perks         — список строк для hero-карточек наборов.
--   rewards       — для kind=bundle: { { kind, amount? }, { kind=boost, boostKind, multiplier, durationSec } }.
--   boostKind / multiplier / durationSec — для kind=boost.
Constants.DEVPRODUCTS = {
    starterPack = {
        key = "starterPack",
        id = 3607825764,
        name = "shop.starterPack.name",
        icon = "pack_starter",
        priceRobux = 99,
        wasPriceRobux = 499,
        badge = "shop.starterPack.badge",
        oneTime = true,
        kind = "bundle",
        desc = "shop.starterPack.desc",
        perks = { "shop.starterPack.perk1", "shop.starterPack.perk2", "shop.starterPack.perk3" },
        rewards = {
            { kind = "coins", amount = 25000 },
            { kind = "boost", boostKind = "coins", multiplier = 2, durationSec = 1800 },
            { kind = "eggs", amount = 3 },
        },
    },
    bundleMiner = {
        key = "bundleMiner",
        id = 3607825194,
        name = "shop.bundleMiner.name",
        icon = "pack_miner",
        priceRobux = 349,
        wasPriceRobux = 699,
        badge = "shop.bundleMiner.badge",
        kind = "bundle",
        desc = "shop.bundleMiner.desc",
        perks = { "shop.bundleMiner.perk1", "shop.bundleMiner.perk2", "shop.bundleMiner.perk3" },
        rewards = {
            { kind = "coins", amount = 50000 },
            { kind = "boost", boostKind = "luck", multiplier = 2, durationSec = 900 },
            { kind = "eggs", amount = 5 },
        },
    },
    bundleMega = {
        key = "bundleMega",
        id = 3607825132,
        name = "shop.bundleMega.name",
        icon = "pack_mega",
        priceRobux = 799,
        wasPriceRobux = 1599,
        badge = "shop.bundleMega.badge",
        kind = "bundle",
        desc = "shop.bundleMega.desc",
        perks = { "shop.bundleMega.perk1", "shop.bundleMega.perk2", "shop.bundleMega.perk3", "shop.bundleMega.perk4" },
        rewards = {
            { kind = "coins", amount = 250000 },
            { kind = "boost", boostKind = "coins", multiplier = 2, durationSec = 3600 },
            { kind = "boost", boostKind = "damage", multiplier = 2, durationSec = 1800 },
            { kind = "eggs", amount = 15 },
        },
    },
    boostLuck15 = {
        key = "boostLuck15",
        id = 3607824028,
        name = "shop.boostLuck15.name",
        icon = "buff_luck",
        priceRobux = 49,
        kind = "boost",
        boostKind = "luck",
        multiplier = 2,
        durationSec = 900,
		desc = "shop.boostLuck15.desc",
    },
    boostLuck60 = {
        key = "boostLuck60",
        id = 3607824932,
        name = "shop.boostLuck60.name",
        icon = "buff_luck",
        priceRobux = 149,
        wasPriceRobux = 196,
        kind = "boost",
        boostKind = "luck",
        multiplier = 2,
        durationSec = 3600,
        desc = "shop.boostLuck60.desc",
    },
    boostCoins15 = {
        key = "boostCoins15",
        id = 3607823520,
        name = "shop.boostCoins15.name",
        icon = "buff_coin",
        priceRobux = 49,
        kind = "boost",
        boostKind = "coins",
        multiplier = 2,
        durationSec = 900,
        desc = "shop.boostCoins15.desc",
    },
    boostCoins60 = {
        key = "boostCoins60",
        id = 3607823642,
        name = "shop.boostCoins60.name",
        icon = "buff_coin",
        priceRobux = 149,
        wasPriceRobux = 196,
        kind = "boost",
        boostKind = "coins",
        multiplier = 2,
        durationSec = 3600,
        desc = "shop.boostCoins60.desc",
    },
    boostDamage15 = {
        key = "boostDamage15",
        id = 3607823852,
        name = "shop.boostDamage15.name",
        icon = "buff_damage",
        priceRobux = 59,
        kind = "boost",
        boostKind = "damage",
        multiplier = 2,
        durationSec = 900,
        desc = "shop.boostDamage15.desc",
    },
    boostSpeed15 = {
        key = "boostSpeed15",
        id = 3607824997,
        name = "shop.boostSpeed15.name",
        icon = "upg_speed",
        priceRobux = 59,
        kind = "boost",
        boostKind = "speed",
        multiplier = 2,
        durationSec = 900,
        desc = "shop.boostSpeed15.desc",
    },
    coinsSmall = {
        key = "coinsSmall",
        id = 3607825478,
        name = "shop.coinsSmall.name",
        icon = "coin",
        priceRobux = 99,
        wasPriceRobux = 149,
        kind = "coins",
        amount = 10000,
        desc = "shop.coinsSmall.desc",
    },
    coinsMedium = {
        key = "coinsMedium",
        id = 3607825379,
        name = "shop.coinsMedium.name",
        icon = "coin",
        priceRobux = 399,
        wasPriceRobux = 599,
        kind = "coins",
        amount = 100000,
        desc = "shop.coinsMedium.desc",
    },
    coinsLarge = {
        key = "coinsLarge",
        id = 3607825304,
        name = "shop.coinsLarge.name",
        icon = "coin",
        priceRobux = 899,
        wasPriceRobux = 1499,
        badge = "shop.coinsLarge.badge",
        kind = "coins",
        amount = 500000,
        desc = "shop.coinsLarge.desc",
    },
    coinsMega = {
        key = "coinsMega",
        id = 3607825435,
        name = "shop.coinsMega.name",
        icon = "coin",
        priceRobux = 2499,
        wasPriceRobux = 4999,
        badge = "shop.coinsMega.badge",
        kind = "coins",
        amount = 2000000,
        desc = "shop.coinsMega.desc",
    },
    egg5 = {
        key = "egg5",
        id = 3607825681,
        name = "shop.egg5.name",
        icon = "icon_egg",
        priceRobux = 99,
        kind = "eggs",
        amount = 5,
        desc = "shop.egg5.desc",
    },
    egg10 = {
        key = "egg10",
        id = 3607825529,
        name = "shop.egg10.name",
        icon = "icon_egg",
        priceRobux = 199,
        wasPriceRobux = 249,
        kind = "eggs",
        amount = 10,
        desc = "shop.egg10.desc",
    },
    egg25 = {
        key = "egg25",
        id = 3607825620,
        name = "shop.egg25.name",
        icon = "icon_egg",
        priceRobux = 399,
        wasPriceRobux = 598,
        badge = "shop.egg25.badge",
        kind = "eggs",
        amount = 25,
        desc = "shop.egg25.desc",
    },
}

-- Phase 13 (Ore Discovery Index): ключевая retention-механика. Цель охоты —
-- сама руда (как в оригинале), а не петы. Журнал находок («Открыто N/M»)
-- превращает копание в коллекционирование кор-ресурса.
--
-- DISCOVERY:
--   layerMilestoneCoins — разовая награда за ПОЛНОСТЬЮ открытый слой (все
--     руды слоя найдены хотя бы раз). Масштабируется с глубиной — нижние
--     слои гейтятся ребёртами, поэтому награда растёт на порядки. Защита от
--     двойной выдачи — playerData.discoveredMilestones[layerId].
-- Формулы (прогресс, каталог по слоям, проверка полноты) — единый источник в
-- shared/util/DiscoveryLogic.lua. Сами руды — shared/data/OreDatabase.lua.
Constants.DISCOVERY = {
    layerMilestoneCoins = {
        dirt = 2500,
        stone = 15000,
        limestone = 75000,
        crimson = 300000,
        marble = 1000000,
        obsidian = 5000000,
        void = 25000000,
    },
}

-- Соц-награда: вступление в группу + добавление игры в избранное.
-- groupId / universeId — заменить после публикации (Creator Hub).
-- Избранное сервером не проверяется (Roblox API); клиент подтверждает
-- через ConfirmSocialFavorite после PromptSetFavorite.
Constants.SOCIAL_REWARD = {
    groupId = 1066009408, -- Zeon Studio (roblox.com/communities/1066009408)
    placeId = 77149464720360, -- Deep Digger (public)
    universeId = 10434759721,
    rewards = {
        coins = 7500,
        gems = 15,
        boost = { kind = "coins", multiplier = 2, durationSec = 900 },
    },
}

-- Обратная совместимость: профиль слоёв живёт в data/LayerProfile.lua.
local LayerProfile = require(script.Parent.data.LayerProfile)
Constants.LAYER_PROFILE = LayerProfile.IDENTITY
Constants.LAYER_BLOCK_GLOW = LayerProfile.BLOCK_GLOW

return Constants
