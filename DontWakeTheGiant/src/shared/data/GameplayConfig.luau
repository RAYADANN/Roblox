--!strict
-- Движение, перенос, подушка, замок, участки (GDD 2.1, 2.6, 6.1, 12.3).

local GameplayConfig = {}

-- Движение
GameplayConfig.WALK_SPEED = 16
GameplayConfig.SNEAK_SPEED = 8
-- Сила (GDD 2.1, 5.3, 9.1). Вес предмета влияет только на шум и взгляд, скорость — отношение Strength / Need.
GameplayConfig.START_STRENGTH = 100
GameplayConfig.NEED_BY_RARITY = {
    Common = 10,
    Uncommon = 50,
    Rare = 2e3,
    Epic = 1e5,
    Legendary = 5e6,
    Mythic = 5e8,
    Secret = 1e9,
} :: { [string]: number }
-- Скорость с предметом: отношение меньше ratio → mult; не меньше последнего ratio → ×1.
GameplayConfig.CARRY_SPEED_BY_RATIO = {
    { ratio = 2, mult = 0.6 },
    { ratio = 5, mult = 0.75 },
    { ratio = 10, mult = 0.9 },
}
GameplayConfig.SURFACE_SPEED_MULT = {
    Water = 0.6,
    Milk = 0.8,
} :: { [string]: number }

-- Взятие
GameplayConfig.GRAB_HOLD_SEC = 0.4
GameplayConfig.STEAL_HOLD_SEC = 1.5
GameplayConfig.GRAB_MAX_DIST = 12
GameplayConfig.GRAB_MAX_PER_SEC = 2
GameplayConfig.CARRY_OFFSET_Y = 3

-- Подушка
GameplayConfig.PILLOW_COOLDOWN_SEC = 2
GameplayConfig.PILLOW_RANGE = 7
GameplayConfig.PILLOW_HALF_ANGLE = 60
GameplayConfig.PILLOW_RAGDOLL_SEC = 0.8
GameplayConfig.PILLOW_PUSH_SPEED = 40

-- Участки
GameplayConfig.PLOT_COUNT = 8
GameplayConfig.PLOT_RADIUS = 200
GameplayConfig.PLOT_SIZE = 40
GameplayConfig.PLOT_Y = 18
GameplayConfig.PEDESTALS_OPEN = 6
GameplayConfig.PEDESTAL_STEP = 4.5
GameplayConfig.PLOT_COLORS = {
    Color3.fromHex("#C4281C"),
    Color3.fromHex("#0D69AC"),
    Color3.fromHex("#4B974B"),
    Color3.fromHex("#F5CD30"),
    Color3.fromHex("#A259FF"),
    Color3.fromHex("#DA8541"),
    Color3.fromHex("#FF66CC"),
    Color3.fromHex("#6CD9FF"),
}

-- Замок
GameplayConfig.LOCK_DURATION_SEC = 45
GameplayConfig.LOCK_COOLDOWN_SEC = 60

-- Античит: горизонтальная скорость выше допустимой × это дольше LIMIT_SEC → откат.
GameplayConfig.SPEED_CHECK_MULT = 1.5
GameplayConfig.SPEED_CHECK_LIMIT_SEC = 1

return GameplayConfig
