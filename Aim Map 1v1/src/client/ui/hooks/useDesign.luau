--!strict
-- Design canvas metrics from DesignRoot (safe insets in design px).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignContext = require(script.Parent.Parent.context.DesignContext)

export type DesignMetrics = DesignContext.DesignMetrics

local function useDesign(): DesignMetrics
    return React.useContext(DesignContext)
end

return useDesign
