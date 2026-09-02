--!strict
-- Shared Flipper spring presets. Higher damping + lower freq = smoother.

export type SpringOpts = {
    frequency: number,
    dampingRatio: number,
}

-- Critically / over-damped: no bounce, soft ease.
local soft: SpringOpts = {
    frequency = 4.2,
    dampingRatio = 1.05,
}

-- Gentle settle, tiny overshoot.
local smooth: SpringOpts = {
    frequency = 5.0,
    dampingRatio = 0.92,
}

-- Noticeable pop (use sparingly).
local bouncy: SpringOpts = {
    frequency = 5.5,
    dampingRatio = 0.55,
}

-- Slow fades / fills.
local slow: SpringOpts = {
    frequency = 3.2,
    dampingRatio = 1.1,
}

return {
    soft = soft,
    smooth = smooth,
    bouncy = bouncy,
    slow = slow,
}
