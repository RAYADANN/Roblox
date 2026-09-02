--!strict
-- Design canvas metrics (1920×1080 space). Layout must not fork by device.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

export type DesignMetrics = {
    scale: number,
    reference: Vector2,
    safeTop: number,
    safeLeft: number,
}

local DEFAULT: DesignMetrics = {
    scale = 1,
    reference = Vector2.new(1920, 1080),
    safeTop = 0,
    safeLeft = 0,
}

local DesignContext = React.createContext(DEFAULT)

return DesignContext
