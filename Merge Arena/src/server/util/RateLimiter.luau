--!strict
-- Token-bucket rate limit per player.

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiter =
    typeof(setmetatable(
        {} :: {
            _buckets: { [Player]: { count: number, resetAt: number } },
            _max: number,
            _window: number,
        },
        RateLimiter
    ))

function RateLimiter.new(maxPerWindow: number, windowSec: number): RateLimiter
    return setmetatable({
        _buckets = {},
        _max = maxPerWindow,
        _window = windowSec,
    }, RateLimiter) :: any
end

function RateLimiter:allow(player: Player): boolean
    local now = os.clock()
    local bucket = self._buckets[player]
    if not bucket or now >= bucket.resetAt then
        self._buckets[player] = { count = 1, resetAt = now + self._window }
        return true
    end
    if bucket.count >= self._max then
        return false
    end
    bucket.count += 1
    return true
end

function RateLimiter:clear(player: Player)
    self._buckets[player] = nil
end

return RateLimiter
