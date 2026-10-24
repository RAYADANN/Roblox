--!strict
-- Шум, фазы, взгляд, удары (GDD 2.2–2.4, 4.2, 4.3).

local GiantConfig = {}

-- Шум
GiantConfig.NOISE_MAX = 100
GiantConfig.TICK_SEC = 0.1
GiantConfig.ZONE_RADIUS = 140
GiantConfig.WALK_NOISE_PER_SEC = 1.5
GiantConfig.SNEAK_NOISE_PER_SEC = 0.3
GiantConfig.MOVING_MIN_SPEED = 2
GiantConfig.LANDING_NOISE = 2
GiantConfig.PILLOW_NOISE = 6
GiantConfig.DECAY_PER_SEC = 4
GiantConfig.DROUGHT_DECAY_PER_SEC = 1
GiantConfig.WAKE_DROUGHT_SEC = 360
GiantConfig.SURFACE_NOISE_MULT = {
    Crunchy = 3,
    Quiet = 0.4,
    Water = 2,
    Milk = 0.4,
    Body = 2,
} :: { [string]: number }
-- Атрибут Noise обновляется только при изменении на столько (GDD 12.3).
GiantConfig.NOISE_REPLICATE_STEP = 0.5

-- Фазы: нижняя граница шума. Глаз закрывается с гистерезисом.
GiantConfig.RESTLESS_AT = 40
GiantConfig.EYE_OPEN_AT = 70
GiantConfig.EYE_CLOSE_BELOW = 65

-- Restless: взмах рукой
GiantConfig.SWAT_INTERVAL_MIN = 6
GiantConfig.SWAT_INTERVAL_MAX = 10
GiantConfig.SWAT_WARN_SEC = 1.2
GiantConfig.SWAT_SWING_SEC = 0.5
GiantConfig.SWAT_RETURN_SEC = 1.0
GiantConfig.SWAT_HITBOX_STEP_SEC = 0.05
GiantConfig.SWAT_RAISE_HEIGHT = 14
-- 4 заранее заданные дуги: углы (градусы, от +X против часовой в плоскости XZ) вокруг плеча правой руки.
GiantConfig.SWAT_ARCS = {
    { from = 60, to = 130 },
    { from = 100, to = 170 },
    { from = 20, to = 90 },
    { from = 140, to = 200 },
}

-- Eye Open: взгляд
GiantConfig.GAZE_HALF_ANGLE = 35
GiantConfig.GAZE_RANGE = 160
GiantConfig.GAZE_TURN_DEG_PER_SEC = 20
-- Взгляд ходит туда-обратно вокруг +X (к ногам); за головой слепая зона.
GiantConfig.GAZE_SWEEP_HALF_DEG = 135
GiantConfig.GAZE_CATCH_SEC = 0.6
GiantConfig.GAZE_DECAY_MULT = 3
GiantConfig.GAZE_HEAVY_WEIGHT = 4

-- WAKE
GiantConfig.WAKE_RISE_SEC = 1.5
GiantConfig.WAKE_SLAM_SEC = 10
GiantConfig.WAKE_YAWN_SEC = 3.5
GiantConfig.TEDDY_RAGE_SEC = 15
GiantConfig.WAKE_RISE_DEG = 60
GiantConfig.SLAM_INTERVAL_SEC = 1.8
GiantConfig.SLAM_WARN_SEC = 1.0
GiantConfig.SLAM_RADIUS = 18
GiantConfig.AFTER_WAKE_NOISE = 25
GiantConfig.AFTER_WAKE_CALM_SEC = 20
GiantConfig.AFTER_WAKE_NOISE_MULT = 0.5

-- Дыхание
GiantConfig.BREATH_PERIOD_SEC = 4
GiantConfig.BREATH_HEIGHT = 2

-- Поимка (GDD 2.4)
GiantConfig.LAUNCH_HEIGHT = 60
GiantConfig.LAUNCH_DIST_MIN = 120
GiantConfig.LAUNCH_DIST_MAX = 160
GiantConfig.RAGDOLL_SEC = 2.5

return GiantConfig
